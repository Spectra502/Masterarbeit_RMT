function plot_csv_vibration_dataset(inputFolder, outputFolder, varargin)
%PLOT_CSV_VIBRATION_DATASET  Batch plot time & frequency for gearbox CSVs.
%
%   plot_csv_vibration_dataset(inputFolder, outputFolder)
%   plot_csv_vibration_dataset(..., 'Fs', 12800, 'GearTeeth', 36, ...
%                                   'MotorToInterRatio', 29/95)
%
% INPUTS
%   inputFolder : folder containing CSV files (Excel CSV format)
%   outputFolder: base folder where plots will be saved (folders created)
%
% NAME PARSER & OUTPUT STRUCTURE
%   Case is inferred from filename prefix up to "_speed_circulation" or
%   "_torque_circulation". For each case:
%       outputFolder/CASE/time/<channel>/*.png
%       outputFolder/CASE/frequency/<channel>/*.png
%
% FREQUENCY MARKERS
%   - Rotational frequency (intermediate shaft): f_rot  [Hz]
%   - Gear-mesh frequency of 36-tooth gear    : f_mesh [Hz] = f_rot*36
%
% NOTES
%   - Expects columns (headers) like:
%       speed, torque, motor_vibration_x/y/z, gearbox_vibration_x/y/z
%   - 'speed' is a key-phase/once-per-rev-like signal (dimensionless).
%     RPM is estimated from threshold-crossing edges; if that fails,
%     it falls back to a Welch peak on the 'speed' channel.
%
% AUTHOR: (you)

% ------------------ parameters ------------------
p = inputParser;
p.addParameter('Fs', 12800, @(x)isnumeric(x)&&isscalar(x)&&x>0);
p.addParameter('GearTeeth', 36, @(x)isnumeric(x)&&isscalar(x)&&x>0);
p.addParameter('MotorToInterRatio', 29/95, @(x)isnumeric(x)&&isscalar(x)&&x>0&&x<10);
p.parse(varargin{:});
fs        = p.Results.Fs;
z_teeth   = p.Results.GearTeeth;
ratio_m2i = p.Results.MotorToInterRatio;

% channels to plot (vibration only)
accVars = ["motor_vibration_x","motor_vibration_y","motor_vibration_z", ...
           "gearbox_vibration_x","gearbox_vibration_y","gearbox_vibration_z"];

% ensure output root exists
if ~exist(outputFolder,'dir'); mkdir(outputFolder); end

% collect CSV files (Excel CSV)
files = dir(fullfile(inputFolder, '*.csv'));
if isempty(files)
    warning('No CSV files found in: %s', inputFolder);
    return;
end

for k = 1:numel(files)
    fpath = fullfile(files(k).folder, files(k).name);
    [~, fname, ~] = fileparts(fpath);

    % --------- parse case from filename ---------
    caseName = parseCaseName(fname);

    % --------- read table ----------
    T = readtable(fpath, 'Delimiter', ',', 'ReadVariableNames',true, ...
                  'VariableNamingRule','preserve');
    % normalize variable names to strings
    vn = string(T.Properties.VariableNames);

    % sanity: required channels
    required = ["speed","torque",accVars];
    missing = required(~ismember(required, vn));
    if ~isempty(missing)
        warning('Skipping %s (missing columns: %s)', fname, strjoin(missing,", "));
        continue;
    end

    N = height(T);
    t = (0:N-1).' / fs;

    % convert accel from g -> m/s^2 (keep torque as provided)
    g2ms2 = 9.80665;
    for v = accVars
        T.(v) = T.(v) * g2ms2;
    end

    % --------- RPM/Hz estimates from key-phase ----------
    [rpm_motor_med, fr_motor, fr_inter, f_mesh] = ...
        estimateFrequencies(T.speed, fs, ratio_m2i, z_teeth);

    torque_mean = mean(T.torque, 'omitnan');

    % --------- output folders for this case ----------
    timeRoot = fullfile(outputFolder, caseName, 'time');
    freqRoot = fullfile(outputFolder, caseName, 'frequency');
    for v = accVars
        ensureDir(fullfile(timeRoot, char(v)));
        ensureDir(fullfile(freqRoot, char(v)));
    end

    % --------- plotting per channel ----------
    for v = accVars
        sig = T.(v);

        % ----- TIME -----
        fig1 = figure('Visible','off'); %#ok<LFIG>
        plot(t, sig, 'LineWidth', 1); grid on;
        xlabel('Time [s]');
        ylabel('Acceleration [m/s^2]');
        title(strrep(fname,'_','\_')); % full name in title

        % annotation with speed/torque + markers
        subtitleStr = sprintf( ...
            'Torque(mean)=%.3g Nm | Motor RPM(med)=%.1f | Inter RPM(med)=%.1f | f_{rot}=%.2f Hz | f_{mesh}=%.2f Hz', ...
            torque_mean, rpm_motor_med, fr_inter*60, fr_inter, f_mesh);
        subtitle(subtitleStr);

        out1 = fullfile(timeRoot, char(v), sprintf('%s__%s_time.png', fname, char(v)));
        exportgraphics(gca, out1, 'Resolution', 200);
        close(fig1);

        % ----- FREQUENCY (Welch PSD) -----
        fig2 = figure('Visible','off'); %#ok<LFIG>
        % Welch PSD (robust for long, nonstationary segments)
        nfft = 4096;
        win  = hanning(nfft);
        noverlap = round(0.5*nfft);
        [Pxx, F] = pwelch(sig, win, noverlap, nfft, fs, 'onesided');

        plot(F, 10*log10(Pxx), 'LineWidth', 1); grid on;
        xlabel('Frequency [Hz]');
        ylabel('PSD [dB/Hz]');
        title(sprintf('%s  (%s)', strrep(fname,'_','\_'), char(v)));

        % frequency markers
        hold on;
        xl1 = xline(fr_inter,  '--', 'f_{rot}',  'LabelOrientation','horizontal', 'LineWidth',1);
        xl2 = xline(f_mesh,    '-',  'f_{mesh}', 'LabelOrientation','horizontal', 'LineWidth',1);
        % keep auto colors; do not set explicit colors

        % annotate speed/torque again
        text(0.01*max(F), max(10*log10(Pxx))-3, ...
            sprintf('Torque(mean)=%.3g Nm | Motor RPM(med)=%.1f | Inter RPM(med)=%.1f', ...
                    torque_mean, rpm_motor_med, fr_inter*60), ...
            'VerticalAlignment','top');

        xlim([0, fs/2]);
        out2 = fullfile(freqRoot, char(v), sprintf('%s__%s_freq.png', fname, char(v)));
        exportgraphics(gca, out2, 'Resolution', 200);
        close(fig2);
    end

    fprintf('[%d/%d] Done: %s | Case: %s | f_rot=%.2f Hz | f_mesh=%.2f Hz\n', ...
        k, numel(files), fname, caseName, fr_inter, f_mesh);
end
end

% ================== helpers ==================
function ensureDir(pth)
    if ~exist(pth,'dir'); mkdir(pth); end
end

function caseName = parseCaseName(fname)
% Extract substring before _speed_circulation or _torque_circulation
    tokens = regexp(fname, '^(.*)_(speed|torque)_circulation.*$', 'tokens', 'once');
    if ~isempty(tokens)
        caseName = tokens{1};
    else
        % fallback: use everything up to the 3rd underscore (e.g., gear_pitting_H)
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
% Estimate RPM from key-phase signal, with Welch fallback.
% Returns:
%   rpm_motor_med : median motor RPM
%   fr_motor      : motor rotational freq [Hz]
%   fr_inter      : intermediate-shaft rotational freq [Hz]
%   f_mesh        : gear-mesh frequency [Hz] (z_teeth on intermediate)

    speedSig = speedSig(:);
    thr = 0.5*(min(speedSig)+max(speedSig));
    edges = find(speedSig(2:end) >= thr & speedSig(1:end-1) < thr) + 1;

    rpm_motor = [];
    if numel(edges) >= 4
        Te = diff(edges)/fs;              % s per revolution
        rpm_motor = 60./Te;
        % guard rails against outliers
        rpm_motor = rpm_motor(isfinite(rpm_motor) & rpm_motor>10 & rpm_motor<60000);
    end

    if isempty(rpm_motor)
        % Fallback: Welch peak of "speed" channel (below 1 kHz)
        nfft = 8192;
        [Psp, Fsp] = pwelch(speedSig, hanning(nfft), round(0.5*nfft), nfft, fs, 'onesided');
        % pick the strongest peak ignoring DC
        [~, idx] = max(Psp(Fsp>0.5 & Fsp<1000));
        cand = Fsp(Fsp>0.5 & Fsp<1000);
        fr_motor = cand(max(idx,1));
        rpm_motor_med = fr_motor*60;
    else
        rpm_motor_med = median(rpm_motor, 'omitnan');
        fr_motor = rpm_motor_med/60;
    end

    fr_inter = fr_motor * ratio_m2i;      % rotational frequency of faulty gear shaft
    f_mesh   = fr_inter * z_teeth;        % gear-mesh frequency
end
