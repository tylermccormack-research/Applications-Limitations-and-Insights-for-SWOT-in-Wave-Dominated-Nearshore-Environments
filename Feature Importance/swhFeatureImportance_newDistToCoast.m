%% =========================================================
%  SWOT SWH Error Drivers: Random Forest + PD Plots
%  - DistToCoast from SWOT pixel FRF_X used for SWH comparison
%  - Includes wavelength L and waveSteepness
%  - Part 1: All instruments together
%  - Part 2: Separate RF per instrument
% =========================================================
paths = setupPaths();

clear; clc;

%% =========================================================
%  Load pre-processed data
% =========================================================
load(fullfile(paths.paperSWH, 'swhAccuracyAnalysis.mat'));   % should contain:
%   SWH_swot_all, instrumentNames, instrumentLabels, dist_all,
%   instrumentSWH_byTime_LR2km, instrumentTp_byTime_LR2km,
%   instrumentWavePeakDir_byTime_LR2km, instrumentWaveMeanDir_byTime_LR2km,
%   instrumentWaterDepth_byTime_LR2km,
%   instrumentCurrentSpeed_byTime_LR2km,
%   instrumentCurrentDirection_byTime_LR2km,
%   instrumentWindSpeed_byTime_LR2km,
%   instrumentWindDirection_byTime_LR2km,
%   versionFlag_LR2km, idx063_LR2km, idx354_LR2km, etc.

% Make sure LR2km is available (for FRF_X and SWH indices).
if ~exist('LR2km','var')
    load(fullfile(paths.swot.l2LrExpert, '250m_LR_L2_SSH_expert_Processed.mat')); % contains dataStruct
    LR2km = dataStruct;
    clear dataStruct;
end

g = 9.81;

%% =========================================================
%  Compute Distance to Coast (FRF_X relative to x=0) per instrument
%  (using the SWOT pixel actually used for SWH comparison)
% =========================================================
fieldNames = fieldnames(LR2km);
numPasses  = numel(fieldNames);

% Preallocate distance-to-coast arrays (one per instrument)
distCoast26m   = nan(numPasses,1);
distCoast17m   = nan(numPasses,1);
distCoast900m  = nan(numPasses,1);
distCoast600m  = nan(numPasses,1);

for t = 1:numPasses
    fn    = fieldNames{t};
    FRF_X = LR2km.(fn).FRF_X;    % cross-shore coordinate (shoreline at x=0)

    % ---- 26 m buoy ----
    idx = LR2km.(fn).SWH_Index26mBuoy;
    distCoast26m(t,1) = abs(FRF_X(idx));   % distance to x=0 shoreline

    % ---- 17 m buoy ----
    idx = LR2km.(fn).SWH_Index17mBuoy;
    distCoast17m(t,1) = abs(FRF_X(idx));

    % ---- 900 m sensor (8 m array) ----
    idx = LR2km.(fn).SWH_Index900mSensor;
    distCoast900m(t,1) = abs(FRF_X(idx));

    % ---- 600 m Signature ----
    idx = LR2km.(fn).SWH_Index600mSensor;
    distCoast600m(t,1) = abs(FRF_X(idx));
end

% Package distance-to-coast in same instrument order as SWH_swot_all
% instrumentNames should be:
% {'waverider_26m','waverider_17m','x8m_array','sig940_600'}
distCoast_all = { ...
    distCoast26m, ...
    distCoast17m, ...
    distCoast900m, ...
    distCoast600m};

%% =========================================================
%  Helper: wavelength with regime logic
% =========================================================
T2L_regime = @(Tp, h) computeWavelength_regime(Tp, h);

%% =========================================================
%  PART 1: Build combined table (all instruments together)
% =========================================================
all_error          = [];
all_SWH_insitu     = [];
all_SWH_swot       = [];
all_instrumentID   = [];
all_Dist           = [];
all_DistCoast      = [];
all_Depth          = [];
all_Tp             = [];
all_PeakDir        = [];
all_MeanDir        = [];
all_CurrentSpeed   = [];
all_CurrentDir     = [];
all_WindSpeed      = [];
all_WindDir        = [];
all_VersionFlag    = [];
all_L              = [];
all_waveSteepness  = [];

