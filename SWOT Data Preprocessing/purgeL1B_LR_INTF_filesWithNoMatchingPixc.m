% Define your folder paths
folderA = 'D:\SWOT\Data\SWOTdata\frf_PointCloud\SWOT_L2_HR_PIXC_2.0_2.0-20241217_171252'; % Update this
folderB = 'D:\SWOT\Data\SWOTdata\L1B_LR_INTF';       % Update this

% Get file listings
filesA = dir(fullfile(folderA, '*'));
filesB = dir(fullfile(folderB, '*'));

% Extract all valid dates from Folder A filenames
datesA = [];
for i = 1:length(filesA)
    fname = filesA(i).name;
    % Match the first timestamp like: 20230802T202942
    match = regexp(fname, '(\d{8})T\d{6}', 'tokens');
    if ~isempty(match)
        datesA(end+1) = str2double(match{1}{1});
    end
end

% Keep only unique dates
datesA = unique(datesA);

% Now check Folder B files for matching dates
for i = 1:length(filesB)
    fname = filesB(i).name;
    fpath = fullfile(folderB, fname);
    
    % Match the first timestamp like: 20230802T201432
    match = regexp(fname, '(\d{8})T\d{6}', 'tokens');
    if isempty(match)
        warning('No valid date found in: %s', fname);
        continue;
    end
    
    dateB = str2double(match{1}{1});
    
    if ~ismember(dateB, datesA)
        fprintf('Deleting %s (no matching date in Folder A)\n', fname);
        delete(fpath); % ⚠️ This deletes the file
    end
end

%% Test script that just prints names of files that will be deleted
% Define your folder paths
folderA = 'D:\SWOT\Data\SWOTdata\frf_PointCloud\SWOT_L2_HR_PIXC_2.0_2.0-20241217_171252'; % Pixel cloud folder
folderB = 'D:\SWOT\Data\SWOTdata\L1B_LR_INTF';  % INTF folder

% Get file listings
filesA = dir(fullfile(folderA, '*'));
filesB = dir(fullfile(folderB, '*'));

% Extract all valid dates from Folder A filenames
datesA = [];
for i = 1:length(filesA)
    fname = filesA(i).name;
    match = regexp(fname, '(\d{8})T\d{6}', 'tokens');
    if ~isempty(match)
        datesA(end+1) = str2double(match{1}{1});
    end
end

% Keep only unique dates
datesA = unique(datesA);

% Check Folder B files and report unmatched ones
fprintf('=== TEST RUN: Files that would be deleted from Folder B ===\n');
for i = 1:length(filesB)
    fname = filesB(i).name;
    fpath = fullfile(folderB, fname);
    
    % Match the first timestamp like: 20230802T201432
    match = regexp(fname, '(\d{8})T\d{6}', 'tokens');
    if isempty(match)
        warning('No valid date found in: %s', fname);
        continue;
    end
    
    dateB = str2double(match{1}{1});
    
    if ~ismember(dateB, datesA)
        fprintf('Would delete: %s\n', fname);
    end
end
