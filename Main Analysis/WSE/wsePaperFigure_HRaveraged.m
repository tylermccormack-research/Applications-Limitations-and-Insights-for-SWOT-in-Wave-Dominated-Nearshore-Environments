clear; clc

%% Averaging settings
% avgRadius_100m = 500;   % meters (e.g., ~3 pixels)
% avgRadius_pixc = 500;   % can tune separately
%% Averaging settings (ellipse)
% Dimensions from sensitivity study ( hrAverageRegionSenstiviity.m )
a_100m = 250;   % cross-shore semi-axis (m)
b_100m = 500;  % alongshore semi-axis (m)

a_pixc = 250;
b_pixc = 500;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load FRF water level data
% load('noaaTideData_all.mat');
load('noaaTideData_all_navd88.mat');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load SWOT data
% SWOT LR_L3_SSH_Expert_2km 
load('convertedTimeArray_L3_LR_SSH_2km.mat');
load('extractedSSH_L3_LR_SSH_2km.mat');

% SWOT LR_L2_SSH_Expert_2km
load('convertedTimeArray_250m_LR_L2_SSH_Expert.mat');
load('extractedSSH_250m_LR_L2_SSH_Expert.mat');

% SWOT HR_L2_Raster_100m
% load("extractedSWE_100HR.mat");
load("convertedTimeArray_100HR.mat");

% --- Compute spatially averaged SWE for HR 100m ---
load('100m_Processed.mat')
fieldNames = fieldnames(dataStruct);
numPasses = numel(fieldNames);

extractedSWE_100HR_avg = nan(numPasses,1);

% NOAA gauge
noaaLat=36.183639;
noaaLong=-75.74528;
[~,~,~,~,noaaY,noaaX] = frfCoord(noaaLong,noaaLat);

for t = 1:numPasses
    fieldName = fieldNames{t};
    
    x = dataStruct.(fieldName).FRF_X;
    y = dataStruct.(fieldName).FRF_Y;
    swe = dataStruct.(fieldName).Filtered_SWE_NAVD88_qualityFiltered;   % or SSH depending on your variable name
    
    % Distance from NOAA gauge
    % dist = sqrt((x - (noaaX+800)).^2 + (y - noaaY).^2);
    % 
    % Select nearby pixels
    % idx = dist <= avgRadius_100m;

    x0 = noaaX ;
    y0 = noaaY;

    ellipseVal = ((x - x0)./b_100m).^2 + ((y - y0)./a_100m).^2;
    idx = ellipseVal <= 1;
    
    if any(idx)
        extractedSWE_100HR_avg(t) = mean(swe(idx),'omitnan');
    end
end

% SWOT HR_L2_Pixel Cloud
% load("extractedSWE_pixelCloudHR_bigArea.mat");
load("convertedTimeArray_pixelCloudHR_bigArea.mat");

% --- Compute spatially averaged SWE for Pixel Cloud ---
load('pixelCloud_Processed_bigArea.mat')
fieldNames = fieldnames(dataStruct);
numPasses = numel(fieldNames);

extractedSWE_pixelCloudHR_avg = nan(numPasses,1);

for t = 1:numPasses
    fieldName = fieldNames{t};
    
    x = dataStruct.(fieldName).FRF_X;
    y = dataStruct.(fieldName).FRF_Y;
    swe = dataStruct.(fieldName).Filtered_SWE_NAVD88;
    
    % dist = sqrt((x - (noaaX+800)).^2 + (y - noaaY).^2);
    % idx = dist <= avgRadius_pixc;
    x0 = noaaX ;
    y0 = noaaY;

    ellipseVal = ((x - x0)./b_pixc).^2 + ((y - y0)./a_pixc).^2;
    idx = ellipseVal <= 1;

    if any(idx)
        extractedSWE_pixelCloudHR_avg(t) = mean(swe(idx),'omitnan');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load Processed SWOT data