% Global (pass-based) predictors (same for all instruments)
cSpd = instrumentCurrentSpeed_byTime_LR2km.sig940_600(:);      % [m/s]
cDir = instrumentCurrentDirection_byTime_LR2km.sig940_600(:);  % [deg]
wSpd = instrumentWindSpeed_byTime_LR2km(:);                    % [m/s]
wDir = instrumentWindDirection_byTime_LR2km(:);                % [deg]
vFlg = versionFlag_LR2km(:);                                   % logical / version flag

nInstr = numel(instrumentNames);

for ii = 1:nInstr

    instName = instrumentNames{ii};

    % ------- In-situ & SWOT SWH for this instrument -------
    SWH_insitu = instrumentSWH_byTime_LR2km.(instName)(:);
    SWH_swot   = SWH_swot_all{ii}(:);
    Dist       = dist_all{ii}(:);
    DistCoast  = distCoast_all{ii}(:);

    % ------- Env. fields for this instrument -------
    Tp       = instrumentTp_byTime_LR2km.(instName)(:);
    PeakDir  = instrumentWavePeakDir_byTime_LR2km.(instName)(:);
    MeanDir  = instrumentWaveMeanDir_byTime_LR2km.(instName)(:);
    Depth    = instrumentWaterDepth_byTime_LR2km.(instName)(:);   % [m]

    % ------- Wavelength & steepness for this instrument -------
    L_i = T2L_regime(Tp, Depth);          % wavelength [m]
    L_i(L_i <= 0) = NaN;                  % guard
    waveSteep_i = SWH_insitu ./ L_i;      % steepness Hs / L
    waveSteep_i(~isfinite(waveSteep_i)) = NaN;

    % ------- Error (absolute) -------
    SWH_err = abs(SWH_swot - SWH_insitu);

    % Valid samples: everything needed must be finite
    valid = isfinite(SWH_err) & isfinite(SWH_insitu) & ...
            isfinite(SWH_swot) & isfinite(Dist) & isfinite(DistCoast) & ...
            isfinite(Depth) & isfinite(Tp)   & ...
            isfinite(PeakDir) & isfinite(MeanDir) & ...
            isfinite(cSpd) & isfinite(cDir) & ...
            isfinite(wSpd) & isfinite(wDir) & ...
            isfinite(vFlg) & isfinite(L_i)  & ...
            isfinite(waveSteep_i);

    % Stack
    all_error          = [all_error;          SWH_err(valid)];
    all_SWH_insitu     = [all_SWH_insitu;     SWH_insitu(valid)];
    all_SWH_swot       = [all_SWH_swot;       SWH_swot(valid)];
    all_instrumentID   = [all_instrumentID;   ii*ones(sum(valid),1)];
    all_Dist           = [all_Dist;           Dist(valid)];
    all_DistCoast      = [all_DistCoast;      DistCoast(valid)];
    all_Depth          = [all_Depth;          Depth(valid)];
    all_Tp             = [all_Tp;             Tp(valid)];
    all_PeakDir        = [all_PeakDir;        PeakDir(valid)];
    all_MeanDir        = [all_MeanDir;        MeanDir(valid)];
    all_CurrentSpeed   = [all_CurrentSpeed;   cSpd(valid)];
    all_CurrentDir     = [all_CurrentDir;     cDir(valid)];
    all_WindSpeed      = [all_WindSpeed;      wSpd(valid)];
    all_WindDir        = [all_WindDir;        wDir(valid)];
    all_VersionFlag    = [all_VersionFlag;    double(vFlg(valid))]; % numeric 0/1
    all_L              = [all_L;              L_i(valid)];
    all_waveSteepness  = [all_waveSteepness;  waveSteep_i(valid)];
end

