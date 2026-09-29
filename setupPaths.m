function paths = setupPaths()
%SETUPPATHS Configure local data paths for the SWOT/FRF analysis.
%
% Edit only paths.root for a new computer. All data, analysis, and output
% paths used by the repository are derived from this directory.
%
% The expected directory structure follows the original analysis layout:
%   <root>/Data/SWOTdata
%   <root>/Data/FRF Hydro data
%   <root>/Analysis/Wave height estimation/waveVariables
%   <root>/Analysis/Paper Analysis/SWH

% -------------------------------------------------------------------------
% USER SETTING
% -------------------------------------------------------------------------
paths.root = 'PATH_TO_YOUR_SWOT_DATA_ROOT';

% -------------------------------------------------------------------------
% DATA ROOTS
% -------------------------------------------------------------------------
paths.data = fullfile(paths.root, 'Data');
paths.swotData = fullfile(paths.data, 'SWOTdata');
paths.frfHydro = fullfile(paths.data, 'FRF Hydro data');
paths.analysis = fullfile(paths.root, 'Analysis');
paths.waveVariables = fullfile(paths.analysis, 'Wave height estimation', 'waveVariables');
paths.paperAnalysis = fullfile(paths.analysis, 'Paper Analysis');
paths.paperSWH = fullfile(paths.paperAnalysis, 'SWH');

% SWOT product directories
paths.swot.l3Expert = fullfile(paths.swotData, 'L3_LR_SSH_Expert');
paths.swot.l2LrExpert = fullfile(paths.swotData, 'frf_raster_LR_L2_250m');
paths.swot.hr100m = fullfile(paths.swotData, 'frf_raster_HR_100m');
paths.swot.pixc = fullfile(paths.swotData, 'frf_PointCloud');
paths.swot.l3Unsmooth = fullfile(paths.swotData, 'L3_LR_SSH_unsmoothed');

% FRF analysis directories
paths.frf.waterLevel = fullfile(paths.frfHydro, 'WaterLevel');
paths.frf.barometer = fullfile(paths.frfHydro, 'Barometer');

% In-situ analysis directories
paths.inSitu.lookup = fullfile(paths.waveVariables, 'Lookup');
paths.inSitu.hs = fullfile(paths.waveVariables, 'Hs');
paths.inSitu.tp = fullfile(paths.waveVariables, 'Tp');
paths.inSitu.direction = fullfile(paths.waveVariables, 'Direction');
paths.inSitu.peakDirection = fullfile(paths.waveVariables, 'PeakDirection');
paths.inSitu.currents = fullfile(paths.waveVariables, 'Currents');
paths.inSitu.wind = fullfile(paths.waveVariables, 'Wind');
paths.inSitu.waterDepth = fullfile(paths.waveVariables, 'WaterDepth');
paths.inSitu.versions = fullfile(paths.waveVariables, 'Versions');

% Static repository data
repoRoot = fileparts(mfilename('fullpath'));
paths.repoRoot = repoRoot;
paths.static = fullfile(repoRoot, 'Helper Functions');

% Create output directories when needed by scripts that generate files.
outputDirs = { ...
    paths.frf.waterLevel, ...
    paths.frf.barometer, ...
    paths.inSitu.lookup, ...
    paths.inSitu.hs, ...
    paths.inSitu.tp, ...
    paths.inSitu.direction, ...
    paths.inSitu.peakDirection, ...
    paths.inSitu.currents, ...
    paths.inSitu.wind, ...
    paths.inSitu.waterDepth, ...
    paths.inSitu.versions, ...
    paths.paperSWH};

for i = 1:numel(outputDirs)
    if ~isfolder(outputDirs{i})
        mkdir(outputDirs{i});
    end
end
end
