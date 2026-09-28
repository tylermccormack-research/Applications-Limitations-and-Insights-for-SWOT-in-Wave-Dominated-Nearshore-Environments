%% Pull down wave hourly average wave heights from all relevant insitu sensors
% Load all SWOT structures
% load('2km_LR_L3_SSH_expert_Processed.mat');          % LR 250m
% L3_2km = dataStruct;
% load('250m_LR_L2_SSH_expert_Processed.mat'); % LR 2km
% LR2km = dataStruct;
% load('100m_Processed.mat');                  % HR 100m
% HR100m = dataStruct;
% load('pixelCloud_Processed_bigArea.mat');            % HR Pixel cloud
% HRpixc = dataStruct;

load("2km_LR_L3_SSH_unsmoothed_Processed.mat");                                % SWOT dataStruct
L3_250m=dataStruct;

allStructs = {L3_250m};%, LR2km, HR100m, HRpixc};
structNames = {'L3_250m'};%, 'LR2km', 'HR100m', 'HRpixc'};

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
% --- CHECK FOR SAVED LOOKUP FIRST ---
loadedOK = false;

if isfile('D:\SWOT\Analysis\Wave height estimation\waveVariables\CurrentMeterMeanPressure\currentMeterMeanPressureLookup.mat')
    try
        load('D:\SWOT\Analysis\Wave height estimation\waveVariables\Lookup\currentMeterMeanPressureLookup.mat', 'currentMeterMeanPressureLookup');
        fprintf('✓ Loaded currentMeterMeanPressureLookup.mat — skipping Current Meter Mean Pressure retrieval.\n');
        loadedOK = true;
    catch
        warning('⚠ Failed to load currentMeterMeanPressureLookup.mat. Recomputing lookup...');
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

variable='meanPressure';

instrumentList = {
    'sig940-300',
    'sig940-400',
    'awac-4.5m',
    'sig940-600',
    'awac-11m'
    };
instrumentFields = cellfun(@(s) matlab.lang.makeValidName(s), instrumentList, 'UniformOutput', false);

% Initialize lookup table with NaNs
emptyTemplate = cell2struct(num2cell(NaN(1,numel(instrumentFields))), instrumentFields, 2);

if ~loadedOK

    currentDirectionLookup= repmat(emptyTemplate, numel(uniqueTimes), 1);

    fprintf('→ Starting parallel retrieval of Current Meter Mean Pressure for %d instruments × %d times...\n', numel(instrumentList), numel(uniqueTimes));

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

        % Store back into lookup after parallel section
        instrumentResults{i} = localData;
    end

    % Merge instrument results into unified struct
    for i = 1:numel(instrumentList)
        fld = instrumentFields{i};
        for t = 1:numel(uniqueTimes)
            currentMeterMeanPressureLookup(t).(fld) = instrumentResults{i}(t);
        end
    end

    fprintf('✓ Parallel Current Meter Mean Pressure retrieval complete.\n');
    save('D:\SWOT\Analysis\Wave height estimation\waveVariables\Lookup\currentMeterMeanPressureLookup.mat', 'currentMeterMeanPressureLookup');
    fprintf('✓ Saved currentMeterMeanPressureLookup.mat\n');
end

%% === Step 3: Assign to each SWOT structure
for s = 1:numel(allStructs)
    dataStruct = allStructs{s};
    fn = fieldnames(dataStruct);
    nT = numel(fn);
    timeVec = NaT(nT,1);

    % Preallocate consistent struct array
    instrumentCurrentMeterMeanPressure_byTime = repmat(emptyTemplate, nT, 1);

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
                instrumentCurrentMeterMeanPressure_byTime(t).(fld) = currentMeterMeanPressureLookup(idx).(fld);
            end
        end
    end

    % Push results to base workspace
    assignin('base', ['instrumentCurrentMeterMeanPressure_byTime_' structNames{s}], instrumentCurrentMeterMeanPressure_byTime);
    assignin('base', ['timeVec_' structNames{s}], timeVec);

    fprintf('✓ Assigned %d matched entries for %s.\n', nT, structNames{s});
end

%% Convert to tables
% instrumentCurrentDirection_byTime_L3_2km=struct2table(instrumentCurrentDirection_byTime_L3_2km);
% instrumentCurrentDirection_byTime_LR2km=struct2table(instrumentCurrentDirection_byTime_LR2km);
% instrumentCurrentDirection_byTime_HR100m=struct2table(instrumentCurrentDirection_byTime_HR100m);
% instrumentCurrentDirection_byTime_HRpixc=struct2table(instrumentCurrentDirection_byTime_HRpixc);

instrumentCurrentMeterMeanPressure_byTime_L3_250m=struct2table(instrumentCurrentMeterMeanPressure_byTime_L3_250m);


%% Save full output
save('D:\SWOT\Analysis\Wave height estimation\waveVariables\Currents\insituCurrentMeterMeanPressure_relevantInstrumentsAllProducts.mat',"instrumentCurrentMeterMeanPressure_byTime_L3_250m")