load('2km_LR_L3_SSH_expert_Processed.mat');          % L3 2km
L3_2km = dataStruct;
load('250m_LR_L2_SSH_expert_Processed.mat'); % LR 2km
LR2km = dataStruct;
load('100m_Processed.mat');                  % HR 100m
HR100m = dataStruct;
load('pixelCloud_Processed_bigArea.mat');            % HR Pixel cloud
HRpixc = dataStruct;
clear vars- dataStruct

% --- Store pixel counts for each pass ---
numPix_100m = nan(numel(fieldnames(HR100m)),1);
numPix_pixc = nan(numel(fieldnames(HRpixc)),1);

% --- HR 100m counts ---
fieldNames = fieldnames(HR100m);
for t = 1:numel(fieldNames)
    f = fieldNames{t};
    
    x = HR100m.(f).FRF_X;
    y = HR100m.(f).FRF_Y;

    % dist = sqrt((x - noaaX).^2 + (y - noaaY).^2);
    % numPix_100m(t) = sum(dist <= avgRadius_100m);
    x0 = noaaX;
    y0 = noaaY;

    ellipseVal = ((x - x0)./a_100m).^2 + ((y - y0)./b_100m).^2;
    numPix_100m(t) = sum(ellipseVal <= 1);
end

% --- Pixel cloud counts ---
fieldNames = fieldnames(HRpixc);
for t = 1:numel(fieldNames)
    f = fieldNames{t};
    
    x = HRpixc.(f).FRF_X;
    y = HRpixc.(f).FRF_Y;

    % dist = sqrt((x - noaaX).^2 + (y - noaaY).^2);
    % numPix_pixc(t) = sum(dist <= avgRadius_pixc);
    x0 = noaaX;
    y0 = noaaY;

    ellipseVal = ((x - x0)./a_pixc).^2 + ((y - y0)./b_pixc).^2;
    numPix_pixc(t) = sum(ellipseVal <= 1);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Data analysis for scatter plot- all 4 products
% Combine the small arrays into a cell array for easier iteration
SmallArrays = {convertedTimeArray_L3_LR_SSH_2km, convertedTimeArray_250m_LR_L2_SSH_Expert, convertedTimeArray_100HR, convertedTimeArray_pixelCloudHR};

% Initialize a cell array to store indices

ClosestIndices = cell(size(SmallArrays));

% Find closest indices for each small array
for k = 1:length(SmallArrays)
    SmallArray = SmallArrays{k};
    indices = zeros(size(SmallArray));
    for i = 1:length(SmallArray)
        [~, indices(i)] = min(abs(noaaTideData_all_navd88.time_dateTime - SmallArray(i))); % Find closest index
    end
    ClosestIndices{k} = indices; % Store indices in the cell array
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Seperate passes
% L3 2km
fn = fieldnames(L3_2km);   % get all field names
idx354_L3_2km = contains(fn, '_354_');   % logical for pass 354
idx063_L3_2km = contains(fn, '_063_');   % logical for pass 063

% LR 2km
fn = fieldnames(LR2km);   % get all field names
idx354_LR2km = contains(fn, '_354_');   % logical for pass 354
idx063_LR2km = contains(fn, '_063_');   % logical for pass 063

% HR100m
fn = fieldnames(HR100m);   % get all field names
idx354_HR100m = contains(fn, '_354_');   % logical for pass 354
idx063_HR100m = contains(fn, '_063_');   % logical for pass 063

