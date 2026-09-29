%% Pull down in-situ CURRENT PROFILES (East + North) + TRUE DEPTH PROFILES at SWOT overpass times
% Uses getCurrentProfile_universal and stores profiles as CELLS per time per instrument.
% Includes:
%   (1) QC filtering:
%       - If qcFlag ~= 1 -> whole profile becomes NaN
%       - Bins > maxCell -> NaN (out of water)
%   (2) TRUE PROFILES:
%       - depth vector (NAVD88 elevation of bin centers) pulled ONCE per instrument
%         using getCurrentDepthProfile_universal(inst) from THREDDS NCML
%       - replicated across all times
%   (3) CURRENT MAGNITUDE:
%       - magnitude = sqrt(east.^2 + north.^2) per time/bin/instrument
%       - saved as a separate table

% -----------------------
% Load SWOT structure(s)
% -----------------------
paths = setupPaths();

load('2km_LR_L3_SSH_unsmoothed_Processed.mat')
L3_unsmoothed = dataStruct;

allStructs  = {L3_unsmoothed};
structNames = {'L3_unsmoothed'};

%% === Step 1: Gather and round all SWOT times
allTimes = [];
for s = 1:numel(allStructs)
    fn = fieldnames(allStructs{s});
    tmpTimes = NaT(numel(fn),1);
    for t = 1:numel(fn)
        meanTime    = mean(allStructs{s}.(fn{t}).time);
        tmpTimes(t) = datetime(meanTime, 'ConvertFrom','epochtime', 'Epoch','2000-01-01');
    end
    allTimes = [allTimes; tmpTimes]; %#ok<AGROW>
end

roundedTimes = dateshift(allTimes, 'start', 'minute');
uniqueTimes  = unique(roundedTimes);

fprintf('→ Found %d unique rounded SWOT overpass times across all datasets.\n', numel(uniqueTimes));

%% === Step 2: Retrieve profiles across instruments
instrumentList = {
    'sig940-300'
    'sig940-400'
    'awac-4.5m'
    'sig940-600'
    'awac-11m'
    };

instrumentFields = cellfun(@(s) matlab.lang.makeValidName(s), instrumentList, 'UniformOutput', false);

% Each instrument field stores a PROFILE VECTOR (cell contents)
emptyTemplate = cell2struct(repmat({[]}, 1, numel(instrumentFields)), instrumentFields, 2);

% Lookup file (includes depth)
lookupFile = 'D:\SWOT\Analysis\Wave height estimation\waveVariables\Lookup\currentENZProfileLookup.mat';

% Try load first
loadedOK = false;
if isfile(lookupFile)
    try
        load(lookupFile, 'currentProfileLookup', 'uniqueTimes_saved', 'instrumentList_saved');
        if exist('currentProfileLookup','var') && ...
                isfield(currentProfileLookup,'east') && isfield(currentProfileLookup,'north') && isfield(currentProfileLookup,'depth')
            if isequal(uniqueTimes_saved, uniqueTimes) && isequal(instrumentList_saved, instrumentList)
                fprintf('✓ Loaded currentENZProfileLookup.mat — skipping retrieval.\n');
                loadedOK = true;
            else
                warning('⚠ Saved lookup does not match current uniqueTimes/instrumentList. Recomputing...');
            end
        else
            warning('⚠ Lookup file exists but variables are missing/invalid. Recomputing...');
        end
    catch
        warning('⚠ Failed to load lookup file. Recomputing currentProfileLookup...');
    end
end

