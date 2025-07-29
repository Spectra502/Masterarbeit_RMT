function norm_signal = min_max_normalization(signal)
    min_val = min(signal);          
    max_val = max(signal);         
    norm_signal = (signal - min_val) / (max_val - min_val);  % Rescale to [0, 1]
end
