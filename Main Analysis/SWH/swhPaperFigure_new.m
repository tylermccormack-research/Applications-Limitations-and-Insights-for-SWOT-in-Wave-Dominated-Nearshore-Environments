clear; clc

%% =========================================================
%  Load Data
%  ---------------------------------------------------------
%  SWOT SWH from LR2km product
% =========================================================
load('250m_LR_L2_SSH_expert_Processed.mat'); % LR 2km
LR2km = dataStruct; 
clearvars dataStruct

% In-situ wave / env info (LR2km time base)
load('insituSWH_relevantInstrumentsAllProducts.mat','instrumentSWH_byTime_LR2km');
load('insituTp_relevantInstrumentsAllProducts.mat','instrumentTp_byTime_LR2km');
load('insituWavePeakDir_relevantInstrumentsAllProducts.mat','instrumentWavePeakDir_byTime_LR2km')
load('insituWaveMeanDir_relevantInstrumentsAllProducts.mat','instrumentWaveMeanDir_byTime_LR2km')
load('insituCurrentSpeeds_relevantInstrumentsAllProducts.mat','instrumentCurrentSpeed_byTime_LR2km');
load('insituCurrentDirection_relevantInstrumentsAllProducts.mat','instrumentCurrentDirection_byTime_LR2km');
load('insituWindSpeeds_relevantInstrumentsAllProducts.mat','instrumentWindSpeed_byTime_LR2km');
load('insituWindDirection_relevantInstrumentsAllProducts.mat','instrumentWindDirection_byTime_LR2km');
load('waterDepth_relevantInstrumentsAllProducts.mat', 'instrumentWaterDepth_byTime_LR2km');

% Pass match (same logicals you used before)
load("passMatchLogical.mat","idx063_LR2km","idx354_LR2km");

% Load tide gauge
load('noaaTideData_all_navd88.mat');

% Time and water level stuff
% SWOT LR_L2_SSH_Expert_2km
load('convertedTimeArray_250m_LR_L2_SSH_Expert.mat');
load('extractedSSH_250m_LR_L2_SSH_Expert.mat');


%% =========================================================
%  Pull SWOT SWH closest to each instrument
%  (26m, 17m, 900m, 600m)
% =========================================================
fieldNames = fieldnames(LR2km);
numPasses  = numel(fieldNames);

SWH_closestTo26mBuoy   = nan(numPasses,1);
SWH_closestTo17mBuoy   = nan(numPasses,1);
SWH_closestTo900mSensor= nan(numPasses,1);
SWH_closestTo600mSensor= nan(numPasses,1);

distTo26mBuoy    = nan(numPasses,1);
distTo17mBuoy    = nan(numPasses,1);
distTo900mSensor = nan(numPasses,1);
distTo600mSensor = nan(numPasses,1);

