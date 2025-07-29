function [fileStruct, folderPathStruct] = listFilesInFolder()
    % This function allows the user to select a folder, and it returns the
    % filenames of all .tdms files in that folder.
    %
    % Returns:
    %   - fileStruct: A struct containing filenames in the selected folder
    %   - folderPathStruct: A struct containing the path of the selected folder
    
    % Ask the user to select a folder
    folderPath = uigetdir('Select Folder');

    % Check if no folder was selected
    if folderPath == 0
        disp('No folder selected');
        fileStruct = [];
        folderPathStruct = '';
        return;
    end

    % Initialize output structs
    fileStruct = struct();
    folderPathStruct = struct();

    % Get all .tdms files in the selected folder
    tdmsFiles = dir(fullfile(folderPath, '*.tdms'));

    % If any .tdms files exist, store their names
    if ~isempty(tdmsFiles)
        fileStruct.files = {tdmsFiles.name};
        folderPathStruct.folder = folderPath;
    else
        disp('No .tdms files found in the selected folder.');
        fileStruct.files = {};
        folderPathStruct.folder = folderPath;
    end
end
