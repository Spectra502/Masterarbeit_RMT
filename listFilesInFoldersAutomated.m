function [fileStruct, folderPathStruct] = listFilesInFoldersAutomated()
    % listFilesInFolders  Let user select multiple folders, then list .tdms files in each.
    %
    % Outputs:
    %   fileStruct(i).files       – cell array of .tdms filenames found in folder i
    %   folderPathStruct(i).folder – full path of folder i
    %
    
    % 1) Let the user select folders one-by-one
    folderList = {};
    while true
        sel = uigetdir(pwd, 'Select a folder (Cancel to finish)');
        if sel == 0
            break;              % user hit Cancel
        end
        folderList{end+1} = sel;
    end
    
    % If no folders selected, return empty
    if isempty(folderList)
        disp('No folders selected.');
        fileStruct = struct('files', {});
        folderPathStruct = struct('folder', {});
        return;
    end
    
    % 2) Preallocate outputs
    n = numel(folderList);
    fileStruct       = struct('files',       cell(1,n));
    folderPathStruct = struct('folder',      cell(1,n));
    
    % 3) Loop over each selected folder and grab .tdms files
    for i = 1:n
        fp = folderList{i};
        td = dir(fullfile(fp, '*.tdms'));
        
        if isempty(td)
            fprintf('  → No .tdms files in "%s"\n', fp);
            fileStruct(i).files = {};
        else
            fileStruct(i).files = { td.name };
        end
        
        folderPathStruct(i).folder = fp;
    end
end
