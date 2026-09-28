function [dataStruct]=processSWOTpixelCloudHRfunc(inputPath)
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
        fieldName = ['HR_pixCloud_' prefix '_' date]; % Combine into "HR_100m_001_354_046F_20230802"


        % Read NetCDF information and variables
        tmplat = ncread(fullFilePath, 'pixel_cloud/latitude');
        tmplon = ncread(fullFilePath, 'pixel_cloud/longitude');
        tmpSSH = ncread(fullFilePath, 'pixel_cloud/height');
        tmpTime = ones(size(tmpSSH)) .* (ncread(fullFilePath, 'pixel_cloud/illumination_time'));
        % tmpPixc_line_qual = ncread(fullFilePath, 'pixel_cloud/pixc_line_qual'); % 'Quality flag for pixel cloud data per rare-posted interferogram line (similar to slc_qual in the L1B_HR_SLC product)'
        tmpGeoid = ncread(fullFilePath, 'pixel_cloud/geoid');
        tmpPixelArea= ncread(fullFilePath, 'pixel_cloud/pixel_area');
        solidEarthTide = ncread(fullFilePath, 'pixel_cloud/solid_earth_tide');
        load_tide_fes= ncread(fullFilePath, 'pixel_cloud/load_tide_fes');
        load_tide_got= ncread(fullFilePath, 'pixel_cloud/load_tide_got');
        pole_tide= ncread(fullFilePath, 'pixel_cloud/pole_tide');
        tmpInterferogramQual=ncread(fullFilePath,'pixel_cloud/interferogram_qual');
        tmpGeolocationQual=ncread(fullFilePath,'pixel_cloud/geolocation_qual');
        tmpVelHeadingMean=mean(ncread(fullFilePath, 'tvp/velocity_heading'));
        % tmpTvpX=ncread(fullFilePath,'tvp/x');
        % tmpTvpY=ncread(fullFilePath,'tvp/y');
        tmpCrossTrackLocation=ncread(fullFilePath,'pixel_cloud/cross_track');
        tmpLandClass=ncread(fullFilePath,'pixel_cloud/classification');


        % Secondary attributes
        tmpSig0 = ncread(fullFilePath, 'pixel_cloud/sig0');
        tmpSig0_qual = ncread(fullFilePath, 'pixel_cloud/sig0_qual');
        tmpPhaseNoiseStd = ncread(fullFilePath, 'pixel_cloud/phase_noise_std');
        tmpIncidenceAngle = ncread(fullFilePath, 'pixel_cloud/inc');
        tmpCoherentPower = ncread(fullFilePath, 'pixel_cloud/coherent_power');
        tmpInterferogram=ncread(fullFilePath,'pixel_cloud/interferogram');
        tmpLayoverImpact=ncread(fullFilePath,'pixel_cloud/layover_impact');

        % Convert from 0-360 longitude to -180 to 180
        tmplon = rem((tmplon + 180), 360) - 180;

        % Filter close to FRF only in lat/lon
        [filteredLat, filteredLon, inBox] = filterFRFregion_latlong(tmplat, tmplon);% tmpSSH, tmpTime, tmpGeoid);

        % Convert to FRF Coordinates
        [~, ~, ~, ~, frfY, frfX] = frfCoord(filteredLon, filteredLat);

        % Filter close to FRF only in FRF coordinates
        [ finalBox, filteredFrfX, filteredFrfY] = filterFRFregion_frf(frfY, frfX, inBox); %, filteredHeight_NAVD88, filteredTime);
      

        % Convert from EGM2008 to NAVD88
        tmpSSH_withTides=tmpSSH  + solidEarthTide + load_tide_fes +  pole_tide;
        filteredHeightGeoid=tmpSSH_withTides(finalBox)-tmpGeoid(finalBox); %% ??
        % mllw2navd88=-0.666;
        filteredHeight_NAVD88 = filteredHeightGeoid  + 0.243; %+ mllw2navd88; %;

        % Filter out all variables of interest
        time=tmpTime(finalBox);
        PixelArea=tmpPixelArea(finalBox);
        Sig0_qual=tmpSig0_qual(finalBox);
        interferogramQual=tmpInterferogramQual(finalBox);
        geolocationQual=tmpGeolocationQual(finalBox);
        landClass=tmpLandClass(finalBox);

        Sigma0=tmpSig0(finalBox);
        PhaseNoiseSTD=tmpPhaseNoiseStd(finalBox);
        CoherentPower=tmpCoherentPower(finalBox);
        IncidenceAngle=tmpIncidenceAngle(finalBox);
        Interferogram=tmpInterferogram(finalBox);
        LayoverImpact=tmpLayoverImpact(finalBox);

        % Quality flag filtering
        [time_qualityFiltered, filteredFrfX_qualityFiltered, filteredFrfY_qualityFiltered, filteredHeight_NAVD88_qualityFiltered, qualityFlagged]=qualityFlagFiltering(Sig0_qual, interferogramQual, geolocationQual, time, filteredFrfX, filteredFrfY, filteredHeight_NAVD88, landClass);

         % Apply quality filters to other variables of interest
        Sigma0=Sigma0(~qualityFlagged);
        PhaseNoiseSTD=PhaseNoiseSTD(~qualityFlagged);
        CoherentPower=CoherentPower(~qualityFlagged);
        IncidenceAngle=IncidenceAngle(~qualityFlagged);
        Interferogram=Interferogram(~qualityFlagged);
        LayoverImpact=LayoverImpact(~qualityFlagged);

        % Find SWOT location closest to FRF pier (with quality check passed)
        distances = sqrt((filteredFrfX_qualityFiltered - waterlevel_frfX).^2 + (filteredFrfY_qualityFiltered - waterlevel_frfY).^2);
        [minDist2waterLevel, waterLevel_idx_min] = min(distances);

        % Store results in the structure under the unique key
        dataStruct.(fieldName) = struct( ...
            'time', time, ...
            'FRF_X', filteredFrfX, ...
            'FRF_Y', filteredFrfY, ...
            'Filtered_SWE_NAVD88', filteredHeight_NAVD88, ...
            'Water_Level_Index', waterLevel_idx_min, ...
            'NearestPointToWaterLevelDist_meters', minDist2waterLevel, ...
            'Velocity_heading_mean', tmpVelHeadingMean, ...
            'CrossTrackLocation', tmpCrossTrackLocation(finalBox), ...
            'Sig0_qual', Sig0_qual,...
            'Geolocation_qual', geolocationQual,...
            'InterferogramQual',interferogramQual,...
            'qualityFlaggedIndices',qualityFlagged,...
            'landClass',landClass,...
            'PixelArea',PixelArea,...
            'time_qualityFiltered', time_qualityFiltered, ...
            'FRF_X_qualityFiltered', filteredFrfX_qualityFiltered, ...
            'FRF_Y_qualityFiltered', filteredFrfY_qualityFiltered, ...
            'Filtered_SWE_NAVD88_qualityFiltered', filteredHeight_NAVD88_qualityFiltered, ...
            'Sig0', Sigma0, ...
            'PhaseNoiseSTD', PhaseNoiseSTD, ...
            'CoherentPower', CoherentPower, ...      
            'IncidenceAngle', IncidenceAngle, ...
            'Interferogram', Interferogram, ...
            'LayoverImpact', LayoverImpact);
       
    end

    % Save the structure to a MAT file
    save(fullfile('D:\SWOT\Data\SWOTdata\frf_PointCloud', 'pixelCloud_Processed.mat'), 'dataStruct');

    disp('Processing complete. Data saved.');
end