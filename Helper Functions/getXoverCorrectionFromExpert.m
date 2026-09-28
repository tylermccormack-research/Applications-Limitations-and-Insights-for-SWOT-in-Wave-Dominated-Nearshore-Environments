function heightCorInterp = getXoverCorrectionFromExpert(inputPath, prefix, dateStr, unsmoothedLat, unsmoothedLon)
% getXoverCorrectionFromExpert
% ---------------------------------------------------------
% Matches UNSMOOTHED 250m file date with Expert file date
% Allows ±1 day offset to handle midnight crossover.
%
% INPUTS:
%   inputPath      = folder with Expert files
%   prefix         = '002_354' etc.
%   dateStr        = 'YYYYMMDD' from unsmoothed file name
%   unsmoothedLat  = latitudes of 250m filtered pixels
%   unsmoothedLon  = longitudes of 250m filtered pixels
%
% OUTPUT:
%   heightCorInterp  = interpolated height_cor_xover
%
% ---------------------------------------------------------

    %% ----------------------------------------------------
    % Construct allowed date strings: date, date-1, date+1
    %% ----------------------------------------------------
    d0 = datetime(dateStr,'InputFormat','yyyyMMdd');
    allowedDates = [
        datetime(d0 - days(1), 'Format','yyyyMMdd')
        datetime(d0,           'Format','yyyyMMdd')
        datetime(d0 + days(1), 'Format','yyyyMMdd')
    ];

    allowedDateStr = cellstr(string(allowedDates,'yyyyMMdd'));

    %% ----------------------------------------
    % Find all Expert files matching prefix
    %% ----------------------------------------
    pattern = fullfile(inputPath, ['SWOT_L2_LR_SSH_Expert_*' prefix '*.nc']);
    expertList = dir(pattern);

    heightCorInterp = nan(size(unsmoothedLat));  % default

    if isempty(expertList)
        warning('No Expert files found for prefix %s', prefix);
        return;
    end

    %% ----------------------------------------
    % Filter Expert files that contain dateStr OR ±1 day
    %% ----------------------------------------
    matched = [];

    for k = 1:length(expertList)
        fname = expertList(k).name;

        % Extract first timestamp in filename (YYYYMMDDThhmmss)
        token = regexp(fname, '(\d{8})T\d{6}_', 'tokens');

        if isempty(token)
            continue;
        end

        fileDate = token{1}{1};  % just YYYYMMDD

        if any(strcmp(fileDate, allowedDateStr))
            matched = [matched; k];
        end
    end

    if isempty(matched)
        warning('No Expert file found within ±1 day of %s', dateStr);
        return;
    end

    % If multiple matches, pick the earliest alphabetically (usually correct)
    expertFile = fullfile(inputPath, expertList(matched(1)).name);
    disp(['  → Matching Expert file: ' expertList(matched(1)).name]);

    %% -----------------------------------------------------
    % Load Expert correction fields
    %% -----------------------------------------------------
    try
        exp_lat  = ncread(expertFile,'latitude');
        exp_lon  = ncread(expertFile,'longitude');
        exp_hcor = ncread(expertFile,'height_cor_xover');
    catch ME
        warning('Could not read Expert file fields: %s', ME.message);
        return;
    end

    % Convert longitude
    exp_lon = rem((exp_lon + 180),360) - 180;

    % Flatten
    exp_lat  = exp_lat(:);
    exp_lon  = exp_lon(:);
    exp_hcor = exp_hcor(:);

    % Mask good values
    good = ~isnan(exp_lat) & ~isnan(exp_lon) & ~isnan(exp_hcor);

    if nnz(good) < 10
        warning('Not enough valid Expert samples for interpolation.');
        return;
    end

    %% -----------------------------------------------------
    % Interpolate height_cor_xover onto unsmoothed pixels
    %% -----------------------------------------------------
    F = scatteredInterpolant(exp_lat(good), exp_lon(good), exp_hcor(good), ...
                             'linear', 'nearest');

    heightCorInterp = F(unsmoothedLat, unsmoothedLon);

end