% HRpixc
fn = fieldnames(HRpixc);   % get all field names
idx354_HRpixc = contains(fn, '_354_');   % logical for pass 354
idx063_HRpixc = contains(fn, '_063_');   % logical for pass 063

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RMSE and Bias
rmse_L3_2km=rmse(noaaTideData_all_navd88.measured(ClosestIndices{1, 1}), extractedSSH_L3_LR_SSH_2km);
rmse_2km=rmse(noaaTideData_all_navd88.measured(ClosestIndices{1, 2}), extractedSSH_250m_LR_L2_SSH_Expert);
% rmse_100m=rmse(noaaTideData_all_navd88.measured(ClosestIndices{1, 3}), extractedSWE_100HR);
% rmse_pix=rmse(noaaTideData_all_navd88.measured(ClosestIndices{1, 4}), extractedSWE_pixelCloudHR);
rmse_100m = rmse(noaaTideData_all_navd88.measured(ClosestIndices{1,3}), extractedSWE_100HR_avg);
rmse_pix  = rmse(noaaTideData_all_navd88.measured(ClosestIndices{1,4}), extractedSWE_pixelCloudHR_avg);

corr_L3_2km=corrcoef(noaaTideData_all_navd88.measured(ClosestIndices{1, 1}), extractedSSH_L3_LR_SSH_2km);
corr_L3_2km=corr_L3_2km(1,2)^2;
corr_2km=corrcoef(noaaTideData_all_navd88.measured(ClosestIndices{1, 2}), extractedSSH_250m_LR_L2_SSH_Expert);
corr_2km=corr_2km(1,2)^2;
corr_100m=corrcoef(noaaTideData_all_navd88.measured(ClosestIndices{1, 3}), extractedSWE_100HR_avg);
corr_100m=corr_100m(1,2)^2;
corr_pix=corrcoef(noaaTideData_all_navd88.measured(ClosestIndices{1, 4}), extractedSWE_pixelCloudHR_avg);
corr_pix=corr_pix(1,2)^2;

bias_L3_2km=mean( extractedSSH_L3_LR_SSH_2km - noaaTideData_all_navd88.measured(ClosestIndices{1, 1}) );
bias_2km=mean( extractedSSH_250m_LR_L2_SSH_Expert - noaaTideData_all_navd88.measured(ClosestIndices{1, 2}) );
bias_100m=mean(extractedSWE_100HR_avg - noaaTideData_all_navd88.measured(ClosestIndices{1, 3}) );
bias_pix=mean(extractedSWE_pixelCloudHR_avg - noaaTideData_all_navd88.measured(ClosestIndices{1, 4}) );

% nRMSE
% In-situ subsets
insitu_2km_L3 = noaaTideData_all_navd88.measured(ClosestIndices{1,1});
insitu_2km    = noaaTideData_all_navd88.measured(ClosestIndices{1,2});
insitu_100m   = noaaTideData_all_navd88.measured(ClosestIndices{1,3});
insitu_pix    = noaaTideData_all_navd88.measured(ClosestIndices{1,4});

% Ranges (ignore NaNs just in case)
range_L3_2km = max(insitu_2km_L3, [], 'omitnan') - min(insitu_2km_L3, [], 'omitnan');
range_2km    = max(insitu_2km,    [], 'omitnan') - min(insitu_2km,    [], 'omitnan');
range_100m   = max(insitu_100m,   [], 'omitnan') - min(insitu_100m,   [], 'omitnan');
range_pix    = max(insitu_pix,    [], 'omitnan') - min(insitu_pix,    [], 'omitnan');

% nRMSE (normalized by in-situ range)
nrmse_L3_2km = rmse(insitu_2km_L3, extractedSSH_L3_LR_SSH_2km) / range_L3_2km;
nrmse_2km    = rmse(insitu_2km,    extractedSSH_250m_LR_L2_SSH_Expert) / range_2km;
nrmse_100m   = rmse(insitu_100m,   extractedSWE_100HR_avg) / range_100m;
nrmse_pix    = rmse(insitu_pix,    extractedSWE_pixelCloudHR_avg) / range_pix;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load Wave, Current, Wind info
load('insituSWH_relevantInstrumentsAllProducts.mat');
load('insituTp_relevantInstrumentsAllProducts.mat');
load('insituWavePeakDir_relevantInstrumentsAllProducts.mat')
load('insituWaveMeanDir_relevantInstrumentsAllProducts.mat')
load('insituCurrentSpeeds_relevantInstrumentsAllProducts.mat');
load('insituCurrentDirection_relevantInstrumentsAllProducts.mat');
load('insituWindSpeeds_relevantInstrumentsAllProducts.mat');
load('insituWindDirection_relevantInstrumentsAllProducts.mat');

