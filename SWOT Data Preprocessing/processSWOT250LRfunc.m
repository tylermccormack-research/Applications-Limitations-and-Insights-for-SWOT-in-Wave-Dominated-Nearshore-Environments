function [dataStruct]=processSWOT250LRfunc(inputPath)
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
        fieldName = ['LR_250m_' prefix '_' date]; % Combine into "001_354_20230802"
        
        if contains(fieldName, '_354_')
            % Read NetCDF information and variables
            tmplat = ncread(fullFilePath, 'left/latitude');
            tmplon = ncread(fullFilePath, 'left/longitude');
            tmpssh = ncread(fullFilePath, 'left/ssh_karin_2');
            tmpTime = ones(size(tmpssh)) .* (ncread(fullFilePath, 'left/time'))';
            qualFlag= ncread(fullFilePath, 'left/ssh_karin_2_qual');
            ssh_uncert = ncread(fullFilePath, 'left/ssh_karin_uncert');
            tmpTotalCoherence = ncread(fullFilePath, 'left/total_coherence');
    
            % Convert from 0-360 longitude to -180 to 180
            tmplon = rem((tmplon + 180), 360) - 180;
    
            % Filter close to FRF only in lat/lon
            [filteredLat, filteredLon, filteredHeight, filteredTime, filteredTotalCoherence] = filterFRFregion_latlong_L2_LR_SSH(tmplat, tmplon, tmpssh, tmpTime, tmpTotalCoherence);

        else
            % Switch to using "right" variables
            tmplat = ncread(fullFilePath, 'right/latitude');
            tmplon = ncread(fullFilePath, 'right/longitude');
            tmpssh = ncread(fullFilePath, 'right/ssh_karin_2');
            tmpTime = ones(size(tmpssh)) .* (ncread(fullFilePath, 'right/time'))';
            tmpTotalCoherence = ncread(fullFilePath, 'left/total_coherence');

            % Reconvert longitude to -180 to 180
            tmplon = rem((tmplon + 180), 360) - 180;

            % Refilter close to FRF
            [filteredLat, filteredLon, filteredHeight, filteredTime, filteredTotalCoherence] = filterFRFregion_latlong_L2_LR_SSH(tmplat, tmplon, tmpssh, tmpTime, tmpTotalCoherence);
        end

        % Convert to EGM2008 (apply geoid)
        filteredHeights_egmEGM2008 = convertToNAVD88(filteredLat, filteredLon, filteredHeight);


        % Get height_cor_xover correction from Expert file
        inputPath="D:\SWOT\Data\SWOTdata\frf_raster_LR_L2_250m\Expert";
        heightCorInterp = getXoverCorrectionFromExpert( ...
                        inputPath, prefix, date, ...
                        filteredLat(:), filteredLon(:));


         filteredHeights_NAVD88=filteredHeights_egmEGM2008 + 0.24 - heightCorInterp; 

        % Convert to FRF Coordinates
        [~, ~, ~, ~, frfY, frfX] = frfCoord_bigArea(filteredLon, filteredLat);

        % Filter close to FRF only in FRF coordinates
        [filteredFrfY, filteredFrfX, filteredHeight_NAVD88_Frf, filteredTimeFrf, filteredTotalCoherenceFrf] = filterFRFregion_frf_LR_L2_SSH(frfY, frfX, filteredHeights_NAVD88, filteredTime, filteredTotalCoherence);

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
            'NearestPointToWaterLevelDist_meters', minDist2waterLevel, ...
            'TotalCoherence',filteredTotalCoherenceFrf);
    end

    % Save the structure to a MAT file
    save(fullfile('D:\SWOT\Data\SWOTdata\frf_raster_LR_L2_250m', '250m_Processed_bigArea.mat'), 'dataStruct');

    disp('Processing complete. Data saved.');
end