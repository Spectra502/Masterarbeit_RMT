function process_all_files_CSV_SIZA_parallel()
     % ---- Config ----
    sourceFolder = 'H:\Masterarbeit\Programming\Data\SIZA\CSV\pitting';
    addpath('H:\Masterarbeit\Experiment_Database\normalization');

    targetRoot = 'H:\Masterarbeit\Programming\Extracted_Features\SIZA_all_damages_highpass';
    if ~exist(targetRoot, 'dir'), mkdir(targetRoot); end

    segment_length = 1000;
    overlap        = 500;
    minFs          = 5000;    % lower bound (Hz)
    maxFs          = 20000;   % upper bound (Hz)
    Zteeth         = 22;      % pinion teeth for GMF

    [~, label] = fileparts(sourceFolder);

    % Folder structure: <targetRoot>/<label>/{time,frequency,time-frequency}
    labelFolder = fullfile(targetRoot, label);
    timeDir = fullfile(labelFolder, 'time');
    freqDir = fullfile(labelFolder, 'frequency');
    tfDir   = fullfile(labelFolder, 'time-frequency');
    if ~exist(labelFolder,'dir'), mkdir(labelFolder); end
    if ~exist(timeDir,'dir'), mkdir(timeDir); end
    if ~exist(freqDir,'dir'), mkdir(freqDir); end
    if ~exist(tfDir,'dir'), mkdir(tfDir); end

    % Files
    csvFiles = dir(fullfile(sourceFolder, '*.csv'));
    if isempty(csvFiles), disp('No CSV files found.'); return; end

    % Read once: RPM / Torque / fs table
    calcPath = fullfile(sourceFolder, ...
        sprintf('%s_csv_fs_calculated', label), ...
        sprintf('%s_csv_calculated_frequencies.csv', label));
    T = readtable(calcPath);

    fileNames = string({csvFiles.name}).';
    Tnames    = string(T.Filename);
    [isMatch, loc] = ismember(lower(fileNames), lower(Tnames));

    speedVec  = nan(numel(csvFiles),1);
    torqueVec = nan(numel(csvFiles),1);
    fsVec     = nan(numel(csvFiles),1);
    speedVec(isMatch)  = T.RPM(loc(isMatch));
    torqueVec(isMatch) = T.Torque(loc(isMatch));
    fsVec(isMatch)     = round(T.EstimatedFS(loc(isMatch)));

    % Pre-filter to range: minFs <= fs <= maxFs AND GMF < Nyquist
    GMFVec = (speedVec/60) * Zteeth;
    nyqVec = fsVec/2;
    valid  = isMatch & fsVec >= minFs & fsVec <= maxFs & GMFVec < nyqVec;

    if ~any(valid)
        warning('No files satisfy %g Hz <= fs <= %g Hz and GMF < Nyquist.', minFs, maxFs);
        return
    end

    idxList = find(valid);
    fprintf('Processing %d/%d files (%g Hz <= fs <= %g Hz and GMF < Nyquist).\n', ...
            numel(idxList), numel(csvFiles), minFs, maxFs);

    % Parallel pool (process-based)
    if isempty(gcp('nocreate')), parpool('Processes'); end
    pctRunOnAll addpath('H:\Masterarbeit\Experiment_Database\normalization');

    % ---- PARFOR over filtered indices ----
    parfor ii = 1:numel(idxList)
        k = idxList(ii);

        fileName     = csvFiles(k).name;
        fullFilePath = fullfile(sourceFolder, fileName);
        speed  = speedVec(k);
        torque = torqueVec(k);
        fs     = fsVec(k);

        % Final guard (per worker)
        if fs < minFs || fs > maxFs
            fprintf('Skipping %s: fs=%.1f Hz outside [%g, %g] Hz.\n', fileName, fs, minFs, maxFs);
            continue
        end
        GMF = (speed/60)*Zteeth;
        nyq = fs/2;
        if GMF >= nyq
            fprintf('Skipping %s: GMF=%.1f Hz ≥ Nyquist=%.1f Hz.\n', fileName, GMF, nyq);
            continue
        end

        try
            data = readmatrix(fullFilePath);
            if isempty(data)
                warning('File %s is empty. Skipping...', fileName);
                continue
            end

            ch = data(:,1);
            ch = min_max_normalization(ch);
            ch = highpassGearMesh(ch, fs, speed, Zteeth, 4);
            
            % [ch, ok] = bandpassGearMeshRobust(ch, fs, speed, 22, 50, 4);  % e.g., bw=50 Hz
            % if ~ok
            %     fprintf('Skipping %s after bandpass guards.\n', fileName);
            %     continue
            % end

            % One domain at a time → dedicated output dirs
            process_vectorSignal(ch, timeDir, segment_length, overlap, ...
                                 fs, {'time'}, label, speed, torque);

            process_vectorSignal(ch, freqDir, segment_length, overlap, ...
                                 fs, {'frequency'}, label, speed, torque);

            process_vectorSignal(ch, tfDir,   segment_length, overlap, ...
                                 fs, {'time-frequency'}, label, speed, torque);

        catch ME
            warning('Failed on %s: %s', fileName, ME.message);
        end
    end
end