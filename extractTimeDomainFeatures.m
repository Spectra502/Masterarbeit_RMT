function features = extractTimeDomainFeatures(segment)
    mean_val = mean(segment);
    %rms_val = rms(segment);
    %std_dev = std(segment);
    skewness_val = skewness(segment);
    kurtosis_val = kurtosis(segment);
    %peak_to_peak_val = peak2peak(segment);
    %crest_factor = max(abs(segment)) ./ rms_val;
    %impulse_factor = max(abs(segment)) ./ mean(abs(segment));
    %clearance_factor = max(abs(segment)) ./ mean(sqrt(abs(segment)));
    %shape_factor = rms_val ./ mean(abs(segment));
    %energy_val = sum(segment.^2);
    %entropy_val = arrayfun(@(i) wentropy(segment(:, i), 'shannon'), 1:size(segment, 2));

    % Return all time-domain features
    % features = [mean_val, rms_val, std_dev, skewness_val, kurtosis_val, ...
    %             peak_to_peak_val, crest_factor, impulse_factor, clearance_factor, ...
    %             shape_factor, energy_val, entropy_val];
    features = [mean_val, skewness_val, kurtosis_val];
end