%% =========================================================
%  Build combined table for Random Forest
% =========================================================
T = table( ...
    all_error, ...
    all_instrumentID, ...
    all_Dist, ...
    all_DistCoast, ...
    all_Depth, ...
    all_SWH_insitu, ...
    all_Tp, ...
    all_PeakDir, ...
    all_MeanDir, ...
    all_CurrentSpeed, ...
    all_CurrentDir, ...
    all_WindSpeed, ...
    all_WindDir, ...
    all_VersionFlag, ...
    all_L, ...
    all_waveSteepness, ...
    'VariableNames', { ...
        'SWH_error', ...
        'InstrumentID', ...
        'DistToInstrument', ...
        'DistToCoast', ...
        'Depth', ...
        'SWH_insitu', ...
        'Tp', ...
        'PeakDir', ...
        'MeanDir', ...
        'CurrentSpeed', ...
        'CurrentDir', ...
        'WindSpeed', ...
        'WindDir', ...
        'VersionFlag', ...
        'L', ...
        'waveSteepness'});

% InstrumentID as categorical (so RF can treat it as a factor)
T.InstrumentID = categorical(T.InstrumentID);

predictorNames = { ...
    'InstrumentID', ...
    'DistToInstrument', ...
    'DistToCoast', ...
    'Depth', ...
    'SWH_insitu', ...
    'CurrentDir', ...
    'MeanDir', ...
    'WindSpeed', ...
    'CurrentSpeed', ...
    'WindDir', ...
    'PeakDir', ...
    'Tp', ...
    'VersionFlag', ...
    'L', ...
    'waveSteepness'};

%% =========================================================
%  Train Random Forest (TreeBagger) on SWH_error: ALL INSTRUMENTS
% =========================================================
rng(1);  % for reproducibility

% Index of InstrumentID for categorical treatment
[~, idxInstr] = ismember('InstrumentID', predictorNames);

Mdl_all = TreeBagger(500, T(:,predictorNames), T.SWH_error, ...
    'Method','regression', ...
    'OOBPrediction','On', ...
    'OOBPredictorImportance','On', ...
    'MinLeafSize',5, ...
    'Surrogate','On', ...
    'PredictorSelection','curvature', ...
    'CategoricalPredictors', idxInstr);

%% =========================================================
%  Feature importance (ALL instruments)
% =========================================================
imp_all = Mdl_all.OOBPermutedPredictorDeltaError;
[impSorted_all, idxSort_all] = sort(imp_all, 'descend');

fprintf('===== FEATURE IMPORTANCE (Descending) - ALL INSTRUMENTS =====\n');
for k = 1:numel(idxSort_all)
    fprintf('%2d) %-20s  Importance = %.3f\n', ...
        k, predictorNames{idxSort_all(k)}, impSorted_all(k));
end

figure;
bar(impSorted_all);
set(gca,'XTick',1:numel(predictorNames), ...
        'XTickLabel', predictorNames(idxSort_all), ...
        'XTickLabelRotation',45, ...
        'FontSize',12);
ylabel('OOB Permuted Importance');
title('RF Feature Importance for SWOT SWH Error (All Instruments)');
box on;

%% =========================================================
%  1D PD Plots for combined model
% =========================================================
pdVars1D = { ...
    'DistToInstrument', ...
    'DistToCoast', ...
    'Depth', ...
    'SWH_insitu', ...
    'waveSteepness', ...
    'CurrentDir', ...
    'PeakDir', ...
    'Tp', ...
    'L'};

for i = 1:numel(pdVars1D)
    figure;
    plotPartialDependence(Mdl_all, T(:,predictorNames), pdVars1D{i});
    title(['PD (All Instruments): ', pdVars1D{i}], 'FontSize', 18);
    xlabel(pdVars1D{i}, 'FontSize', 14);
    ylabel('Predicted |SWH Error| [m]', 'FontSize', 14);
    grid on; box on;
end

 %% =========================================================
% %  2D PD Plots for combined model
% % =========================================================
% pdPairs = { ...
%     'waveSteepness','Depth'; ...
%     'waveSteepness','SWH_insitu'; ...
%     'L','Depth'; ...
%     'SWH_insitu','Depth'; ...
%     'DistToInstrument','Depth'; ...
%     'DistToCoast','Depth'};
% 
% for i = 1:size(pdPairs,1)
%     figure;
%     plotPartialDependence(Mdl_all, T(:,predictorNames), {pdPairs{i,1}, pdPairs{i,2}});
%     title(sprintf('PD (All Instruments): %s vs %s', pdPairs{i,1}, pdPairs{i,2}), ...
%         'FontSize', 18);
% end