%% Plot scatter plots and include comparison locations
scr = get(0,'ScreenSize');
figWidth  = scr(3) / 2;
figHeight = scr(4);

figure('Position',[0 0 figWidth figHeight]);

t = tiledlayout(3,2);
t.TileSpacing = 'tight';
t.Padding     = 'tight';


% -----------------------
% Helper function to print stats
% -----------------------
printStats = @(rmse_val,r2_val,bias_val) ...
    text(0.03,0.97, sprintf('Bias = %.2f m \nRMSE = %.2f m \nR^{2} = %.2f', ...
    bias_val, rmse_val, r2_val), ...
    'Units','normalized','VerticalAlignment','top','FontSize',14, ...
    'Interpreter','tex');


% -----------------------
% Helper formatting function
% -----------------------
formatAxes = @() set(gca, ...
    'FontSize',15, ...
    'Box','on', ...
    'XColor','k', ...
    'YColor','k', ...
    'LineWidth',1);

addPanelLabel = @(ax,labelChar) ...
    text(ax,0.91,1.01,labelChar, ...
    'Units','normalized', ...
    'HorizontalAlignment','right', ...
    'VerticalAlignment','top', ...
    'FontSize',18, ...
    'FontWeight','bold');



% ================================================================
% Tile 1 — L3 LR 2 km
% ================================================================
ax1 = nexttile; hold(ax1,'on');
scatter(noaaTideData_all_navd88.measured(ClosestIndices{1,1}), ...
        extractedSSH_L3_LR_SSH_2km, 100, 'y','filled'); hold on;
plot(-1.5:1:1.5, -1.5:1:1.5,'k');
xlim([-1.5 1.5]); ylim([-1.5 1.5]);
ax = gca;
ax.YTick = ax.XTick;
ax.XTickLabelRotation = 0;
ticks = -1.5:0.5:1.5;
set(gca,'XTick',ticks,'YTick',ticks)
axis square; grid on;
ylabel('SWOT Water Level (m)','FontSize',18);
title('SWOT L3 LR 2 km','FontSize',20);
formatAxes();
printStats(rmse_L3_2km, corr_L3_2km, bias_L3_2km);
addPanelLabel(ax1,'A');

% ================================================================
% Tile 2 — L2 LR Expert
% ================================================================
ax2 = nexttile; hold(ax2,'on');
scatter(noaaTideData_all_navd88.measured(ClosestIndices{1,2}), ...
        extractedSSH_250m_LR_L2_SSH_Expert, 100, 'kd'); hold on;
plot(-1.5:1:1.5, -1.5:1:1.5,'k');
xlim([-1.5 1.5]); ylim([-1.5 1.5]);
ax = gca;
ax.YTick = ax.XTick;
ax.XTickLabelRotation = 0;
ticks = -1.5:0.5:1.5;
set(gca,'XTick',ticks,'YTick',ticks)
axis square; grid on;
title('SWOT L2 LR Expert','FontSize',20);
set(gca,'YTickLabel',[]);
formatAxes();
printStats(rmse_2km, corr_2km, bias_2km);
addPanelLabel(ax2,'B');

% ================================================================
% Tile 3 — HR 100 m
% ================================================================
ax3 = nexttile; hold(ax3,'on');
scatter(noaaTideData_all_navd88.measured(ClosestIndices{1,3}), ...
        extractedSWE_100HR_avg, 100, '+r', 'LineWidth',1.5); hold on;
