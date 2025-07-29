function x_aug = augment_translation(x, shift_amount)
    % Shifts the signal forward or backward
    x_aug = zeros(size(x)); % Initialize shifted signal
    if shift_amount > 0
        x_aug(shift_amount+1:end) = x(1:end-shift_amount); % Shift right
    elseif shift_amount < 0
        x_aug(1:end+shift_amount) = x(-shift_amount+1:end); % Shift left
    else
        x_aug = x; % No shift
    end
end