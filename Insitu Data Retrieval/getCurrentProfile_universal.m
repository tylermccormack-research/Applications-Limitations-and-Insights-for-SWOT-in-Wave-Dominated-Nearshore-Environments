paths = setupPaths();

function [out, timeNearest, idxNearest] = getCurrentProfile_universal(meanTimes, instrument, variables)
% getCurrentProfile_universal
%
% Vectorized FRF currents getter for scalar OR vector times.
% Downloads each monthly netCDF once and samples nearest time index.
%
% KEY BEHAVIOR:
% - Profile variables (time x bins) are returned as N×1 CELL ARRAYS,
%   where out.var{t} is a column vector (nBins×1). Bin count may vary by month.
% - Scalar variables (time only) are returned as N×1 numeric arrays.
% - Missing year/month files do NOT error: those requested times are left as [] (cells) or NaN (numeric).
%
% INPUTS
%   meanTimes  : datetime array (recommended) OR char/string/cellstr time(s)
%                If text, expects 'dd-MMM-yyyy HH:mm:ss'
%   instrument : e.g., 'sig940-300', 'awac-11m', etc.
%   variables  : char/string OR cell array, e.g. 'currentEast' or {'currentEast','currentNorth'}
%
% OUTPUTS
%   out        : struct with one field per variable:
%                - profile vars -> N×1 cell, each cell is nBins×1
%                - scalar vars  -> N×1 double
%   timeNearest: datetime [N×1] nearest file time
%   idxNearest : double   [N×1] nearest index used

    % -------------------------
    % Normalize variables input
    % -------------------------
    if ischar(variables) || isstring(variables)
        variables = {char(variables)};
    elseif ~iscell(variables)
        error('variables must be char/string or a cell array of variable names.');
    end

    % -------------------------
    % Convert meanTimes to datetime vector
    % -------------------------
    if isdatetime(meanTimes)
        tReq = meanTimes(:);
    else
        if ischar(meanTimes) || isstring(meanTimes)
            meanTimes = cellstr(meanTimes(:));
        elseif iscell(meanTimes)
            meanTimes = meanTimes(:);
        else
            error('meanTimes must be datetime, char/string, or cellstr.');
        end

        % Try strict format with English locale, then fallback to inferred parsing
        tReq = NaT(size(meanTimes));
        try
            tReq = datetime(meanTimes, 'InputFormat','dd-MMM-yyyy HH:mm:ss', 'Locale','en_US');
        catch
        end

        bad = isnat(tReq);
        if any(bad)
            try
                tReq(bad) = datetime(meanTimes(bad), 'Locale','en_US');
            catch
            end
        end

        if any(isnat(tReq))
            badIdx = find(isnat(tReq), 1, 'first');
            error('Failed to parse meanTimes. Example bad entry: "%s"', meanTimes{badIdx});
        end

        tReq = tReq(:);
    end

    N = numel(tReq);
    timeNearest = NaT(N,1);
    idxNearest  = NaN(N,1);

    % -------------------------
    % Group by year-month (version-safe)
    % -------------------------
    dv = datevec(tReq); % [Y M D H MN S]
    ymKey = cell(N,1);
    for k = 1:N
        ymKey{k} = sprintf('%04d%02d', dv(k,1), dv(k,2)); % 'yyyymm'
    end
    [ymGroups, ~, gIdx] = unique(ymKey, 'stable');

    % -------------------------
    % Init output struct (unknown types until we read first real month)
    % -------------------------
    out = struct();
    for v = 1:numel(variables)
        out.(matlab.lang.makeValidName(variables{v})) = []; % allocated on first successful read
    end

    % -------------------------
    % Loop over month groups
    % -------------------------
    for gg = 1:numel(ymGroups)
        these = find(gIdx == gg);
        tThis = tReq(these);

        thisYear   = sprintf('%04d', dv(these(1),1));
        thisYYYYMM = ymGroups{gg};

        yearCatalogURL = sprintf( ...
            "https://chldata.erdc.dren.mil/thredds/catalog/frf/oceanography/currents/%s/%s/catalog.html", ...
            instrument, thisYear);

        fileServerBaseURL = sprintf( ...
            "https://chldata.erdc.dren.mil/thredds/fileServer/frf/oceanography/currents/%s/%s/", ...
            instrument, thisYear);

        % Find monthly file safely (no error if missing)
        fileName = findNetCDFFile_safe(yearCatalogURL, thisYYYYMM, instrument);

        if isempty(fileName)
            % Missing year or missing month file:
            % Leave as [] for profile vars or NaN for scalar vars if already allocated
            for v = 1:numel(variables)
                fld = matlab.lang.makeValidName(variables{v});
                if isempty(out.(fld))
                    continue
                end
                if iscell(out.(fld))
                    for k = 1:numel(these)
                        out.(fld){these(k)} = [];
                    end
                else
                    out.(fld)(these) = NaN;
                end
            end
            continue
        end

        % Download monthly file once
        netCDFURL = strcat(fileServerBaseURL, fileName);
        localFile = strcat(tempname, ".nc");
        websave(localFile, netCDFURL);

        try
            % --- Read time values and convert using units attribute
            infoT = ncinfo(localFile, 'time');
            timeUnits = '';
            for a = 1:numel(infoT.Attributes)
                if strcmpi(infoT.Attributes(a).Name, 'units')
                    timeUnits = infoT.Attributes(a).Value;
                    break
                end
            end
            if isempty(timeUnits)
                error('time variable has no "units" attribute in %s', fileName);
            end

            timeVals = ncread(localFile, 'time');
            timeFile = convertNetcdfTime(timeVals, timeUnits);

            % Nearest indices for each requested time
            for k = 1:numel(these)
                [~, ii] = min(abs(timeFile - tThis(k)));
                idxNearest(these(k))  = double(ii);
                timeNearest(these(k)) = timeFile(ii);
            end

            % Pull each variable
            for v = 1:numel(variables)
                varName = variables{v};
                fld = matlab.lang.makeValidName(varName);

                varInfo = ncinfo(localFile, varName);
                dimNames = string({varInfo.Dimensions.Name});
                dimLens  = [varInfo.Dimensions.Length];

                % Identify time dimension
                tDimPos = find(strcmpi(dimNames, "time"), 1, 'first');
                if isempty(tDimPos)
                    error('Variable "%s" has no time dimension. Dims: %s', varName, strjoin(dimNames,", "));
                end

                V = ncread(localFile, varName);

                % Move time to first dimension
                if tDimPos ~= 1
                    perm = 1:numel(dimLens);
                    perm([1 tDimPos]) = [tDimPos 1];
                    V = permute(V, perm);
                    dimLens = dimLens(perm);
                end

                % Now V is [time x ...]
                V2 = reshape(V, size(V,1), []);     % [time x nOther]
                rows = idxNearest(these);
                vals = V2(rows, :);                  % [nThese x nOther]
                nOther = size(vals,2);

                isProfile = (nOther > 1);

                if isProfile
                    % Ensure field is cell N×1
                    if isempty(out.(fld))
                        out.(fld) = cell(N,1);
                    elseif ~iscell(out.(fld))
                        % Convert numeric->cell if it was allocated as numeric earlier
                        tmp = out.(fld);
                        out.(fld) = cell(N,1);
                        for ii = 1:size(tmp,1)
                            if all(isnan(tmp(ii,:)))
                                out.(fld){ii} = [];
                            else
                                out.(fld){ii} = tmp(ii,:).';
                            end
                        end
                    end

                    % Store per-time column vectors
                    for k = 1:numel(these)
                        out.(fld){these(k)} = vals(k,:).';
                    end

                else
                    % Scalar variable: numeric N×1
                    if isempty(out.(fld))
                        out.(fld) = NaN(N,1);
                    elseif iscell(out.(fld))
                        % Shouldn't happen, but keep safe
                        tmp = out.(fld); %#ok<NASGU>
                        out.(fld) = NaN(N,1);
                    end
                    out.(fld)(these) = vals(:,1);
                end
            end

        catch ME
            delete(localFile);
            rethrow(ME);
        end

        delete(localFile);
    end
