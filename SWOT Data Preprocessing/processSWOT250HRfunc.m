function [dataStruct]=processSWOT250HRfunc(inputPath)
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
        pattern = '(\d{3}_\d{3}_\w{4})_(\d{8})'; % Matches "001_354_046F_20230802"
        match = regexp(fname, pattern, 'tokens');
        if isempty(match)
            warning('No valid pattern found in file name: %s', fname);
            continue;
        end
        prefix = match{1}{1}; % The "001_354" part
        date = match{1}{2};   % The "20230802" part
        fieldName = ['HR_250m_' prefix '_' date]; % Combine into "001_354_20230802"

        % Read NetCDF information and variables
        tmplat = ncread(fullFilePath, 'latitude');
        tmplon = ncread(fullFilePath, 'longitude');
        tmpswe = ncread(fullFilePath, 'wse');
        tmpTime = (ncread(fullFilePath, 'illumination_time'))';
        tmpSolidEarthTide= ncread(fullFilePath, 'solid_earth_tide');
        tmpLoadTideFes= ncread(fullFilePath, 'load_tide_fes');
        tmpPoleTide=ncread(fullFilePath, 'pole_tide');
        tmpGeoid=ncread(fullFilePath,'geoid');
        wseFlag= ncread(fullFilePath, 'wse_qual');
        wse_uncert = ncread(fullFilePath, 'wse_uncert');

        % Convert from 0-360 longitude to -180 to 180
        tmplon = rem((tmplon + 180), 360) - 180;

        % Add tidal effects back on
        swe=tmpswe; %+ tmpSolidEarthTide + tmpLoadTideFes + tmpPoleTide;

        % Substract off geoid
        % tmpswe_Navd88 = swe- tmpGeoid;

        % Filter close to FRF only in lat/lon
        [filteredLat, filteredLon, filteredHeight, filteredTime] = filterFRFregion_latlong(tmplat, tmplon, swe, tmpTime);

        % Convert from EGM2008 to NAVD88
        % filteredHeights_NAVD88 = convertToNAVD88(filteredLat, filteredLon, filteredHeight);

        % Convert to FRF Coordinates
        [~, ~, ~, ~, frfY, frfX] = frfCoord(filteredLon, filteredLat);

        % Filter close to FRF only in FRF coordinates
        [filteredFrfY, filteredFrfX, filteredHeight_NAVD88_Frf, filteredTimeFrf] = filterFRFregion_frf(frfY, frfX, filteredHeight, filteredTime);

        % Find SWOT location closest to FRF pier (with quality check passed)
        distances = sqrt((filteredFrfX - waterlevel_frfX).^2 + (filteredFrfY - waterlevel_frfY).^2);
        [minDist2waterLevel, waterLevel_idx_min] = min(distances);

        % Store results in the structure under the unique key
        dataStruct.(fieldName) = struct( ...
            'time', filteredTimeFrf, ...
            'FRF_X', filteredFrfX, ...
            'FRF_Y', filteredFrfY, ...
            'Filtered_SSH_NAVD88', filteredHeight_NAVD88_Frf, ...
            'Water_Level_Index', waterLevel_idx_min, ...
            'NearestPointToWaterLevelDist_meters', minDist2waterLevel);
    end

    % Save the structure to a MAT file
    save(fullfile('D:\SWOT\Data\SWOTdata\frf_raster_HR_250m', '250m_HR_Processed.mat'), 'dataStruct');

    disp('Processing complete. Data saved.');
end