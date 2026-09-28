function results = extract_and_plot_transect_points(dataStruct, transect_min, transect_max, constant_value, distance_threshold, axis)
% Extract x and y coordinates from the structure
x_coords = dataStruct.HR_pixCloud_001_354_091L_20230802.FRF_X;
y_coords = dataStruct.HR_pixCloud_001_354_091L_20230802.FRF_Y;

% Determine the axis of the transect ('x' or 'y')
if strcmp(axis, 'x')
    % Transect is along a constant x value
    distances = abs(x_coords - constant_value); % Perpendicular distance to the transect
    within_transect = (distances <= distance_threshold) & (y_coords >= transect_min) & (y_coords <= transect_max);
elseif strcmp(axis, 'y')
    % Transect is along a constant y value
    distances = abs(y_coords - constant_value); % Perpendicular distance to the transect
    within_transect = (distances <= distance_threshold) & (x_coords >= transect_min) & (x_coords <= transect_max);
else
    error('Invalid axis. Please specify ''x'' or ''y''.');
end

% Extract SWE and corresponding FRF_X values within the transect
swe_values = dataStruct.HR_pixCloud_001_354_091L_20230802.Filtered_SWE_NAVD88(within_transect);
frf_x_values = dataStruct.HR_pixCloud_001_354_091L_20230802.FRF_X(within_transect);

% Identify outliers in SWE values
q1 = quantile(swe_values, 0.25);
q3 = quantile(swe_values, 0.75);
iqr = q3 - q1;
low_bound = q1 - 1.5 * iqr;
high_bound = q3 + 1.5 * iqr;

outliers = (swe_values < low_bound) | (swe_values > high_bound);

% Filter SWE and FRF_X values
filtered_swe_values = swe_values(~outliers);
filtered_frf_x_values = frf_x_values(~outliers);

% Calculate SWH from SWOT
if axis == 'y'
    wseSTD=std(filtered_swe_values);
    SWH_Swot=4*wseSTD;
else
    wseSTD=std(dataStruct.HR_pixCloud_001_354_091L_20230802.Filtered_SWE_NAVD88(within_transect));
    SWH_Swot=4*wseSTD;
end

% Get insitu wave height
meanTime=mean(dataStruct.HR_pixCloud_001_354_091L_20230802.time  );
meanTimeDateTime=datetime(meanTime,'ConvertFrom','epochtime','Epoch','2000-01-01');
fprintf('SWOT Significant wave height at %s: %.2f m\n', meanTimeDateTime, SWH_Swot);


% Get FRF sig wave height at signature940_300
swh_insitu = getFrfWaveHeight(meanTimeDateTime);

% Plotting
% Plot all points
figure;
scatter(x_coords, y_coords, 10, 'b', 'filled'); % Plot all points in blue
hold on;
scatter(x_coords(within_transect), y_coords(within_transect), 30, 'r', 'filled'); % Highlight selected points in red
xlabel('X Coordinates');
ylabel('Y Coordinates');
title('Scatter Plot of Points with Selected Points Highlighted');
legend('All Points', 'Selected Points');
grid on;
plotFRFinstruments()
lgd=legend('SWOT','FRF','Water Level','Waves & Water Level');
fontsize(lgd,18,'points')
hold off;


if axis=='y'
    figure(); hold on
    plot(dataStruct.HR_pixCloud_001_354_091L_20230802.FRF_X(within_transect), dataStruct.HR_pixCloud_001_354_091L_20230802.Filtered_SWE_NAVD88(within_transect), 'o')
    title('FRF X vs WSE')

    % DEM XYZ
    demX=ncread('FRF_geomorphology_DEMs_surveyDEM_20230815.nc','xFRF');
    demY=ncread('FRF_geomorphology_DEMs_surveyDEM_20230815.nc','yFRF');
    demZ=ncread("FRF_geomorphology_DEMs_surveyDEM_20230815.nc",'elevation');
   
    % Find the index of the Y value closest to Y_transect
    [~, idx_y] = min(abs(demY - constant_value));

    % Extract the Z values for the closest Y value
    Z_transect = demZ(:, idx_y);

    plot(demX, Z_transect)
    xlabel('FRF X [m]')
    ylabel('Elevation [m] (NAVD88)')

    % Add filtered out data
    % scatter(filtered_frf_x_values, filtered_swe_values, 30, 'r', 'filled'); % Filtered points
    scatter(frf_x_values(outliers), swe_values(outliers), 50, 'k', 'x'); % Outliers

    legend('SWOT SWE','Bottom Profile','Removed Data')

else
    figure(); hold on
    subplot(211)
    plot(dataStruct.HR_pixCloud_001_354_091L_20230802.FRF_X(within_transect), dataStruct.HR_pixCloud_001_354_091L_20230802.Filtered_SWE_NAVD88(within_transect), 'o')
    title('FRF X vs WSE')
    xlabel('FRF X [m]')
    ylabel('Elevation [m] (NAVD88)')

    subplot(212)
    plot(dataStruct.HR_pixCloud_001_354_091L_20230802.FRF_Y(within_transect), dataStruct.HR_pixCloud_001_354_091L_20230802.Filtered_SWE_NAVD88(within_transect),'o')
    title('FRF Y vs WSE')
    xlabel('FRF Y [m]')
    ylabel('Elevation [m] (NAVD88)')

end

% Optionally return the results as a structure
results.indices_within_transect = find(within_transect);
results.swe_values = filtered_swe_values;
results.frf_x_values = filtered_frf_x_values;
end
