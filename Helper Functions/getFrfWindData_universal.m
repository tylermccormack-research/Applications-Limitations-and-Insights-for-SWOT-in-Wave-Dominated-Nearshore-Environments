function [output] = getFrfWindData_universal(meanTimeDateTime, variable)
    % Input: 
    %   meanTimeDateTime (string) in format 'dd-MMM-yyyy HH:mm:ss'
    %   instrument (string) e.g., 'sig940-300', 'paros940-250', etc.


    % Varaible Choices (only most relevant listed here)
      % windDirection
      % windSpeed


    % Output: 
    %    (double)

    % Convert input time string to datetime
    targetDateTime = datetime(meanTimeDateTime, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss');
    targetYear = datestr(targetDateTime, 'yyyy');
    targetMonth = datestr(targetDateTime, 'yyyymm');

    % Base URL paths
    catalogBaseURL = sprintf("https://chldata.erdc.dren.mil/thredds/catalog/frf/meteorology/wind/derived/%s/catalog.html", targetYear);
    fileServerBaseURL = sprintf("https://chldata.erdc.dren.mil/thredds/fileServer/frf/meteorology/wind/derived/%s/", targetYear);

    % Find file matching the month
    fileName = findNetCDFFile(catalogBaseURL, targetMonth);

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

    if strcmpi(variable, 'windSpeed')
        fprintf('Wind speed at %s: %.2f m/s\n', meanTimeDateTime, output);
    elseif strcmpi(variable, 'windDirection')
        fprintf('Wind direction at %s: %.2f deg\n', meanTimeDateTime, output);
    else
        fprintf('%s at %s: %.2f\n', variable, meanTimeDateTime, output);
    end
end

function fileName = findNetCDFFile(baseURL, targetMonth, instrument)
    % Find file matching the month and instrument from THREDDS catalog HTML
    catalogHTML = webread(baseURL);

    % Construct dynamic file regex pattern
    filePattern = sprintf('FRF-met_wind_derived_%s.*?\\.nc', targetMonth);
    fileMatches = regexp(catalogHTML, filePattern, 'match');

    if isempty(fileMatches)
        error('No netCDF file found for instrument %s in month %s.', instrument, targetMonth);
    end

    fileName = fileMatches{1};
end