plot(-1.5:1:1.5, -1.5:1:1.5,'k');
xlim([-1.5 1.5]); ylim([-1.5 1.5]);
ax = gca;
ax.YTick = ax.XTick;
ax.XTickLabelRotation = 0;
ticks = -1.5:0.5:1.5;
set(gca,'XTick',ticks,'YTick',ticks)
axis square; grid on;
xlabel('NOAA Tide Gauge (m)','FontSize',18);
ylabel('SWOT Water Level (m)','FontSize',18);
title('SWOT HR 100 m','FontSize',20);
formatAxes();
printStats(rmse_100m, corr_100m, bias_100m);
addPanelLabel(ax3,'C');

% ================================================================
% Tile 4 — Pixel Cloud HR
% ================================================================
ax4 = nexttile; hold(ax4,'on');
scatter(noaaTideData_all_navd88.measured(ClosestIndices{1,4}), ...
        extractedSWE_pixelCloudHR_avg, 100, 'ks','filled'); hold on;
plot(-1.5:1:1.5, -1.5:1:1.5,'k');
xlim([-1.5 1.5]); ylim([-1.5 1.5]);
ax = gca;
ax.YTick = ax.XTick;
ax.XTickLabelRotation = 0;
ticks = -1.5:0.5:1.5;
set(gca,'XTick',ticks,'YTick',ticks)
axis square; grid on;
xlabel('NOAA Tide Gauge (m)','FontSize',18);
title('SWOT HR Pixel Cloud','FontSize',20);
set(gca,'YTickLabel',[]);
formatAxes();
printStats(rmse_pix, corr_pix, bias_pix);
addPanelLabel(ax4,'D');


% ================================================================
% Tile 5 — Spatial location of SWOT comparison points
% ================================================================
axMap = nexttile([1 2]); hold(axMap,'on');
axes(axMap);   % make sure text attaches to the map axes
hold(axMap,'on');

set(axMap,'Box','on', ...
          'Layer','top', ...
          'LineWidth',1.5);

load("demVariables.mat");

levelsFill = -0.25:-0.5:-35;
levelsLine = -5:-5:-35;

% --- Filled contours ---
[C, h] = contourf(frfX, frfY, Z_crop, levelsFill, 'LineColor','none');

% --- Line contours ---
[C2, h2] = contour(frfX, frfY, Z_crop, levelsLine, 'k', 'LineWidth', 1);
clabel(C2, h2, 'Color','k');

colormap(m_colmap('blue'));
box on;

cb = colorbar(axMap);   % attach ONLY to axMap
% cb.Layout.Tile = 'east';
cb.Label.String = 'Elevation (m NAVD88)';
caxis(axMap,[-30 0])


% Pier
fill([0 585 585 0], [514 514 520 520],'k','EdgeColor','k', ...
     'LineWidth', 2);

% NOAA gauge
noaaLat=36.183639;
noaaLong=-75.74528;
[~,~,~,~,noaaY,noaaX] = frfCoord(noaaLong,noaaLat);
plot(noaaX,noaaY,'ob','MarkerFaceColor','b','LineWidth',3, MarkerSize=20);



% Shoreline
load("UsShapeFrfX.mat");
load("UsShapeFrfY.mat");
plot(UsShapeFrfX,UsShapeFrfY,'k-');

% --- SWOT points (reuse your loops exactly as-is) ---

% L3 fake
scatter(NaN,NaN,100,'y',"filled")

% L2
clearvars fieldNames numPasses t fieldName WLI x y
load('250m_LR_L2_SSH_expert_Processed.mat')
fieldNames = fieldnames(dataStruct);
numPasses = numel(fieldNames);
for t = 1:numPasses
    fieldName = fieldNames{t};
    WLI(t) = dataStruct.(fieldName).Water_Level_Index;

    x(t)= dataStruct.(fieldName).FRF_X(WLI(t));
    y(t) = dataStruct.(fieldName).FRF_Y(WLI(t));

end
% scatter(x,y,300,'kd',LineWidth=3)
plotPointsWithCountsL2(axMap, x, y, {300,'kd','LineWidth',3}, 'k')

