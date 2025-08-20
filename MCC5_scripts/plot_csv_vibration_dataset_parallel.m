function plot_csv_vibration_dataset_parallel(inputFolder, outputFolder, varargin)
%PLOT_CSV_VIBRATION_DATASET_PARALLEL
% Parallel batch plotting of time- and frequency-domain figures for CSV files.
%
% Usage:
%   plot_csv_vibration_dataset_parallel(inFolder, outFolder, ...
%       'Fs', 12800, 'GearTeeth', 36, 'MotorToInterRatio', 29/95, ...
%       'NFFT', 4096)
%
% Creates:
%   outFolder/CASE/time/<channel>/*.png
%   outFolder/CASE/frequency/<channel>/*.png
%
% Filename pattern examples (parsed to build CASE):
%   gear_pitting_H_speed_circulation_10Nm-1000rpm.csv
%   gear_pitting_L_torque_circulation_2000rpm_10Nm.csv
%   miss_teeth_torque_circulation_3000rpm_20Nm.csv

% ---------- parameters ----------
p = inputParser;
p.addParameter('Fs', 12800, @(x)isnumeric(x)&&isscalar(x)&&x>0);
p.addParameter('GearTeeth', 36, @(x)isnumeric(x)&&isscalar(x)&&x>0);
p.addParameter('MotorToInterRatio', 29/95, @(x)isnumeric(x)&&isscalar(x)&&x>0&&x<10);
p.addParameter('NFFT', 4096, @(x)isnumeric(x)&&isscalar(x)&&x>=256);
p.parse(varargin{:});
fs        = p.Results.Fs;
z_teeth   = p.Results.GearTeeth;
ratio_m2i = p.Results.MotorToInterRatio;
nfft      = p.Results.NFFT;

accVars = ["motor_vibration_x","motor_vibration_y","motor_vibration_z", ...
           "gearbox_vibration_x","gearbox_vibration_y","gearbox_vibration_z"];

if ~exist(outputFolder,'dir'); mkdir(outputFolder); end

% ---------- list files ----------
files = dir(fullfile(inputFolder, '*.csv'));
if isempty(files)
    warning('No CSV files in %s', inputFolder);
    return;
end

% ---------- prep Welch constants (broadcast to workers) ----------
win       = hanning(nfft);
noverlap  = round(0.5*nfft);

% ---------- start/ensure pool (threads if available, fallback to processes) ----------
pool = gcp('nocreate');
if isempty(pool)
    try
        parpool('threads');
    catch
        parpool; % default profile
    end
end

% ---------- simple progress (DataQueue) ----------
dq = parallel.pool.DataQueue;
nTot = numel(files);
nDone = 0;
afterEach(dq, @() fprintf('Progress: %d/%d files\r', min(nDone+1,nTot), nTot));

% ---------- PARFOR over files ----------
parfor k = 1:nTot
    fpath = fullfile(files(k).folder, files(k).name);
    [~, fname, ~] = fileparts(fpath);

    % parse case name from filename
    caseName = parseCaseName(fname);

    % robust CSV read with headers preserved
    opts = detectImportOptions(fpath, 'Delimiter', ',');
    opts.VariableNamingRule = 'preserve';
    T = readtable(fpath, opts);
    vn = string(T.Properties.VariableNames);

    % required columns
    required = ["speed","torque",accVars];
    if any(~ismember(required, vn))
        send(dq, 1); %#ok<PFBNS>
        continue;
    end

    % build time vector
    N = height(T);
    t = (0:N-1).' / fs;

    % convert acceleration g->m/s^2
    g2ms2 = 9.80665;
    for v = accVars
        T.(v) = T.(v) * g2ms2;
    end

    % estimate speeds and marker frequencies
    [rpm_motor_med, fr_motor, fr_inter, f_mesh] = ...
        estimateFrequencies(T.speed, fs, ratio_m2i, z_teeth);

    torque_mean = mean(T.torque, 'omitnan');

    % ensure output folders for this case exist (safe in parallel)
    timeRoot = fullfile(outputFolder, caseName, 'time');
    freqRoot = fullfile(outputFolder, caseName, 'frequency');
    for v = accVars
        ensureDir(fullfile(timeRoot, char(v)));
        ensureDir(fullfile(freqRoot, char(v)));
    end

    % precompute freq axis for labels (Welch F depends only on fs & nfft)
    % We still compute PSD per channel.
    for v = accVars
        sig = T.(v);

        % ---------- TIME ----------
        fig1 = figure('Visible','off');
        plot(t, sig, 'LineWidth', 1); grid on;
        xlabel('Time [s]'); ylabel('Acceleration [m/s^2]');
        title(strrep(fname,'_','\_'));  % full name
        txt = sprintf(['Torque(mean)=%.3g Nm | Motor RPM(med)=%.1f | ', ...
                       'Inter RPM(med)=%.1f | f_{rot}=%.2f Hz | f_{mesh}=%.2f Hz'], ...
                       torque_mean, rpm_motor_med, fr_inter*60, fr_inter, f_mesh);
        text(0.01*t(end), 0.98*max(sig), txt, 'Units','normalized', ...
            'HorizontalAlignment','left','VerticalAlignment','top');
        out1 = fullfile(timeRoot, char(v), sprintf('%s__%s_time.png', fname, char(v)));
        exportgraphics(gca, out1, 'Resolution', 200);
        close(fig1);

        % ---------- FREQUENCY (Welch PSD) ----------
        fig2 = figure('Visible','off');
        [Pxx, F] = pwelch(sig, win, noverlap, nfft, fs, 'onesided');
        plot(F, 10*log10(Pxx), 'LineWidth', 1); grid on;
        xlabel('Frequency [Hz]'); ylabel('PSD [dB/Hz]');
        title(sprintf('%s  (%s)', strrep(fname,'_','\_'), char(v)));
        hold on;
        xline(fr_inter, '--', 'f_{rot}', 'LabelOrientation','horizontal', 'LineWidth',1);
        xline(f_mesh,   '-',  'f_{mesh}', 'LabelOrientation','horizontal', 'LineWidth',1);
        xlim([0 fs/2]);
        text(0.01*fs/2, max(10*log10(Pxx))-3, ...
            sprintf('Torque(mean)=%.3g Nm | Motor RPM(med)=%.1f | Inter RPM(med)=%.1f', ...
                    torque_mean, rpm_motor_med, fr_inter*60), ...
            'VerticalAlignment','top');
        out2 = fullfile(freqRoot, char(v), sprintf('%s__%s_freq.png', fname, char(v)));
        exportgraphics(gca, out2, 'Resolution', 200);
        close(fig2);
    end

    send(dq, 1); %#ok<PFBNS>
end

fprintf('\nDone. Plots saved to: %s\n', outputFolder);
end

% ================= helpers =================
function ensureDir(pth)
    if ~exist(pth,'dir'); mkdir(pth); end
end

function caseName = parseCaseName(fname)
% Extract substring before _speed_circulation or _torque_circulation
    tokens = regexp(fname, '^(.*)_(speed|torque)_circulation.*$', 'tokens', 'once');
    if ~isempty(tokens)
        caseName = tokens{1};
    else
        parts = split(string(fname), '_');
        if numel(parts) >= 3
            caseName = strjoin(parts(1:3), '_');
        else
            caseName = string(fname);
        end
    end
    caseName = char(caseName);
end

function [rpm_motor_med, fr_motor, fr_inter, f_mesh] = ...
    estimateFrequencies(speedSig, fs, ratio_m2i, z_teeth)
% Robust RPM estimate from key-phase with Welch fallback (works in workers)
    speedSig = speedSig(:);
    thr = 0.5*(min(speedSig)+max(speedSig));
    edges = find(speedSig(2:end) >= thr & speedSig(1:end-1) < thr) + 1;

    rpm_motor = [];
    if numel(edges) >= 4
        Te = diff(edges)/fs;
        rpm_motor = 60./Te;
        rpm_motor = rpm_motor(isfinite(rpm_motor) & rpm_motor>10 & rpm_motor<60000);
    end

    if isempty(rpm_motor)
        % fallback via Welch peak (ignore DC)
        nfft_fb = 8192;
        [Psp, Fsp] = pwelch(speedSig, hanning(nfft_fb), round(0.5*nfft_fb), nfft_fb, fs, 'onesided');
        mask = Fsp>0.5 & Fsp<1000;
        [~, idx] = max(Psp(mask));
        fvec = Fsp(mask);
        fr_motor = fvec(max(idx,1));
        rpm_motor_med = fr_motor*60;
    else
        rpm_motor_med = median(rpm_motor, 'omitnan');
        fr_motor = rpm_motor_med/60;
    end

    fr_inter = fr_motor * ratio_m2i; % intermediate shaft rotational frequency [Hz]
    f_mesh   = fr_inter * z_teeth;   % gear-mesh frequency [Hz]
end
