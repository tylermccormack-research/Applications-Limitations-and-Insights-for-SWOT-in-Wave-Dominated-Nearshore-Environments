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
    SWH_closestTo26mBuoy(t,1) = SWH(LR2km.(fn).SWH_Index26mBuoy);
    distTo26mBuoy(t,1)        = LR2km.(fn).DistanceTo26mBuoy;
    validMask                 = SWH_closestTo26mBuoy > 0;
    SWH_closestTo26mBuoy(~validMask) = NaN;
    distTo26mBuoy(~validMask)       = NaN;

    % ---- 17 m buoy ----
    SWH_closestTo17mBuoy(t,1) = SWH(LR2km.(fn).SWH_Index17mBuoy);
    distTo17mBuoy(t,1)        = LR2km.(fn).DistanceTo17mBuoy;
    validMask                 = SWH_closestTo17mBuoy > 0;
    SWH_closestTo17mBuoy(~validMask) = NaN;
    distTo17mBuoy(~validMask)       = NaN;

    % ---- 900 m sensor (8 m array) ----
    SWH_closestTo900mSensor(t,1) = SWH(LR2km.(fn).SWH_Index900mSensor);
    distTo900mSensor(t,1)        = LR2km.(fn).DistanceTo900mSensor;
    validMask                    = SWH_closestTo900mSensor > 0;
    SWH_closestTo900mSensor(~validMask) = NaN;
    distTo900mSensor(~validMask)       = NaN;

    % ---- 600 m Signature ----
    SWH_closestTo600mSensor(t,1) = SWH(LR2km.(fn).SWH_Index600mSensor);
    distTo600mSensor(t,1)        = LR2km.(fn).DistanceTo600mSensor;
    validMask                    = SWH_closestTo600mSensor > 0;
    SWH_closestTo600mSensor(~validMask) = NaN;
    distTo600mSensor(~validMask)       = NaN;
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
%  4-panel: SWOT vs in-situ SWH (one panel per instrument)
% =========================================================
scr = get(0,'ScreenSize');   % [left bottom width height]
figWidth  = scr(3) / 2;      
figHeight = scr(4);          
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');