% HR 100m raster fake
scatter(NaN, NaN,600,'r+', 'LineWidth', 3)

% Pixel Cloud
clearvars fieldNames numPasses t fieldName WLI x y
load('pixelCloud_Processed_bigArea.mat')
fieldNames = fieldnames(dataStruct);
numPasses = numel(fieldNames);
for t = 1:numPasses
    fieldName = fieldNames{t};
    WLI(t) = dataStruct.(fieldName).Water_Level_Index;

    x(t)= dataStruct.(fieldName).FRF_X(WLI(t));
    y(t) = dataStruct.(fieldName).FRF_Y(WLI(t));

end
% scatter(x,y,300,'ks',LineWidth=3)
% plotPointsWithCountsHR(axMap, x, y, {300,'ks','LineWidth',3}, 'k')


% HR 100 m
clearvars fieldNames numPasses t fieldName WLI x y
load('100m_Processed.mat')
fieldNames = fieldnames(dataStruct);
numPasses = numel(fieldNames);
for t = 1:numPasses
    fieldName = fieldNames{t};
    WLI(t) = dataStruct.(fieldName).Water_Level_Index;

    x(t)= dataStruct.(fieldName).FRF_X(WLI(t));
    y(t) = dataStruct.(fieldName).FRF_Y(WLI(t));

end
% scatter(x,y,600,'r+', 'LineWidth', 3)
% plotPointsWithCounts100m(axMap, x, y, {600,'r+','LineWidth',3}, 'r')

% L3
load('2km_LR_L3_SSH_expert_Processed.mat');          % L3 2km
fieldNames = fieldnames(dataStruct);
numPasses = numel(fieldNames);
for t = 1:numPasses
    fieldName = fieldNames{t};
    WLI(t) = dataStruct.(fieldName).Water_Level_Index;

    x(t)= dataStruct.(fieldName).FRF_X(WLI(t));
    y(t) = dataStruct.(fieldName).FRF_Y(WLI(t));

end
% scatter(x,y,100,'y',"filled")
plotPointsWithCountsL3(axMap, x, y, {100,'y','filled'}, 'y')

% --- Draw averaging radius circles ---
% theta = linspace(0,2*pi,200);
% 
% % HR 100m radius (red)
% xCirc100 = noaaX + avgRadius_100m*cos(theta);
% yCirc100 = noaaY + avgRadius_100m*sin(theta);
% plot(xCirc100, yCirc100, 'r-', 'LineWidth', 2);

theta = linspace(0,2*pi,300);

% HR 100m ellipse
xEll100 = (noaaX) + a_100m*cos(theta);
yEll100 = noaaY + b_100m*sin(theta);
plot(xEll100, yEll100, 'r-', 'LineWidth', 2);




% Pixel cloud radius (black dashed)
% xCircPix = noaaX + avgRadius_pixc*cos(theta);
% yCircPix = noaaY + avgRadius_pixc*sin(theta);
% plot(xCircPix, yCircPix, 'k--', 'LineWidth', 2);
% Pixel cloud ellipse
xEllPix = (noaaX) + a_pixc*cos(theta);
yEllPix = noaaY + b_pixc*sin(theta);
plot(xEllPix, yEllPix, 'k--', 'LineWidth', 2);

xlim([-500 8000]);
ylim([-5000 6000]);

title('Locations of SWOT Water-Level Comparisons','FontSize',20);
xlabel('FRF X (m)','FontSize',16);
ylabel('FRF Y (m)','FontSize',16);

legend1=legend('','','FRF Pier','NOAA Water Level Gauge','','L3 LR 2km','L2 LR 2km','','','L2 HR 100m Averaging Region','L2 HR Pixel Cloud Averaging Region', '','');

set(legend1,...
    'Position',[0.479657794665246 0.0599139386239882 0.21993126666423 0.101787484745757]);

addPanelLabel(axMap,'E');

