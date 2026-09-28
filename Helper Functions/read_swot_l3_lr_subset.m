function S = read_swot_l3_lr_subset(opendapURL, outMatFile)
%READ_SWOT_L3_LR_SUBSET Read a subset of SWOT L3 LR SSH (Unsmoothed) via OPeNDAP
%
% S = read_swot_l3_lr_subset(opendapURL, outMatFile)
%
% Inputs:
%   opendapURL  - OPeNDAP URL to the .nc file (NO constraint string, NO '?')
%   outMatFile  - path to .mat file to save (optional)
%
% Output:
%   S           - struct with requested variables

    if nargin < 2
        outMatFile = '';
    end

    fprintf('Opening OPeNDAP dataset:\n  %s\n', opendapURL);

    % --- Inspect dataset to get sizes ---
    info = ncinfo(opendapURL);

    % Grab dimensions by name (adjust names if needed)
    dimNames = {info.Dimensions.Name};

    % time dimension
    idxTime = strcmp(dimNames, 'time');
    if ~any(idxTime)
        error('Could not find "time" dimension in this file.');
    end
    nTime = info.Dimensions(idxTime).Length;

    % For 2D vars, the second dimension name may be something like 'num_lines'
    % or 'num_cells'. We'll just pick the first non-time dimension.
    otherDims = info.Dimensions(~idxTime);
    if isempty(otherDims)
        error('No non-time dimensions found.');
    end
    nX = otherDims(1).Length;

    fprintf('  Detected dimensions: time = %d, cross-track = %d\n', nTime, nX);

    % --- Read variables explicitly (NO constraint in URL) ---
    S = struct();

    % 1D time
    fprintf('  Reading time...\n');
    S.time = ncread(opendapURL, 'time', [1], [nTime]);

    % 2D variables: [time, x]
    fprintf('  Reading latitude...\n');
    S.latitude = ncread(opendapURL, 'latitude', [1 1], [nTime nX]);

    fprintf('  Reading longitude...\n');
    S.longitude = ncread(opendapURL, 'longitude', [1 1], [nTime nX]);

    fprintf('  Reading quality_flag...\n');
    S.quality_flag = ncread(opendapURL, 'quality_flag', [1 1], [nTime nX]);

    fprintf('  Reading ssha_filtered...\n');
    S.ssha_filtered = ncread(opendapURL, 'ssha_filtered', [1 1], [nTime nX]);

    fprintf('  Reading ugos_filtered...\n');
    S.ugos_filtered = ncread(opendapURL, 'ugos_filtered', [1 1], [nTime nX]);

    fprintf('  Reading vgos_filtered...\n');
    S.vgos_filtered = ncread(opendapURL, 'vgos_filtered', [1 1], [nTime nX]);

    % --- Save if requested ---
    if ~isempty(outMatFile)
        fprintf('  Saving to %s ...\n', outMatFile);
        save(outMatFile, '-struct', 'S', '-v7.3');
        fprintf('  Saved.\n');
    end

    fprintf('Done reading OPeNDAP file.\n');
end
