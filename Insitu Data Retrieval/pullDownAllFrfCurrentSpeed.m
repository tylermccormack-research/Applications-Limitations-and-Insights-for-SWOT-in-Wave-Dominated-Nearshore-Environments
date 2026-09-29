%% Pull down wave hourly average wave heights from all relevant insitu sensors
% Load all SWOT structures
paths = setupPaths();

load('2km_LR_L3_SSH_expert_Processed.mat');          % LR 250m
L3_2km = dataStruct;
load('250m_LR_L2_SSH_expert_Processed.mat'); % LR 2km
LR2km = dataStruct;
load('100m_Processed.mat');                  % HR 100m
HR100m = dataStruct;
load('pixelCloud_Processed_bigArea.mat');            % HR Pixel cloud
HRpixc = dataStruct;

allStructs = {L3_2km, LR2km, HR100m, HRpixc};
structNames = {'L3_2km', 'LR2km', 'HR100m', 'HRpixc'};

%% === Step 1: Gather and round all SWOT times
allTimes = [];
for s = 1:numel(allStructs)
    fn = fieldnames(allStructs{s});
    tmpTimes = NaT(numel(fn),1);
    for t = 1:numel(fn)
        meanTime = mean(allStructs{s}.(fn{t}).time);
        tmpTimes(t) = datetime(meanTime, 'ConvertFrom', 'epochtime', 'Epoch', '2000-01-01');
    end
    allTimes = [allTimes; tmpTimes];
end

% Round to nearest minute (adjust tolerance here)
roundedTimes = dateshift(allTimes, 'start', 'minute');
uniqueTimes = unique(roundedTimes);

fprintf('→ Found %d unique rounded SWOT overpass times across all datasets.\n', numel(uniqueTimes));

%% === Step 2: Parallel retrieval across instruments
% --- CHECK FOR SAVED currentSpeedLookup FIRST ---
loadedOK = false;

if isfile(fullfile(paths.inSitu.lookup, 'currentSpeedLookup.mat'))
    try
        load(fullfile(paths.inSitu.lookup, 'currentSpeedLookup.mat'), 'currentSpeedLookup');
        fprintf('✓ Loaded currentSpeedLookup.mat — skipping Current Speed retrieval.\n');
        loadedOK = true;
    catch
        warning('⚠ Failed to load currentSpeedLookup.mat. Recomputing currentSpeedLookup...');
        loadedOK = false;
    end
end

% Pick your variable (only most relevant listed here)
% time
% depth
% blankDist
% maxCell
% currentSpeed
% currentDirection
% currentEast
% currentNorth
% qcFlag

variable='currentSpeed';

instrumentList = {
    'sig940-300',
    'sig940-400',
    'awac-4.5m',
    'sig940-600',
    'awac-11m'
    };
instrumentFields = cellfun(@(s) matlab.lang.makeValidName(s), instrumentList, 'UniformOutput', false);

% Initialize currentSpeedLookup table with NaNs
emptyTemplate = cell2struct(num2cell(NaN(1,numel(instrumentFields))), instrumentFields, 2);

if ~loadedOK

    currentSpeedLookup = repmat(emptyTemplate, numel(uniqueTimes), 1);

    fprintf('→ Starting parallel retrieval of Current Speed for %d instruments × %d times...\n', numel(instrumentList), numel(uniqueTimes));

    % Start parallel pool if not already active
    if isempty(gcp('nocreate'))
        parpool; % uses default cluster
    end

    % Each instrument runs independently in parallel
    for i = 1:numel(instrumentList)
        inst = instrumentList{i};
        fld = instrumentFields{i};
        localData = NaN(numel(uniqueTimes), 1);

        for t = 1:numel(uniqueTimes)
            thisTime = uniqueTimes(t);
            try
                localData(t) = getFrfCurrentData_universal(thisTime, inst, variable);
            catch ME
                fprintf('Error at time %d: %s\n', t, ME.message);
                localData(t) = NaN;
            end
        end

        % Store back into currentSpeedLookup after parallel section
        instrumentResults{i} = localData;
    end

    % Merge instrument results into unified struct
    for i = 1:numel(instrumentList)
        fld = instrumentFields{i};
        for t = 1:numel(uniqueTimes)
            currentSpeedLookup(t).(fld) = instrumentResults{i}(t);
        end
    end

    fprintf('✓ Parallel Current speed retrieval complete.\n');
    save(fullfile(paths.inSitu.lookup, 'currentSpeedLookup.mat'), 'currentSpeedLookup');
    fprintf('✓ Saved currentSpeedLookup.mat\n');
end

%% === Step 3: Assign to each SWOT structure
for s = 1:numel(allStructs)
    dataStruct = allStructs{s};
    fn = fieldnames(dataStruct);
    nT = numel(fn);
    timeVec = NaT(nT,1);

    % Preallocate consistent struct array
    instrumentCurrentSpeed_byTime = repmat(emptyTemplate, nT, 1);

    for t = 1:nT
        meanTime = mean(dataStruct.(fn{t}).time);
        thisTime = datetime(meanTime, 'ConvertFrom', 'epochtime', 'Epoch', '2000-01-01');
        timeVec(t) = thisTime;

        % Find closest rounded cluster (tolerance ±30 minutes)
        roundedTime = dateshift(thisTime, 'start', 'minute');
        [dt, idx] = min(abs(uniqueTimes - roundedTime));

        if ~isempty(idx) && minutes(dt) < 30
            % Assign all fields directly
            for f = 1:numel(instrumentFields)
                fld = instrumentFields{f};
                instrumentCurrentSpeed_byTime(t).(fld) = currentSpeedLookup(idx).(fld);
            end
        end
    end

    % Push results to base workspace
    assignin('base', ['instrumentCurrentSpeed_byTime_' structNames{s}], instrumentCurrentSpeed_byTime);
    assignin('base', ['timeVec_' structNames{s}], timeVec);

    fprintf('✓ Assigned %d matched entries for %s.\n', nT, structNames{s});
end

%% Convert to tables
instrumentCurrentSpeed_byTime_L3_2km=struct2table(instrumentCurrentSpeed_byTime_L3_2km);
instrumentCurrentSpeed_byTime_LR2km=struct2table(instrumentCurrentSpeed_byTime_LR2km);
instrumentCurrentSpeed_byTime_HR100m=struct2table(instrumentCurrentSpeed_byTime_HR100m);
instrumentCurrentSpeed_byTime_HRpixc=struct2table(instrumentCurrentSpeed_byTime_HRpixc);

%% Save full output
save(fullfile(paths.inSitu.currents, 'insituCurrentSpeeds_relevantInstrumentsAllProducts.mat'),"instrumentCurrentSpeed_byTime_L3_2km", "instrumentCurrentSpeed_byTime_LR2km", "instrumentCurrentSpeed_byTime_HR100m", "instrumentCurrentSpeed_byTime_HRpixc")
