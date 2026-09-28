function [xFRF, yFRF, elevation] = getFrfDEM(meanTimeDateTime)
    % Input: meanTimeDateTime (string) in format 'dd-MMM-yyyy'
    % Output: xFRF, yFRF, elevation (arrays from the DEM file)
    %
    % This version discovers available DEM files on the THREDDS file-server
    % directory by reading the directory HTML and matching filenames of the
    % form:
    % FRF_geomorphology_DEMs_surveyDEM_YYYYMMDD.nc
    %
    % If the directory cannot be read, and frfDEMnames.mat exists locally,
    % it will attempt to use that as a fallback.

    % Construct base directory (directory listing) and filename pattern
    baseDir = "https://chldata.erdc.dren.mil/thredds/fileServer/frf/geomorphology/DEMs/surveyDEM/data/";
    filePattern = 'FRF_geomorphology_DEMs_surveyDEM_(\d{8})\.nc';

    % Convert input date to datetime
    targetDateTime = datetime(meanTimeDateTime, 'InputFormat', 'dd-MMM-yyyy');

    closestIndex = [];
    demDates = datetime.empty;
    demFileNames = string.empty;

    % Try to read directory listing from the web
    try
        % Read HTML/content of the directory (returns char or string)
        htmlText = webread(char(baseDir));
        % Extract filenames that match pattern
        tokens = regexp(htmlText, filePattern, 'tokens');
        if ~isempty(tokens)
            % tokens is cell array of 1x1 cells with the date string
            extractedDates = cellfun(@(c) c{1}, tokens, 'UniformOutput', false);
            % Unique-ify while preserving order
            extractedDates = unique(extractedDates, 'stable');
            % Build full file names
            demFileNames = strcat("FRF_geomorphology_DEMs_surveyDEM_", string(extractedDates), ".nc");
            % Convert to datetimes
            demDates = datetime(extractedDates, 'InputFormat','yyyyMMdd');
        else
            warning('No matching DEM filenames found in directory listing.');
        end
    catch webErr
        % Could not read remote directory listing (network issue / site blocked / etc.)
        warning('Could not read remote directory listing: %s', webErr.message);
    end

    % If we didn't get a list from web, attempt fallback to local frfDEMnames.mat
    if isempty(demFileNames)
        if exist('frfDEMnames.mat','file') == 2
            try
                % Expecting frfDEMnames variable to contain strings like YYYYMMDD (or full filenames)
                s = load('frfDEMnames.mat');
                % try a few common variable names and formats
                if isfield(s, 'frfDEMnames')
                    rawList = s.frfDEMnames;
                elseif isfield(s, 'demFileNames')
                    rawList = s.demFileNames;
                else
                    % If the .mat stored filenames as a cell array variable
                    vars = fieldnames(s);
                    rawList = s.(vars{1});
                end

                % Normalize rawList to strings of filenames or date substrings
                if iscell(rawList) || isstring(rawList) || ischar(rawList)
                    rawList = string(rawList);
                    % If elements look like 'YYYYMMDD' without prefix/suffix turn them into filenames
                    isDateOnly = all(cellfun(@(x) ~isempty(regexp(char(x), '^\d{8}$','once')), cellstr(rawList)));
                    if isDateOnly
                        demFileNames = strcat("FRF_geomorphology_DEMs_surveyDEM_", rawList, ".nc");
                        demDates = datetime(rawList, 'InputFormat', 'yyyyMMdd');
                    else
                        % Try to extract the YYYYMMDD portion from each entry
                        toks = regexp(rawList, '(\d{8})', 'tokens', 'once');
                        ok = ~cellfun(@isempty, toks);
                        if any(ok)
                            datestrlist = string(cellfun(@(c) c{1}, toks(ok), 'UniformOutput', false));
                            demFileNames = strcat("FRF_geomorphology_DEMs_surveyDEM_", datestrlist, ".nc");
                            demDates = datetime(datestrlist, 'InputFormat', 'yyyyMMdd');
                        else
                            error('Unable to parse dates from frfDEMnames.mat contents.');
                        end
                    end
                else
                    error('Unexpected format inside frfDEMnames.mat.');
                end
            catch matErr
                error('Fallback failed: unable to parse frfDEMnames.mat: %s', matErr.message);
            end
        else
            error('No remote listing found and frfDEMnames.mat not present. Cannot determine DEM files.');
        end
    end

    % Find the closest date in the DEM list
    [~, closestIndex] = min(abs(demDates - targetDateTime));
    closestDate = demDates(closestIndex);
    closestFileName = demFileNames(closestIndex);

    % Construct the full URL for the closest DEM file
    netCDFURL = strcat(baseDir, closestFileName);

    % Read variables from netCDF: attempt to use ncread (direct URL) and
    % fall back to websave + netcdf.open if ncread fails.
    try
        % Try ncread directly from URL (works if server supports OPeNDAP or direct HTTP reads)
        xFRF = ncread(char(netCDFURL), 'xFRF');
        yFRF = ncread(char(netCDFURL), 'yFRF');
        elevation = ncread(char(netCDFURL), 'elevation');
    catch ncreadErr
        % If ncread fails, download the file locally and use netcdf.* API
        localFile = strcat(tempname, ".nc");
        try
            websave(localFile, char(netCDFURL));
            ncid = netcdf.open(localFile, 'NC_NOWRITE');
            try
                xFRF = netcdf.getVar(ncid, netcdf.inqVarID(ncid, 'xFRF'));
                yFRF = netcdf.getVar(ncid, netcdf.inqVarID(ncid, 'yFRF'));
                elevation = netcdf.getVar(ncid, netcdf.inqVarID(ncid, 'elevation'));
            catch innerME
                netcdf.close(ncid);
                delete(localFile);
                rethrow(innerME);
            end
            netcdf.close(ncid);
            delete(localFile);
        catch dlErr
            if exist('localFile','var') && exist(localFile,'file')
                delete(localFile);
            end
            error('Failed to read DEM from URL: %s\nncread error: %s', dlErr.message, ncreadErr.message);
        end
    end

    fprintf('Retrieved DEM data for date: %s (closest to input date: %s)\n', datestr(closestDate, 'yyyy-mm-dd'), meanTimeDateTime);
end
