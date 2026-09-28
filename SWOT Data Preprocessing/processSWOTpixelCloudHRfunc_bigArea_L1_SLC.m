function [dataStruct]=processSWOTpixelCloudHRfunc_bigArea_L1_SLC(inputPath)
    % processSWOTFiles Processes SWOT NetCDF files in the given directory
    % 
    % INPUT:
    %   inputPath - Path to the folder containing SWOT NetCDF files.
    %
    % OUTPUT:
    %   Saves a MAT file containing the processed data structure.

    % Disable warnings
    % warning('off', 'all'); % Turn off all warnings

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
    % load('waterLevel_frfX.mat');
    % load('waterLevel_frfY.mat');
    waterlevel_frfX=627.472; % Use this point so we don't get too close to pier
    waterlevel_frfY=504.707;

    % Initialize the structure
    dataStruct = struct();

    % Loop through each file
    for i = 1:length(fileList)
        % Get file name
        fname = fileList(i).name;
        fullFilePath = fullfile(fileList(i).folder, fname);

        % Print the name of the file being processed
        disp(['Processing file: ', fname]);

        % Extract the digits and characters before the date and the date itself
        pattern = '(\d{3}_\d{3}_\w{4})_(\d{8})'; % Matches "001_354_046F_20230802"
        match = regexp(fname, pattern, 'tokens');
        if isempty(match)
            warning('No valid pattern found in file name: %s', fname);
            continue;
        end

        prefix = match{1}{1}; % The "001_354_046F" part
        date = match{1}{2};   % The "20230802" part
        fieldName = ['HR_L1_SLC_' prefix '_' date]; % Combine into "HR_100m_001_354_046F_20230802"


        % Read NetCDF information and variables
        tmpNoise_plus_y=double(ncread(fullFilePath,'noise/noise_plus_y'));
        tmpNoise_minus_y=double(ncread(fullFilePath,'noise/noise_minus_y'));
        tmpXfactor_plus_y=ncread(fullFilePath,'xfactor/xfactor_plus_y');
        tmpXfactor_minus_y=ncread(fullFilePath,'xfactor/xfactor_minus_y');

        % Load HR pixel cloud for mapping
        pix=load('pixelCloud_Processed_bigArea.mat');

        % Function to to pixel cloud file and extract range indices, and
        % map noise powers to pixel cloud spacing
        % dataStruct = matchAndAttachNoisePower(pix, fname);
        dataStruct = matchAndAttachNoisePower_byTime(pix, fname);

        % Convert from 0-360 longitude to -180 to 180
        tmplon = rem((tmplon + 180), 360) - 180;

  
        % Convert to FRF Coordinates
        [~, ~, ~, ~, frfY, frfX] = frfCoord_bigArea(tmplon, tmplat);

        % Geographic location mask
        minLat = 36.15;
        maxLat = 36.22;
        minLon = -75.765;
        maxLon = -75.69;

        locationMask = (tmplat >= minLat) & (tmplat <= maxLat) & ...
            (tmplon >= minLon) & (tmplon <= maxLon);  

        % Combine both masks
        combinedMask =  locationMask;

        % Store results in the structure under the unique key
        dataStruct.(fieldName) = struct( ...
            'time', tmpTime(combinedMask), ...
            'noise_plus_interp',noise_plus_interp(combinedMask), ...
            'noise_minus_interp',noise_minus_interp(combinedMask) ...
        );

    end

    % Save the structure to a MAT file
    save(fullfile('D:\SWOT\Data\SWOTdata\frf_PointCloud', 'pixelCloud_Processed_bigArea.mat'), 'dataStruct');

    disp('Processing complete. Data saved.');
end