if ~loadedOK
    currentProfileLookup.east  = repmat(emptyTemplate, numel(uniqueTimes), 1);
    currentProfileLookup.north = repmat(emptyTemplate, numel(uniqueTimes), 1);
    currentProfileLookup.depth = repmat(emptyTemplate, numel(uniqueTimes), 1);

    fprintf('→ Retrieving CURRENT PROFILES + STATIC DEPTH (QC-filtered) for %d instruments × %d times...\n', ...
        numel(instrumentList), numel(uniqueTimes));

    if isempty(gcp('nocreate'))
        parpool;
    end

    instrumentResultsEast  = cell(numel(instrumentList), 1); % each: N×1 cell
    instrumentResultsNorth = cell(numel(instrumentList), 1);
    instrumentResultsDepth = cell(numel(instrumentList), 1);

    parfor i = 1:numel(instrumentList)
        inst = instrumentList{i};

        localEast  = cell(numel(uniqueTimes), 1);
        localNorth = cell(numel(uniqueTimes), 1);
        localDepth = cell(numel(uniqueTimes), 1);

        try
            % ---- (A) Pull STATIC depth once (no time dimension) ----
            depthVec = getCurrentDepthProfile_universal(inst);

            % Replace fill values (-999) with NaN
            if ~isempty(depthVec) && isnumeric(depthVec)
                depthVec(depthVec == -999) = NaN;
            end

            % ---- (B) Pull time-varying currents + qcFlag + maxCell ----
            out = getCurrentProfile_universal(uniqueTimes, inst, ...
                {'currentEast','currentNorth','qcFlag','maxCell'});

            % Raw profile cells
            if isfield(out,'currentEast')  && iscell(out.currentEast)
                eastRaw = out.currentEast(:);
            else
                eastRaw = localEast;
            end

            if isfield(out,'currentNorth') && iscell(out.currentNorth)
                northRaw = out.currentNorth(:);
            else
                northRaw = localNorth;
            end

            % qcFlag and maxCell per time (scalar per time)
            qcCells = cell(numel(uniqueTimes),1);
            mcCells = cell(numel(uniqueTimes),1);

            if isfield(out,'qcFlag')
                qcCells = normalizeToTimeCells(out.qcFlag, numel(uniqueTimes));
            end
            if isfield(out,'maxCell')
                mcCells = normalizeToTimeCells(out.maxCell, numel(uniqueTimes));
            end

            % ---- (C) Apply QC per time and build depth cell per time ----
            for tt = 1:numel(uniqueTimes)
                qc = qcCells{tt};
                mc = mcCells{tt};

                profE = eastRaw{tt};
                profN = northRaw{tt};

                % currents
                localEast{tt}  = applyProfileQC(profE, qc, mc);
                localNorth{tt} = applyProfileQC(profN, qc, mc);

                % depth: match length to currents, then apply SAME masking
                if ~isempty(depthVec)
                    z = matchVectorLength(depthVec(:), localEast{tt}, localNorth{tt});
                    localDepth{tt} = applyDepthQC(z, qc, mc);
                else
                    localDepth{tt} = [];
                end
            end

        catch ME
            warning('Instrument %s failed: %s', inst, ME.message);
            % keep empties
        end

        instrumentResultsEast{i}  = localEast;
        instrumentResultsNorth{i} = localNorth;
        instrumentResultsDepth{i} = localDepth;
    end

    % Merge into lookup (time-indexed struct array)
    for i = 1:numel(instrumentList)
        fld = instrumentFields{i};
        eCells = instrumentResultsEast{i};
        nCells = instrumentResultsNorth{i};
        zCells = instrumentResultsDepth{i};

        for tt = 1:numel(uniqueTimes)
            currentProfileLookup.east(tt).(fld)  = eCells{tt};
            currentProfileLookup.north(tt).(fld) = nCells{tt};
            currentProfileLookup.depth(tt).(fld) = zCells{tt};
        end
    end

    uniqueTimes_saved    = uniqueTimes;     %#ok<NASGU>
    instrumentList_saved = instrumentList;  %#ok<NASGU>
    save(lookupFile, 'currentProfileLookup', 'uniqueTimes_saved', 'instrumentList_saved');
    fprintf('✓ Saved: %s\n', lookupFile);
end

