function [dataStruct]=processSWOT100HRfunc(inputPath)
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
        fieldName = ['HR_100m_' prefix '_' date]; % Combine into "HR_100m_001_354_046F_20230802"


        % Read NetCDF information and variables
        tmplat = ncread(fullFilePath, 'latitude');
        tmplon = ncread(fullFilePath, 'longitude');
        tmpSwe = ncread(fullFilePath, 'wse');
        tmpTime = ones(size(tmpSwe)) .* (ncread(fullFilePath, 'illumination_time'));
        tmpWseQualFlag= ncread(fullFilePath, 'wse_qual');
        ssh_uncert = ncread(fullFilePath, 'wse_uncert');
        geoid = ncread(fullFilePath, 'geoid');
        solid_earth_tide = ncread(fullFilePath, 'solid_earth_tide');
        load_tide_fes = ncread(fullFilePath, 'load_tide_fes');
        pole_tide = ncread(fullFilePath, 'pole_tide');
        % height_cor_xover = ncread(fullFilePath, 'height_cor_xover');

        % Convert from 0-360 longitude to -180 to 180
        tmplon = rem((tmplon + 180), 360) - 180;

        % Filter close to FRF only in lat/lon
        [filteredLat, filteredLon, inBox] = filterFRFregion_latlong(tmplat, tmplon);
      
         % Convert to FRF Coordinates
        [~, ~, ~, ~, frfY, frfX] = frfCoord(filteredLon, filteredLat);

        % Filter close to FRF only in FRF coordinates
        [ finalBox, filteredFrfX, filteredFrfY] = filterFRFregion_frf(frfY, frfX, inBox);

        % Convert from EGM2008 to NAVD88
        egm2008toNavd88Value=0.24; % From vdatum for FRF coords
        filteredHeight_NAVD88 = tmpSwe(finalBox) + egm2008toNavd88Value;% + ( solid_earth_tide(finalBox) + load_tide_fes(finalBox) + pole_tide(finalBox) ) ;

         % Filter out all variables of interest
        time=tmpTime(finalBox);
        wseQualFlag=tmpWseQualFlag(finalBox);
        
         % Quality flag filtering
        [time_qualityFiltered, filteredFrfX_qualityFiltered, filteredFrfY_qualityFiltered, filteredHeight_NAVD88_qualityFiltered, qualityFlagged]=qualityFlagFiltering_100m(wseQualFlag, time, filteredFrfX, filteredFrfY, filteredHeight_NAVD88);

        % Find SWOT location closest to FRF pier (with quality check passed)
        distances = sqrt((filteredFrfX_qualityFiltered - waterlevel_frfX).^2 + (filteredFrfY_qualityFiltered - waterlevel_frfY).^2);
        [minDist2waterLevel, waterLevel_idx_min] = min(distances);

        % Store results in the structure under the unique key
        dataStruct.(fieldName) = struct( ...
            'time', time, ...
            'FRF_X', filteredFrfX_qualityFiltered, ... % 'FRF_X', filteredFrfX, ...
            'FRF_Y', filteredFrfY_qualityFiltered, ... % 'FRF_Y', filteredFrfY, ...
            'Filtered_SWE_NAVD88', filteredHeight_NAVD88, ...
            'Water_Level_Index', waterLevel_idx_min, ...
            'NearestPointToWaterLevelDist_meters', minDist2waterLevel,...
            'qualityFlaggedIndices',qualityFlagged,...
            'time_qualityFiltered', time_qualityFiltered, ...
            'FRF_X_qualityFiltered', filteredFrfX_qualityFiltered, ...
            'FRF_Y_qualityFiltered', filteredFrfY_qualityFiltered, ...
            'Filtered_SWE_NAVD88_qualityFiltered', filteredHeight_NAVD88_qualityFiltered);
    
    end

    % Save the structure to a MAT file
    save(fullfile('D:\SWOT\Data\SWOTdata\frf_raster_HR_100m', '100m_Processed.mat'), 'dataStruct');

    disp('Processing complete. Data saved.');
end