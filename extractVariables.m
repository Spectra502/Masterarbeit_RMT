function [label, torque, speed, damageLabel, damageType] = extractVariables(inputString)

    % Determine the label based on the presence of "GF"
    if contains(inputString, 'GF_Ritzel') || contains(inputString,'Gf_Ritzel')
        if contains(inputString, 'Rad')
            label = 'damaged';
            damageLabel = 2;
            damageType = 'severe_micropitting';
        else
            label = 'damaged';
            damageLabel = 1;
            damageType = 'micropitting';
        end
    elseif contains(inputString, 'V')
        label = 'damaged';
        damageLabel = 3;
        damageType = 'wear_moderate'
    elseif contains(inputString, 'leicht')
        label = 'damaged';
        damageLabel = 4;
        damageType = 'dimples_light'
    else
        label = 'healthy';
        damageLabel = 0;
        damageType = 'none';
    end

   pattern = '-112_5_';
   length(pattern);
   startIndex = strfind(inputString, pattern);

   if ~isempty(startIndex)
       startIndex = startIndex + length(pattern);
       remainderString = inputString(startIndex:end);

       numPattern = '(\d+)';
       tokens = regexp(remainderString, numPattern, 'tokens');

       % Debug: Print the remainder string and tokens
        % disp('Remainder String:');
        % disp(remainderString);
        % disp('Tokens:');
        % disp(tokens);
        % disp(length(tokens))
        % disp(tokens{3})

        if length(tokens) == 2
            torque = str2double(tokens{1});
            speed = str2double(tokens{2});
        elseif length(tokens) == 4
            torque = str2double(tokens{3});
            speed = str2double(tokens{4});
        else
            torque = NaN;
            speed = NaN;
        end
    else
        torque = NaN;
        speed = NaN;
        tokens = {};
    end

end

