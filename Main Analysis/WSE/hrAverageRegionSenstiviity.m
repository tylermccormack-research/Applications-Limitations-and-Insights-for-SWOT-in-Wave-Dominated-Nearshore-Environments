%% Sensitivity Study for HR 100m & Pixel Cloud Averaging Radius
clear; clc; close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load FRF NOAA water level data
load('noaaTideData_all_navd88.mat');

% NOAA gauge location
noaaLat  = 36.183639;
noaaLong = -75.74528;
[~,~,~,~,noaaY,noaaX] = frfCoord(noaaLong,noaaLat);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load processed SWOT HR products
load('100m_Processed.mat');          % HR 100m raster
HR100m = dataStruct;
load('pixelCloud_Processed_bigArea.mat'); % Pixel cloud
HRpixc = dataStruct;
clear dataStruct

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Matching times
load('convertedTimeArray_100HR.mat');
load('convertedTimeArray_pixelCloudHR_bigArea.mat');

% Find closest indices to NOAA gauge for each pass
SmallArrays = {convertedTimeArray_100HR, convertedTimeArray_pixelCloudHR};
ClosestIndices = cell(size(SmallArrays));
for k = 1:length(SmallArrays)
    SmallArray = SmallArrays{k};
    indices = zeros(size(SmallArray));
    for i = 1:length(SmallArray)
        [~, indices(i)] = min(abs(noaaTideData_all_navd88.time_dateTime - SmallArray(i)));
    end
    ClosestIndices{k} = indices;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sensitivity study parameters
radii = 50:50:5000;  % averaging radius (meters)
rmse_100m = nan(size(radii));
rmse_pixc = nan(size(radii));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ------------------------- HR 100m Raster -------------------------------
fieldNames100 = fieldnames(HR100m);
numPasses100 = numel(fieldNames100);

for rIdx = 1:length(radii)
    radius = radii(rIdx);
    avgSWE = nan(numPasses100,1);

    for t = 1:numPasses100
        f = fieldNames100{t};
        x = HR100m.(f).FRF_X;
        y = HR100m.(f).FRF_Y;
        swe = HR100m.(f).Filtered_SWE_NAVD88_qualityFiltered;

        dist = sqrt((x - noaaX).^2 + (y - noaaY).^2);
        idx = dist <= radius;
        if any(idx)
            avgSWE(t) = mean(swe(idx),'omitnan');
        end
    end

    % Compute RMSE vs NOAA
    rmse_100m(rIdx) = rmse(noaaTideData_all_navd88.measured(ClosestIndices{1}), avgSWE);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ------------------------- Pixel Cloud HR -------------------------------
fieldNamesPix = fieldnames(HRpixc);
numPassesPix = numel(fieldNamesPix);

for rIdx = 1:length(radii)
    radius = radii(rIdx);
    avgSWE = nan(numPassesPix,1);

    for t = 1:numPassesPix
        f = fieldNamesPix{t};
        x = HRpixc.(f).FRF_X;
        y = HRpixc.(f).FRF_Y;
        swe = HRpixc.(f).Filtered_SWE_NAVD88;

        dist = sqrt((x - noaaX).^2 + (y - noaaY).^2);
        idx = dist <= radius;
        if any(idx)
            avgSWE(t) = mean(swe(idx),'omitnan');
        end
    end

    % Compute RMSE vs NOAA
    rmse_pixc(rIdx) = rmse(noaaTideData_all_navd88.measured(ClosestIndices{2}), avgSWE);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ------------------------- Plotting -------------------------------------
figure('Position',[100 100 1200 500])

% HR 100m Raster
subplot(1,2,1)
plot(radii, rmse_100m,'-or','LineWidth',2,'MarkerFaceColor','r')
xlabel('Averaging radius (m)','FontSize',14)
ylabel('RMSE (m)','FontSize',14)
title('HR 100m Raster - RMSE vs Averaging Radius','FontSize',16)
grid on
ylim([0  0.5])