for t = 1:numPasses
    fn = fieldNames{t};

    SWH = LR2km.(fn).SWH;

    % ---- 26 m buoy ----
    idx = LR2km.(fn).SWH_Index26mBuoy;
    dist = LR2km.(fn).DistanceTo26mBuoy;

    if ~isnan(idx) && idx > 0 && idx <= numel(SWH)
        SWH_closestTo26mBuoy(t,1) = SWH(idx);
        distTo26mBuoy(t,1)        = dist;

        if SWH_closestTo26mBuoy(t,1) <= 0
            SWH_closestTo26mBuoy(t,1) = NaN;
            distTo26mBuoy(t,1)        = NaN;
        end
    else
        SWH_closestTo26mBuoy(t,1) = NaN;
        distTo26mBuoy(t,1)        = NaN;
    end

    % ---- 17 m buoy ----
    idx = LR2km.(fn).SWH_Index17mBuoy;
    dist = LR2km.(fn).DistanceTo17mBuoy;

    if ~isnan(idx) && idx > 0 && idx <= numel(SWH)
        SWH_closestTo17mBuoy(t,1) = SWH(idx);
        distTo17mBuoy(t,1)        = dist;

        if SWH_closestTo17mBuoy(t,1) <= 0
            SWH_closestTo17mBuoy(t,1) = NaN;
            distTo17mBuoy(t,1)        = NaN;
        end
    else
        SWH_closestTo17mBuoy(t,1) = NaN;
        distTo17mBuoy(t,1)        = NaN;
    end

    % ---- 900 m sensor (8 m array) ----
    idx = LR2km.(fn).SWH_Index900mSensor;
    dist = LR2km.(fn).DistanceTo900mSensor;

    if ~isnan(idx) && idx > 0 && idx <= numel(SWH)
        SWH_closestTo900mSensor(t,1) = SWH(idx);
        distTo900mSensor(t,1)        = dist;

        if SWH_closestTo900mSensor(t,1) <= 0
            SWH_closestTo900mSensor(t,1) = NaN;
            distTo900mSensor(t,1)        = NaN;
        end
    else
        SWH_closestTo900mSensor(t,1) = NaN;
        distTo900mSensor(t,1)        = NaN;
    end

    % ---- 600 m Signature ----
    idx = LR2km.(fn).SWH_Index600mSensor;
    dist = LR2km.(fn).DistanceTo600mSensor;

    if ~isnan(idx) && idx > 0 && idx <= numel(SWH)
        SWH_closestTo600mSensor(t,1) = SWH(idx);
        distTo600mSensor(t,1)        = dist;

        if SWH_closestTo600mSensor(t,1) <= 0
            SWH_closestTo600mSensor(t,1) = NaN;
            distTo600mSensor(t,1)        = NaN;
        end
    else
        SWH_closestTo600mSensor(t,1) = NaN;
        distTo600mSensor(t,1)        = NaN;
    end
end

% Package for looping
instrumentNames  = {'waverider_26m','waverider_17m','x8m_array','sig940_600'};
instrumentLabels = { ...
    '26 m Waverider (16 km)', ...
    '17 m Waverider (4 km)', ...
    '8 m Array (900 m)', ...
    '7 m Signature (600 m)'};

SWH_swot_all = { ...
    SWH_closestTo26mBuoy, ...
    SWH_closestTo17mBuoy, ...
    SWH_closestTo900mSensor, ...
    SWH_closestTo600mSensor};

dist_all = { ...
    distTo26mBuoy, ...
    distTo17mBuoy, ...
    distTo900mSensor, ...
    distTo600mSensor};

% =========================================================
% Distance thresholds for each instrument (meters)
% =========================================================
maxDist_26m   = 1500;   
maxDist_17m   = 1500;   
maxDist_900m  = 3000;
maxDist_600m  = 3000;

maxDist_all = { ...
    maxDist_26m, ...
    maxDist_17m, ...
    maxDist_900m, ...
    maxDist_600m};

%% Helper: error metrics printer (same style as your SWH plots)
printMetricsBox = @(xData,yData,idx063,idx354,distVec) ...
    sprintf([ ...
    'Bulk Bias = %.2f m\nBulk RMSE = %.2f m\n\n' ...
    'Pass Bias  : \n#063 = %.2f m,  \n#354 = %.2f m\n' ...
    '\nPass RMSE  : \n#063 = %.2f m, \n#354 = %.2f m' ...
    '\nn=%d'], ...
    mean(yData - xData,'omitnan'), ...            % bulk bias
    rmse(xData, yData,'omitnan'), ...             % bulk rmse
    mean(yData(idx063) - xData(idx063),'omitnan'), ...  % bias 063
    mean(yData(idx354) - xData(idx354),'omitnan'), ...  % bias 354
    rmse(xData(idx063), yData(idx063),'omitnan'), ...   % rmse 063
    rmse(xData(idx354), yData(idx354),'omitnan'), ...   % rmse 354
    sum(~isnan(distVec)));                         % n



%% =========================================================
%  SWOT vs In-situ SWH (4 panels) + Comparison Locations Map
%  Styled IDENTICALLY to WSE figure
% =========================================================