%% === Step 3: Assign profiles to each SWOT structure time
for s = 1:numel(allStructs)
    dataStruct = allStructs{s};
    fn = fieldnames(dataStruct);
    nT = numel(fn);

    timeVec = NaT(nT,1);

    instrumentCurrentEastProfile_byTime  = repmat(emptyTemplate, nT, 1);
    instrumentCurrentNorthProfile_byTime = repmat(emptyTemplate, nT, 1);
    instrumentCurrentDepthProfile_byTime = repmat(emptyTemplate, nT, 1);

    for t = 1:nT
        meanTime = mean(dataStruct.(fn{t}).time);
        thisTime = datetime(meanTime, 'ConvertFrom','epochtime', 'Epoch','2000-01-01');
        timeVec(t) = thisTime;

        roundedTime = dateshift(thisTime, 'start', 'minute');
        [dt, idx]   = min(abs(uniqueTimes - roundedTime));

        if ~isempty(idx) && minutes(dt) < 30
            for f = 1:numel(instrumentFields)
                fld = instrumentFields{f};
                instrumentCurrentEastProfile_byTime(t).(fld)  = currentProfileLookup.east(idx).(fld);
                instrumentCurrentNorthProfile_byTime(t).(fld) = currentProfileLookup.north(idx).(fld);
                instrumentCurrentDepthProfile_byTime(t).(fld) = currentProfileLookup.depth(idx).(fld);
            end
        end
    end

    assignin('base', ['instrumentCurrentEastProfile_byTime_'  structNames{s}], instrumentCurrentEastProfile_byTime);
    assignin('base', ['instrumentCurrentNorthProfile_byTime_' structNames{s}], instrumentCurrentNorthProfile_byTime);
    assignin('base', ['instrumentCurrentDepthProfile_byTime_' structNames{s}], instrumentCurrentDepthProfile_byTime);
    assignin('base', ['timeVec_' structNames{s}], timeVec);

    fprintf('✓ Assigned %d matched entries for %s.\n', nT, structNames{s});
end

%% === Convert to tables (cell columns)
instrumentCurrentEastProfile_byTime_L3_unsmoothed   = struct2table(instrumentCurrentEastProfile_byTime_L3_unsmoothed);
instrumentCurrentNorthProfile_byTime_L3_unsmoothed  = struct2table(instrumentCurrentNorthProfile_byTime_L3_unsmoothed);
instrumentCurrentDepthProfile_byTime_L3_unsmoothed  = struct2table(instrumentCurrentDepthProfile_byTime_L3_unsmoothed);

%% === NEW: Compute current magnitude profiles as a separate table
instrumentCurrentMagProfile_byTime_L3_unsmoothed = instrumentCurrentEastProfile_byTime_L3_unsmoothed;

for c = 1:width(instrumentCurrentMagProfile_byTime_L3_unsmoothed)
    uCol = instrumentCurrentEastProfile_byTime_L3_unsmoothed{:,c};   % N×1 cell
    vCol = instrumentCurrentNorthProfile_byTime_L3_unsmoothed{:,c};  % N×1 cell

    instrumentCurrentMagProfile_byTime_L3_unsmoothed{:,c} = cellfun( ...
        @(u,v) computeMagProfile(u,v), uCol, vCol, 'UniformOutput', false);
end

%% === Save full output (now includes magnitude table)
outFile = 'D:\SWOT\Analysis\Wave height estimation\waveVariables\Currents\insituCurrents_ENZMag_profiles_relevantInstruments_L3_unsmoothed.mat';
save(outFile, ...
    "instrumentCurrentEastProfile_byTime_L3_unsmoothed", ...
    "instrumentCurrentNorthProfile_byTime_L3_unsmoothed", ...
    "instrumentCurrentDepthProfile_byTime_L3_unsmoothed", ...
    "instrumentCurrentMagProfile_byTime_L3_unsmoothed", ...
    "timeVec_L3_unsmoothed");