end

% -------------------------------------------------------------------------
% Find monthly NetCDF file safely (returns '' if not found or year missing)
% -------------------------------------------------------------------------
function fileName = findNetCDFFile_safe(yearCatalogURL, targetMonth, instrument)
    try
        catalogHTML = webread(yearCatalogURL);
    catch
        fileName = '';
        return
    end

    filePattern = sprintf('FRF-ocean_currents_%s_%s.*?\\.nc', instrument, targetMonth);
    fileMatches = regexp(catalogHTML, filePattern, 'match');

    if isempty(fileMatches)
        fileName = '';
    else
        fileName = fileMatches{1};
    end
end

% -------------------------------------------------------------------------
% Convert NetCDF time values to datetime using time units attribute
% -------------------------------------------------------------------------
function dt = convertNetcdfTime(timeVals, unitsStr)
    unitsStr = char(unitsStr);

    tok = regexp(unitsStr, '^\s*(\w+)\s+since\s+(.+)\s*$', 'tokens', 'once');
    if isempty(tok) || numel(tok) < 2
        error('Unrecognized time units string: "%s"', unitsStr);
    end

    unit = lower(tok{1});
    ref  = strtrim(tok{2});

    ref = strrep(ref, 'T', ' ');
    ref = regexprep(ref, '\s*(utc|z)\s*$', '', 'ignorecase');

    try
        t0 = datetime(ref, 'InputFormat','yyyy-MM-dd HH:mm:ss');
    catch
        try
            t0 = datetime(ref, 'InputFormat','yyyy-MM-dd HH:mm');
        catch
            t0 = datetime(ref);
        end
    end

    switch unit
        case {'second','seconds','sec','secs','s'}
            dt = t0 + seconds(double(timeVals));
        case {'minute','minutes','min','mins'}
            dt = t0 + minutes(double(timeVals));
        case {'hour','hours','hr','hrs','h'}
            dt = t0 + hours(double(timeVals));
        case {'day','days','d'}
            dt = t0 + days(double(timeVals));
        otherwise
            error('Unsupported time unit in "%s": %s', unitsStr, unit);
    end
end
