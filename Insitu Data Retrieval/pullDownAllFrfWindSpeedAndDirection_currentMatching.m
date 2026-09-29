paths = setupPaths();

load('currents26m_struct');

%% === Step 1: Define fixed hourly time vector (NO SWOT DEPENDENCY)


timeGrid =currents26m.time;
nTimes = numel(timeGrid);

fprintf('→ Building hourly wind time series: %d timestamps\n', nTimes);

%% === Step 2: Retrieve wind for ALL hours (not SWOT times)

loadedOK = false;

if isfile(fullfile(paths.inSitu.lookup, 'wind_hourly_lookup.mat'))
    try
        load(fullfile(paths.inSitu.lookup, 'wind_hourly_lookup.mat'), 'wind_hourly');
        fprintf('✓ Loaded wind hourly lookup — skipping recomputation.\n');
        loadedOK = true;
    catch
        warning('⚠ Failed to load wind hourly lookup. Recomputing...');
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

    wind_hourly = repmat(emptyTemplate, nTimes, 1);

    fprintf('→ Computing hourly wind for %d instruments × %d times...\n', ...
        numel(instrumentList), nTimes);

    if isempty(gcp('nocreate'))
        parpool;
    end

    instrumentResults = cell(numel(instrumentList),1);

    % parfor i = 1:numel(instrumentList)
    for i = 1:numel(instrumentList)

        inst = instrumentList{i};
        fld  = instrumentFields{i};

        localDataSpeed = NaN(nTimes,1);
        localDataDir = NaN(nTimes,1);

        for t = 1:nTimes
            try
                % DIRECT hourly query (no rounding, no SWOT alignment)
                localDataSpeed(t) = getFrfWindData_universal(timeGrid(t), 'windSpeed');
                localDataDir(t) = getFrfWindData_universal(timeGrid(t), 'windDirection');

            catch
                localDataSpeed(t) = NaN;
                localDataDir(t) = NaN;

            end
        end

        instrumentResultsSpeed{i} = localDataSpeed;
        instrumentResultsDir{i} = localDataDir;

    end

    % merge results
    for i = 1:numel(instrumentList)
        fld = instrumentFields{i};
        for t = 1:nTimes
            windSpeed_hourly(t).(fld) = instrumentResultsSpeed{i}(t);
            windDir_hourly(t).(fld) = instrumentResultsDir{i}(t);

        end
    end

    windSpeed_hourly=table2array(struct2table(windSpeed_hourly));
    windDir_hourly=table2array(struct2table(windDir_hourly));


    wind_hourly=struct('time',timeGrid, ...
                        'windSpeed', windSpeed_hourly, ...
                        'windDir', windDir_hourly);

    save(fullfile(paths.inSitu.lookup, 'wind_hourly_lookup.mat'), ...
        'wind_hourly','timeGrid');

    fprintf('✓ Saved hourly wind lookup\n');
end

