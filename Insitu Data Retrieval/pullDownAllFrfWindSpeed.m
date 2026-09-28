%% Pull down wave hourly average wave heights from all relevant insitu sensors
% Load all SWOT structures
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
% --- CHECK FOR SAVED LOOKUP FIRST ---
loadedOK = false;

if isfile('D:\SWOT\Analysis\Wave height estimation\waveVariables\Lookup\windSpeedLookup.mat')
    try
        load('D:\SWOT\Analysis\Wave height estimation\waveVariables\Lookup\windSpeedLookup.mat', 'windSpeedLookup');
        fprintf('✓ Loaded windSpeedLookup.mat — skipping Wind Speed retrieval.\n');
        loadedOK = true;
    catch
        warning('⚠ Failed to load windSpeedLookup.mat. Recomputing lookup...');
        loadedOK = false;
    end
end

% Pick your variable (only most relevant listed here)
      % windDirection
      % windSpeed

variable='windSpeed';

if ~loadedOK


% Initialize lookup table with NaNs
windSpeedLookup = NaN(numel(uniqueTimes), 1);

fprintf('→ Starting retrieval of Current Wind for %d times...\n',  numel(uniqueTimes));

for t = 1:numel(uniqueTimes)
    thisTime = uniqueTimes(t);
    try
        localData(t) = getFrfWindData_universal(thisTime, variable);
    catch ME
        fprintf('Error at time %d: %s\n', t, ME.message);
        localData(t) = NaN;
    end
end

% Store back into lookup after parallel section
instrumentResults = double(localData);

for t = 1:numel(uniqueTimes)
    windSpeedLookup(t) = instrumentResults(t);
end

fprintf('✓ Parallel Wind Speed retrieval complete.\n');
    save('D:\SWOT\Analysis\Wave height estimation\waveVariables\Lookup\windSpeedLookup.mat', 'windSpeedLookup');
    fprintf('✓ Saved windSpeedLookup.mat\n');
end

%% === Step 3: Assign to each SWOT structure
for s = 1:numel(allStructs)
    dataStruct = allStructs{s};
    fn = fieldnames(dataStruct);
    nT = numel(fn);
    timeVec = NaT(nT,1);

    % Preallocate consistent struct array
    instrumentWindSpeed_byTime = repmat( NaN, nT, 1);

    for t = 1:nT
        meanTime = mean(dataStruct.(fn{t}).time);
        thisTime = datetime(meanTime, 'ConvertFrom', 'epochtime', 'Epoch', '2000-01-01');
        timeVec(t) = thisTime;

        % Find closest rounded cluster (tolerance ±30 minutes)
        roundedTime = dateshift(thisTime, 'start', 'minute');
        [dt, idx] = min(abs(uniqueTimes - roundedTime));

        if ~isempty(idx) && minutes(dt) < 30
            % Assign all fields directly
                instrumentWindSpeed_byTime(t) = windSpeedLookup(idx);
            
        end
    end

    % Push results to base workspace
    assignin('base', ['instrumentWindSpeed_byTime_' structNames{s}], instrumentWindSpeed_byTime);
    assignin('base', ['timeVec_' structNames{s}], timeVec);

    fprintf('✓ Assigned %d matched entries for %s.\n', nT, structNames{s});
end

%% Save full output
save('D:\SWOT\Analysis\Wave height estimation\waveVariables\Wind\insituWindSpeeds_relevantInstrumentsAllProducts.mat',"instrumentWindSpeed_byTime_L3_2km", "instrumentWindSpeed_byTime_LR2km", "instrumentWindSpeed_byTime_HR100m", "instrumentWindSpeed_byTime_HRpixc")