fprintf('✓ Saved: %s\n', outFile);
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Local helper functions (script-local)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function profOut = applyProfileQC(profIn, qcFlag, maxCell)
    profOut = profIn;
    if isempty(profIn) || ~isnumeric(profIn), return; end

    wasRow = isrow(profOut);
    profOut = profOut(:);
    nBins = numel(profOut);

    if iscell(qcFlag) && numel(qcFlag) == 1, qcFlag = qcFlag{1}; end
    if ~isempty(qcFlag) && isnumeric(qcFlag) && qcFlag ~= 1
        profOut(:) = NaN;
        if wasRow, profOut = profOut.'; end
        return;
    end

    if iscell(maxCell) && numel(maxCell) == 1, maxCell = maxCell{1}; end
    if ~isempty(maxCell) && isnumeric(maxCell) && isscalar(maxCell) && ~isnan(maxCell)
        profOut((1:nBins)' > maxCell) = NaN;
    end

    if wasRow, profOut = profOut.'; end
end

function zOut = applyDepthQC(zIn, qcFlag, maxCell)
    zOut = zIn;
    if isempty(zIn) || ~isnumeric(zIn), return; end

    wasRow = isrow(zOut);
    zOut = zOut(:);
    nBins = numel(zOut);

    if iscell(qcFlag) && numel(qcFlag) == 1, qcFlag = qcFlag{1}; end
    if ~isempty(qcFlag) && isnumeric(qcFlag) && qcFlag ~= 1
        zOut(:) = NaN;
        if wasRow, zOut = zOut.'; end
        return;
    end

    if iscell(maxCell) && numel(maxCell) == 1, maxCell = maxCell{1}; end
    if ~isempty(maxCell) && isnumeric(maxCell) && isscalar(maxCell) && ~isnan(maxCell)
        zOut((1:nBins)' > maxCell) = NaN;
    end

    if wasRow, zOut = zOut.'; end
end

function z = matchVectorLength(z, profE, profN)
    if isempty(z) || ~isnumeric(z), return; end
    z = z(:);

    nTarget = [];
    if ~isempty(profE) && isnumeric(profE)
        nTarget = numel(profE);
    elseif ~isempty(profN) && isnumeric(profN)
        nTarget = numel(profN);
    else
        return;
    end

    nz = numel(z);
    if nz > nTarget
        z = z(1:nTarget);
    elseif nz < nTarget
        z(end+1:nTarget,1) = NaN;
    end
end

function timeCells = normalizeToTimeCells(x, nTimes)
    timeCells = cell(nTimes,1);
    if isempty(x), return; end

    if isstruct(x)
        if isfield(x,'qcFlag'), x = x.qcFlag;
        elseif isfield(x,'maxCell'), x = x.maxCell;
        else, return;
        end
    end

    if iscell(x)
        x = x(:);
        if numel(x) == nTimes
            timeCells = x;
        elseif numel(x) == 1
            timeCells(:) = x;
        else
            nn = min(numel(x), nTimes);
            timeCells(1:nn) = x(1:nn);
        end
        return;
    end

    if isnumeric(x) || islogical(x)
        if isscalar(x)
            timeCells(:) = {x};
            return;
        end

        if isvector(x) && numel(x) == nTimes
            xv = x(:);
            for i = 1:nTimes
                timeCells{i} = xv(i);
            end
            return;
        end

        if ismatrix(x) && size(x,1) == nTimes
            for i = 1:nTimes
                timeCells{i} = x(i,:).';
            end
            return;
        end
    end
end

function mag = computeMagProfile(u, v)
% Compute magnitude per bin for one time/instrument profile.
% Returns a column vector, or [] if inputs are empty.
% If lengths differ, pads shorter with NaN to match longer.

    if isempty(u) || isempty(v) || ~isnumeric(u) || ~isnumeric(v)
        mag = [];
        return;
    end

    u = u(:);
    v = v(:);

    nu = numel(u);
    nv = numel(v);

    n = max(nu, nv);
    if nu < n, u(end+1:n,1) = NaN; end
    if nv < n, v(end+1:n,1) = NaN; end

    mag = sqrt(u.^2 + v.^2);
end
