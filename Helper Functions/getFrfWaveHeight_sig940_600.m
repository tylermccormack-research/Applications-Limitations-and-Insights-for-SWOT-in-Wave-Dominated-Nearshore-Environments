function [significantWaveHeight, peakPeriod, peakDirection, meanDirection]  = getFrfWaveHeight_sig940_600(meanTimeDateTime)
    % Input: meanTimeDateTime (string) in format 'dd-MMM-yyyy HH:mm:ss'
    % Output: significantWaveHeight (double)

    % Convert meanTimeDateTime to MATLAB datetime
    targetDateTime = datetime(meanTimeDateTime, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss');
    targetYear = datestr(targetDateTime, 'yyyy');
    targetMonth = datestr(targetDateTime, 'yyyymm');

    % URL of the catalog for the specific year
    baseURL = strcat("https://chldata.erdc.dren.mil/thredds/catalog/frf/oceanography/waves/sig940-600/", targetYear, "/catalog.html");

    % Search the catalog for files matching the target month
    catalogURL = strcat("https://chldata.erdc.dren.mil/thredds/fileServer/frf/oceanography/waves/sig940-600/", targetYear, "/");
    fileName = findNetCDFFile(baseURL, targetMonth);

    % Full URL of the netCDF file
    netCDFURL = strcat(catalogURL, fileName);

    % Download the netCDF file locally
    localFile = strcat(tempname, ".nc");
    websave(localFile, netCDFURL);

    % Open the downloaded netCDF file
    ncid = netcdf.open(localFile, 'NC_NOWRITE');

    try
        % Read time variable
        timeVarID = netcdf.inqVarID(ncid, 'time');
        timeData = netcdf.getVar(ncid, timeVarID);
        
        % Convert time to MATLAB datetime
        timeData=datetime(timeData, 'convertFrom','epochtime');

        % Find the closest time index
        [~, closestIndex] = min(abs(timeData - targetDateTime));

        % Read significant wave height and other variables
        % Wave height (significant)
        waveHeightVarID = netcdf.inqVarID(ncid, 'waveHs');
        waveHeightData = netcdf.getVar(ncid, waveHeightVarID);
        % Peak period
        periodVarID=netcdf.inqVarID(ncid, 'waveTp');
        periodData=netcdf.getVar(ncid, periodVarID);
        % mean Direction, peak period
        peakDirectionID=netcdf.inqVarID(ncid,'wavePeakDirectionPeakFrequency');
        peakDirectionData=netcdf.getVar(ncid,peakDirectionID);
        % mean direction
        meanDirectionID=netcdf.inqVarID(ncid,'waveMeanDirection');
        meanDirectionData=netcdf.getVar(ncid,meanDirectionID);

        
        % Extract significant wave height at closest index
        significantWaveHeight = waveHeightData(closestIndex);
        peakPeriod=periodData(closestIndex);
        peakDirection=peakDirectionData(closestIndex);
        meanDirection=meanDirectionData(closestIndex);

    catch ME
        netcdf.close(ncid);
        delete(localFile);
        rethrow(ME);
    end

    % Close the netCDF file and delete the local copy
    netcdf.close(ncid);
    delete(localFile);

    fprintf('In-situ Significant wave height at %s: %.2f m\n', meanTimeDateTime, significantWaveHeight);
end

function fileName = findNetCDFFile(baseURL, targetMonth)
    % Function to scrape the catalog HTML and find the file matching the target month
    % Input: baseURL (string), targetMonth (string in 'yyyymm')
    % Output: fileName (string)

    % Use MATLAB's webread to fetch the HTML catalog
    catalogHTML = webread(baseURL);

    % Parse the HTML to find the correct file for the month
    filePattern = strcat('FRF-ocean_waves_sig940-600_', targetMonth, '.*?.nc');
    fileMatches = regexp(catalogHTML, filePattern, 'match');

    if isempty(fileMatches)
        error('No netCDF file found for the specified month.');
    end

    % Return the first matching file name
    fileName = fileMatches{1};
end
