paths = setupPaths();

function [dataStruct]=processSWOT_L3_unsmoothed(inputPath)
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
        fieldName = ['L3_LR_SSH_Unsmoothed' prefix '_' date];

        tmplat = ncread(fullFilePath, 'latitude');
        tmplon = ncread(fullFilePath, 'longitude');
        tmpTime = ones(size(tmplat)) .* (ncread(fullFilePath, 'time'))';
        tmpQualFlag= ncread(fullFilePath, 'quality_flag');
        ssha_filtered= ncread(fullFilePath, 'ssha_filtered'); 
        ugos=ncread(fullFilePath, 'ugos_filtered');
        vgos=ncread(fullFilePath, 'vgos_filtered');
         
        ocean_tide = ncread(fullFilePath,'ocean_tide');
        dac =ncread(fullFilePath,'dac');
        mss=ncread(fullFilePath, 'mss');
        % internal_tide = ncread(fullFilePath, 'internal_tide');

        tmplon = rem((tmplon + 180), 360) - 180;

        % Geographic location mask
        minLat = 36.15; maxLat = 36.28;
        minLon = -75.765; maxLon = -75.3;
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

        % Closest point to Current meters using point closest SWOt point
        % Set maximum allowed distances for each sensor (meters)
        maxDistWaterLevel = 500;
        maxDistSig940_300   = 500;
        maxDistSig940_400 = 500;
        maxDistSig940_600   = 500;
        maxDistAwac4p5 = 500;
        maxDistAwac11 = 500;
        maxDistWaverider17m= 500;
        maxDistWaverider26m= 500;

        load(fullfile(paths.static, 'sensorCoords_currents.mat'));

        % Sig940_300         distances2buoy = sqrt((frfX - sensorCoords_currents.X(1)).^2 + (frfY - sensorCoords_currents.Y(1)).^2);
        [minDistToSig940_300, minDistToSig940_300_idx] = min(distances2buoy);
        if minDistToSig940_300 > maxDistSig940_300
            minDistToSig940_300 = 0; %NaN;
        end

        % Sig940_400        distances2buoy = sqrt((frfX - sensorCoords_currents.X(2)).^2 + (frfY - sensorCoords_currents.Y(2)).^2);
        [minDistToSig940_400, minDistToSig940_400_idx] = min(distances2buoy);
        if minDistToSig940_400 > maxDistSig940_400
            minDistToSig940_400 = 0; %NaN;
        end

                % AWAC- 4.5m  (~400m)        distances2buoy = sqrt((frfX - sensorCoords_currents.X(3)).^2 + (frfY - sensorCoords_currents.Y(3)).^2);        
        [minDistToAwac4p5, minDistToAwac4p5_idx] = min(distances2buoy);
        if minDistToAwac4p5 > maxDistAwac4p5
            minDistToAwac4p5 = 0; %NaN;
        end

        % Sig940_600        distances2buoy = sqrt((frfX - sensorCoords_currents.X(4)).^2 + (frfY - sensorCoords_currents.Y(4)).^2);     
        [minDistToSig940_600, minDistToSig940_600_idx] = min(distances2buoy);
        if minDistToSig940_600 > maxDistSig940_600
            minDistToSig940_600 = 0; %NaN;
        end


        % AWAC 11m (~1300m)         distances2buoy = sqrt((frfX - sensorCoords_currents.X(5)).^2 + (frfY - sensorCoords_currents.Y(5)).^2);
        [minDistToAwac11, minDistToAwac11_idx] = min(distances2buoy);
        if minDistToAwac11 > maxDistAwac11
            minDistToAwac11 = 0; %NaN;
        end

        % Waverider 17m
        distances2buoy = sqrt((frfX - sensorCoords_currents.X(6)).^2 + (frfY - sensorCoords_currents.Y(6)).^2);
        [minDistToWaverider17m, minDistToWaverider17m_idx] = min(distances2buoy);
        if minDistToWaverider17m > maxDistWaverider17m
            minDistToWaverider17m = 0; %NaN;
        end

        % Waverider 26m
        distances2buoy = sqrt((frfX - sensorCoords_currents.X(7)).^2 + (frfY - sensorCoords_currents.Y(7)).^2);
        [minDistToWaverider26m, minDistToWaverider26m_idx] = min(distances2buoy);
        if minDistToWaverider26m > maxDistWaverider26m
            minDistToWaverider26m = 0; %NaN;
        end

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
            'U_zonal', ugos(combinedMask),...
            'V_meridian', vgos(combinedMask), ...
            'QualityFlag', tmpQualFlag(combinedMask), ...
            'Current_IndexSig940_300', minDistToSig940_300_idx, ...
            'DistanceToSig940_300', minDistToSig940_300, ...
            'Current_IndexSig940_400', minDistToSig940_400_idx, ...
            'DistanceToSig940_400', minDistToSig940_400, ...
            'Current_IndexAwac4p5', minDistToAwac4p5_idx, ...
            'DistanceToAwac4p5', minDistToAwac4p5, ... 
            'Current_IndexSig940_600', minDistToSig940_600_idx, ...
            'DistanceToSig940_600', minDistToSig940_600, ... 
            'Current_IndexAwac11', minDistToAwac11_idx, ...
            'DistanceToAwac11', minDistToAwac11, ... 
            'Current_IndexWaverider17m', minDistToWaverider17m_idx , ...
            'DistanceToWaverider17m', minDistToWaverider17m , ...
            'Current_IndexWaverider26m', minDistToWaverider26m_idx , ...
            'DistanceToWaverider26m', minDistToWaverider26m  ...
          );
    end

    % Remove empty fields
    dataStruct = removeEmptyFieldsFromStruct(dataStruct);


    % Save the structure to a MAT file
    save(fullfile(paths.swot.l3Unsmooth, ...
        '2km_LR_L3_SSH_unsmoothed_Processed.mat'), 'dataStruct');

    disp('Processing complete. Data saved.');
end
