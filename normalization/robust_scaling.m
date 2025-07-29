function norm_signal = robust_scaling(signal)
    med = median(signal);
    iqr_val = iqr(signal); % interquartile range = quantile(75%) - quantile(25%)
    norm_signal = (signal - med) / iqr_val;
end