% -----------------------
% Figure + layout
% -----------------------
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);

figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(3,2);
t.TileSpacing = 'tight';
t.Padding     = 'tight';

% -----------------------
% Helper formatting
% -----------------------
formatAxes = @() set(gca, ...
    'FontSize',15, ...
    'Box','on', ...
    'XColor','k', ...
    'YColor','k', ...
    'LineWidth',1);

% -----------------------
% Helper function to print stats (TOP-LEFT)
% -----------------------
% printStats = @(rmse_val,r2_val,bias_val) ...
%     text(0.03,0.97, sprintf('Bias = %.2f m \nRMSE = %.2f m \nR^{2} = %.2f', ...
%     bias_val, rmse_val, r2_val), ...
%     'Units','normalized','VerticalAlignment','top','FontSize',14, ...
%     'Interpreter','tex');

printStats = @(rmse_val,r2_val,bias_val,N,xPos,yPos,align) ...
    text(xPos,yPos, sprintf( ...
    'Bias = %.2f m \nRMSE = %.2f m \nR^{2} = %.2f \nn = %d', ...
    bias_val, rmse_val, r2_val, N), ...
    'Units','normalized', ...
    'HorizontalAlignment',align, ...
    'VerticalAlignment','top', ...
    'FontSize',14, ...
    'Interpreter','tex');

% -----------------------
% Panel label helper (TOP-RIGHT)
% -----------------------
addPanelLabel = @(ax,labelChar) ...
    text(ax,0.91,1.01,labelChar, ...
    'Units','normalized', ...
    'HorizontalAlignment','right', ...
    'VerticalAlignment','top', ...
    'FontSize',18, ...
    'FontWeight','bold');


% =========================================================
%  Tiles 1–4: SWOT vs In-situ SWH
% =========================================================
panelLetters = {'A','B','C','D','E'};

for ii = 1:4
    ax = nexttile; hold(ax,'on');

    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    distVec = dist_all{ii};
    maxDist = maxDist_all{ii};

    % --- Distance filter ---
    validDist = distVec <= maxDist;
    validPass = idx063_LR2km | idx354_LR2km;   % or both separately if needed
    % valid = validDist & validPass & (SWH > 0);

    % Apply filter
    xData(~validDist) = NaN;
    yData(~validDist) = NaN;

    % =====================================================
    % 3-sigma outlier filter (applied separately to SWOT and in-situ)
    % =====================================================
    % In-situ filter
    mu_x  = mean(xData,'omitnan');
    sig_x = std(xData,'omitnan');
    valid_x = (xData >= mu_x - 3*sig_x) & (xData <= mu_x + 3*sig_x);

    % SWOT filter
    mu_y  = mean(yData,'omitnan');
    sig_y = std(yData,'omitnan');
    valid_y = (yData >= mu_y - 3*sig_y) & (yData <= mu_y + 3*sig_y);

    % Remove outliers
    xData(~valid_x) = NaN;
    yData(~valid_y) = NaN;

    % -------- Marker styles matched to map --------
switch ii
    case 1   % 26 m buoy
        mkr = 'o'; clr = 'r'; filled = true;
    case 2   % 17 m buoy
        mkr = 'x'; clr = 'k'; filled = false;
    case 3   % 8 m array (900 m)
        mkr = 'd'; clr = 'g'; filled = true;
    case 4   % 600 m sensor
        mkr = 's'; clr = 'm'; filled = true;
end

idx063 = idx063_LR2km & validDist;
idx354 = idx354_LR2km & validDist;

if filled
    scatter(xData(idx063), yData(idx063), 100, mkr, ...
        'MarkerEdgeColor',clr,'MarkerFaceColor',clr,'LineWidth',2);
    scatter(xData(idx354), yData(idx354), 100, mkr, ...
        'MarkerEdgeColor',clr,'MarkerFaceColor',clr,'LineWidth',2);
