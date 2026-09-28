function [xFRF, yFRF, elevation] = getFrfDEM(meanTimeDateTime)
    % Input: meanTimeDateTime (string) in format 'dd-MMM-yyyy'
    % Output: xFRF, yFRF, elevation (arrays from the DEM file)

    % Load DEM file names and their corresponding dates
    load('frfDEMnames.mat'); %, 'demDates', 'demFileNames');

    % Convert input date to datetime
    targetDateTime = datetime(meanTimeDateTime, 'InputFormat', 'dd-MMM-yyyy');

    % Find the closest date in the DEM list
    demDates=datetime(frfDEMnames,'InputFormat','yyyyMMdd');
    [~, closestIndex] = min(abs(demDates - targetDateTime));
    closestDate = demDates(closestIndex);
    % closestFileName = demFileNames{closestIndex};

    % Construct the full URL for the closest DEM file
    baseURL = "https://chldata.erdc.dren.mil/thredds/fileServer/frf/geomorphology/DEMs/surveyDEM/data/FRF_geomorphology_DEMs_surveyDEM_";
    netCDFURL = strcat(baseURL, frfDEMnames(closestIndex),'.nc');

    % Download the netCDF file locally
    localFile = strcat(tempname, ".nc");
    websave(localFile, netCDFURL);

    try
        % Open the downloaded netCDF file
        ncid = netcdf.open(localFile, 'NC_NOWRITE');

        % Extract xFRF, yFRF, and elevation variables
        xFRF = netcdf.getVar(ncid, netcdf.inqVarID(ncid, 'xFRF'));
        yFRF = netcdf.getVar(ncid, netcdf.inqVarID(ncid, 'yFRF'));
        elevation = netcdf.getVar(ncid, netcdf.inqVarID(ncid, 'elevation'));

        % Close the netCDF file
        netcdf.close(ncid);

    catch ME
        % Close the file and delete the local copy if an error occurs
        if exist('ncid', 'var')
            netcdf.close(ncid);
        end
        delete(localFile);
        rethrow(ME);
    end

    % Delete the local copy of the file
    delete(localFile);

    fprintf('Retrieved DEM data for date: %s (closest to input date: %s)\n', datestr(closestDate, 'yyyy-mm-dd'), meanTimeDateTime);
end
