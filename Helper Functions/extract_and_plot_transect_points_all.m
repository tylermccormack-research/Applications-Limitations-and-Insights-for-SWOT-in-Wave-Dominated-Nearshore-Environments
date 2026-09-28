function results = extract_and_plot_transect_points_all(dataStruct, transect_min, transect_max, constant_value, distance_threshold, axis)
    % Create a results structure to store outputs
    results = struct();

    % Loop over all fields in dataStruct
    fieldNames = fieldnames(dataStruct);
    for i = 1:numel(fieldNames)
        fieldName = fieldNames{i};
        
        % Extract coordinates from the current field
        x_coords = dataStruct.(fieldName).FRF_X_qualityFiltered;
        y_coords = dataStruct.(fieldName).FRF_Y_qualityFiltered;

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

        % Extract SWE and corresponding FRF_X & Y values within the transect
        % swe_values = dataStruct.(fieldName).Filtered_SWE_NAVD88(within_transect);
        swe_values = dataStruct.(fieldName).Filtered_SWE_NAVD88_qualityFiltered(within_transect);

        frf_x_values = dataStruct.(fieldName).FRF_X_qualityFiltered(within_transect);
        frf_y_values = dataStruct.(fieldName).FRF_Y_qualityFiltered(within_transect);

        % % Identify outliers in SWE values
        % q1 = quantile(swe_values, 0.25);
        % q3 = quantile(swe_values, 0.75);
        % iqr = q3 - q1;
        % low_bound = q1 - 1.5 * iqr;
        % high_bound = q3 + 1.5 * iqr;
        % 
        % outliers = (swe_values < low_bound) | (swe_values > high_bound);

        % Filter SWE and FRF_X values
        % filtered_swe_values = swe_values(~outliers);
        filtered_swe_values = swe_values;

        % filtered_frf_x_values = frf_x_values(~outliers);


        % Calculate SWH from SWOT
        if strcmp(axis, 'y') % Cross shore
            wseSTD = std(filtered_swe_values);
            SWH_Swot = 4 * wseSTD;
        else % Alongshore
            % wseSTD = std(dataStruct.(fieldName).Filtered_SWE_NAVD88(within_transect));
            wseSTD = std(filtered_swe_values);
            SWH_Swot = 4 * wseSTD;
        end

        % Get insitu wave height
        meanTime = mean(dataStruct.(fieldName).time);
        meanTimeDateTime = datetime(meanTime, 'ConvertFrom', 'epochtime', 'Epoch', '2000-01-01');
        fprintf('SWOT Significant wave height at %s: %.2f m\n', meanTimeDateTime, SWH_Swot);

        % Get FRF sig wave height at signature940_300
        swh_insitu = getFrfWaveHeight(meanTimeDateTime);

        % Save SWH_swot and swh_insitu for each field
        results.(fieldName).SWH_swot = SWH_Swot;
        results.(fieldName).swh_insitu = swh_insitu;

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
        lgd = legend('SWOT', 'FRF', 'Water Level', 'Waves & Water Level');
        fontsize(lgd, 18, 'points');
        hold off;

        % Format meanTimeDateTime for file naming (remove spaces, colons, etc.)
        meanTimeDateTime_str = datestr(meanTimeDateTime, 'yyyy-mm-dd_HHMMSS');

        % Save figure for the first plot
        if axis =='y'
            savefig(fullfile('D:\SWOT\Figures\waveHeightPlots\SelectedSwotPoints_CrossShore', sprintf('%s_allPoints_crossShore.fig', meanTimeDateTime_str)));
        else
            savefig(fullfile('D:\SWOT\Figures\waveHeightPlots\SelectedSwotPoints_alongshore', sprintf('%s_allPoints_alongShore.fig', meanTimeDateTime_str)));
        end

        % DEM XYZ
        [demX, demY, demZ] = getFrfDEM(meanTimeDateTime); % [demX, demY, demZ]

        % Find the index of the Y value closest to Y_transect
        [~, idx_y] = min(abs(demY - constant_value));

        % Extract the Z values for the closest Y value
        Z_transect = demZ(:, idx_y);

        % Find the index of the X value closest to Y_transect
        [~, idx_x] = min(abs(demX - constant_value));
        Z_transect_Y = demZ(idx_x, :);


        if strcmp(axis, 'y') % Cross SHore
            figure; hold on;
            plot(dataStruct.(fieldName).FRF_X_qualityFiltered(within_transect), dataStruct.(fieldName).Filtered_SWE_NAVD88_qualityFiltered(within_transect), 'o')
            title('FRF X vs WSE')
          
            plot(demX, Z_transect);
            xlabel('FRF X [m]');
            ylabel('Elevation [m] (NAVD88)');

            % Add filtered out data
            % scatter(frf_x_values(outliers), swe_values(outliers), 50, 'k', 'x'); % Outliers
            legend('SWOT SWE', 'Bottom Profile', 'Removed Data');

             % Save figure for the second plot
            saveas(gcf,fullfile('D:\SWOT\Figures\waveHeightPlots\CrossShore\', sprintf('%s_SWEvsPosition_crossShore_.png', meanTimeDateTime_str)));

        else % Along shore
            figure; hold on;
            plot(dataStruct.(fieldName).FRF_Y_qualityFiltered(within_transect), dataStruct.(fieldName).Filtered_SWE_NAVD88_qualityFiltered(within_transect), 'o');
            title('FRF Y vs WSE');
            xlabel('FRF Y [m]');
            ylabel('Elevation [m] (NAVD88)');

            % Plot BAthy
            plot(demY, Z_transect_Y);
           
             % Add filtered out data
            % scatter(frf_y_values(outliers), swe_values(outliers), 50, 'k', 'x'); % Outliers
            % legend('SWOT SWE', 'Bottom Profile', 'Removed Data');
            % xlim([700 1100])

             % Save figure for the second plot
            saveas(gcf,fullfile('D:\SWOT\Figures\waveHeightPlots\AlongShore\', sprintf('%s_SWEvsPosition_alongShore_.png', meanTimeDateTime_str)));
        end

       
    end
end