else
    scatter(xData(idx063), yData(idx063), 150, mkr, ...
        'MarkerEdgeColor',clr,'LineWidth',2);
    scatter(xData(idx354), yData(idx354), 150, mkr, ...
        'MarkerEdgeColor',clr,'LineWidth',2);
end

    plot(0:1:6, 0:1:6, 'k');

    xlim([0 6]); ylim([0 6]);
    axis square; grid on;

    title(instrumentLabels{ii}, 'FontSize',18);

    if ii > 2
        xlabel('In-situ SWH [m]','FontSize',16);
    end
    if ismember(ii,[1 3])
        ylabel('SWOT SWH [m]','FontSize',16);
    end

    formatAxes();

    % ---------- Bulk Metrics (WSE-style) ----------
    bulkBias = mean(yData - xData, 'omitnan');
    bulkRMSE = rmse(xData, yData, 'omitnan');

    rangeXdata=max(xData) - min(xData);

    validIdx = ~isnan(xData) & ~isnan(yData);
    R = corrcoef(xData(validIdx), yData(validIdx));
    bulkR2 = R(1,2)^2;
    N = sum(validIdx);



    if ii <= 2
        % Panels 1–2: top-left
        % printStats(bulkRMSE, bulkR2, bulkBias);
        printStats(bulkRMSE, bulkR2, bulkBias, N, 0.03, 0.97, 'left');

    else
        % Panels 3–4: bottom-right
        % text(0.97,0.03, sprintf( ...
        %     'Bias = %.2f m \nRMSE = %.2f m \nR^{2} = %.2f', ...
        %     bulkBias, bulkRMSE, bulkR2), ...
        %     'Units','normalized', ...
        %     'HorizontalAlignment','right', ...
        %     'VerticalAlignment','bottom', ...
        %     'FontSize',14, ...
        %     'Interpreter','tex');
        text(0.97,0.03, sprintf( ...
            'Bias = %.2f m \nRMSE = %.2f m \nR^{2} = %.2f \nn = %d', ...
            bulkBias, bulkRMSE, bulkR2, N), ...
            'Units','normalized', ...
            'HorizontalAlignment','right', ...
            'VerticalAlignment','bottom', ...
            'FontSize',14, ...
            'Interpreter','tex');
    end

        % Panel letter (draw LAST so it stays on top)
    addPanelLabel(ax, panelLetters{ii});

end

validIndices26  = ~isnan(instrumentSWH_byTime_LR2km.waverider_26m) & ~isnan(SWH_closestTo26mBuoy) & ...
                  distTo26mBuoy <= maxDist_26m & (idx063_LR2km | idx354_LR2km);
validIndices17  = ~isnan(instrumentSWH_byTime_LR2km.waverider_17m) & ~isnan(SWH_closestTo17mBuoy) & ...
                  distTo17mBuoy <= maxDist_17m & (idx063_LR2km | idx354_LR2km);
validIndices900 = ~isnan(instrumentSWH_byTime_LR2km.x8m_array) & ~isnan(SWH_closestTo900mSensor) & ...
                  distTo900mSensor <= maxDist_900m & (idx063_LR2km | idx354_LR2km);
validIndices600 = ~isnan(instrumentSWH_byTime_LR2km.sig940_600) & ~isnan(SWH_closestTo600mSensor) & ...
                  distTo600mSensor <= maxDist_600m & (idx063_LR2km | idx354_LR2km);

% =========================================================
%  Tile 5: Spatial locations of SWOT pixels used for SWH
% =========================================================
axMap = nexttile([1 2]);
hold(axMap,'on');

addPanelLabel(axMap, panelLetters{5});

set(axMap,'Box','on','Layer','top','LineWidth',1.5);

% --- DEM background ---
load("demVariables.mat");

levelsFill = -0.25:-0.5:-35;
levelsLine = -5:-5:-35;

[C, h] = contourf(frfX, frfY, Z_crop, levelsFill, 'LineColor','none');
[C2, h2] = contour(frfX, frfY, Z_crop, levelsLine, 'k', 'LineWidth', 1);
clabel(C2, h2, 'Color','k');

