function waveDirection = getFrfWaveMeanDirection_universal(meanTimeDateTime, instrument)
    % Input: 
    %   meanTimeDateTime (string) in format 'dd-MMM-yyyy HH:mm:ss'
    %   instrument (string) e.g., 'sig940-300', 'paros940-250', etc.
    % awac-4.5m
    % lidarWaveGauge080 X
    % lidarWaveGauge090 X
    % lidarWaveGauge100 X 
    % lidarWaveGauge110 X
    % lidarWaveGauge140 X
    % paros940-200
    % paros940-250
    % sig940-300
    % sig940-600
    % waverider-17m
    % waverider-26m
    % xp340m


    % Output: 
    %   significantWaveHeight (double)

    % Convert input time string to datetime
    targetDateTime = datetime(meanTimeDateTime, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss');
    targetYear = datestr(targetDateTime, 'yyyy');
    targetMonth = datestr(targetDateTime, 'yyyymm');

    % Base URL paths
    catalogBaseURL = sprintf("https://chldata.erdc.dren.mil/thredds/catalog/frf/oceanography/waves/%s/%s/catalog.html", instrument, targetYear);
    fileServerBaseURL = sprintf("https://chldata.erdc.dren.mil/thredds/fileServer/frf/oceanography/waves/%s/%s/", instrument, targetYear);

    % Find file matching the month
    fileName = findNetCDFFile(catalogBaseURL, targetMonth, instrument);

    % Download and read NetCDF
    netCDFURL = strcat(fileServerBaseURL, fileName);
    localFile = strcat(tempname, ".nc");
    websave(localFile, netCDFURL);

    % Open NetCDF and extract wave height
    ncid = netcdf.open(localFile, 'NC_NOWRITE');
    try
        timeVarID = netcdf.inqVarID(ncid, 'time');
        timeData = netcdf.getVar(ncid, timeVarID);
        timeData = datetime(timeData, 'ConvertFrom', 'epochtime');

        [~, closestIndex] = min(abs(timeData - targetDateTime));

        waveHeightVarID = netcdf.inqVarID(ncid, 'waveMeanDirection');
        % waveHeightVarID = netcdf.inqVarID(ncid, 'waveMeanDirectionPeakFrequency');
        % waveHeightVarID = netcdf.inqVarID(ncid, 'wavePrincipleDirection');
        % waveHeightVarID = netcdf.inqVarID(ncid, 'thetaM');

        waveHeightData = netcdf.getVar(ncid, waveHeightVarID);
        waveDirection = waveHeightData(closestIndex);
    catch ME
        netcdf.close(ncid);
        delete(localFile);
        rethrow(ME);
    end

    netcdf.close(ncid);
    delete(localFile);

    fprintf('Wave Direction at %s from %s: %.2f [degrees from north]\n', meanTimeDateTime, instrument, waveDirection);
end

function fileName = findNetCDFFile(baseURL, targetMonth, instrument)
    % Find file matching the month and instrument from THREDDS catalog HTML
    catalogHTML = webread(baseURL);

    % Construct dynamic file regex pattern
    filePattern = sprintf('FRF-ocean_waves_%s_%s.*?\\.nc', instrument, targetMonth);
    fileMatches = regexp(catalogHTML, filePattern, 'match');

    if isempty(fileMatches)
        error('No netCDF file found for instrument %s in month %s.', instrument, targetMonth);
    end

    fileName = fileMatches{1};
end