% Pixel Cloud
subplot(1,2,2)
plot(radii, rmse_pixc,'-sk','LineWidth',2,'MarkerFaceColor','k')
xlabel('Averaging radius (m)','FontSize',14)
ylabel('RMSE (m)','FontSize',14)
title('Pixel Cloud HR - RMSE vs Averaging Radius','FontSize',16)
grid on
ylim([0  0.5])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Optional: print best radius
[~, bestIdx100] = min(rmse_100m);
[~, bestIdxPix] = min(rmse_pixc);
fprintf('Best radius for HR 100m: %d m (RMSE = %.3f m)\n', radii(bestIdx100), rmse_100m(bestIdx100));
fprintf('Best radius for Pixel Cloud: %d m (RMSE = %.3f m)\n', radii(bestIdxPix), rmse_pixc(bestIdxPix));

%% Ellipse
%% Sensitivity Study for HR 100m & Pixel Cloud Using Elliptical Averaging
clear; clc; close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load FRF NOAA water level data
load('noaaTideData_all_navd88.mat');

% NOAA gauge location
noaaLat  = 36.183639;
noaaLong = -75.74528;
[~,~,~,~,noaaY,noaaX] = frfCoord(noaaLong,noaaLat);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load processed SWOT HR products
load('100m_Processed.mat');          % HR 100m raster
HR100m = dataStruct;
load('pixelCloud_Processed_bigArea.mat'); % Pixel cloud
HRpixc = dataStruct;
clear dataStruct

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Matching times
load('convertedTimeArray_100HR.mat');
load('convertedTimeArray_pixelCloudHR_bigArea.mat');

% Find closest indices to NOAA gauge for each pass
SmallArrays = {convertedTimeArray_100HR, convertedTimeArray_pixelCloudHR};
ClosestIndices = cell(size(SmallArrays));
for k = 1:length(SmallArrays)
    SmallArray = SmallArrays{k};
    indices = zeros(size(SmallArray));
    for i = 1:length(SmallArray)
        [~, indices(i)] = min(abs(noaaTideData_all_navd88.time_dateTime - SmallArray(i)));
    end
    ClosestIndices{k} = indices;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sensitivity study parameters
crossShore = 1000;            % fixed cross-shore radius (m)
alongShoreList = 0:100:8000; % along-shore length (m)
rmse_100m = nan(size(alongShoreList));
rmse_pixc = nan(size(alongShoreList));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ------------------------- HR 100m Raster -------------------------------
fieldNames100 = fieldnames(HR100m);
numPasses100 = numel(fieldNames100);

for aIdx = 1:length(alongShoreList)
    aRadius = alongShoreList(aIdx);
    avgSWE = nan(numPasses100,1);

    for t = 1:numPasses100
        f = fieldNames100{t};
        x = HR100m.(f).FRF_X;
        y = HR100m.(f).FRF_Y;
        swe = HR100m.(f).Filtered_SWE_NAVD88_qualityFiltered;

        % Ellipse formula: ((x-noaaX)/along)^2 + ((y-noaaY)/cross)^2 <= 1
        if aRadius==0
            % Avoid divide by zero
            idx = abs(y-noaaY) <= crossShore;
        else
            idx = ((x-noaaX)/aRadius).^2 + ((y-noaaY)/crossShore).^2 <= 1;
        end

        if any(idx)
            avgSWE(t) = mean(swe(idx),'omitnan');
        end
    end

    % Compute RMSE vs NOAA
    rmse_100m(aIdx) = rmse(noaaTideData_all_navd88.measured(ClosestIndices{1}), avgSWE);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ------------------------- Pixel Cloud HR -------------------------------
fieldNamesPix = fieldnames(HRpixc);
numPassesPix = numel(fieldNamesPix);

