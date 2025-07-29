function feature_names = generateFeatureNames(numChannels, featureDomains)
    % Simplified for a single channel; generate feature names based on selected domains
    feature_names = {};
    
    if any(strcmp(featureDomains, 'time'))
        %feature_names = [feature_names, {'mean', 'rms', 'std_dev', 'skewness', 'kurtosis', 'peak_to_peak', 'crest_factor', 'impulse_factor', 'clearance_factor', 'shape_factor', 'energy', 'entropy'}];
        feature_names = [feature_names, {'mean', 'skewness', 'kurtosis'}];
    end

    if any(strcmp(featureDomains, 'frequency'))
        %feature_names = [feature_names, {'mean_freq', 'median_freq', 'bandwidth', 'spectral_centroid', 'spectral_flatness', 'spectral_entropy', 'spectral_skewness', 'spectral_kurtosis'}];
        feature_names = [feature_names, {'mean_freq', 'median_freq', 'bandwidth', 'spectral_flatness'}];
    end

    if any(strcmp(featureDomains, 'time-frequency'))
        %feature_names = [feature_names, {'mean_wavelet', 'var_wavelet', 'entropy_wavelet', 'energy_wavelet', 'mean_spectrogram', 'var_spectrogram', 'entropy_spectrogram', 'energy_spectrogram'}];
        feature_names = [feature_names, {'mean_wavelet', 'var_wavelet', 'entropy_wavelet' }];
    end
end
