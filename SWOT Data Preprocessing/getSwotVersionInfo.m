function [fileNames, versionType, versionFlag] = getSwotVersionInfo(dataDir, timeArray)
% GETSWOTVERSIONINFO  Determine if SWOT LR files are Version C or D and
% match file timestamps to a datetime array WITH ±2 hour tolerance.
%
%   [fileNames, versionType, versionFlag] = getSwotVersionInfo(dataDir, timeArray)
%
%   Inputs:
%       dataDir   - Directory containing SWOT LR files
%       timeArray - Datetime array of target times
%
%   Outputs:
%       fileNames   - Cell array of matched filenames
%       versionType - {'C','D','Unknown'}
%       versionFlag - Logical array: false = C, true = D
%

    % Ensure valid input
    if ~isdatetime(timeArray)
        error('timeArray must be a datetime array.');
    end

    % Define tolerance
    toleranceHours = hours(2);

    % List directory files
    fileList = dir(fullfile(dataDir, '*.*'));
    N = numel(fileList);

    % Preallocate
    fileNames   = cell(N,1);
    versionType = cell(N,1);
    versionFlag = false(N,1);  % logical

    idx = 0;

    for k = 1:N
        fname = fileList(k).name;

        % Skip directories
        if fileList(k).isdir
            continue
        end

        % Only process files ending in _01.nc, _02.nc, _03.nc
        tokenIdx = regexp(fname, '_0[1-3].nc$', 'start');
        if isempty(tokenIdx)
            continue
        end

        % Extract the timestamp(s): yyyyMMddTHHmmss
        dateTokens = regexp(fname, '(\d{8}T\d{6})', 'match');
        if isempty(dateTokens)
            continue
        end

        % Convert the first timestamp to a datetime
        fileTime = datetime(dateTokens{1}, 'InputFormat','yyyyMMdd''T''HHmmss');

        % Check if fileTime is within ±2 hours of ANY input time
        timeDiff = abs(fileTime - timeArray);
        if all(timeDiff > toleranceHours)
            continue  % skip: not within ±2 hours of any provided time
        end

        % ===== Extract version information (C/D) =====
        prefix = fname(1:tokenIdx-1);
        last4 = prefix(max(end-3,1):end);

        idx = idx + 1;
        fileNames{idx} = fname;

        if contains(last4, 'C', 'IgnoreCase', true)
            versionType{idx} = 'C';
            versionFlag(idx) = false;  % logical

        elseif contains(last4, 'D', 'IgnoreCase', true)
            versionType{idx} = 'D';
            versionFlag(idx) = true;   % logical

        else
            versionType{idx} = 'Unknown';
            versionFlag(idx) = false;  % default to false for Unknown
        end
    end

    % Trim unused rows
    fileNames   = fileNames(1:idx);
    versionType = versionType(1:idx);
    versionFlag = versionFlag(1:idx);
end