%% =========================================================
%  PART 2: Separate RF models for each instrument
% =========================================================
fprintf('\n\n=============================================\n');
fprintf(' SEPARATE RANDOM FOREST MODELS BY INSTRUMENT\n');
fprintf('=============================================\n\n');

% Predictor set for per-instrument models (no InstrumentID)
predictorNames_noID = predictorNames(~strcmp(predictorNames,'InstrumentID'));

for ii = 1:nInstr

    instLabel = instrumentLabels{ii};

    % Subset table to this instrument only
    idxInst = (T.InstrumentID == categorical(ii));
    Ti = T(idxInst, :);

    fprintf('--- Instrument %d: %s ---\n', ii, instLabel);
    fprintf('Samples: %d\n', height(Ti));

    if height(Ti) < 50
        warning('Very few samples for %s; RF may be unstable.', instLabel);
    end

    % Train RF for this instrument (no InstrumentID predictor)
    rng(1);  % keep reproducible for each
    Mdl_i = TreeBagger(300, Ti(:,predictorNames_noID), Ti.SWH_error, ...
        'Method','regression', ...
        'OOBPrediction','On', ...
        'OOBPredictorImportance','On', ...
        'MinLeafSize',5, ...
        'Surrogate','On', ...
        'PredictorSelection','curvature');

    % Feature importance for this instrument
    imp_i = Mdl_i.OOBPermutedPredictorDeltaError;
    [impSort_i, idxSort_i] = sort(imp_i,'descend');

    fprintf('  >>> Feature Importance for %s:\n', instLabel);
    for k = 1:numel(idxSort_i)
        fprintf('  %2d) %-20s  Importance = %.3f\n', ...
            k, predictorNames_noID{idxSort_i(k)}, impSort_i(k));
    end
    fprintf('\n');

    % Bar plot
    figure;
    bar(impSort_i);
    set(gca,'XTick',1:numel(predictorNames_noID), ...
            'XTickLabel', predictorNames_noID(idxSort_i), ...
            'XTickLabelRotation',45, ...
            'FontSize',12);
    ylabel('OOB Permuted Importance');
    title(sprintf('RF Feature Importance: %s', instLabel));
    box on;

    % ---- 1D PD plots for this instrument ----
    for p = 1:numel(pdVars1D)
        thisVar = pdVars1D{p};
        if ~ismember(thisVar, predictorNames_noID)
            continue;  % skip if not in this model
        end
        figure;
        plotPartialDependence(Mdl_i, Ti(:,predictorNames_noID), thisVar);
        title(sprintf('PD: %s (%s)', thisVar, instLabel), 'FontSize', 18);
        xlabel(thisVar, 'FontSize', 14);
        ylabel('Predicted |SWH Error| [m]', 'FontSize', 14);
        grid on; box on;
    end

    % ---- 2D PD plots for this instrument ----
    for p = 1:size(pdPairs,1)
        var1 = pdPairs{p,1};
        var2 = pdPairs{p,2};
        if ~ismember(var1,predictorNames_noID) || ~ismember(var2,predictorNames_noID)
            continue;
        end
        figure;
        plotPartialDependence(Mdl_i, Ti(:,predictorNames_noID), {var1,var2});
        title(sprintf('PD: %s vs %s (%s)', var1, var2, instLabel), ...
            'FontSize', 18);
    end
end


