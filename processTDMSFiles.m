function tdmsTables = processTDMSFiles(decimateFactor, imageFolder, normalization_method)
    % Set a default value for decimateFactor if not provided
    if nargin < 1
        decimateFactor = 1;
    end

    % Call listFilesInFolder to get the file list and folder path
    [fileStruct, folderPathStruct] = listFilesInFolder();

    % Extract the list of .tdms filenames
    fileList = fileStruct.files;
    folderPath = folderPathStruct.folder;

    % Check if there are no files to process
    if isempty(fileList)
        disp('No .tdms files found in the folder.');
        tdmsTables = struct();
        return;
    end

    % Creates a dictionary to store the data with the corresponding labels
    tdmsTables = struct();

    for i = 1:length(fileList)
        [label, torque, speed, damageLabel, damageType] = extractVariables(fileList{i});

        fullFilePath = fullfile(folderPath, fileList{i});
        
        % Read the data from the TDMS file
        data = tdmsread(fullFilePath);
        dataTable = data{1};

        % Apply decimation if needed
        if decimateFactor > 1
            % Initialize a new table for the decimated data
            sampledData = dataTable(1:decimateFactor:end, :);
            sampling_frequency = 100000/decimateFactor;
            % Decimate each column except for the Time column
            % for col = 2:width(dataTable)
            %     sampledData{:, col} = decimate(dataTable{:, col}, decimateFactor);
            %     % if col == 2
            %     %     channel_1 = sampledData{:, 2};
            %     %     plotFFTAndSave(channel_1, sampling_frequency, speed, 22, 'HBK_original', label, speed, torque, imageFolder);
            %     % end
            %     sampledData{:, col} = highpassGearMesh(sampledData{:, col}, sampling_frequency, speed, 22);
            %     % if col == 2
            %     %     channel_1_transformed = sampledData{:, 2};
            %     %     channel_1_transformed = lowpassGearMesh(channel_1_transformed, sampling_frequency, speed, 22);
            %     %     plotFFTAndSave(channel_1_transformed, sampling_frequency, speed, 22, 'HBK_transformed', label, speed, torque, imageFolder);
            %     % end
            % end
            sampledData{:, 2} = decimate(dataTable{:, 2}, decimateFactor);
            %plotFFTAndSave(sampledData{:, 2}, sampling_frequency, speed, 22, 'HBK_original', label, speed, torque, imageFolder)
            if normalization_method == "robust_scaling"
                sampledData{:, 2} = robust_scaling(sampledData{:, 2});
            elseif normalization_method == "min_max"
                sampledData{:, 2} = min_max_normalization(sampledData{:, 2});
            elseif normalization_method == "z_score"
                sampledData{:, 2} = z_score_normalization(sampledData{:, 2});
            end
            %sampledData{:, 2} = highpassGearMesh(sampledData{:, 2}, sampling_frequency, speed, 22);
            if nargin >= 2 && ~isempty(imageFolder)
                plotFFTAndSave(sampledData{:, 2}, sampling_frequency, speed, 22, 'HBK_transformed', label, speed, torque, imageFolder);
            end
            %
        else
            sampledData = dataTable;
        end

        [~, fileName, ~] = fileparts(fullFilePath);
        
        % Creates a valid name for struct field
        validFieldName = matlab.lang.makeValidName(fileName);
        
        % Store the data in the struct
        tdmsTables.(validFieldName).data = sampledData;
        tdmsTables.(validFieldName).label = label;
        tdmsTables.(validFieldName).torque = torque;
        tdmsTables.(validFieldName).speed = speed;
        tdmsTables.(validFieldName).damageLabel = damageLabel;
        tdmsTables.(validFieldName).damageType = damageType;

        if decimateFactor == 1
            tdmsTables.(validFieldName).fs = 100000;
        else
            tdmsTables.(validFieldName).fs = 100000 / decimateFactor;
        end
    end
end
