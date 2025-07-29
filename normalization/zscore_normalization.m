function norm_signal = zscore_normalization(signal)
    mu = mean(signal);
    sigma = std(signal);
    norm_signal = (signal - mu) / sigma;
end
