function [dataStruct]=processSWOTpixelCloudHRfunc_bigArea(inputPath)
paths = setupPaths();

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
    % load(fullfile(paths.preprocessing, 'waterLevel_frfX.mat'));
    % load(fullfile(paths.preprocessing, 'waterLevel_frfY.mat'));
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
        fieldName = ['HR_pixCloud_' prefix '_' date]; % Combine into "HR_100m_001_354_046F_20230802"


        % Read NetCDF information and variables
        tmplat = ncread(fullFilePath, 'pixel_cloud/latitude');
        tmplon = ncread(fullFilePath, 'pixel_cloud/longitude');
        tmpSSH = ncread(fullFilePath, 'pixel_cloud/height');
        tmpTime = ones(size(tmpSSH)) .* (ncread(fullFilePath, 'pixel_cloud/illumination_time'));
        tmpGeoid = ncread(fullFilePath, 'pixel_cloud/geoid');
        tmpPixelArea= ncread(fullFilePath, 'pixel_cloud/pixel_area');
        solidEarthTide = ncread(fullFilePath, 'pixel_cloud/solid_earth_tide');
        load_tide_fes= ncread(fullFilePath, 'pixel_cloud/load_tide_fes');
        % load_tide_got= ncread(fullFilePath, 'pixel_cloud/load_tide_got');
        pole_tide= ncread(fullFilePath, 'pixel_cloud/pole_tide');
        tmpInterferogramQual=ncread(fullFilePath,'pixel_cloud/interferogram_qual');
        tmpGeolocationQual=ncread(fullFilePath,'pixel_cloud/geolocation_qual');
        tmpCrossTrackLocation=ncread(fullFilePath,'pixel_cloud/cross_track');
        tmpLandClass=ncread(fullFilePath,'pixel_cloud/classification');

        % Secondary attributes
        tmpSig0 = ncread(fullFilePath, 'pixel_cloud/sig0');
        tmpSig0_qual = ncread(fullFilePath, 'pixel_cloud/sig0_qual');
        tmpPhaseNoiseStd = ncread(fullFilePath, 'pixel_cloud/phase_noise_std');
        tmpIncidenceAngle = ncread(fullFilePath, 'pixel_cloud/inc');
        tmpCoherentPower = ncread(fullFilePath, 'pixel_cloud/coherent_power');
        tmpPowerPlusY= ncread(fullFilePath, 'pixel_cloud/power_plus_y');
        tmpPowerMinusY=ncread(fullFilePath, 'pixel_cloud/power_minus_y');
        tmpXFactorPlusY=ncread(fullFilePath, 'pixel_cloud/x_factor_plus_y');
        tmpXFactorMinusY=ncread(fullFilePath, 'pixel_cloud/x_factor_minus_y');
        tmpDheight_dphase=ncread(fullFilePath, 'pixel_cloud/dheight_dphase');
        tmpAzimuth_index=ncread(fullFilePath, 'pixel_cloud/azimuth_index');
        tmpRange_index=ncread(fullFilePath, 'pixel_cloud/range_index');
        tmpNumLooks=ncread(fullFilePath, 'pixel_cloud/eff_num_rare_looks');
        tmpInterferogram=ncread(fullFilePath, 'pixel_cloud/interferogram');

        % TVP variables
        tmpVelHeadingMean=mean(ncread(fullFilePath, 'tvp/velocity_heading'));

        % Convert from 0-360 longitude to -180 to 180
        tmplon = rem((tmplon + 180), 360) - 180;

        % % Filter close to FRF only in lat/lon
        % [filteredLat, filteredLon, inBox] = filterFRFregion_latlong_bigArea(tmplat, tmplon);% tmpSSH, tmpTime, tmpGeoid);
        % 
        % Convert to FRF Coordinates
        [~, ~, ~, ~, frfY, frfX] = frfCoord_bigArea(tmplon, tmplat);

        % Filter close to FRF only in FRF coordinates
        % [ finalBox, filteredFrfX, filteredFrfY] = filterFRFregion_frf(frfY, frfX, inBox); %, filteredHeight_NAVD88, filteredTime);
        % filteredFrfX=frfX;
        % filteredFrfY=frfY;

        % Quality flag mask
        qualityFlagged = (tmpSig0_qual >= 33554432) | ...
            (tmpInterferogramQual >= 134217728) | ...
            (tmpGeolocationQual == 4) | ...
            (tmpGeolocationQual >= 134217728) | ...
            (tmpLandClass <= 2); % If its flagged, its bad
        qualityMask = ~qualityFlagged;  % Good data = not flagged

        % Geographic location mask
        minLat = 36.15;
        maxLat = 36.22;
        minLon = -75.765;
        maxLon = -75.69;

        locationMask = (tmplat >= minLat) & (tmplat <= maxLat) & ...
            (tmplon >= minLon) & (tmplon <= maxLon);  

        % Combine both masks
        combinedMask = qualityMask & locationMask;

        % % Quality flag filtering
        % [time_qualityFiltered, filteredFrfX_qualityFiltered, filteredFrfY_qualityFiltered, filteredHeight_NAVD88_qualityFiltered, qualityFlagged]=qualityFlagFiltering(Sig0_qual, interferogramQual, geolocationQual, time, filteredFrfX, filteredFrfY, filteredHeight_NAVD88, landClass);


         % Convert from EGM2008 to NAVD88
        % tmpSSH_withTides=tmpSSH(combinedMask);
        filteredHeightGeoid=tmpSSH(combinedMask)-tmpGeoid(combinedMask) - (solidEarthTide(combinedMask) + load_tide_fes(combinedMask) + pole_tide(combinedMask)) ; 

        egm2008toNavd88Value=0.24; % From vdatum for FRF coords
        filteredHeight_NAVD88 = filteredHeightGeoid  + egm2008toNavd88Value; 

         % Find SWOT location closest to FRF pier (with quality check passed)
        distances = sqrt((frfX(combinedMask) - waterlevel_frfX).^2 + (frfY(combinedMask) - waterlevel_frfY).^2);
        [minDist2waterLevel, waterLevel_idx_min] = min(distances);

        % Add noise powers
        [noise_plus_y_remapped, noise_minus_y_remapped] = addNoisePowerToProcessedPixelCloud(fname);


        % Store results in the structure under the unique key
        dataStruct.(fieldName) = struct( ...
            'time', tmpTime(combinedMask), ...
            'lat', tmplat(combinedMask),...
            'lon', tmplon(combinedMask),...
            'FRF_X', frfX(combinedMask), ...
            'FRF_Y', frfY(combinedMask), ...
            'Filtered_SWE_NAVD88', filteredHeight_NAVD88, ...
            'Water_Level_Index', waterLevel_idx_min, ...
            'NearestPointToWaterLevelDist_meters', minDist2waterLevel, ...
            'Velocity_heading_mean', tmpVelHeadingMean, ...
            'CrossTrackLocation', tmpCrossTrackLocation(combinedMask), ...
            'Sig0_qual', tmpSig0_qual(combinedMask), ...
            'Geolocation_qual', tmpGeolocationQual(combinedMask), ...
            'InterferogramQual', tmpInterferogramQual(combinedMask), ...
            'qualityFlaggedIndices', qualityFlagged, ...
            'landClass', tmpLandClass(combinedMask), ...
            'PixelArea', tmpPixelArea(combinedMask), ...
            'Sig0', tmpSig0(combinedMask), ...
            'PhaseNoiseSTD', tmpPhaseNoiseStd(combinedMask), ...
            'IncidenceAngle', tmpIncidenceAngle(combinedMask), ...
            'CoherentPower', tmpCoherentPower(combinedMask), ...
            'PowerPlusY', tmpPowerPlusY(combinedMask), ...
            'PowerMinusY', tmpPowerMinusY(combinedMask), ...
            'XFactorPlusY', tmpXFactorPlusY(combinedMask), ...
            'XFactorMinusY', tmpXFactorMinusY(combinedMask), ...
            'dheight_dphase', tmpDheight_dphase(combinedMask), ...
            'AzimuthIndex', tmpAzimuth_index(combinedMask), ...
            'RangeIndex', tmpRange_index(combinedMask), ...
            'noise_plus_y_remapped', noise_plus_y_remapped(combinedMask), ...
            'noise_minus_y_remapped', noise_minus_y_remapped(combinedMask), ...
            'NumLooks', tmpNumLooks(combinedMask), ...
            'Interferogram', tmpInterferogram(:,combinedMask) ...
        );

    end

    % Save the structure to a MAT file
    save(fullfile(paths.swot.pixc, 'pixelCloud_Processed_bigArea.mat'), 'dataStruct');

    disp('Processing complete. Data saved.');
end