%% =========================================================
%  Local function: wavelength with regime logic
% =========================================================
function L = computeWavelength_regime(Tp, h)
    % computeWavelength_regime
    %   Computes wavelength L for given period Tp and depth h,
    %   using:
    %     - deep-water approx when h/L_deep >= 0.5
    %     - shallow-water approx when h/L_deep <= 0.05
    %     - full dispersion (fzero) otherwise
    %
    %   Tp  : wave period [s]  (vector)
    %   h   : water depth [m]  (vector)
    %   L   : wavelength [m]

    g = 9.81;
    Tp = Tp(:);
    h  = h(:);
    L  = NaN(size(Tp));

    valid = Tp > 0 & h > 0 & isfinite(Tp) & isfinite(h);
    idxValid = find(valid);

    if isempty(idxValid)
        return;
    end

    T  = Tp(valid);
    hv = h(valid);

    % Deep-water first guess
    L0 = g .* T.^2 ./ (2*pi);
    d_over_L0 = hv ./ L0;

    deep        = d_over_L0 >= 0.5;
    shallow     = d_over_L0 <= 0.05;
    intermediate = ~(deep | shallow);

    % Deep-water: use L0 directly
    L(idxValid(deep)) = L0(deep);

    % Shallow-water: c = sqrt(g*h), L = c*T
    if any(shallow)
        Lsh = T(shallow) .* sqrt(g .* hv(shallow));
        L(idxValid(shallow)) = Lsh;
    end

    % Intermediate: solve dispersion with fzero
    if any(intermediate)
        idxInt = idxValid(intermediate);
        T_int  = T(intermediate);
        h_int  = hv(intermediate);
        L0_int = L0(intermediate);

        for n = 1:numel(idxInt)
            omega = 2*pi ./ T_int(n);
            k0    = 2*pi ./ L0_int(n);     % initial guess for wavenumber
            f     = @(k) g*k.*tanh(k*h_int(n)) - omega.^2;

            try
                k = fzero(f, k0);
                if k > 0
                    L(idxInt(n)) = 2*pi ./ k;
                else
                    L(idxInt(n)) = L0_int(n); % fallback
                end
            catch
                % If fzero fails, fall back to deep-water estimate
                L(idxInt(n)) = L0_int(n);
            end
        end
    end
end


%% =========================================================
%  Local function: Partial Dependence (1D or 2D)
% =========================================================
function plotPartialDependence(Mdl, T, vars)
    % plotPartialDependence
    %   Mdl  : TreeBagger regression model
    %   T    : table of predictors (same vars as used in training)
    %   vars : char/string for 1D, or {var1, var2} for 2D

    if ischar(vars) || (isstring(vars) && isscalar(vars))
        % ----------------- 1D PD -----------------
        varName = char(vars);
        x = T.(varName);
        if iscategorical(x)
            error('1D PD: %s is categorical; this helper expects numeric.', varName);
        end

        xMin = prctile(x,5);
        xMax = prctile(x,95);
        xGrid = linspace(xMin, xMax, 40)';

        yPD = nan(size(xGrid));

        for i = 1:numel(xGrid)
            Ttmp = T;
            Ttmp.(varName)(:) = xGrid(i);
            yhat = predict(Mdl, Ttmp);
            yPD(i) = mean(yhat, 'omitnan');
        end

        plot(xGrid, yPD, 'LineWidth', 2);
        grid on; box on;

    else
        % ----------------- 2D PD -----------------
        var1 = char(vars{1});
        var2 = char(vars{2});

        x1 = T.(var1);
        x2 = T.(var2);
        if iscategorical(x1) || iscategorical(x2)
            error('2D PD: both %s and %s must be numeric.', var1, var2);
        end

        x1Min = prctile(x1,5); x1Max = prctile(x1,95);
        x2Min = prctile(x2,5); x2Max = prctile(x2,95);

        x1Grid = linspace(x1Min, x1Max, 30);
        x2Grid = linspace(x2Min, x2Max, 30);

        [X1, X2] = meshgrid(x1Grid, x2Grid);
        Z = nan(size(X1));

        for i = 1:numel(x1Grid)
            for j = 1:numel(x2Grid)
                Ttmp = T;
                Ttmp.(var1)(:) = x1Grid(i);
                Ttmp.(var2)(:) = x2Grid(j);
                yhat = predict(Mdl, Ttmp);
                Z(j,i) = mean(yhat, 'omitnan');
            end
        end

        imagesc(x1Grid, x2Grid, Z);
        set(gca,'YDir','normal');
        colorbar;
        xlabel(var1, 'FontSize', 12);
        ylabel(var2, 'FontSize', 12);
        title('Mean predicted |SWH error|', 'FontSize', 12);
        box on;
    end
end
