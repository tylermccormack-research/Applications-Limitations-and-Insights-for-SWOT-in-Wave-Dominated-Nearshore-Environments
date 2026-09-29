function [dataStruct]=processSWOT250_L3_LR_SSH_expert_func(inputPath)
paths = setupPaths();

    % processSWOTFiles Processes SWOT NetCDF files in the given directory
    % 
    % INPUT:
    %   inputPath - Path to the folder containing SWOT NetCDF files.
    %
    % OUTPUT:
    %   Saves a MAT file containing the processed data structure.

    warning('off', 'all'); % Turn off all warnings

    if ~isfolder(inputPath)
        error('The specified folder does not exist: %s', inputPath);
    end

    % Delete any files in path that don't contain "_354_" or "_063_"
    deleteFilesNotContainingPatterns(inputPath);

    fileList = dir(fullfile(inputPath, '*.nc'));
    if isempty(fileList)
        error('No NetCDF files found in the specified folder: %s', inputPath);
    end

    % Load FRF water level sensor locations
    load(fullfile(paths.preprocessing, 'waterLevel_frfX.mat'));
    load(fullfile(paths.preprocessing, 'waterLevel_frfY.mat'));
    load(fullfile(paths.static, 'sensorCoords.mat'));  % [numSensors x 2] (x,y)

    % Set maximum allowed distances for each sensor (meters)
    maxDistWaterLevel = 0;
    maxDist17mBuoy   = 1500;
    maxDist600mSensor = 1500;
    maxDist26mBuoy   = 1500;
    maxDist900mSensor = 1500;

    dataStruct = struct();

    for i = 1:length(fileList)
        fname = fileList(i).name;
        fullFilePath = fullfile(fileList(i).folder, fname);

        disp(['Processing file: ', fname]);

        pattern = '(\d{3}_\d{3})_(\d{8})';
        match = regexp(fname, pattern, 'tokens');
        if isempty(match)
            warning('No valid pattern found in file name: %s', fname);
            continue;
        end
        prefix = match{1}{1};
        date = match{1}{2};
        fieldName = ['L3_LR_SSH_Expert' prefix '_' date];

        tmplat = ncread(fullFilePath, 'latitude');
        tmplon = ncread(fullFilePath, 'longitude');
        tmpTime = ones(size(tmplat)) .* (ncread(fullFilePath, 'time'))';
        tmpQualFlag= ncread(fullFilePath, 'quality_flag');
        
        ssha_filtered= ncread(fullFilePath, 'ssha_filtered'); % ai
        % ssha_unedited= ncread(fullFilePath, 'ssha_unedited');
        % ssha_unfiltered= ncread(fullFilePath, 'ssha_unfiltered');
         
        ocean_tide = ncread(fullFilePath,'ocean_tide');
        dac =ncread(fullFilePath,'dac');
        mss=ncread(fullFilePath, 'mss');
        internal_tide = ncread(fullFilePath, 'internal_tide');

        tmplon = rem((tmplon + 180), 360) - 180;

        % Geographic location mask
        2
        locationMask = (tmplat >= minLat) & (tmplat <= maxLat) & ...
                       (tmplon >= minLon) & (tmplon <= maxLon);  

        % Quality flag mask
        qualityMask = ~(tmpQualFlag > 0); % Worse than good, removed
        % qualityMask = ~(tmpQualFlag == 10 | tmpQualFlag ==18 | tmpQualFlag > 101); % Flag for bad coast


        combinedMask = qualityMask & locationMask ;

        % Convert to FRF Coordinates
        [~, ~, ~, ~, frfY, frfX] = frfCoord_bigArea(tmplon(combinedMask), tmplat(combinedMask));

        % Calculate geoid heights using the geoidheight function
        geoid_heights = geoidheight(tmplat(combinedMask), tmplon(combinedMask), 'egm2008');

        % Convert from EGM2008 to NAVD88
        % Total water level method
        filteredHeight_NAVD88=ssha_filtered(combinedMask)  + mss(combinedMask) + dac(combinedMask) + ...
            ocean_tide(combinedMask)  - geoid_heights + 0.24;

       % + internal_tide(combinedMask)
       %  + ocean_tide(combinedMask)

        % --- Nearest pixels with thresholds ---
        % Water level pier
        distances = sqrt((frfX - waterlevel_frfX).^2 + (frfY - waterlevel_frfY).^2);
        [minDist2waterLevel, waterLevel_idx_min] = min(distances);
        % if minDist2waterLevel > maxDistWaterLevel
        %     % waterLevel_idx_min = NaN;
        %     minDist2waterLevel = 0;% NaN;
        % end

        % 17m buoy
        distances2buoy = sqrt((frfX - sensorCoords(13,1)).^2 + (frfY - sensorCoords(13,2)).^2);
        [minDistTo17mBuoy, minDistTo17mBuoy_idx] = min(distances2buoy);
        % if minDistTo17mBuoy > maxDist17mBuoy
        %     % minDistTo17mBuoy_idx = NaN;
        %     minDistTo17mBuoy = 0; %NaN;
        % end

        % 600m sensor
        distancesTo600mSensor = sqrt((frfX - sensorCoords(11,1)).^2 + (frfY - sensorCoords(11,2)).^2);
        [minDistTo600mSensor, minDistTo600mSensor_idx] = min(distancesTo600mSensor);
        % if minDistTo600mSensor > maxDist600mSensor
        %     % minDistTo600mSensor_idx = NaN;
        %     minDistTo600mSensor = 0;% NaN;
        % end

        % 26m buoy
        distancesTo26mBuoy = sqrt((frfX - sensorCoords(14,1)).^2 + (frfY - sensorCoords(14,2)).^2);
        [minDistTo26mBuoy, minDistTo26mBuoy_idx] = min(distancesTo26mBuoy);
        % if minDistTo26mBuoy > maxDist26mBuoy
        %     % minDistTo26mBuoy_idx = NaN;
        %     minDistTo26mBuoy = 0; % NaN;
        % end

          % 900m sensor
        distancesTo900mSensor = sqrt((frfX - sensorCoords(12,1)).^2 + (frfY - sensorCoords(12,2)).^2);
        [minDistTo900mSensor, minDistTo900mSensor_idx] = min(distancesTo900mSensor);
        % if minDistTo900mSensor > maxDist900mSensor
        %     % minDistTo600mSensor_idx = NaN;
        %     minDistTo900mSensor = 0;% NaN;
        % end

        % Store results in the structure
        dataStruct.(fieldName) = struct( ...
            'time', tmpTime(combinedMask), ...
            'lat', tmplat(combinedMask),...
            'lon', tmplon(combinedMask),...
            'FRF_X', frfX, ...
            'FRF_Y', frfY, ...
            'Filtered_SSH_NAVD88', filteredHeight_NAVD88, ...
            'Water_Level_Index', waterLevel_idx_min, ...
            'NearestPointToWaterLevelDist_meters', minDist2waterLevel, ...
            'SWH_Index17mBuoy', minDistTo17mBuoy_idx, ...
            'DistanceTo17mBuoy', minDistTo17mBuoy, ...
            'SWH_Index26mBuoy', minDistTo26mBuoy_idx, ...
            'DistanceTo26mBuoy', minDistTo26mBuoy, ...
            'SWH_Index600mSensor', minDistTo600mSensor_idx, ...
            'DistanceTo600mSensor', minDistTo600mSensor, ... 
            'SWH_Index900mSensor', minDistTo900mSensor_idx, ...
            'DistanceTo900mSensor', minDistTo900mSensor, ... 
            'QualityFlag', tmpQualFlag(combinedMask) ...
          );
    end

    % Remove empty fields
    dataStruct = removeEmptyFieldsFromStruct(dataStruct);


    % Save the structure to a MAT file
    save(fullfile(paths.swot.l3Expert, ...
        '2km_LR_L3_SSH_expert_Processed.mat'), 'dataStruct');

    disp('Processing complete. Data saved.');
end
