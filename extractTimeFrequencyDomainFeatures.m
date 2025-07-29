function features = extractTimeFrequencyDomainFeatures(segment, fs)
    mean_wavelet = zeros(1, size(segment, 2));
    var_wavelet = zeros(1, size(segment, 2));
    entropy_wavelet = zeros(1, size(segment, 2));
    % energy_wavelet = zeros(1, size(segment, 2));
    % mean_spectrogram = zeros(1, size(segment, 2));
    % var_spectrogram = zeros(1, size(segment, 2));
    % entropy_spectrogram = zeros(1, size(segment, 2));
    % energy_spectrogram = zeros(1, size(segment, 2));

    % for ch = 1:size(segment, 2)
    %     % Wavelet Transform
    %     [cfs, ~] = cwt(segment(:, ch), 'amor', fs);
    %     mean_wavelet(ch) = mean(abs(cfs(:)));
    %     var_wavelet(ch) = var(abs(cfs(:)));
    %     entropy_wavelet(ch) = wentropy(abs(cfs(:)), 'shannon');
    %     energy_wavelet(ch) = sum(abs(cfs(:)).^2);
    % 
    %     % Spectrogram
    %     [~, ~, ~, P] = spectrogram(segment(:, ch), 128, 120, 128, fs);
    %     mean_spectrogram(ch) = mean(abs(P(:)));
    %     var_spectrogram(ch) = var(abs(P(:)));
    %     entropy_spectrogram(ch) = wentropy(abs(P(:)), 'shannon');
    %     energy_spectrogram(ch) = sum(abs(P(:)).^2);
    % end

    for ch = 1:size(segment, 2)
        % Wavelet Transform
        [cfs, ~] = cwt(segment(:, ch), 'amor', fs);
        mean_wavelet(ch) = mean(abs(cfs(:)));
        var_wavelet(ch) = var(abs(cfs(:)));
        entropy_wavelet(ch) = wentropy(abs(cfs(:)), 'shannon');
    end

    % Return all time-frequency-domain features
    % features = [mean_wavelet, var_wavelet, entropy_wavelet, energy_wavelet, ...
    %             mean_spectrogram, var_spectrogram, entropy_spectrogram, energy_spectrogram];
    features = [mean_wavelet, var_wavelet, entropy_wavelet];
end
