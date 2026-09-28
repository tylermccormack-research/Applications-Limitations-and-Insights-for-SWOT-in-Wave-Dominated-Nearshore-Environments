function [output] = getFrfCurrentData_universal(meanTimeDateTime, instrument, variable)
    % Input: 
    %   meanTimeDateTime (string) in format 'dd-MMM-yyyy HH:mm:ss'
    %   instrument (string) e.g., 'sig940-300', 'paros940-250', etc.
 
    % Instrument choices
    % sig940-300
    % sig940-400
    % awac-4.5m
    % sig940-600
    % awac-11m

    % Varaible Choices (only most relevant listed here)
    % time
    % depth
    % blankDist
    % maxCell
    % currentSpeed
    % currentDirection
    % currentEast
    % currentNorth
    % qcFlag


    % Output: 
    %    (double)

    % Convert input time string to datetime
    targetDateTime = datetime(meanTimeDateTime, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss');
    targetYear = datestr(targetDateTime, 'yyyy');
    targetMonth = datestr(targetDateTime, 'yyyymm');

    % Base URL paths
    catalogBaseURL = sprintf("https://chldata.erdc.dren.mil/thredds/catalog/frf/oceanography/currents/%s/%s/catalog.html", instrument, targetYear);
    fileServerBaseURL = sprintf("https://chldata.erdc.dren.mil/thredds/fileServer/frf/oceanography/currents/%s/%s/", instrument, targetYear);

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

        outputVarID = netcdf.inqVarID(ncid, variable);
        outputData = netcdf.getVar(ncid, outputVarID);
        output = outputData(closestIndex);
    catch ME
        netcdf.close(ncid);
        delete(localFile);
        rethrow(ME);
    end

    netcdf.close(ncid);
    delete(localFile);

    fprintf('Current Speed at %s from %s: %.2f m\n', meanTimeDateTime, instrument, variable);
end

function fileName = findNetCDFFile(baseURL, targetMonth, instrument)
    % Find file matching the month and instrument from THREDDS catalog HTML
    catalogHTML = webread(baseURL);

    % Construct dynamic file regex pattern
    filePattern = sprintf('FRF-ocean_currents_%s_%s.*?\\.nc', instrument, targetMonth);
    fileMatches = regexp(catalogHTML, filePattern, 'match');

    if isempty(fileMatches)
        error('No netCDF file found for instrument %s in month %s.', instrument, targetMonth);
    end

    fileName = fileMatches{1};
end