%% helper functions
function plotPointsWithCountsHR(ax, x, y, markerArgs, textColor)

    % Remove NaNs
    valid = ~isnan(x) & ~isnan(y);
    x = x(valid);
    y = y(valid);

    % Find unique locations and counts
    XY = [x(:) y(:)];
    [uniqueXY, ~, idx] = unique(XY, 'rows');
    counts = accumarray(idx, 1);

    % Plot markers
    scatter(ax, uniqueXY(:,1), uniqueXY(:,2), markerArgs{:});

    % Add count labels
    dx = 150;   % horizontal offset in meters (adjust if needed)
    dy = -150;   % vertical offset

    for i = 1:size(uniqueXY,1)
        text(ax, uniqueXY(i,1)+dx, uniqueXY(i,2)+dy, ...
            num2str(counts(i)), ...
            'FontSize',12, ...
            'FontWeight','bold', ...
            'Color', textColor, ...
            'HorizontalAlignment','left', ...
            'VerticalAlignment','middle');
    end
end

function plotPointsWithCounts100m(ax, x, y, markerArgs, textColor)

    % Remove NaNs
    valid = ~isnan(x) & ~isnan(y);
    x = x(valid);
    y = y(valid);

    % Find unique locations and counts
    XY = [x(:) y(:)];
    [uniqueXY, ~, idx] = unique(XY, 'rows');
    counts = accumarray(idx, 1);

    % Plot markers
    scatter(ax, uniqueXY(:,1), uniqueXY(:,2), markerArgs{:});

    % Add count labels
    dx = 100;   % horizontal offset in meters (adjust if needed)
    dy = -1000;   % vertical offset

    for i = 1:size(uniqueXY,1)
        text(ax, uniqueXY(i,1)+dx, uniqueXY(i,2)+dy, ...
            num2str(counts(i)), ...
            'FontSize',12, ...
            'FontWeight','bold', ...
            'Color', textColor, ...
            'HorizontalAlignment','left', ...
            'VerticalAlignment','middle');
    end
end

function plotPointsWithCountsL3(ax, x, y, markerArgs, textColor)

    % Remove NaNs
    valid = ~isnan(x) & ~isnan(y);
    x = x(valid);
    y = y(valid);

    % Find unique locations and counts
    XY = [x(:) y(:)];
    [uniqueXY, ~, idx] = unique(XY, 'rows');
    counts = accumarray(idx, 1);

    % Plot markers
    scatter(ax, uniqueXY(:,1), uniqueXY(:,2), markerArgs{:});

    % Add count labels
    dx = 50;   % horizontal offset in meters (adjust if needed)
    dy = 900;   % vertical offset

    for i = 1:size(uniqueXY,1)
        text(ax, uniqueXY(i,1)+dx, uniqueXY(i,2)+dy, ...
            num2str(counts(i)), ...
            'FontSize',12, ...
            'FontWeight','bold', ...
            'Color', textColor, ...
            'HorizontalAlignment','left', ...
            'VerticalAlignment','middle');
    end
end

function plotPointsWithCountsL2(ax, x, y, markerArgs, textColor)

    % Remove NaNs
    valid = ~isnan(x) & ~isnan(y);
    x = x(valid);
    y = y(valid);

    % Find unique locations and counts
    XY = [x(:) y(:)];
    [uniqueXY, ~, idx] = unique(XY, 'rows');
    counts = accumarray(idx, 1);

    % Plot markers
    scatter(ax, uniqueXY(:,1), uniqueXY(:,2), markerArgs{:});

    % Add count labels
    dx = 150;   % horizontal offset in meters (adjust if needed)
    dy = -150;   % vertical offset

    for i = 1:size(uniqueXY,1)
        text(ax, uniqueXY(i,1)+dx, uniqueXY(i,2)+dy, ...
            num2str(counts(i)), ...
            'FontSize',12, ...
            'FontWeight','bold', ...
            'Color', textColor, ...
            'HorizontalAlignment','left', ...
            'VerticalAlignment','middle');
    end
end