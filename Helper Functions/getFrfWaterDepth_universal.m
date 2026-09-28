function waterDepth = getFrfWaterDepth_universal(meanTimeDateTime, instrument)
    % Input:
    %   meanTimeDateTime (string) in format 'dd-MMM-yyyy HH:mm:ss'
    %   instrument (string): e.g., 'sig940-300', 'paros940-250', etc.
    %
    % Output:
    %   waterDepth (double)

    % ---- SPECIAL CASE: 8m-array → ALWAYS RETURN 8.43 ----
    if strcmpi(instrument, '8m-array')
        waterDepth = 8.43;
        fprintf('Water Depth at %s from %s: %.2f m (nominal depth)\n', ...
                meanTimeDateTime, instrument, waterDepth);
        return;
    end

    % Convert input time string to datetime
    targetDateTime = datetime(meanTimeDateTime, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss');
    targetYear = datestr(targetDateTime, 'yyyy');
    targetMonth = datestr(targetDateTime, 'yyyymm');

    % Base URL paths
    catalogBaseURL   = sprintf("https://chldata.erdc.dren.mil/thredds/catalog/frf/oceanography/waves/%s/%s/catalog.html", instrument, targetYear);
    fileServerBaseURL = sprintf("https://chldata.erdc.dren.mil/thredds/fileServer/frf/oceanography/waves/%s/%s/", instrument, targetYear);

    % Find file matching month
    fileName = findNetCDFFile(catalogBaseURL, targetMonth, instrument);

    % Download file
    netCDFURL = strcat(fileServerBaseURL, fileName);
    localFile = strcat(tempname, ".nc");
    websave(localFile, netCDFURL);

    % Open NetCDF
    ncid = netcdf.open(localFile, 'NC_NOWRITE');

    try
        % ---- TIME ----
        timeVarID = netcdf.inqVarID(ncid, 'time');
        timeData = netcdf.getVar(ncid, timeVarID);
        timeData = datetime(timeData, 'ConvertFrom', 'epochtime');
        [~, closestIndex] = min(abs(timeData - targetDateTime));

        % ---- DEPTH LOGIC BRANCHES ----
        switch instrument

            case {'paros940-200','paros940-250','xp340m'}
                varID = netcdf.inqVarID(ncid, 'depthP');
                data = netcdf.getVar(ncid, varID);
                waterDepth = data(closestIndex);

            case {'sig940-300','sig940-600'}
                bottomID    = netcdf.inqVarID(ncid,'bottomEelevation');
                gaugeElevID = netcdf.inqVarID(ncid,'gaugeElevation');
                gaugeDepthID = netcdf.inqVarID(ncid,'gaugeDepth');

                bottom = netcdf.getVar(ncid, bottomID);
                gElev  = netcdf.getVar(ncid, gaugeElevID);
                gDepth = netcdf.getVar(ncid, gaugeDepthID);

                waterDepth = (bottom(closestIndex) - gElev) + gDepth(closestIndex);

            case 'awac-4.5m'
                varID = netcdf.inqVarID(ncid, 'depth');
                data = netcdf.getVar(ncid, varID);
                waterDepth = data(closestIndex);

            case 'waverider-17m'
                waterDepth = 17.0;

            case 'waverider-26m'
                waterDepth = 26.0;

            otherwise
                % Try nominalDepth as fallback
                try
                    varID = netcdf.inqVarID(ncid, 'nominalDepth');
                    data = netcdf.getVar(ncid, varID);
                    waterDepth = data(closestIndex);
                catch
                    error('Instrument %s does not match any logic and has no nominalDepth.', instrument);
                end
        end

    catch ME
        netcdf.close(ncid);
        delete(localFile);
        rethrow(ME);
    end

    % Cleanup
    netcdf.close(ncid);
    delete(localFile);

    fprintf('Water Depth at %s from %s: %.2f m\n', meanTimeDateTime, instrument, waterDepth);
end


function fileName = findNetCDFFile(baseURL, targetMonth, instrument)
    catalogHTML = webread(baseURL);
    filePattern = sprintf('FRF-ocean_waves_%s_%s.*?\\.nc', instrument, targetMonth);
    fileMatches = regexp(catalogHTML, filePattern, 'match');

    if isempty(fileMatches)
        error('No netCDF file found for instrument %s in month %s.', instrument, targetMonth);
    end

    fileName = fileMatches{1};
end
