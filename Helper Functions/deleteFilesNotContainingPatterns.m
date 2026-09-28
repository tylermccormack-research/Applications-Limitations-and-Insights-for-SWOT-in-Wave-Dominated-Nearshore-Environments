function deleteFilesNotContainingPatterns(folderPath)
    % deleteFilesNotContainingPatterns(folderPath)
    % Deletes files in the specified folder that do not contain '_354_' or '_063_' in their name.
    %
    % Inputs:
    %   folderPath: The path to the folder where the files are located.

    % Check if the folder path exists
    if ~isfolder(folderPath)
        error('The specified folder does not exist.');
    end

    % Get a list of all files in the folder
    files = dir(folderPath);

    % Loop through each file in the folder
    for i = 1:length(files)
        % Skip directories
        if files(i).isdir
            continue;
        end
        
        % Get the filename
        fileName = files(i).name;
        
        % Check if the filename contains '_354_' or '_063_'
        if ~contains(fileName, '_354_') && ~contains(fileName, '_063_')
            % If it doesn't, delete the file
            delete(fullfile(folderPath, fileName));
            fprintf('Deleted: %s\n', fileName);
        end
    end
end