colormap(m_colmap('blue'));
box on;

cb = colorbar(axMap);
cb.Label.String = 'Elevation (m NAVD88)';
caxis(axMap,[-30 0]);

% --- FRF pier ---
hPier=fill([0 585 585 0],[514 514 520 520],'k','LineWidth',2);

% --- NOAA gauge ---
% noaaLat  = 36.183639;
% noaaLong = -75.74528;
% [~,~,~,~,noaaY,noaaX] = frfCoord(noaaLong,noaaLat);
% plot(noaaX,noaaY,'ob','MarkerFaceColor','b', ...
%      'LineWidth',3,'MarkerSize',18);

% --- Instrument locations ---
hGauges = plotFRFinstruments_instrumentsOnly_4SWOT_compare_locations;

% --- Shoreline ---
load("UsShapeFrfX.mat");
load("UsShapeFrfY.mat");
plot(UsShapeFrfX,UsShapeFrfY,'k-');

% --- Load SWOT SWH comparison locations ---
fn = fieldnames(LR2km);
nP = numel(fn);

% --- Only use points within threshold for plotting ---
%% --- Build map points using valid scatter indices ---
nP = numel(fn);

x26 = nan(sum(validIndices26),1);
y26 = nan(sum(validIndices26),1);
x17 = nan(sum(validIndices17),1);
y17 = nan(sum(validIndices17),1);
x900 = nan(sum(validIndices900),1);
y900 = nan(sum(validIndices900),1);
x600 = nan(sum(validIndices600),1);
y600 = nan(sum(validIndices600),1);

% 26 m buoy
cnt = 1;
for i = 1:nP
    if validIndices26(i)
        x26(cnt) = LR2km.(fn{i}).FRF_X(LR2km.(fn{i}).SWH_Index26mBuoy);
        y26(cnt) = LR2km.(fn{i}).FRF_Y(LR2km.(fn{i}).SWH_Index26mBuoy);
        cnt = cnt + 1;
    end
end

% 17 m buoy
cnt = 1;
for i = 1:nP
    if validIndices17(i)
        x17(cnt) = LR2km.(fn{i}).FRF_X(LR2km.(fn{i}).SWH_Index17mBuoy);
        y17(cnt) = LR2km.(fn{i}).FRF_Y(LR2km.(fn{i}).SWH_Index17mBuoy);
        cnt = cnt + 1;
    end
end

% 900 m sensor
cnt = 1;
for i = 1:nP
    if validIndices900(i)
        x900(cnt) = LR2km.(fn{i}).FRF_X(LR2km.(fn{i}).SWH_Index900mSensor);
        y900(cnt) = LR2km.(fn{i}).FRF_Y(LR2km.(fn{i}).SWH_Index900mSensor);
        cnt = cnt + 1;
    end
end

% 600 m sensor
cnt = 1;
for i = 1:nP
    if validIndices600(i)
        x600(cnt) = LR2km.(fn{i}).FRF_X(LR2km.(fn{i}).SWH_Index600mSensor);
        y600(cnt) = LR2km.(fn{i}).FRF_Y(LR2km.(fn{i}).SWH_Index600mSensor);
        cnt = cnt + 1;
    end
end

% --- Plot SWH comparison points (MATCH scatter markers) ---
h26 = plotPointsWithCounts_fixed(axMap, x26, y26, ...
    {120,'o','MarkerEdgeColor','r','MarkerFaceColor','r','LineWidth',2}, 'r', 400, -700, 18);

h900 = plotPointsWithCounts_fixed(axMap, x900, y900, ...
    {400,'d','MarkerEdgeColor','g','MarkerFaceColor','g','LineWidth',2}, 'g', 200, 0, 18);

h600 = plotPointsWithCounts_fixed(axMap, x600, y600, ...
    {180,'s','MarkerEdgeColor','m','MarkerFaceColor','m','LineWidth',2}, 'm', -200, 0, 18);

