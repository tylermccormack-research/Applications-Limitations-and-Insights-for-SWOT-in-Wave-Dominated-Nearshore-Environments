function [dataStruct]=processSWOT250_L2_LR_SSH_expert_func(inputPath)
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
    % maxDistWaterLevel = 15000;
    % maxDist17mBuoy   = 15000;
    % maxDist600mSensor = 15000;
    % maxDist26mBuoy   = 15000;
    % maxDist900mSensor = 15000;

        maxDistWaterLevel = 10000;
    % maxDist17mBuoy   = 3000;
    % maxDist600mSensor = 3000;
    % maxDist26mBuoy   = 3000;
    % maxDist900mSensor = 3000;

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
        fieldName = ['L2_LR_SSH_Expert' prefix '_' date];

        tmplat = ncread(fullFilePath, 'latitude');
        tmplon = ncread(fullFilePath, 'longitude');
        tmpSSH = ncread(fullFilePath, 'ssh_karin_2');
        tmpTime = ones(size(tmpSSH)) .* (ncread(fullFilePath, 'time'))';
        tmpGeoid= ncread(fullFilePath, 'geoid');
        tmpQualFlag= ncread(fullFilePath, 'ssh_karin_qual');
        % tmpSSH_uncert = ncread(fullFilePath, 'ssh_karin_uncert');
        tmpSWH_karin = ncread(fullFilePath, 'swh_karin');
        tmpSWH_qualityFlag= ncread(fullFilePath, 'swh_karin_qual');
        tmpWindSpeed = ncread(fullFilePath, 'wind_speed_karin');
        tmpDistanceToCoast = ncread(fullFilePath, 'distance_to_coast');
        tmpVolumetric_correlation = ncread(fullFilePath, 'volumetric_correlation');
        tmpVolumetric_correlation_uncert = ncread(fullFilePath, 'volumetric_correlation_uncert');
        % tmpSig0_qual = ncread(fullFilePath, 'sig0_karin_qual');
        tmpCrossOver = ncread(fullFilePath, 'height_cor_xover');
        tmpSolidEarthTide = ncread(fullFilePath,'solid_earth_tide');
        tmpLoadTide = ncread(fullFilePath, 'load_tide_fes');
        tmpPoleTide = ncread(fullFilePath, 'pole_tide');
        sea_state_bias_cor_2=ncread(fullFilePath, 'sea_state_bias_cor_2');
        ssha_karin_2= ncread(fullFilePath, 'ssha_karin_2');
        ocean_tide_fes = ncread(fullFilePath,'ocean_tide_fes');
        dac =ncread(fullFilePath,'dac');
        mean_sea_surface_cnescls=ncread(fullFilePath, 'mean_sea_surface_cnescls');
        ocean_tide_non_eq=ncread(fullFilePath, 'ocean_tide_non_eq' );
        internal_tide_hret = ncread(fullFilePath, 'internal_tide_hret');

        % Set SWH Karin values to NaN where quality flag > 4096
        badSWHmask = tmpSWH_qualityFlag > 4096;
        tmpSWH_karin(badSWHmask) = NaN;

        tmplon = rem((tmplon + 180), 360) - 180;

        % Geographic location mask
        minLat = 36.15; maxLat = 36.28;
        minLon = -75.765; maxLon = -75.3;
        locationMask = (tmplat >= minLat) & (tmplat <= maxLat) & ...
                       (tmplon >= minLon) & (tmplon <= maxLon);  

        % Quality flag mask
        qualityMask = ~(tmpSWH_qualityFlag >= 4096); % degraded and worse excluded
        % qualityMask = ~(tmpSWH_qualityFlag >= 131072); % degraded and worse excluded
        % qualityMask = ~(tmpSWH_qualityFlag >= 16777216); % Bad excluded

        % Distance to coast mask
        % distanceToCoastMask = ~(tmpDistanceToCoast <= 2000);
        % distanceToCoastMask = ~(tmpDistanceToCoast <= 0);

        % combinedMask = qualityMask & locationMask;% & distanceToCoastMask;
        combinedMask1 = qualityMask & locationMask;% & distanceToCoastMask;


        % Convert to FRF Coordinates
        % [~, ~, ~, ~, frfY, frfX] = frfCoord_bigArea(tmplon(combinedMask), tmplat(combinedMask));
        [~, ~, ~, ~, frfY, frfX] = frfCoord_bigArea(tmplon(combinedMask1), tmplat(combinedMask1));


        % --- New FRF X mask: keep only pixels with FRF_X >= 1700 ---
        frfMask = frfX >= 1700;
        % frfMask = frfX >= 1100;
        % frfMask = frfX >= 0;

        % --- Update combinedMask by embedding frfMask back into main array ---
        fullMask = combinedMask1;
        fullMask(combinedMask1) = frfMask;

        % Replace original combinedMask
        combinedMask = fullMask;

        % --- ALSO shrink frfX and frfY so they match the updated mask ---
        frfX = frfX(frfMask);
        frfY = frfY(frfMask);

        % Convert from EGM2008 to NAVD88
        filteredHeightGeoid = tmpSSH(combinedMask) - tmpGeoid(combinedMask) + tmpCrossOver(combinedMask) + sea_state_bias_cor_2(combinedMask) - tmpSolidEarthTide(combinedMask) - tmpLoadTide(combinedMask) - tmpPoleTide(combinedMask); 
        filteredHeight_NAVD88 = filteredHeightGeoid + 0.24; 

        % Total water level method
        % filteredHeight_NAVD88=ssha_karin_2(combinedMask) + ocean_tide_fes(combinedMask) + mean_sea_surface_cnescls(combinedMask) + dac(combinedMask) + ...
            % ocean_tide_non_eq(combinedMask) + internal_tide_hret(combinedMask) - tmpGeoid(combinedMask) + 0.24;

        % Just plain old ssh
        % filteredHeight_NAVD88= tmpSSH(combinedMask) - tmpGeoid(combinedMask) + 0.24;

        % --- Nearest pixels with thresholds ---
        % Water level pier
        distances = sqrt((frfX - waterlevel_frfX).^2 + (frfY - waterlevel_frfY).^2);
        [minDist2waterLevel, waterLevel_idx_min] = min(distances);
        if minDist2waterLevel > maxDistWaterLevel
            % waterLevel_idx_min = NaN;
            minDist2waterLevel = 0;% NaN;
        end

        % 17m buoy
        distances2buoy = sqrt((frfX - sensorCoords(13,1)).^2 + (frfY - sensorCoords(13,2)).^2);
        [minDistTo17mBuoy, minDistTo17mBuoy_idx] = min(distances2buoy);
        % if minDistTo17mBuoy > maxDist17mBuoy
        %     minDistTo17mBuoy_idx = NaN;
        %     minDistTo17mBuoy = NaN;
        % end

        % 600m sensor
        distancesTo600mSensor = sqrt((frfX - sensorCoords(11,1)).^2 + (frfY - sensorCoords(11,2)).^2);
        [minDistTo600mSensor, minDistTo600mSensor_idx] = min(distancesTo600mSensor);
        % if minDistTo600mSensor > maxDist600mSensor
        %     minDistTo600mSensor_idx = NaN;
        %     minDistTo600mSensor =  NaN;
        % end

        % 26m buoy
        distancesTo26mBuoy = sqrt((frfX - sensorCoords(14,1)).^2 + (frfY - sensorCoords(14,2)).^2);
        [minDistTo26mBuoy, minDistTo26mBuoy_idx] = min(distancesTo26mBuoy);
        % if minDistTo26mBuoy > maxDist26mBuoy
        %     minDistTo26mBuoy_idx = NaN;
        %     minDistTo26mBuoy =  NaN;
        % end

          % 900m sensor
        distancesTo900mSensor = sqrt((frfX - sensorCoords(12,1)).^2 + (frfY - sensorCoords(12,2)).^2);
        [minDistTo900mSensor, minDistTo900mSensor_idx] = min(distancesTo900mSensor);
        % if minDistTo900mSensor > maxDist900mSensor
        %     minDistTo600mSensor_idx = NaN;
        %     minDistTo900mSensor = NaN;
        % end

        % % Uses point closest to x coordinate
        % % 17m buoy        % [minDistTo17mBuoy, minDistTo17mBuoy_idx] = min(distances2buoy);
        % if minDistTo17mBuoy > maxDist17mBuoy
        %     % minDistTo17mBuoy_idx = NaN;
        %     minDistTo17mBuoy = 0; %NaN;
        % end
        % 
        % % 600m sensor        % [minDistTo600mSensor, minDistTo600mSensor_idx] = min(distancesTo600mSensor);
        % if minDistTo600mSensor > maxDist600mSensor
        %     % minDistTo600mSensor_idx = NaN;
        %     minDistTo600mSensor = 0;% NaN;
        % end
        % 
        % % 26m buoy        % [minDistTo26mBuoy, minDistTo26mBuoy_idx] = min(distancesTo26mBuoy);
        % if minDistTo26mBuoy > maxDist26mBuoy
        %     % minDistTo26mBuoy_idx = NaN;
        %     minDistTo26mBuoy = 0; % NaN;
        % end
        % 
        % % 900m sensor        % [minDistTo900mSensor, minDistTo900mSensor_idx] = min(distancesTo900mSensor);
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
            'SWH', tmpSWH_karin(combinedMask), ...
            'SWH_qualityFlag', tmpSWH_qualityFlag(combinedMask), ...
            'SWH_Index17mBuoy', minDistTo17mBuoy_idx, ...
            'DistanceTo17mBuoy', minDistTo17mBuoy, ...
            'SWH_Index26mBuoy', minDistTo26mBuoy_idx, ...
            'DistanceTo26mBuoy', minDistTo26mBuoy, ...
            'SWH_Index600mSensor', minDistTo600mSensor_idx, ...
            'DistanceTo600mSensor', minDistTo600mSensor, ... 
            'SWH_Index900mSensor', minDistTo900mSensor_idx, ...
            'DistanceTo900mSensor', minDistTo900mSensor, ... 
            'WindSpeed', tmpWindSpeed(combinedMask), ...
            'Distance2Coast', tmpDistanceToCoast(combinedMask), ...
            'SshQualityFlag', tmpQualFlag(combinedMask), ...
            'Vol_Corr', tmpVolumetric_correlation(combinedMask), ...
            'Vol_Corr_Uncert', tmpVolumetric_correlation_uncert(combinedMask) ...
        );
    end

  % Remove empty fields
    dataStruct = removeEmptyFieldsFromStruct(dataStruct);

    % Save the structure to a MAT file
    save(fullfile(paths.swot.l2LrExpert, ...
        '250m_LR_L2_SSH_expert_Processed.mat'), 'dataStruct');

    disp('Processing complete. Data saved.');
end
