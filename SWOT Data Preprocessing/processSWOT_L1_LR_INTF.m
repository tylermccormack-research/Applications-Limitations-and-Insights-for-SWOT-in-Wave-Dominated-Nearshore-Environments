function [dataStructOut]=processSWOT_L1_LR_INTF(inputPath)
    % processSWOTFiles Processes SWOT NetCDF files in the given directory
    % 
    % INPUT:
    %   inputPath - Path to the folder containing SWOT NetCDF files.
    %
    % OUTPUT:
    %   Saves a MAT file containing the processed data structure.

    % Disable warnings
    warning('off', 'all'); % Turn off all warnings

    % Validate input path
    if ~isfolder(inputPath)
        error('The specified folder does not exist: %s', inputPath);
    end

    % Delete any files in path that don't contain "_354_" or "_063_"
    deleteFilesNotContainingPatterns(inputPath);

    % Get a list of NetCDF files in the directory
    fileList = dir(fullfile(inputPath, '*.nc'));

    % Check if files are found
    if isempty(fileList)
        error('No NetCDF files found in the specified folder: %s', inputPath);
    end

    % Load FRF water level sensor locations
    load('waterLevel_frfX.mat');
    load('waterLevel_frfY.mat');

    % Initialize the structure
    dataStruct = struct();

    % Loop through each file
    for i = 1:length(fileList)
        % Get file name
        fname = fileList(i).name;
        fullFilePath = fullfile(fileList(i).folder, fname);

        % Print the name of the file being processed
        disp(['Processing file: ', fname]);

        % Extract the digits before the date and the date itself
        pattern = '(\d{3}_\d{3})_(\d{8})'; % Matches "001_354_20230802"
        match = regexp(fname, pattern, 'tokens');
        if isempty(match)
            warning('No valid pattern found in file name: %s', fname);
            continue;
        end
        prefix = match{1}{1}; % The "001_354" part
        date = match{1}{2};   % The "20230802" part
        fieldName = ['L1B_LR_INTF_' prefix '_' date]; % Combine into "001_354_20230802"


        

        % Map to pixel cloud locations
         [Xpix, Ypix, InterferogramInterp, AngleInterp, GeomInterp, NoiseInterp] = matchAndAttachAngleGeom_byLocation( fname);


         % Store results in the structure under the unique key
        dataStructOut.(fieldName) = struct( ...
            'FRF_X', Xpix, ...
            'FRF_Y', Ypix, ...
            'Interferogram_interp', InterferogramInterp, ...
            'AngleCorrelation_interp', AngleInterp, ...
            'GeomCorrection_interp',GeomInterp, ...
            'Noise_interp', NoiseInterp ...
            );

    % Save the structure to a MAT file
    save(fullfile('D:\SWOT\Data\SWOTdata', 'dataStruct_LR_L1B_INTF.mat'), 'dataStructOut');

    end
        disp('Processing complete. Data saved.');

end