for aIdx = 1:length(alongShoreList)
    aRadius = alongShoreList(aIdx);
    avgSWE = nan(numPassesPix,1);

    for t = 1:numPassesPix
        f = fieldNamesPix{t};
        x = HRpixc.(f).FRF_X;
        y = HRpixc.(f).FRF_Y;
        swe = HRpixc.(f).Filtered_SWE_NAVD88;

        if aRadius==0
            idx = abs(y-noaaY) <= crossShore;
        else
            idx = ((x-noaaX)/aRadius).^2 + ((y-noaaY)/crossShore).^2 <= 1;
        end

        if any(idx)
            avgSWE(t) = mean(swe(idx),'omitnan');
        end
    end

    % Compute RMSE vs NOAA
    rmse_pixc(aIdx) = rmse(noaaTideData_all_navd88.measured(ClosestIndices{2}), avgSWE);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ------------------------- Plotting -------------------------------------
figure('Position',[100 100 1200 500])

% HR 100m Raster
subplot(1,2,1)
plot(alongShoreList, rmse_100m,'-or','LineWidth',2,'MarkerFaceColor','r')
xlabel('Along-shore length of ellipse (m)','FontSize',14)
ylabel('RMSE (m)','FontSize',14)
title('HR 100m Raster - RMSE vs Along-Shore Ellipse Length','FontSize',16)
grid on
ylim([0 0.5])

% Pixel Cloud
subplot(1,2,2)
plot(alongShoreList, rmse_pixc,'-sk','LineWidth',2,'MarkerFaceColor','k')
xlabel('Along-shore length of ellipse (m)','FontSize',14)
ylabel('RMSE (m)','FontSize',14)
title('Pixel Cloud HR - RMSE vs Along-Shore Ellipse Length','FontSize',16)
grid on
ylim([0 0.5])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Optional: print best ellipse length
[~, bestIdx100] = min(rmse_100m);
[~, bestIdxPix] = min(rmse_pixc);
fprintf('Best along-shore ellipse length for HR 100m: %d m (RMSE = %.3f m)\n', ...
    alongShoreList(bestIdx100), rmse_100m(bestIdx100));
fprintf('Best along-shore ellipse length for Pixel Cloud: %d m (RMSE = %.3f m)\n', ...
    alongShoreList(bestIdxPix), rmse_pixc(bestIdxPix));

%% 2D Sensitivity Study for HR 100m & Pixel Cloud - Elliptical Averaging
clear; clc; close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load FRF NOAA water level data
load('noaaTideData_all_navd88.mat');

% NOAA gauge location
noaaLat  = 36.183639;
noaaLong = -75.74528;
[~,~,~,~,noaaY,noaaX] = frfCoord(noaaLong,noaaLat);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load processed SWOT HR products
load('100m_Processed.mat');          % HR 100m raster
HR100m = dataStruct;
load('pixelCloud_Processed_bigArea.mat'); % Pixel cloud
HRpixc = dataStruct;
clear dataStruct

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Matching times
load('convertedTimeArray_100HR.mat');
load('convertedTimeArray_pixelCloudHR_bigArea.mat');

% Find closest indices to NOAA gauge for each pass
SmallArrays = {convertedTimeArray_100HR, convertedTimeArray_pixelCloudHR};
ClosestIndices = cell(size(SmallArrays));
for k = 1:length(SmallArrays)
    SmallArray = SmallArrays{k};
    indices = zeros(size(SmallArray));
    for i = 1:length(SmallArray)
        [~, indices(i)] = min(abs(noaaTideData_all_navd88.time_dateTime - SmallArray(i)));
    end
    ClosestIndices{k} = indices;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sensitivity study parameters
crossShoreList = 0:50:300;      % cross-shore radius
alongShoreList = 0:500:8000;    % along-shore radius

