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
% --- CHECK FOR SAVED LOOKUP FIRST ---
loadedOK = false;

if isfile(fullfile(paths.inSitu.lookup, 'waveDir_lookup.mat'))
    try
        load(fullfile(paths.inSitu.lookup, 'waveDir_lookup.mat'), 'waveDir_lookup');
        fprintf('✓ Loaded waveDir_lookup.mat — skipping Wave Direction retrieval.\n');
        loadedOK = true;
    catch
        warning('⚠ Failed to load waveDir_lookup.mat. Recomputing lookup...');
        loadedOK = false;
    end
end

instrumentList = {
    'paros940-200',
    'paros940-250',
    'sig940-300',
    'xp340m',
    'awac-4.5m',
    'sig940-600',
    '8m-array',
    'waverider-17m',
    'waverider-26m'
    };
instrumentFields = cellfun(@(s) matlab.lang.makeValidName(s), instrumentList, 'UniformOutput', false);

% Initialize lookup table with NaNs
emptyTemplate = cell2struct(num2cell(NaN(1,numel(instrumentFields))), instrumentFields, 2);

if ~loadedOK

    waveDir_lookup = repmat(emptyTemplate, numel(uniqueTimes), 1);

    fprintf('→ Starting parallel retrieval of Wave Direction for %d instruments × %d times...\n', numel(instrumentList), numel(uniqueTimes));

    % Start parallel pool if not already active
    if isempty(gcp('nocreate'))
        parpool; % uses default cluster
    end

    % Each instrument runs independently in parallel
    parfor i = 1:numel(instrumentList)
        inst = instrumentList{i};
        fld = instrumentFields{i};
        localData = NaN(numel(uniqueTimes), 1);

        for t = 1:numel(uniqueTimes)
            thisTime = uniqueTimes(t);
            try
                % localData(t) = getFrfWaveMeanDirection_universal(thisTime, inst); % Mean Direction
                localData(t) = getFrfWavePeakDirection_universal(thisTime, inst); % Peak Direction

            catch
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
            waveDir_lookup(t).(fld) = instrumentResults{i}(t);
        end
    end

    fprintf('✓ Parallel Wave Direction retrieval complete.\n');
    save(fullfile(paths.inSitu.lookup, 'waveDir_lookup.mat'), 'waveDir_lookup');
    fprintf('✓ Saved waveDir_lookup.mat\n');
end

%% === Step 3: Assign to each SWOT structure
for s = 1:numel(allStructs)
    dataStruct = allStructs{s};
    fn = fieldnames(dataStruct);
    nT = numel(fn);
    timeVec = NaT(nT,1);

    % Preallocate consistent struct array
    instrumentWavePeakDir_byTime = repmat(emptyTemplate, nT, 1);

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
                instrumentWavePeakDir_byTime(t).(fld) = waveDir_lookup(idx).(fld);
            end
        end
    end

    % Push results to base workspace
    assignin('base', ['instrumentWavePeakDir_byTime_' structNames{s}], instrumentWavePeakDir_byTime);
    assignin('base', ['timeVec_' structNames{s}], timeVec);

    fprintf('✓ Assigned %d matched entries for %s.\n', nT, structNames{s});
end

%% Convert to tables
instrumentWavePeakDir_byTime_L3_2km=struct2table(instrumentWavePeakDir_byTime_L3_2km);
instrumentWavePeakDir_byTime_LR2km=struct2table(instrumentWavePeakDir_byTime_LR2km);
instrumentWavePeakDir_byTime_HR100m=struct2table(instrumentWavePeakDir_byTime_HR100m);
instrumentWavePeakDir_byTime_HRpixc=struct2table(instrumentWavePeakDir_byTime_HRpixc);

%% === Replace -999 with NaN in all tables ===
waveDirTables = {
    'instrumentWavePeakDir_byTime_L3_2km'
    'instrumentWavePeakDir_byTime_LR2km'
    'instrumentWavePeakDir_byTime_HR100m'
    'instrumentWavePeakDir_byTime_HRpixc'
};

for k = 1:numel(waveDirTables)
    Tname = waveDirTables{k};
    T = eval(Tname);   % retrieve table

    % Replace all -999 values in numeric columns
    numericVars = varfun(@isnumeric, T, 'OutputFormat','uniform');
    T{:, numericVars} = arrayfun(@(x) replaceNeg999(x), T{:, numericVars});

    % Assign back to workspace
    assignin('base', Tname, T);
end

function out = replaceNeg999(x)
    out = x;
    out(out == -999) = NaN;
end

%% Save full output
save(fullfile(paths.inSitu.peakDirection, 'insituWavePeakDir_relevantInstrumentsAllProducts.mat'),"instrumentWavePeakDir_byTime_L3_2km", "instrumentWavePeakDir_byTime_LR2km", "instrumentWavePeakDir_byTime_HR100m", "instrumentWavePeakDir_byTime_HRpixc")

%% Save Time vecs
% save('D:\SWOT\Analysis\Wave height estimation\waveVariables\insituTimeVec_swotMatches_allProducts.mat',"timeVec_LR250m", "timeVec_LR2km", "timeVec_HR100m", "timeVec_HRpixc")

%% Instrument Names
% load('instrumentNames.mat');
% instrumentNames(1:5)=[];
% instrumentNamesSWH_new=instrumentNames;
% save(fullfile(paths.inSitu.hs, 'instrumentNamesSWH_new.mat'),"instrumentNames")
