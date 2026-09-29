%% download_swot_passes.m
% Downloads SWOT L3 LR SSH Expert NetCDF files for passes 063 and 354
% across all available cycles from the AVISO THREDDS catalog.

paths = setupPaths();

clear; clc;

%% === USER SETTINGS ===
baseCatalogURL = 'https://tds-odatis.aviso.altimetry.fr/thredds/catalog/dataset-l3-swot-karin-nadir-validated/l3_lr_ssh/v2_0_1/Expert/catalog.html';
baseDataURL = 'https://tds-odatis.aviso.altimetry.fr/thredds/fileServer/dataset-l3-swot-karin-nadir-validated/l3_lr_ssh/v2_0_1/Expert';
outputDir = 'D:\SWOT\Data\SWOTdata\L3_LR_SSH_Expert';

targetPasses = {'063', '354'};

% Prompt for credentials (won’t be stored)
username = input('Enter AVISO/ODATIS username: ', 's');
password = input('Enter password: ', 's');

% Create output directory if needed
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

%% === SCRAPE MAIN CATALOG FOR CYCLES ===
fprintf('Fetching cycle list from catalog...\n');
htmlText = webread(baseCatalogURL);
cycleMatches = regexp(htmlText, 'href="(cycle_\d{3})/', 'tokens');
cycleList = unique([cycleMatches{:}]);

% Extract numeric cycle numbers
cycleNums = cellfun(@(c) str2double(regexp(c, '\d{3}', 'match', 'once')), cycleList);

% Keep only cycles < 200
validIdx = cycleNums < 200;
cycleList = cycleList(validIdx);
cycleNums = cycleNums(validIdx);

fprintf('Found %d cycles with number < 200.\n', numel(cycleList));

%% === LOOP OVER EACH CYCLE AND DOWNLOAD FILES ===
for iCycle = 1:numel(cycleList)
    cycleName = cycleList{iCycle};
    cycleNum = cycleNums(iCycle);
    cycleCatalogURL = sprintf('https://tds-odatis.aviso.altimetry.fr/thredds/catalog/dataset-l3-swot-karin-nadir-validated/l3_lr_ssh/v2_0_1/Expert/%s/catalog.html', cycleName);

    fprintf('\n--- Checking %s (Cycle %03d) ---\n', cycleName, cycleNum);

    try
        cycleHTML = webread(cycleCatalogURL);
    catch
        warning('Could not access %s. Skipping.', cycleCatalogURL);
        continue;
    end

    % === FIX: More robust filename extraction ===
    % Matches any link to a SWOT_L3_LR_SSH_Expert file
    ncMatches = regexp(cycleHTML, 'SWOT_L3_LR_SSH_Expert_\d{3}_\d{3}_\d{8}T\d{6}_\d{8}T\d{6}_v2\.0\.1\.nc', 'match');
    ncFiles = unique(ncMatches);

    if isempty(ncFiles)
        fprintf('No .nc files found for %s.\n', cycleName);
        continue;
    end

    % Filter only target passes (e.g., 063 and 354)
    for iPass = 1:numel(targetPasses)
        passStr = targetPasses{iPass};
        passFiles = ncFiles(contains(ncFiles, ['_' passStr '_']));

        if isempty(passFiles)
            continue;
        end

        for iFile = 1:numel(passFiles)
            fileName = passFiles{iFile};
            fileURL = sprintf('%s/%s/%s', baseDataURL, cycleName, fileName);
            localFile = fullfile(outputDir, fileName);

            if isfile(localFile)
                fprintf('Already downloaded: %s\n', fileName);
                continue;
            end

            fprintf('Downloading: %s\n', fileName);

            try
                opts = weboptions('Username', username, 'Password', password, ...
                    'Timeout', 120, 'CertificateFilename', '');
                websave(localFile, fileURL, opts);
                fprintf('Saved: %s\n', localFile);
            catch ME
                warning('Failed to download %s (%s)', fileName, ME.message);
            end
        end
    end
end

fprintf('\n✅ All downloads complete.\n');