rmse_100m = nan(length(crossShoreList), length(alongShoreList));
rmse_pixc = nan(length(crossShoreList), length(alongShoreList));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ------------------------- HR 100m Raster -------------------------------
fieldNames100 = fieldnames(HR100m);
numPasses100 = numel(fieldNames100);

for csIdx = 1:length(crossShoreList)
    crossR = crossShoreList(csIdx);
    
    for asIdx = 1:length(alongShoreList)
        alongR = alongShoreList(asIdx);
        avgSWE = nan(numPasses100,1);

        for t = 1:numPasses100
            f = fieldNames100{t};
            x = HR100m.(f).FRF_X;
            y = HR100m.(f).FRF_Y;
            swe = HR100m.(f).Filtered_SWE_NAVD88_qualityFiltered;

            if alongR==0
                idx = abs(y-noaaY) <= crossR;
            else
                idx = ((x-noaaX)/alongR).^2 + ((y-noaaY)/crossR).^2 <= 1;
            end

            if any(idx)
                avgSWE(t) = mean(swe(idx),'omitnan');
            end
        end

        rmse_100m(csIdx, asIdx) = rmse(noaaTideData_all_navd88.measured(ClosestIndices{1}), avgSWE);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ------------------------- Pixel Cloud HR -------------------------------
fieldNamesPix = fieldnames(HRpixc);
numPassesPix = numel(fieldNamesPix);

for csIdx = 1:length(crossShoreList)
    crossR = crossShoreList(csIdx);
    
    for asIdx = 1:length(alongShoreList)
        alongR = alongShoreList(asIdx);
        avgSWE = nan(numPassesPix,1);

        for t = 1:numPassesPix
            f = fieldNamesPix{t};
            x = HRpixc.(f).FRF_X;
            y = HRpixc.(f).FRF_Y;
            swe = HRpixc.(f).Filtered_SWE_NAVD88;

            if alongR==0
                idx = abs(y-noaaY) <= crossR;
            else
                idx = ((x-noaaX)/alongR).^2 + ((y-noaaY)/crossR).^2 <= 1;
            end

            if any(idx)
                avgSWE(t) = mean(swe(idx),'omitnan');
            end
        end

        rmse_pixc(csIdx, asIdx) = rmse(noaaTideData_all_navd88.measured(ClosestIndices{2}), avgSWE);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ------------------------- Plotting -------------------------------------
figure('Position',[100 100 1400 600])

% HR 100m Raster RMSE Surface
subplot(1,2,1)
imagesc(alongShoreList, crossShoreList, rmse_100m)
set(gca,'YDir','normal')
colorbar
xlabel('Along-shore length (m)','FontSize',14)
ylabel('Cross-shore radius (m)','FontSize',14)
title('HR 100m Raster - RMSE Surface','FontSize',16)
caxis([0 0.5])
grid on

% Pixel Cloud RMSE Surface
subplot(1,2,2)
imagesc(alongShoreList, crossShoreList, rmse_pixc)
set(gca,'YDir','normal')
colorbar
xlabel('Along-shore length (m)','FontSize',14)
ylabel('Cross-shore radius (m)','FontSize',14)
title('Pixel Cloud HR - RMSE Surface','FontSize',16)
caxis([0 0.5])
grid on

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Optional: find best combination of radii
[minVal100, idx100] = min(rmse_100m(:));
[csBest100, asBest100] = ind2sub(size(rmse_100m), idx100);
fprintf('HR 100m best cross-shore = %d m, along-shore = %d m (RMSE = %.3f m)\n', ...
    crossShoreList(csBest100), alongShoreList(asBest100), minVal100);

[minValPix, idxPix] = min(rmse_pixc(:));
[csBestPix, asBestPix] = ind2sub(size(rmse_pixc), idxPix);
fprintf('Pixel Cloud best cross-shore = %d m, along-shore = %d m (RMSE = %.3f m)\n', ...
    crossShoreList(csBestPix), alongShoreList(asBestPix), minValPix);