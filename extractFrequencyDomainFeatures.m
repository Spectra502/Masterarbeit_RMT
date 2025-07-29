function features = extractFrequencyDomainFeatures(segment, fs)
    mean_freq = zeros(1, size(segment, 2));
    median_freq = zeros(1, size(segment, 2));
    bandwidth_val = zeros(1, size(segment, 2));
    % spectral_centroid = zeros(1, size(segment, 2));
    spectral_flatness = zeros(1, size(segment, 2));
    % spectral_entropy = zeros(1, size(segment, 2));
    % spectral_skewness = zeros(1, size(segment, 2));
    % spectral_kurtosis = zeros(1, size(segment, 2));
    % 
    % for ch = 1:size(segment, 2)
    %     [Pxx, f] = pwelch(segment(:, ch), [], [], [], fs);
    %     mean_freq(ch) = sum(f .* Pxx) / sum(Pxx);
    %     median_freq(ch) = medfreq(segment(:, ch), fs);
    %     bandwidth_val(ch) = obw(segment(:, ch), fs);
    %     spectral_centroid(ch) = sum(f .* Pxx) / sum(Pxx);
    %     spectral_flatness(ch) = geomean(Pxx) / mean(Pxx);
    %     spectral_entropy(ch) = -sum(Pxx .* log(Pxx));
    %     spectral_skewness(ch) = skewness(Pxx);
    %     spectral_kurtosis(ch) = kurtosis(Pxx);
    % end

    for ch = 1:size(segment, 2)
        [Pxx, f] = pwelch(segment(:, ch), [], [], [], fs);
        mean_freq(ch) = sum(f .* Pxx) / sum(Pxx);
        median_freq(ch) = medfreq(segment(:, ch), fs);
        bandwidth_val(ch) = obw(segment(:, ch), fs);
        spectral_flatness(ch) = geomean(Pxx) / mean(Pxx);
       
    end

    % Return all frequency-domain features
    % features = [mean_freq, median_freq, bandwidth_val, spectral_centroid, spectral_flatness, ...
    %             spectral_entropy, spectral_skewness, spectral_kurtosis];
    features = [mean_freq, median_freq, bandwidth_val, spectral_flatness];

end
