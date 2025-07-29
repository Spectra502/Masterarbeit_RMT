function process_vectorSignal(signalVector, targetFilePath, segment_length, overlap, fs, featureDomains, label, speed, torque)
    % Set default values if not provided
    if nargin < 3 || isempty(segment_length)
        segment_length = 1000;
    end
    if nargin < 4 || isempty(overlap)
        overlap = 500;
    end
    if nargin < 5 || isempty(fs)
        fs = 1000;  % Default sampling frequency
    end
    if nargin < 6 || isempty(featureDomains)
        featureDomains = {'time', 'frequency', 'time-frequency'};
    end
    if nargin < 7, label = 'unknown'; end
    if nargin < 8, speed = 0; end
    if nargin < 9, torque = 0; end

    % Determine number of segments
    num_segments = floor((length(signalVector) - overlap) / (segment_length - overlap));

    % Initialize feature matrix
    features = [];

    % Loop through each segment and extract features
    for seg = 1:num_segments
        start_idx = (seg-1) * (segment_length - overlap) + 1;
        end_idx = start_idx + segment_length - 1;

        % Extract the segment
        segment = signalVector(start_idx:end_idx);

        % Initialize the segment's feature vector
        segment_features = [];

        % Extract selected features
        if any(strcmp(featureDomains, 'time'))
            segment_features = [segment_features, extractTimeDomainFeatures(segment)];
        end
        if any(strcmp(featureDomains, 'frequency'))
            segment_features = [segment_features, extractFrequencyDomainFeatures(segment, fs)];
        end
        if any(strcmp(featureDomains, 'time-frequency'))
            segment_features = [segment_features, extractTimeFrequencyDomainFeatures(segment, fs)];
        end

        features = [features; segment_features];
    end

    % Feature names for a single vector
    feature_names = generateFeatureNames(1, featureDomains);  % Just one channel

    % Convert to table
    feature_table = array2table(features, 'VariableNames', feature_names);

    % Metadata table
    metadata_table = table(repmat({label}, size(features,1), 1), ...
                           repmat(speed, size(features,1), 1), ...
                           repmat(torque, size(features,1), 1), ...
                           'VariableNames', {'Label', 'Speed', 'Torque'});

    % Combine and write to file
    combined_table = [metadata_table, feature_table];

    % Construct filename
    domains_str = strjoin(featureDomains, '_');
    outputFileName = fullfile(targetFilePath, ...
        sprintf('Signal_%dHz_%s_%s_%d_%d_features.csv', fs, domains_str, label, speed, torque));

    writetable(combined_table, outputFileName);
end
