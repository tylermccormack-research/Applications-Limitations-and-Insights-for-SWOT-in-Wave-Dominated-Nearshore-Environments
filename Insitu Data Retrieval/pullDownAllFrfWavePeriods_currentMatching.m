paths = setupPaths();

load('currents26m_struct');

%% === Step 1: Define fixed hourly time vector (NO SWOT DEPENDENCY)


timeGrid =currents26m.time;
nTimes = numel(timeGrid);

fprintf('→ Building hourly Tp time series: %d timestamps\n', nTimes);

%% === Step 2: Retrieve Tp for ALL hours (not SWOT times)

loadedOK = false;

if isfile(fullfile(paths.inSitu.lookup, 'Tp_hourly_lookup.mat'))
    try
        load(fullfile(paths.inSitu.lookup, 'Tp_hourly_lookup.mat'), 'Tp_hourly');
        fprintf('✓ Loaded Tp hourly lookup — skipping recomputation.\n');
        loadedOK = true;
    catch
        warning('⚠ Failed to load Tp hourly lookup. Recomputing...');
        loadedOK = false;
    end
end

instrumentList = {
    % 'paros940-200',
    % 'paros940-250',
    % 'sig940-300',
    % 'xp340m',
    % 'awac-4.5m',
    % 'sig940-600',
    % '8m-array',
    % 'waverider-17m',
    'waverider-26m'
};

instrumentFields = cellfun(@matlab.lang.makeValidName, instrumentList, 'UniformOutput', false);

emptyTemplate = cell2struct(num2cell(NaN(1,numel(instrumentFields))), instrumentFields, 2);

if ~loadedOK

    Tp_hourly = repmat(emptyTemplate, nTimes, 1);

    fprintf('→ Computing hourly Tp for %d instruments × %d times...\n', ...
        numel(instrumentList), nTimes);

    if isempty(gcp('nocreate'))
        parpool;
    end

    instrumentResults = cell(numel(instrumentList),1);

    parfor i = 1:numel(instrumentList)

        inst = instrumentList{i};
        fld  = instrumentFields{i};

        localData = NaN(nTimes,1);

        for t = 1:nTimes
            try
                % DIRECT hourly query (no rounding, no SWOT alignment)
                localData(t) = getFrfWavePeakPeriod_universal(timeGrid(t), inst);
            catch
                localData(t) = NaN;
            end
        end

        instrumentResults{i} = localData;
    end

    % merge results
    for i = 1:numel(instrumentList)
        fld = instrumentFields{i};
        for t = 1:nTimes
            Tp_hourly(t).(fld) = instrumentResults{i}(t);
        end
    end

    Tp_hourly=table2array(struct2table(Tp_hourly));

    Tp_hourly=struct('time',timeGrid, ...
                        'Tp', Tp_hourly);

    save(fullfile(paths.inSitu.lookup, 'Tp_hourly_lookup.mat'), ...
        'Tp_hourly','timeGrid');

    fprintf('✓ Saved hourly Tp lookup\n');
end