for ii = 1:4
    nexttile; hold on

    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};

    % Pass 063 (black) and 354 (green), same style as your single plots
    scatter(xData(idx063_LR2km), yData(idx063_LR2km), 100, 'k', 'filled');
    scatter(xData(idx354_LR2km), yData(idx354_LR2km), 100, 'g', 'filled');

    plot(0:1:4, 0:1:4, 'k');

    xlim([0 4]); ylim([0 4]); axis square; grid on; box on
    title(['SWOT SWH vs In-situ - ' instrumentLabels{ii}], 'FontSize', 18);

    if ii > 2
        xlabel('In-situ SWH [m]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWOT SWH [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);

    metricsStr = printMetricsBox(xData,yData,idx063_LR2km,idx354_LR2km,dist_all{ii});

    % % Metrics box (normalized position)
    % text(0.03, 0.97, metricsStr, ...
    %     'Units','normalized', ...
    %     'VerticalAlignment','top', ...
    %     'FontSize', 14, ...
    %     'BackgroundColor','w', ...
    %     'EdgeColor','k');

    % --- Compute the metrics fresh (clean version) ---
    bulkBias  = mean(yData - xData, 'omitnan');
    bulkRMSE  = rmse(xData, yData, 'omitnan');

    bias063   = mean(yData(idx063_LR2km) - xData(idx063_LR2km), 'omitnan');
    bias354   = mean(yData(idx354_LR2km) - xData(idx354_LR2km), 'omitnan');

    rmse063   = rmse(xData(idx063_LR2km), yData(idx063_LR2km), 'omitnan');
    rmse354   = rmse(xData(idx354_LR2km), yData(idx354_LR2km), 'omitnan');

    nPoints   = sum(~isnan(xData) & ~isnan(yData));


    % --- Two-column pure text, above the axes ---
    ax = gca;
    yl = ax.YLim;
    xl = ax.XLim;

    % New vertical position you provided
    yText = yl(2) - 0.15*(yl(2)-yl(1));

    % Horizontal positions (closer together)
    xLeft  = xl(1) + 0.05*(xl(2)-xl(1));
    xRight = xl(1) + 0.48*(xl(2)-xl(1));   % moved left to reduce gap


    % ----- Left column: Bias -----
    text(xLeft, yText, sprintf([ ...
        'Bulk Bias:   %.2f m\n' ...
        '063 Bias:    %.2f m\n' ...
        '354 Bias:    %.2f m'], ...
        bulkBias, bias063, bias354), ...
        'HorizontalAlignment','left', ...
        'VerticalAlignment','bottom', ...
        'FontSize',12);

    % ----- Right column: RMSE -----
    text(xRight, yText, sprintf([ ...
        'Bulk RMSE:   %.2f m\n' ...
        '063 RMSE:    %.2f m\n' ...
        '354 RMSE:    %.2f m'], ...
        bulkRMSE, rmse063, rmse354), ...
        'HorizontalAlignment','left', ...
        'VerticalAlignment','bottom', ...
        'FontSize',12);

    % ----- n value centered below -----
    text(xLeft+0.2, yText , ...
        sprintf('n = %d', nPoints), ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','top', ...
        'FontSize',12);


end

lgd = legend({'Pass #063','Pass #354'},'Location','best');
set(lgd,...
    'Position',[0.0830468762821207 0.800554453130985 0.14583333057041 0.0521350531971088],...
    'FontSize',14);
fontsize(lgd, 14,"points");

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
printStats = @(rmse_val,r2_val,bias_val) ...
    text(0.03,0.97, sprintf('Bias = %.2f m \nRMSE = %.2f m \nR^{2} = %.2f', ...
    bias_val, rmse_val, r2_val), ...
    'Units','normalized','VerticalAlignment','top','FontSize',14, ...
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

if filled
    scatter(xData(idx063_LR2km), yData(idx063_LR2km), 100, mkr, ...
        'MarkerEdgeColor',clr,'MarkerFaceColor',clr,'LineWidth',2);
    scatter(xData(idx354_LR2km), yData(idx354_LR2km), 100, mkr, ...
        'MarkerEdgeColor',clr,'MarkerFaceColor',clr,'LineWidth',2);
else
    scatter(xData(idx063_LR2km), yData(idx063_LR2km), 150, mkr, ...
        'MarkerEdgeColor',clr,'LineWidth',2);
    scatter(xData(idx354_LR2km), yData(idx354_LR2km), 150, mkr, ...
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

    validIdx = ~isnan(xData) & ~isnan(yData);
    R = corrcoef(xData(validIdx), yData(validIdx));
    bulkR2 = R(1,2)^2;

    if ii <= 2
        % Panels 1–2: top-left
        printStats(bulkRMSE, bulkR2, bulkBias);
    else
        % Panels 3–4: bottom-right
        text(0.97,0.03, sprintf( ...
            'Bias = %.2f m \nRMSE = %.2f m \nR^{2} = %.2f', ...
            bulkBias, bulkRMSE, bulkR2), ...
            'Units','normalized', ...
            'HorizontalAlignment','right', ...
            'VerticalAlignment','bottom', ...
            'FontSize',14, ...
            'Interpreter','tex');
    end

        % Panel letter (draw LAST so it stays on top)
    addPanelLabel(ax, panelLetters{ii});

end

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
fill([0 585 585 0],[514 514 520 520],'k','LineWidth',2);

% --- NOAA gauge ---
% noaaLat  = 36.183639;
% noaaLong = -75.74528;
% [~,~,~,~,noaaY,noaaX] = frfCoord(noaaLong,noaaLat);
% plot(noaaX,noaaY,'ob','MarkerFaceColor','b', ...
%      'LineWidth',3,'MarkerSize',18);

% --- Instrument locations ---
plotFRFinstruments_instrumentsOnly_4SWOT_compare_locations


% --- Shoreline ---
load("UsShapeFrfX.mat");
load("UsShapeFrfY.mat");
plot(UsShapeFrfX,UsShapeFrfY,'k-');

% --- Load SWOT SWH comparison locations ---
load('250m_LR_L2_SSH_expert_Processed.mat');
fn = fieldnames(dataStruct);
nP = numel(fn);

x26 = nan(nP,1); y26 = nan(nP,1);
x17 = nan(nP,1); y17 = nan(nP,1);
x900 = nan(nP,1); y900 = nan(nP,1);
x600 = nan(nP,1); y600 = nan(nP,1);

for i = 1:nP
    F = dataStruct.(fn{i});
    if F.SWH_Index26mBuoy > 0
        x26(i) = F.FRF_X(F.SWH_Index26mBuoy);
        y26(i) = F.FRF_Y(F.SWH_Index26mBuoy);
    end
    if F.SWH_Index17mBuoy > 0
        x17(i) = F.FRF_X(F.SWH_Index17mBuoy);
        y17(i) = F.FRF_Y(F.SWH_Index17mBuoy);
    end
    if F.SWH_Index900mSensor > 0
        x900(i) = F.FRF_X(F.SWH_Index900mSensor);
        y900(i) = F.FRF_Y(F.SWH_Index900mSensor);
    end
    if F.SWH_Index600mSensor > 0
        x600(i) = F.FRF_X(F.SWH_Index600mSensor);
        y600(i) = F.FRF_Y(F.SWH_Index600mSensor);
    end
end

% --- Plot SWH comparison points (MATCH scatter markers) ---

% 26 m buoy – red filled circle
plot(x26, y26, 'o', ...
    'MarkerSize',12, ...
    'MarkerEdgeColor','r', ...
    'MarkerFaceColor','r', ...
    'LineWidth',2);

% 17 m buoy – black X (unfilled)
plot(x17, y17, 'x', ...
    'MarkerSize',30, ...
    'Color','k', ...
    'LineWidth',2);

% 8 m array (900 m) – green filled diamond
plot(x900, y900, 'd', ...
    'MarkerSize',20, ...
    'MarkerEdgeColor','g', ...
    'MarkerFaceColor','g', ...
    'LineWidth',2);

% 600 m sensor – magenta filled triangle
plot(x600, y600, 's', ...
    'MarkerSize',12, ...
    'MarkerEdgeColor','m', ...
    'MarkerFaceColor','m', ...
    'LineWidth',2);


xlim([-1100 20000]);
ylim([-5000 7000]);

xlabel('FRF X (m)','FontSize',16);
ylabel('FRF Y (m)','FontSize',16);
title('Locations of SWOT Pixels Used for SWH Comparison','FontSize',20);

legend({'','','FRF Pier','', ...
        'Wave Gauges','','','','','','SWOT Measurements for 26 m Wave Buoy','SWOT Measurements for 17 m Wave Buoy', ...
        'SWOT Measurements for 8 m Wave Gauge','SWOT Measurements for 7 m Wave Gauge'}, ...
       'NumColumns',1,'FontSize',11);



%% =========================================================
%  One big scatter: all instruments together
% =========================================================
figure(); hold on

% Use distinct markers but keep 063 black, 354 green
markers = {'o','^','s','d'};
for ii = 1:4
    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};

    scatter(xData(idx063_LR2km), yData(idx063_LR2km), 80, 'k', markers{ii}, 'filled');
    scatter(xData(idx354_LR2km), yData(idx354_LR2km), 80, 'g', markers{ii}, 'filled');
end

plot(0:1:4,0:1:4,'k');
xlim([0 4]); ylim([0 4]); axis square; grid on; box on
xlabel('In-situ SWH [m]', 'FontSize', 18);
ylabel('SWOT SWH [m]', 'FontSize', 18);
title('SWOT SWH vs In-situ SWH (All Instruments)','FontSize',18);

lgd = legend({ ...
    '26 m - Pass 063','26 m - Pass 354', ...
    '17 m - Pass 063','17 m - Pass 354', ...
    '8 m - Pass 063','8 m - Pass 354', ...
    '600 m - Pass 063','600 m - Pass 354'}, ...
    'Location','best');
fontsize(lgd, 12,"points");

%% =========================================================
%  4-panel: SWOT vs in-situ SWH colored by SWH (per instrument)
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');
xL = [0 4]; yL = [0 4];

for ii = 1:4
    nexttile; hold on
    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};

    scatter(xData, yData, 100, xData, 'filled'); % color by in-situ SWH
    plot(0:1:4,0:1:4,'k');
    xlim(xL); ylim(yL); axis square
    grid on; box on

    title(instrumentLabels{ii});

    if ii > 2
        xlabel('In-situ SWH [m]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWOT SWH [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

cb = colorbar;
cb.Layout.Tile = 'east';
ylabel(cb, 'Significant Wave Height [m]', 'FontSize', 16);
colormap(flipud(hot));

%% =========================================================
%  SWH residual vs SWH (per instrument, 4-panel)
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');

xL = [0 4];
yL = [0 3];   % allow larger SWH residuals

for ii = 1:4
    nexttile; hold on

    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    res   = abs(yData - xData);

    p1 = scatter(xData, res, 100, 'k','filled');
    p2 = scatter(xData(idx354_LR2km), res(idx354_LR2km), 100, 'g','filled');

    xlim(xL); ylim(yL); axis square; grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('In-situ SWH [m]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWH residual [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

lgd = legend([p1 p2], {'Pass #063','Pass #354'}, 'Location','northoutside');
fontsize(lgd, 14,"points");

%% =========================================================
%  4-panel: SWOT vs in-situ SWH colored by Tp
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');
xL = [0 4]; yL = [0 4];

for ii = 1:4
    nexttile; hold on
    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    Tp    = instrumentTp_byTime_LR2km.(instrumentNames{ii});

    scatter(xData, yData, 100, Tp,'filled');
    plot(0:1:4,0:1:4,'k');
    xlim(xL); ylim(yL); axis square
    grid on; box on

    title(instrumentLabels{ii});

    if ii > 2
        xlabel('In-situ SWH [m]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWOT SWH [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

cb = colorbar;
cb.Layout.Tile = 'east';
ylabel(cb, 'Peak Wave Period [s]', 'FontSize', 16);
colormap(flipud(hot));



%% =========================================================
%  SWH residual vs Tp (4-panel)
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');

yL = [0 3];
xL = [2 16];

for ii = 1:4
    nexttile; hold on

    Tp    = instrumentTp_byTime_LR2km.(instrumentNames{ii});
    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    res   = abs(yData - xData);

    p1 = scatter(Tp, res, 100, 'k','filled');
    p2 = scatter(Tp(idx354_LR2km), res(idx354_LR2km), 100, 'g','filled');

    xlim(xL); ylim(yL); axis square; grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('Peak Period [s]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWH residual [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

lgd = legend([p1 p2], {'Pass #063','Pass #354'}, 'Location','northoutside');
fontsize(lgd,14,"points");

%% =========================================================
%  4-panel: SWOT vs in-situ SWH colored by Wavelength
% =========================================================

scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');
xL = [0 4]; yL = [0 4];

for ii = 1:4
    nexttile; hold on

    % --- Extract in-situ & SWOT SWH
    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};

    % --- Get Tp and water depth for this instrument
    Tp = instrumentTp_byTime_LR2km.(instrumentNames{ii});
    h  = instrumentWaterDepth_byTime_LR2km.(instrumentNames{ii});

    % --- Compute wavelength from dispersion relation
    L = computeWavelength(Tp, h);

    % --- Plot
    scatter(xData, yData, 100, L, 'filled');
    plot(0:4,0:4,'k');

    xlim(xL); ylim(yL); axis square
    grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('In-situ SWH [m]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWOT SWH [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

cb = colorbar;
cb.Layout.Tile = 'east';
ylabel(cb, 'Wavelength [m]', 'FontSize', 16);

colormap(flipud(hot));

%% =========================================================
%  SWH residual vs Wave length (4-panel)
% =========================================================

scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');

yL = [-2 3];        % signed residual range (adjust if needed)
xL = [20 300];      % wavelength range (adjust if needed)

for ii = 1:4
    nexttile; hold on

    % --- Inputs
    Tp    = instrumentTp_byTime_LR2km.(instrumentNames{ii});
    h     = instrumentWaterDepth_byTime_LR2km.(instrumentNames{ii});
    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};

    % --- Wavelength
    L = computeWavelength(Tp, h);

    % --- Signed residual (NO abs)
    res = yData - xData;

    % --- Scatter plot by pass #
    p1 = scatter(L, res, 100, 'k','filled');                     % pass 063
    p2 = scatter(L(idx354_LR2km), res(idx354_LR2km), ...
                 100, 'g','filled');                            % pass 354

    % --- Plot formatting
    yline(0,'k--','LineWidth',1.2);
    xlim(xL); ylim(yL); axis square
    grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('Wavelength [m]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('Residual = SWOT - In-situ SWH [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

% Shared legend
lgd = legend([p1 p2], {'Pass #063','Pass #354'}, 'Location','northoutside');
fontsize(lgd,14,"points");

set(lgd,...
    'Position',[0.0908333345161129 0.892667994598646 0.14583333057041 0.0521350531971088],...
    'FontSize',14);

%% =========================================================
%  SWOT vs in-situ SWH colored by Peak Direction
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');
xL = [0 4]; yL = [0 4];


for ii =  1:4
    nexttile; hold on
    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    dirP  = instrumentWavePeakDir_byTime_LR2km.(instrumentNames{ii});

    scatter(xData, yData, 100, dirP,'filled');
    plot(0:1:4,0:1:4,'k');
    xlim(xL); ylim(yL); axis square
    grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('In-situ SWH [m]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWOT SWH [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

cb = colorbar;
cb.Layout.Tile = 'east';
ylabel(cb, 'Peak Wave Direction [deg from North]', 'FontSize', 16);
colormap(flipud(hot));   % set global colormap first

%% =========================================================
%  SWH residual vs Peak Direction (4-panel)
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');

yL = [0 3];
xL = [0 150];

for ii = 1:4
    nexttile; hold on
    dirP  = instrumentWavePeakDir_byTime_LR2km.(instrumentNames{ii});
    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    res   = abs(yData - xData);

    p1 = scatter(dirP, res, 100, 'k','filled');
    p2 = scatter(dirP(idx354_LR2km), res(idx354_LR2km), 100, 'g','filled');

    xlim(xL); ylim(yL); axis square; grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('Peak Wave Direction [deg from North]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWH residual [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

lgd = legend([p1 p2], {'Pass #063','Pass #354'}, 'Location','northoutside');
fontsize(lgd,14,"points");

%% =========================================================
%  SWOT vs in-situ SWH colored by Mean Direction
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');
xL = [0 4]; yL = [0 4];

for ii = 1:4
    nexttile; hold on
    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    dirM  = instrumentWaveMeanDir_byTime_LR2km.(instrumentNames{ii});

    scatter(xData, yData, 100, dirM,'filled');
    plot(0:1:4,0:1:4,'k');
    xlim(xL); ylim(yL); axis square
    grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('In-situ SWH [m]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWOT SWH [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

cb = colorbar;
cb.Layout.Tile = 'east';
ylabel(cb, 'Mean Wave Direction [deg from North]', 'FontSize', 16);
colormap(flipud(hot));

%% =========================================================
%  SWH residual vs Mean Direction (4-panel)
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');

yL = [0 3];
xL = [0 150];

for ii = 1:4
    nexttile; hold on
    dirM  = instrumentWaveMeanDir_byTime_LR2km.(instrumentNames{ii});
    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    res   = abs(yData - xData);

    p1 = scatter(dirM, res, 100, 'k','filled');
    p2 = scatter(dirM(idx354_LR2km), res(idx354_LR2km), 100, 'g','filled');

    xlim(xL); ylim(yL); axis square; grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('Mean Wave Direction [deg from North]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWH residual [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

lgd = legend([p1 p2], {'Pass #063','Pass #354'}, 'Location','northoutside');
fontsize(lgd,14,"points");

%% =========================================================
%  SWOT vs in-situ SWH colored by (Peak - Mean Direction)
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');
xL = [0 4]; yL = [0 4];

for ii = 1:4
    nexttile; hold on
    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};

    dirP  = instrumentWavePeakDir_byTime_LR2km.(instrumentNames{ii});
    dirM  = instrumentWaveMeanDir_byTime_LR2km.(instrumentNames{ii});
    dPM   = dirP - dirM;

    scatter(xData, yData, 100, dPM,'filled');
    plot(0:1:4,0:1:4,'k');
    xlim(xL); ylim(yL); axis square
    grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('In-situ SWH [m]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWOT SWH [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

% Force identical color scaling
axs = findall(gcf,'Type','axes');
set(axs,'CLim',[-20 20]);

cb = colorbar;
cb.Layout.Tile = 'east';
ylabel(cb, 'Peak - Mean Wave Direction [deg]', 'FontSize', 16);
colormap(flipud(hot));

%% =========================================================
%  SWH residual vs (Peak - Mean Direction) (4-panel)
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');

yL = [0 3];
xL = [-70 60];

for ii = 1:4
    nexttile; hold on

    dirP  = instrumentWavePeakDir_byTime_LR2km.(instrumentNames{ii});
    dirM  = instrumentWaveMeanDir_byTime_LR2km.(instrumentNames{ii});
    dPM   = dirP - dirM;

    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    res   = abs(yData - xData);

    p1 = scatter(dPM, res, 100, 'k','filled');
    p2 = scatter(dPM(idx354_LR2km), res(idx354_LR2km), 100, 'g','filled');

    xlim(xL); ylim(yL); axis square; grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('Peak - Mean Direction [deg]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWH residual [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

lgd = legend([p1 p2], {'Pass #063','Pass #354'}, 'Location','northoutside');
fontsize(lgd,14,"points");

%% =========================================================
%  SWOT heading vs Peak direction (relative angle) - colored
% =========================================================
track063 = 12.1;
track354 = 167.8;

scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');
xL = [0 4]; yL = [0 4];

for ii = 1:4
    nexttile; hold on

    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    dirP  = instrumentWavePeakDir_byTime_LR2km.(instrumentNames{ii});

    rel063 = dirP(idx063_LR2km) - track063;
    rel354 = dirP(idx354_LR2km) - track354;

    scatter(xData(idx063_LR2km), yData(idx063_LR2km), 100, rel063, 'filled');
    scatter(xData(idx354_LR2km), yData(idx354_LR2km), 100, rel354, 'd','filled');

    plot(0:1:4,0:1:4,'k');
    xlim(xL); ylim(yL); axis square
    grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('In-situ SWH [m]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWOT SWH [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

axs = findall(gcf,'Type','axes');
set(axs,'CLim',[-150 150]);

cb = colorbar;
cb.Layout.Tile = 'east';
ylabel(cb, 'Peak wave dir. relative to SWOT heading [deg]', 'FontSize', 16);
colormap(flipud(hot));

% Legend for pass markers
h1 = scatter(nan,nan,40,'filled','MarkerFaceColor','k');
h2 = scatter(nan,nan,40,'d','filled','MarkerFaceColor','k','MarkerEdgeColor','k');
legend1 = legend([h1 h2], {'Pass #063','Pass #354'}, 'Location','northoutside');
fontsize(legend1,14,"points");

%% =========================================================
%  SWH residual vs relative angle (Peak dir - heading)
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');

yL = [0 3];
xL = [-150 150];

for ii = 1:4
    nexttile; hold on

    dirP  = instrumentWavePeakDir_byTime_LR2km.(instrumentNames{ii});
    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    res   = abs(yData - xData);

    rel063_full = dirP - track063;
    rel354_full = dirP - track354;

    p1 = scatter(rel063_full, res, 100, 'k','filled');
    p2 = scatter(rel354_full(idx354_LR2km), res(idx354_LR2km), 100, 'g','filled');

    xlim(xL); ylim(yL); axis square; grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('Peak wave dir. relative to SWOT heading [deg]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWH residual [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

lgd = legend([p1 p2], {'Pass #063','Pass #354'}, 'Location','northoutside');
fontsize(lgd,14,"points");

%% =========================================================
%  Alignment metric: SWOT SWH vs In-situ SWH (colored by alignment)
%  |sin(relative angle)|, per instrument (2x2)
% =========================================================
track063 = 12.1;
track354 = 167.8;

scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');
xL = [0 4]; 
yL = [0 4];

alignment_all = cell(1,4);

for ii = 1:4
    nexttile; hold on

    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};

    % Wave directions at this instrument
    dirs = instrumentWavePeakDir_byTime_LR2km.(instrumentNames{ii});
    alignMetric = nan(size(dirs));

    % Relative angle metric for each pass
    theta063 = mod(dirs(idx063_LR2km) - track063 + 180,360) - 180;
    theta354 = mod(dirs(idx354_LR2km) - track354 + 180,360) - 180;

    alignMetric(idx063_LR2km) = abs(sind(theta063));
    alignMetric(idx354_LR2km) = abs(sind(theta354));

    alignment_all{ii} = alignMetric;

    % Color by alignment metric
    scatter(xData(idx063_LR2km), yData(idx063_LR2km), 100, alignMetric(idx063_LR2km), 'filled');
    scatter(xData(idx354_LR2km), yData(idx354_LR2km), 100, alignMetric(idx354_LR2km), 'd','filled');

    plot(0:1:4,0:1:4,'k');
    xlim(xL); ylim(yL); axis square
    grid on; box on
    title(instrumentLabels{ii},'FontSize',18);

    if ii > 2
        xlabel('In-situ SWH [m]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWOT SWH [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

cb = colorbar;
cb.Layout.Tile = 'east';
ylabel(cb, '|sin(relative angle)|  (0 = parallel, 1 = perpendicular)', 'FontSize', 16);
clim([0 1]);
colormap(flipud(hot));

% Dummy points for legend (marker shapes only)
h1 = scatter(nan, nan, 80, 'o', 'filled', 'MarkerFaceColor','k');
h2 = scatter(nan, nan, 80, 'd', 'filled', 'MarkerFaceColor','k','MarkerEdgeColor','k');
lgd = legend([h1 h2], {'Pass #063','Pass #354'}, FontSize=14);
set(lgd,...
    'Position',[0.081 0.90 0.16 0.06],...
    'FontSize',14);

%% =========================================================
%  SWH residual vs alignment metric (per instrument)
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');

xL = [0 1];
yL = [0 3];

for ii = 1:4
    nexttile; hold on

    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    res   = abs(yData - xData);
    alignMetric = alignment_all{ii};

    p1 = scatter(alignMetric(idx063_LR2km), res(idx063_LR2km), 100, 'k','filled');
    p2 = scatter(alignMetric(idx354_LR2km), res(idx354_LR2km), 100, 'g','filled');

    xlim(xL); ylim(yL); axis square
    grid on; box on
    title(instrumentLabels{ii},'FontSize',18);

    if ii > 2
        xlabel('Relative Angle Alignment  |sin(\theta_{rel})|', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWH residual [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

lgd = legend([p1 p2], {'Pass #063','Pass #354'}, 'Location','northoutside');
fontsize(lgd, 14,"points");

%% =========================================================
%  Normalized tidal stage (from water depth) – shading
%  SWOT SWH vs In-situ SWH, colored by tidal stage
% =========================================================
SmallArrays = {convertedTimeArray_250m_LR_L2_SSH_Expert};

% Initialize a cell array to store indices
ClosestIndices = cell(size(SmallArrays));

% Find closest indices for each small array
    indices = zeros(size(SmallArrays{1,1}));
    for i = 1:length(SmallArrays{1,1})
        [~, indices(i)] = min(abs(noaaTideData_all_navd88.time_dateTime - SmallArrays{1,1}(i))); % Find closest index
    end
    ClosestIndices = indices; % Store indices in the cell array


tidalMin=min(noaaTideData_all_navd88.measured(ClosestIndices));
tidalMax=max(noaaTideData_all_navd88.measured(ClosestIndices));
tidalStage2km = (noaaTideData_all_navd88.measured(ClosestIndices) - tidalMin) / (tidalMax - tidalMin);

noramlizedTidalStage_all = tidalStage2km;


scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');
xL = [0 4]; 
yL = [0 4];

for ii = 1:4
    nexttile; hold on

    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};

    scatter(xData, yData, 100, noramlizedTidalStage_all, 'filled');
    plot(0:1:4,0:1:4,'k');

    xlim(xL); ylim(yL); axis square
    grid on; box on
    title(instrumentLabels{ii},'FontSize',18);

    if ii > 2
        xlabel('In-situ SWH [m]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWOT SWH [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

cb = colorbar;
cb.Layout.Tile = 'east';
ylabel(cb, 'Normalized Tidal Stage (from depth)', 'FontSize', 16);
colormap(flipud(hot));

%% =========================================================
%  SWH residual vs tidal stage
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');

xL = [0 1];
yL = [0 3];

for ii = 1:4
    nexttile; hold on

    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    res   = abs(yData - xData);

    p1 = scatter(noramlizedTidalStage_all(idx063_LR2km), res(idx063_LR2km), 100, 'k','filled');
    p2 = scatter(noramlizedTidalStage_all(idx354_LR2km), res(idx354_LR2km), 100, 'g','filled');

    xlim(xL); ylim(yL); axis square
    grid on; box on
    title(instrumentLabels{ii},'FontSize',18);

    if ii > 2
        xlabel('Normalized Tidal Stage', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWH residual [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

lgd = legend([p1 p2], {'Pass #063','Pass #354'}, 'Location','northoutside');
fontsize(lgd, 14,"points");

%% =========================================================
%  Current speed shading – separate 4-panel
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');
xL = [0 4]; 
yL = [0 4];

for ii = 1:4
    nexttile; hold on
    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    cData = instrumentCurrentSpeed_byTime_LR2km.sig940_600;

    scatter(xData, yData, 100, cData, 'filled');
    plot(0:1:4,0:1:4,'k');
    xlim(xL); ylim(yL); axis square
    grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('In-situ SWH [m]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWOT SWH [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

cb = colorbar;
cb.Layout.Tile = 'east';
ylabel(cb, 'Current Speed [m/s]', 'FontSize', 16);
colormap(flipud(hot));

%% =========================================================
%  Current speed shading – all instruments in one plot
% =========================================================
figure(); hold on

markers = {'o','^','s','d'};

for ii = 1:4
    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    cData = instrumentCurrentSpeed_byTime_LR2km.sig940_600;

    scatter(xData, yData, 100, cData, markers{ii}, 'filled');
end

plot(0:1:4,0:1:4,'k');
xlim([0 4]); ylim([0 4]);
ylabel('SWOT SWH [m]',FontSize=16);
xlabel('In-situ SWH [m]',FontSize=16);
axis square
grid on
cb = colorbar(); 
ylabel(cb,'Current Speed [m/s]','FontSize',16,'Rotation',90);
title('SWOT SWH Accuracy Colored by Current Speed');
colormap(flipud(hot))
box on

% Dummy points for legend
h1 = scatter(nan, nan, 40, 'o', 'filled', 'MarkerFaceColor','k');
h2 = scatter(nan, nan, 40, '^', 'filled', 'MarkerFaceColor','k','MarkerEdgeColor','k');
h3 = scatter(nan, nan, 40, 's', 'filled', 'MarkerFaceColor','k','MarkerEdgeColor','k');
h4 = scatter(nan, nan, 40, 'd', 'filled', 'MarkerFaceColor','k','MarkerEdgeColor','k');
legend([h1 h2 h3 h4], instrumentLabels , FontSize=14);

%% =========================================================
%  SWH residual vs current speed (per instrument)
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');

xL = [0 1];   % adjust if your currents exceed 1 m/s
yL = [0 3];

for ii = 1:4
    nexttile; hold on

    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    res   = abs(yData - xData);
    cData = instrumentCurrentSpeed_byTime_LR2km.sig940_600;

    p1 = scatter(cData(idx063_LR2km), res(idx063_LR2km), 100, 'k','filled');
    p2 = scatter(cData(idx354_LR2km), res(idx354_LR2km), 100, 'g','filled');

    xlim(xL); ylim(yL); axis square
    grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('Current Speed [m/s]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWH residual [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

lgd = legend([p1 p2], {'Pass #063','Pass #354'}, 'Location','northoutside');
fontsize(lgd, 14,"points");

%% =========================================================
%  Current direction shading – separate 4-panel
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');
xL = [0 4]; 
yL = [0 4];

for ii = 1:4
    nexttile; hold on
    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    cData = instrumentCurrentDirection_byTime_LR2km.sig940_600;

    scatter(xData, yData, 100, cData, 'filled');
    plot(0:1:4,0:1:4,'k');
    xlim(xL); ylim(yL); axis square
    grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('In-situ SWH [m]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWOT SWH [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

cb = colorbar;
cb.Layout.Tile = 'east';
ylabel(cb, 'Current Direction [deg from North]', 'FontSize', 16);
colormap(flipud(hot));

%% =========================================================
%  SWH residual vs current direction
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');

xL = [0 360];
yL = [0 3];

for ii = 1:4
    nexttile; hold on

    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    res   = abs(yData - xData);
    cDir  = instrumentCurrentDirection_byTime_LR2km.sig940_600;

    p1 = scatter(cDir(idx063_LR2km), res(idx063_LR2km), 100, 'k','filled');
    p2 = scatter(cDir(idx354_LR2km), res(idx354_LR2km), 100, 'g','filled');

    xlim(xL); ylim(yL); axis square
    grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('Current Direction [deg from North]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWH residual [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

lgd = legend([p1 p2], {'Pass #063','Pass #354'}, 'Location','northoutside');
fontsize(lgd, 14,"points");

%% =========================================================
%  Wind speed shading – separate 4-panel
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');
xL = [0 4]; 
yL = [0 4];

for ii = 1:4
    nexttile; hold on
    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    cData = instrumentWindSpeed_byTime_LR2km;

    scatter(xData, yData, 100, cData, 'filled');
    plot(0:1:4,0:1:4,'k');
    xlim(xL); ylim(yL); axis square
    grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('In-situ SWH [m]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWOT SWH [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

cb = colorbar;
cb.Layout.Tile = 'east';
ylabel(cb, 'Wind Speed [m/s]', 'FontSize', 16);
colormap(flipud(hot));

%% =========================================================
%  SWH residual vs wind speed
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');

xL = [0 12];
yL = [0 3];

for ii = 1:4
    nexttile; hold on

    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    res   = abs(yData - xData);
    wSpd  = instrumentWindSpeed_byTime_LR2km;

    p1 = scatter(wSpd(idx063_LR2km), res(idx063_LR2km), 100, 'k','filled');
    p2 = scatter(wSpd(idx354_LR2km), res(idx354_LR2km), 100, 'g','filled');

    xlim(xL); ylim(yL); axis square
    grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('Wind Speed [m/s]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWH residual [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

lgd = legend([p1 p2], {'Pass #063','Pass #354'}, 'Location','northoutside');
fontsize(lgd, 14,"points");

%% =========================================================
%  Wind direction shading – separate 4-panel
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');
xL = [0 4]; 
yL = [0 4];

for ii = 1:4
    nexttile; hold on
    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    cData = instrumentWindDirection_byTime_LR2km;

    scatter(xData, yData, 100, cData, 'filled');
    plot(0:1:4,0:1:4,'k');
    xlim(xL); ylim(yL); axis square
    grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('In-situ SWH [m]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWOT SWH [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

cb = colorbar;
cb.Layout.Tile = 'east';
ylabel(cb, 'Wind Direction [deg from North]', 'FontSize', 16);
colormap(flipud(hot));

%% =========================================================
%  SWH residual vs wind direction
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');

xL = [0 360];
yL = [0 3];

for ii = 1:4
    nexttile; hold on

    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    res   = abs(yData - xData);
    wDir  = instrumentWindDirection_byTime_LR2km;

    p1 = scatter(wDir(idx063_LR2km), res(idx063_LR2km), 100, 'k','filled');
    p2 = scatter(wDir(idx354_LR2km), res(idx354_LR2km), 100, 'g','filled');

    xlim(xL); ylim(yL); axis square
    grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('Wind Direction [deg from North]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWH residual [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

lgd = legend([p1 p2], {'Pass #063','Pass #354'}, 'Location','northoutside');
fontsize(lgd, 14,"points");

%% =========================================================
%  Version shading (C vs D) – SWOT SWH vs In-situ SWH
% =========================================================
load('versionVariables.mat');   % expects versionFlag_LR2km

scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');
xL = [0 4];
yL = [0 4];

versionCColor = 'r';
versionDColor = 'b';

for ii = 1:4
    nexttile; hold on

    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};

    scatter(xData(~versionFlag_LR2km), yData(~versionFlag_LR2km), 100, versionCColor,'filled');
    scatter(xData(versionFlag_LR2km),  yData(versionFlag_LR2km),  100, versionDColor,'filled');

    plot(0:1:4,0:1:4,'k');
    xlim(xL); ylim(yL); axis square
    grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('In-situ SWH [m]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWOT SWH [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

xlabel(t, 'In-situ SWH [m]', 'FontSize', 16);
ylabel(t, 'SWOT SWH [m]', 'FontSize', 16);

lgd = legend({'Version C','Version D'}, 'FontSize',14,'Location','northoutside');

%% =========================================================
%  SWH residual vs version (C vs D)
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');
yL = [0 3];

for ii = 1:4
    nexttile; hold on

    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    res   = abs(yData - xData);

    resC = res(~versionFlag_LR2km);
    resD = res(versionFlag_LR2km);

    scatter(ones(numel(resC),1), resC, 100, versionCColor,'filled');
    scatter(2*ones(numel(resD),1), resD, 100, versionDColor,'filled');

    ylim(yL); xlim([0.5 2.5]); axis square
    grid on; box on
    title(instrumentLabels{ii});

    set(gca,'XTick',[1 2],'XTickLabel',{'C','D'},'FontSize',14);
end

xlabel(t, 'Version', 'FontSize', 16);
ylabel(t, 'SWH residual [m]', 'FontSize', 16);
legend({'Version C','Version D'}, 'FontSize',14,'Location','northoutside');

%% =========================================================
%  Rising vs falling tide (using depth as proxy) – shading
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');

xL = [0 4];
yL = [0 4];

% --- Define colors ---
risingColor = [0 0.4470 0.7410]; % blue for rising tide
fallingColor = [0.8500 0.3250 0.0980]; % orange for falling tide

% --- Function to get rising/falling tide colors ---
getTideColors = @(wse) arrayfun(@(i) ...
    risingColor*(i>1 & wse(i)-wse(i-1)>=0) + fallingColor*(i>1 & wse(i)-wse(i-1)<0), ...
    1:length(wse),'UniformOutput',false);

% Compute rising/falling indices
wse=noaaTideData_all_navd88.measured(ClosestIndices);
deltaWSE = [0; diff(wse)]; % positive -> rising, negative -> falling
colors = zeros(length(wse),3);
colors(deltaWSE>=0,:) = repmat(risingColor,sum(deltaWSE>=0),1);
colors(deltaWSE<0,:) = repmat(fallingColor,sum(deltaWSE<0),1);


for ii = 1:4
    nexttile; hold on

    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    % depth = instrumentWaterDepth_byTime_LR2km.(instrumentNames{ii});

    scatter(xData, yData, 100, colors,'filled');

    plot(0:1:4,0:1:4,'k');
    xlim(xL); ylim(yL); axis square
    grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('In-situ SWH [m]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWOT SWH [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

xlabel(t, 'In-situ SWH [m]', 'FontSize', 16);
ylabel(t, 'SWOT SWH [m]', 'FontSize', 16);

h1 = scatter(nan, nan, 40, risingColor,'filled');
h2 = scatter(nan, nan, 40, fallingColor,'filled');
legend([h1 h2], {'Rising Tide','Falling Tide'}, 'FontSize',14,'Location','northoutside');

%% =========================================================
%  SWH residual vs rising / falling tide
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');

yL = [0 3];



for ii = 1:4
    nexttile; hold on

    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
     depth = instrumentWaterDepth_byTime_LR2km.(instrumentNames{ii});

    deltaD = [0; diff(depth)];
    res    = abs(yData - xData);

    resRise = res(deltaD>=0);
    resFall = res(deltaD<0);

    scatter(ones(numel(resRise),1), resRise, 100, risingColor,'filled');
    scatter(2*ones(numel(resFall),1), resFall, 100, fallingColor,'filled');

    ylim(yL); xlim([0.5 2.5]); axis square
    grid on; box on
    title(instrumentLabels{ii});

    set(gca,'XTick',[1 2],'XTickLabel',{'Rising','Falling'},'FontSize',14);
end

xlabel(t, 'Tide Phase', 'FontSize', 16);
ylabel(t, 'SWH residual [m]', 'FontSize', 16);
legend({'Rising Tide','Falling Tide'}, 'FontSize',14,'Location','northoutside');

%% =========================================================
%  4-panel: SWOT vs in-situ SWH (one panel per instrument)- mean removed
%  for 7&8 meter sensors
%  for 
% =========================================================
scr = get(0,'ScreenSize');   % [left bottom width height]
figWidth  = scr(3) / 2;      
figHeight = scr(4);          
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');

for ii = 1:4
    nexttile; hold on

    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};

    % Pass 063 (black) and 354 (green), same style as your single plots
    scatter(xData(idx063_LR2km)-mean(xData(idx063_LR2km),'omitnan'), yData(idx063_LR2km)-mean(yData(idx063_LR2km),'omitnan'), 100, 'k', 'filled');
    scatter(xData(idx354_LR2km)-mean(xData(idx354_LR2km),'omitnan'), yData(idx354_LR2km)-mean(yData(idx354_LR2km),'omitnan'), 100, 'g', 'filled');

    plot(-1.5:1:4, -1.5:1:4, 'k');

    xlim([-1.5 2.5]); ylim([-1.5 2.5]); axis square; grid on; box on
    title(['SWOT SWH vs In-situ - ' instrumentLabels{ii}], 'FontSize', 18);

    if ii > 2
        xlabel('In-situ SWH [m]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWOT SWH [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);

    metricsStr = printMetricsBox(xData,yData,idx063_LR2km,idx354_LR2km,dist_all{ii});

    % Metrics box (normalized position)
    % text(0.03, 0.97, metricsStr, ...
    %     'Units','normalized', ...
    %     'VerticalAlignment','top', ...
    %     'FontSize', 14, ...
    %     'BackgroundColor','w', ...
    %     'EdgeColor','k');
end

lgd = legend({'Pass #063','Pass #354'},'Location','best');
set(lgd,...
    'Position',[0.0830468762821207 0.900554453130985 0.14583333057041 0.0521350531971088],...
    'FontSize',14);
fontsize(lgd, 14,"points");

%% =========================================================
%  4-panel: SWOT vs in-situ SWH colored by Steepness
% =========================================================

scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');
xL = [0 4]; yL = [0 4];

for ii = 1:4
    nexttile; hold on

    % --- Extract in-situ & SWOT SWH
    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};

    % --- Get Tp and water depth for this instrument
    Tp = instrumentTp_byTime_LR2km.(instrumentNames{ii});
    h  = instrumentWaterDepth_byTime_LR2km.(instrumentNames{ii});

    % --- Compute wavelength from dispersion relation
    L = computeWavelength(Tp, h);

    % --- Plot
    scatter(xData, yData, 100, xData./L, 'filled');
    plot(0:4,0:4,'k');

    xlim(xL); ylim(yL); axis square
    grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('In-situ SWH [m]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWOT SWH [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

cb = colorbar;
cb.Layout.Tile = 'east';
ylabel(cb, 'Wave Steepness [-]', 'FontSize', 16);

colormap(flipud(hot));

%% =========================================================
%  SWH residual vs Wave steepness (4-panel)
% =========================================================

scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');

yL = [-2 3];        % signed residual range (adjust if needed)
xL = [0 0.05];      % wavelength range (adjust if needed)

for ii = 1:4
    nexttile; hold on

    % --- Inputs
    Tp    = instrumentTp_byTime_LR2km.(instrumentNames{ii});
    h     = instrumentWaterDepth_byTime_LR2km.(instrumentNames{ii});
    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};

    % --- Wavelength
    L = computeWavelength(Tp, h);

    % --- Signed residual (NO abs)
    res = yData - xData;

    % --- Steepness
    steepness= xData./L;

    % --- Scatter plot by pass #
    p1 = scatter(steepness, res, 100, 'k','filled');                     % pass 063
    p2 = scatter(steepness(idx354_LR2km), res(idx354_LR2km), ...
                 100, 'g','filled');                            % pass 354

    % --- Plot formatting
    yline(0,'k--','LineWidth',1.2);
    xlim(xL); ylim(yL); axis square
    grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('Wave Steepness [-]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('Residual = SWOT - In-situ SWH  [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

% Shared legend
lgd = legend([p1 p2], {'Pass #063','Pass #354'}, 'Location','northoutside');
fontsize(lgd,14,"points");

set(lgd,...
    'Position',[0.0908333345161129 0.892667994598646 0.14583333057041 0.0521350531971088],...
    'FontSize',14);

%% =========================================================
%  4-panel: SWOT vs in-situ SWH colored by Distance to coast
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


scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');
xL = [0 4]; yL = [0 4];

for ii = 1:4
    ax = nexttile; hold on;

    % --- Extract in-situ & SWOT SWH
    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};
    cData = distCoast_all{ii};

    % --- Plot
    scatter(xData, yData, 100, cData, 'filled');
    plot(0:4,0:4, 'k');

    xlim(xL); ylim(yL); axis square
    grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('In-situ SWH [m]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('SWOT SWH [m]', 'FontSize', 16);
    end

    % --- Set per-panel color limits
    vmin = min(cData(:));
    vmax = max(cData(:));
    caxis([vmin-100 vmax]);

    set(gca,'FontSize',14);

    % --- Add per-panel colorbar
    cb = colorbar(ax);
    ylabel(cb, 'Distance to Coast [m]', 'FontSize', 14);
end

colormap(flipud(hot));


%% =========================================================
%  SWH residual vs Distance to coast (4-panel)
% =========================================================
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);
figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');

yL = [-2 3];  % signed residual range (keep fixed)

for ii = 1:4
    nexttile; hold on

    % --- Get in-situ & SWOT for this panel
    xData = instrumentSWH_byTime_LR2km.(instrumentNames{ii});
    yData = SWH_swot_all{ii};

    % --- Signed residual
    res = yData - xData;

    % --- Distance to coast
    cData = distCoast_all{ii};

    % --- Pass masks (must match data size)
    mask063 = idx063_LR2km;
    mask354 = idx354_LR2km;

    % --- Scatter plots
    p1 = scatter(cData(mask063), res(mask063), 100, 'k', 'filled');
    p2 = scatter(cData(mask354), res(mask354), 100, 'g', 'filled');

    % --- Per-panel x-range ----------------------------------------
    xmin = min(cData);
    xmax = max(cData);
    dx   = 0.1 * (xmax - xmin);     % 10% padding
    xlim([xmin - dx, xmax + dx]);
    % --------------------------------------------------------------

    ylim(yL);
    yline(0,'k--','LineWidth',1.2);
    axis square
    grid on; box on
    title(instrumentLabels{ii});

    if ii > 2
        xlabel('Distance to Coast [m]', 'FontSize', 16);
    end
    if ismember(ii,[1 3])
        ylabel('Residual = SWOT - In-situ SWH  [m]', 'FontSize', 16);
    end

    set(gca,'FontSize',14);
end

% Shared legend
lgd = legend([p1 p2], {'Pass #063','Pass #354'}, 'Location','northoutside');
fontsize(lgd,14,"points");

set(lgd,...
    'Position',[0.0908333345161129 0.892667994598646 0.14583333057041 0.0521350531971088],...
    'FontSize',14);

figure; hold on;

% --- Define instrument colors for visibility
instColors = lines(4);    % or manually define

% --- Optional: markers for each instrument
markers = {'o','s','d','^'};

for ii = 1:4
    
    % Get x/y
    xData = distCoast_all{ii};
    yData = SWH_swot_all{ii} - instrumentSWH_byTime_LR2km.(instrumentNames{ii});

    % Plot all passes for this instrument
    scatter(xData, yData, 80, instColors(ii,:), markers{ii}, 'filled', ...
        'DisplayName', instrumentLabels{ii});
end

% --- Formatting ---
yline(0,'k--','LineWidth',1.4);

xlabel('Distance to Coast [m]', 'FontSize', 18);
ylabel('Residual = SWOT − In-situ SWH [m]', 'FontSize', 18);
grid on; box on;
set(gca,'FontSize',16);

title('SWH Residual vs Distance to Coast (All Instruments)', 'FontSize', 20);

legend('Location','bestoutside','FontSize',15);
axis tight;


%% Save all variables 
save('D:\SWOT\Analysis\Paper Analysis\SWH\swhAccuracyAnalysis.mat');