% --- plot LAST so it's on top ---
h17 = plotPointsWithCounts_fixed(axMap, x17, y17, ...
    {180,'x','LineWidth',2,'MarkerEdgeColor','k'}, 'k', -400, -700, 18);

xlim([-1100 20000]);
ylim([-5000 7000]);

xlabel('FRF X (m)','FontSize',16);
ylabel('FRF Y (m)','FontSize',16);
title('Locations of SWOT Pixels Used for SWH Comparison','FontSize',20);

% legend({'','','FRF Pier','', ...
%         'Wave Gauges','','','','','','SWOT Measurements for 26 m Wave Buoy','SWOT Measurements for 17 m Wave Buoy', ...
%         'SWOT Measurements for 8 m Wave Gauge','SWOT Measurements for 7 m Wave Gauge'}, ...
%        'NumColumns',1,'FontSize',11);



% legend([ ...
%     hPier, ...
%     hGauges, ...
%     h26, ...
%     h17, ...
%     h900, ...
%     h600], ...
%     {'FRF Pier', ...
%      '26 m Waverider', ...
%      '17 m Waverider', ...
%      '8 m Array (900 m)', ...
%      '7 m Signature (600 m)', ...
%      'SWOT Measurements for 26 m Wave Buoy', ...
%      'SWOT Measurements for 17 m Wave Buoy', ...
%      'SWOT Measurements for 8 m Wave Gauge', ...
%      'SWOT Measurements for 7 m Wave Gauge'}, ...
%     'FontSize',11);

hGaugeLegend = plot(nan, nan, '^', ...
    'MarkerEdgeColor','k', ...
    'MarkerFaceColor','k', ...
    'LineStyle','none', ...
    'MarkerSize',10);

legend([ ...
    hPier, ...
    hGaugeLegend, ...
    h26, ...
    h17, ...
    h900, ...
    h600], ...
    {'FRF Pier', ...
     'Wave Gauges', ...
     'SWOT Measurements for 26 m Wave Buoy', ...
     'SWOT Measurements for 17 m Wave Buoy', ...
     'SWOT Measurements for 8 m Wave Gauge', ...
     'SWOT Measurements for 7 m Wave Gauge'}, ...
    'FontSize',11);
%% Helper function
function h=plotPointsWithCounts_fixed(ax, x, y, markerArgs, textColor, dx, dy, fontSize)
    % Plot SWOT comparison points and annotate counts
    % Ensures sum of annotated counts = total valid comparisons
    
    if nargin < 7
        fontSize = 18; % default
    end

    % Keep only valid points
    valid = ~isnan(x) & ~isnan(y);
    x = x(valid);
    y = y(valid);

    % Return immediately if empty
    if isempty(x)
        return
    end

    % --- Identify "unique" pixels allowing tiny tolerance for floating-point differences ---
    tol = 1e-3; % 1 mm tolerance
    [uniqueXY, ~, ic] = uniquetol([x y], tol, 'ByRows', true);

    % Count number of comparisons per unique pixel
    counts = accumarray(ic, 1);

    % --- Plot points using same marker as scatter ---
    h=scatter(ax, uniqueXY(:,1), uniqueXY(:,2), markerArgs{:});

    % --- Annotate counts for each pixel ---
    % for i = 1:size(uniqueXY,1)
    %     text(ax, uniqueXY(i,1)+dx, uniqueXY(i,2)+dy, ...
    %         num2str(counts(i)), ...
    %         'FontSize', fontSize, ...
    %         'FontWeight','bold', ...
    %         'Color', textColor, ...
    %         'HorizontalAlignment','center', ...
    %         'VerticalAlignment','middle');
    % end

    % % --- Optional: annotate total n somewhere if needed ---
    % totalN = numel(x);
    % text(ax, mean(x)+dx, mean(y)+dy, ['n=' num2str(totalN)], ...
    %     'FontSize', fontSize, ...
    %     'FontWeight','bold', ...
    %     'Color', textColor, ...
    %     'HorizontalAlignment','center', ...
    %     'VerticalAlignment','bottom');
end

