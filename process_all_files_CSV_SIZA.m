function process_all_files_CSV_SIZA()
    % Define folder where your CSV files are
    sourceFolder = 'H:\Masterarbeit\Programming\Data\SIZA\CSV\healthy';

    addpath('H:\Masterarbeit\Experiment_Database\normalization');
    % Parameters that stay constant
    targetFilePath = 'H:\Masterarbeit\Programming\Extracted_Features\SIZA_all_damages_highpass';
    if ~exist(targetFilePath, 'dir')
        mkdir(targetFilePath);
    end
    segment_length = 1000;
    overlap = 500;
    featureDomains = {'time', 'frequency', 'time-frequency'};
    [~, label] = fileparts(sourceFolder)
    timeFolder = fullfile(targetFilePath, 'time');
    frequencyFolder = fullfile(targetFilePath, 'frequency')
    timeFrequencyFolder = fullfile(targetFilePath, 'time-frequency')

    % Get list of CSV files in the folder
    csvFiles = dir(fullfile(sourceFolder, '*.csv'));

    % Check if any files were found
    if isempty(csvFiles)
        disp('No CSV files found in the folder.');
        return;
    end

    % Loop through each file
    for k = 1:length(csvFiles)
        fileName = csvFiles(k).name;
        fullFilePath = fullfile(sourceFolder, fileName);
        fprintf('\nProcessing file: %s\n', fileName);

        % Read the first column of the CSV file
        data = readmatrix(fullFilePath);
        if isempty(data)
            warning('File %s is empty. Skipping...', fileName);
            continue;
        end

        channel_1 = data(:, 1);
        % normalized_ch = min_max_normalization(channel_1);
        % 
        % %Ask user for input values
        % speed = input('Enter speed: ');
        % torque = input('Enter torque: ');
        % fs = input('Enter sampling frequency (fs): ');

        %table_fs_calculated = readtable('H:\Masterarbeit\Programming\Data\SIZA\CSV\healthy\healthy_csv_fs_calculated\healthy_csv_calculated_frequencies.csv')
        calculated_frequencies_path = fullfile(sourceFolder, ...
        sprintf('%s_csv_fs_calculated', label), ...
        sprintf('%s_csv_calculated_frequencies.csv', label))

        table_fs_calculated = readtable(calculated_frequencies_path)

        idx = find(strcmp(table_fs_calculated{:,1}, fileName))

        % Display result
        if ~isempty(idx)
            fprintf('Match found at row %d\n', idx)
            fprintf('speed of %s is: %d RPM\n', fileName, table_fs_calculated.RPM(idx))
            fprintf('torque: %d Nm\n', table_fs_calculated.Torque(idx))
            fprintf('sampling Frequency: %d Hz\n', round(table_fs_calculated.EstimatedFS(idx)))
            speed = table_fs_calculated.RPM(idx);
            torque = table_fs_calculated.Torque(idx);
            fs = round(table_fs_calculated.EstimatedFS(idx));
        else
            disp('No match found.');
        end

        normalized_ch_min_max = min_max_normalization(channel_1);
        normalized_ch = highpassGearMesh(normalized_ch_min_max, fs, speed, 22, 4);

        % Call your processing function
        process_vectorSignal(normalized_ch, targetFilePath, segment_length, overlap, fs, featureDomains, label, speed, torque);
    end

end

