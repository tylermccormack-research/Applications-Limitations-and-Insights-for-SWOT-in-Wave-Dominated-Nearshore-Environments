load('pixelCloud_Processed.mat')
load("passes.mat");

%% dynamic plot quality filtered and quality filtered
for i=1:length(passes(:,1))
    passNum=i;
    fieldName=passes(passNum,:);
    
    figure('Units', 'normalized', 'Position', [0 0 1 1]);
    subplot(2,1,1); hold on
    title(['Pass #' num2str(passNum) ', ' fieldName],Interpreter="none");
    scatter(dataStruct.(fieldName).FRF_X, dataStruct.(fieldName).FRF_Y)
    scatter(dataStruct.(fieldName).FRF_X(dataStruct.(fieldName).qualityFlaggedIndices), dataStruct.(fieldName).FRF_Y(dataStruct.(fieldName).qualityFlaggedIndices),'k','filled')
    
    subplot(2,1,2)
    scatter(dataStruct.(fieldName).FRF_X_qualityFiltered, dataStruct.(fieldName).FRF_Y_qualityFiltered)
    
    saveas(gcf, fullfile('D:\SWOT\Figures\qualityFlagFiltering',['Pass#' num2str(passNum) '_' fieldName]),'png')
end


%% Plot and color by quality flag code
% Define the flags for each dataset
sigma0_flags = {
    'no_flag', 'Sig0_uncert_suspect', 'Sig0_cor_atmos_suspect', ...
    'Noise_power_suspect', 'Xfactor_suspect', 'Suspect_karin_telem', ...
    'Rare_power_suspect', 'Tvp_suspect', 'Sc_event_suspect', ...
    'small_karin_gap', 'in_air_pixel_degraded', 'specular_ringing_degraded', ...
    'sig0_cor_atmos_missing', 'noise_power_bad', 'xfactor_bad', ...
    'rare_power_bad', 'tvp_bad', 'sc_event_bad', 'Large_karin_gap'
};

interferogram_flags = {
    'No_flag', 'suspect_karin_telem', 'rare_power_suspect', 'rare_phase_suspect', ...
    'tvp_suspect', 'sc_event_suspect', 'small_karin_gap', 'in_air_pixel_degraded', ...
    'specular_ringing_degraded', 'rare_power_bad', 'rare_phase_bad', 'tvp_bad', ...
    'sc_event_bad', 'large_karin_gap'
};

geolocation_flags = {
    'No_flag', 'Layover_significant', 'phase_noise_suspect', 'phase_unwrapping_suspect', ...
    'model_dry_tropo_cor_suspect', 'model_wet_tropo_cor_suspect', 'iono_cor_gim_ka_suspect', ...
    'xovercal_suspect', 'suspect_karin_telem', 'medium_phase_suspect', 'tvp_suspect', ...
    'sc_event_suspect', 'small_karin_gap', 'specular_ringing_degraded', ...
    'model_dry_tropo_cor_missing', 'model_wet_tropo_cor_missing', 'iono_cor_gim_ka_missing', ...
    'xovercal_missing', 'geolocation_is_from_refloc', 'no_geolocation_bad', 'medium_phase_bad', ...
    'tvp_bad', 'sc_event_bad', 'large_karin_gap'
};

% Define the three quality flag sets
flags1 = [0, 1, 2, 4, 8, 1024, 2048, 8192, 16384, 32768, ...
    262144, 524288, 1048576, 33554432, 67108864, 134217728, ...
    536870912, 1073741824, 2147483648];

flags2 = [0, 1024, 2048, 4096, 8192, 16384, 32768, 262144, 524288, ...
    134217728, 268435456, 536870912, 1073741824, 2147483648];

flags3 = [0, 1, 2, 4, 8, 16, 32, 64, 1024, 4096, 8192, 16384, 32768, ...
    524288, 1048576, 2097152, 4194304, 8388608, 16777216, ...
    134217728, 268435456, 536870912, 1073741824, 2147483648];

% Define a categorical colormap for 24 unique colors
num_sigma0_flags = numel(sigma0_flags);
num_interferogram_flags = numel(interferogram_flags);
num_geolocation_flags = numel(geolocation_flags);

% Use the 'parula' colormap, which is perceptually uniform and generates distinct colors
% sigma0_cmap = parula(num_sigma0_flags); % Generate unique colors for sigma0 flags
% interferogram_cmap = parula(num_interferogram_flags); % Generate unique colors for interferogram flags
geolocation_cmap = distinguishable_colors(num_geolocation_flags); % Generate unique colors for geolocation flags
sigma0_cmap = geolocation_cmap(1:num_sigma0_flags,:);
interferogram_cmap = geolocation_cmap(1:num_interferogram_flags,:);

% Handle 0 (or close to zero) values separately to make them white
white_index = 1; % First color is white

for i = 1:length(passes(:,1))
    passNum = i;
    fieldName = passes(passNum, :);

    % Create figure in fullscreen mode
    figure('Units', 'normalized', 'Position', [0 0 1 1]);
    hold on
    t = tiledlayout(3, 1);

    % Subplot 1 - Sigma0 Quality
    nexttile
    C1 = discretize(dataStruct.(fieldName).Sig0_qual, [-inf, flags1(2:end)-1, inf]); % Assign discrete bins
    C1(dataStruct.(fieldName).Sig0_qual < eps) = white_index;  % Set values close to zero to be white (index 1)
    scatter_handle1 = scatter(dataStruct.(fieldName).FRF_X, dataStruct.(fieldName).FRF_Y, 50, C1, "filled", 'MarkerEdgeColor', 'k');  % Add black edges
    colormap(gca, sigma0_cmap); % Use the distinct colors for sigma0 flags
    caxis([1 numel(sigma0_flags)]); % Ensure proper color scaling

    % Colorbar setup with discrete flags as labels
    cb1 = colorbar;
    cb1.Ticks = 1:numel(sigma0_flags); % Place ticks at discrete levels
    cb1.TickLabels = sigma0_flags; % Label them with flag names
    cb1.Label.String = 'Quality Flags (Dataset 1)';
    cb1.TickLabelInterpreter = 'none';  % Disable interpreter for tick labels
    title('Sigma0');
    xlabel('FRF X');
    ylabel('FRF Y');
    grid on;

    % Add data tips (hover-over labels) with corresponding flag names
    dataTip = scatter_handle1.DataTipTemplate;
    dataTip.DataTipRows(end+1) = dataTipTextRow('Flag', sigma0_flags(C1));  % Add custom data tip for flags
    dataTip.Interpreter = 'none';  % Prevent interpreting underscores as subscripts

    % Subplot 2 - Interferogram Quality
    nexttile
    C2 = discretize(dataStruct.(fieldName).InterferogramQual, [-inf, flags2(2:end)-1, inf]); % Assign discrete bins
    C2(dataStruct.(fieldName).InterferogramQual < eps) = white_index;  % Set values close to zero to be white (index 1)
    scatter_handle2 = scatter(dataStruct.(fieldName).FRF_X, dataStruct.(fieldName).FRF_Y, 50, C2, "filled", 'MarkerEdgeColor', 'k');  % Add black edges
    colormap(gca, interferogram_cmap); % Use the distinct colors for interferogram flags
    caxis([1 numel(interferogram_flags)]); % Ensure proper color scaling

    % Colorbar setup with discrete flags as labels
    cb2 = colorbar;
    cb2.Ticks = 1:numel(interferogram_flags); % Place ticks at discrete levels
    cb2.TickLabels = interferogram_flags; % Label them with flag names
    cb2.Label.String = 'Quality Flags (Dataset 2)';
    cb2.TickLabelInterpreter = 'none';  % Disable interpreter for tick labels
    title('Interferogram');
    xlabel('FRF X');
    ylabel('FRF Y');
    grid on;

    % Add data tips (hover-over labels) with corresponding flag names
    dataTip = scatter_handle2.DataTipTemplate;
    dataTip.DataTipRows(end+1) = dataTipTextRow('Flag', interferogram_flags(C2));  % Add custom data tip for flags
    dataTip.Interpreter = 'none';  % Prevent interpreting underscores as subscripts

    % Subplot 3 - Geolocation Quality
    nexttile
    C3 = discretize(dataStruct.(fieldName).Geolocation_qual, [-inf, flags3(2:end)-1, inf]); % Assign discrete bins
    C3(dataStruct.(fieldName).Geolocation_qual < eps) = white_index;  % Set values close to zero to be white (index 1)
    scatter_handle3 = scatter(dataStruct.(fieldName).FRF_X, dataStruct.(fieldName).FRF_Y, 50, C3, "filled", 'MarkerEdgeColor', 'k');  % Add black edges
    colormap(gca, geolocation_cmap); % Use the distinct colors for geolocation flags
    caxis([1 numel(geolocation_flags)]); % Ensure proper color scaling

    % Colorbar setup with discrete flags as labels
    cb3 = colorbar;
    cb3.Ticks = 1:numel(geolocation_flags); % Place ticks at discrete levels
    cb3.TickLabels = geolocation_flags; % Label them with flag names
    cb3.Label.String = 'Quality Flags (Dataset 3 - Geolocation)';
    cb3.TickLabelInterpreter = 'none';  % Disable interpreter for tick labels
    title('Geolocation');
    xlabel('FRF X');
    ylabel('FRF Y');
    grid on;

    % Add data tips (hover-over labels) with corresponding flag names
    dataTip = scatter_handle3.DataTipTemplate;
    dataTip.DataTipRows(end+1) = dataTipTextRow('Flag', geolocation_flags(C3));  % Add custom data tip for flags
    dataTip.Interpreter = 'none';  % Prevent interpreting underscores as subscripts


    % Adjust figure properties
    sgtitle('Scatter Plots with Distinct Color Maps');
    
    % Optionally save the figure
    saveas(gcf, fullfile('D:\SWOT\Figures\qualityFlagColored\',['Pass#' num2str(passNum) '_' fieldName]),'png')
end


%%  Plot and color by quality flag and land class code
% Load
load('pixelCloud_Processed.mat')
load("passes.mat");

% Define the flags for each dataset
sigma0_flags = {
    'no_flag', 'Sig0_uncert_suspect', 'Sig0_cor_atmos_suspect', ...
    'Noise_power_suspect', 'Xfactor_suspect', 'Suspect_karin_telem', ...
    'Rare_power_suspect', 'Tvp_suspect', 'Sc_event_suspect', ...
    'small_karin_gap', 'in_air_pixel_degraded', 'specular_ringing_degraded', ...
    'sig0_cor_atmos_missing', 'noise_power_bad', 'xfactor_bad', ...
    'rare_power_bad', 'tvp_bad', 'sc_event_bad', 'Large_karin_gap'
};

interferogram_flags = {
    'No_flag', 'suspect_karin_telem', 'rare_power_suspect', 'rare_phase_suspect', ...
    'tvp_suspect', 'sc_event_suspect', 'small_karin_gap', 'in_air_pixel_degraded', ...
    'specular_ringing_degraded', 'rare_power_bad', 'rare_phase_bad', 'tvp_bad', ...
    'sc_event_bad', 'large_karin_gap'
};

geolocation_flags = {
    'No_flag', 'Layover_significant', 'phase_noise_suspect', 'phase_unwrapping_suspect', ...
    'model_dry_tropo_cor_suspect', 'model_wet_tropo_cor_suspect', 'iono_cor_gim_ka_suspect', ...
    'xovercal_suspect', 'suspect_karin_telem', 'medium_phase_suspect', 'tvp_suspect', ...
    'sc_event_suspect', 'small_karin_gap', 'specular_ringing_degraded', ...
    'model_dry_tropo_cor_missing', 'model_wet_tropo_cor_missing', 'iono_cor_gim_ka_missing', ...
    'xovercal_missing', 'geolocation_is_from_refloc', 'no_geolocation_bad', 'medium_phase_bad', ...
    'tvp_bad', 'sc_event_bad', 'large_karin_gap'
};

landClass_flags= {'land', 'land_near_water', 'water_near_land', 'open_water', 'dark_water', 'low_coh_water_near_land', 'open_low_coh_water'};

% Define the three quality flag sets
flags1 = [0, 1, 2, 4, 8, 1024, 2048, 8192, 16384, 32768, ...
    262144, 524288, 1048576, 33554432, 67108864, 134217728, ...
    536870912, 1073741824, 2147483648];

flags2 = [0, 1024, 2048, 4096, 8192, 16384, 32768, 262144, 524288, ...
    134217728, 268435456, 536870912, 1073741824, 2147483648];

flags3 = [0, 1, 2, 4, 8, 16, 32, 64, 1024, 4096, 8192, 16384, 32768, ...
    524288, 1048576, 2097152, 4194304, 8388608, 16777216, ...
    134217728, 268435456, 536870912, 1073741824, 2147483648];

flags4= [1,2,3,4,5,6,7];

% Define a categorical colormap for 24 unique colors
num_sigma0_flags = numel(sigma0_flags);
num_interferogram_flags = numel(interferogram_flags);
num_geolocation_flags = numel(geolocation_flags);
num_landClass_flags=numel(landClass_flags);

% Use the 'parula' colormap, which is perceptually uniform and generates distinct colors
% sigma0_cmap = parula(num_sigma0_flags); % Generate unique colors for sigma0 flags
% interferogram_cmap = parula(num_interferogram_flags); % Generate unique colors for interferogram flags
geolocation_cmap = distinguishable_colors(num_geolocation_flags); % Generate unique colors for geolocation flags
sigma0_cmap = geolocation_cmap(1:num_sigma0_flags,:);
interferogram_cmap = geolocation_cmap(1:num_interferogram_flags,:);
landClass_cmap=geolocation_cmap(1:num_landClass_flags,:);

% Handle 0 (or close to zero) values separately to make them white
white_index = 1; % First color is white

for i = 1:length(passes(:,1))
    passNum = i;
    fieldName = passes(passNum, :);

    % Create figure in fullscreen mode
    figure('Units', 'normalized', 'Position', [0 0 1 1]);
    hold on
    t = tiledlayout(4, 1);

    % Subplot 1 - Sigma0 Quality
    nexttile
    C1 = discretize(dataStruct.(fieldName).Sig0_qual, [-inf, flags1(2:end)-1, inf]); % Assign discrete bins
    C1(dataStruct.(fieldName).Sig0_qual < eps) = white_index;  % Set values close to zero to be white (index 1)
    scatter_handle1 = scatter(dataStruct.(fieldName).FRF_X, dataStruct.(fieldName).FRF_Y, 50, C1, "filled", 'MarkerEdgeColor', 'k');  % Add black edges
    colormap(gca, sigma0_cmap); % Use the distinct colors for sigma0 flags
    caxis([1 numel(sigma0_flags)]); % Ensure proper color scaling

    % Colorbar setup with discrete flags as labels
    cb1 = colorbar;
    cb1.Ticks = 1:numel(sigma0_flags); % Place ticks at discrete levels
    cb1.TickLabels = sigma0_flags; % Label them with flag names
    cb1.Label.String = 'Quality Flags (Dataset 1)';
    cb1.TickLabelInterpreter = 'none';  % Disable interpreter for tick labels
    title('Sigma0');
    xlabel('FRF X');
    ylabel('FRF Y');
    grid on;

    % Add data tips (hover-over labels) with corresponding flag names
    dataTip = scatter_handle1.DataTipTemplate;
    dataTip.DataTipRows(end+1) = dataTipTextRow('Flag', sigma0_flags(C1));  % Add custom data tip for flags
    dataTip.Interpreter = 'none';  % Prevent interpreting underscores as subscripts

    % Subplot 2 - Interferogram Quality
    nexttile
    C2 = discretize(dataStruct.(fieldName).InterferogramQual, [-inf, flags2(2:end)-1, inf]); % Assign discrete bins
    C2(dataStruct.(fieldName).InterferogramQual < eps) = white_index;  % Set values close to zero to be white (index 1)
    scatter_handle2 = scatter(dataStruct.(fieldName).FRF_X, dataStruct.(fieldName).FRF_Y, 50, C2, "filled", 'MarkerEdgeColor', 'k');  % Add black edges
    colormap(gca, interferogram_cmap); % Use the distinct colors for interferogram flags
    caxis([1 numel(interferogram_flags)]); % Ensure proper color scaling

    % Colorbar setup with discrete flags as labels
    cb2 = colorbar;
    cb2.Ticks = 1:numel(interferogram_flags); % Place ticks at discrete levels
    cb2.TickLabels = interferogram_flags; % Label them with flag names
    cb2.Label.String = 'Quality Flags (Dataset 2)';
    cb2.TickLabelInterpreter = 'none';  % Disable interpreter for tick labels
    title('Interferogram');
    xlabel('FRF X');
    ylabel('FRF Y');
    grid on;

    % Add data tips (hover-over labels) with corresponding flag names
    dataTip = scatter_handle2.DataTipTemplate;
    dataTip.DataTipRows(end+1) = dataTipTextRow('Flag', interferogram_flags(C2));  % Add custom data tip for flags
    dataTip.Interpreter = 'none';  % Prevent interpreting underscores as subscripts

    % Subplot 3 - Geolocation Quality
    nexttile
    C3 = discretize(dataStruct.(fieldName).Geolocation_qual, [-inf, flags3(2:end)-1, inf]); % Assign discrete bins
    C3(dataStruct.(fieldName).Geolocation_qual < eps) = white_index;  % Set values close to zero to be white (index 1)
    scatter_handle3 = scatter(dataStruct.(fieldName).FRF_X, dataStruct.(fieldName).FRF_Y, 50, C3, "filled", 'MarkerEdgeColor', 'k');  % Add black edges
    colormap(gca, geolocation_cmap); % Use the distinct colors for geolocation flags
    caxis([1 numel(geolocation_flags)]); % Ensure proper color scaling

    % Colorbar setup with discrete flags as labels
    cb3 = colorbar;
    cb3.Ticks = 1:numel(geolocation_flags); % Place ticks at discrete levels
    cb3.TickLabels = geolocation_flags; % Label them with flag names
    cb3.Label.String = 'Quality Flags (Dataset 3 - Geolocation)';
    cb3.TickLabelInterpreter = 'none';  % Disable interpreter for tick labels
    title('Geolocation');
    xlabel('FRF X');
    ylabel('FRF Y');
    grid on;

    % Add data tips (hover-over labels) with corresponding flag names
    dataTip = scatter_handle3.DataTipTemplate;
    dataTip.DataTipRows(end+1) = dataTipTextRow('Flag', geolocation_flags(C3));  % Add custom data tip for flags
    dataTip.Interpreter = 'none';  % Prevent interpreting underscores as subscripts

    % Subplot 4 - Land Class
    nexttile
    % C4 = discretize(dataStruct.(fieldName).landClass, [-inf, flags4(1:end)-1, inf]); % Assign discrete bins
    scatter_handle4 = scatter(dataStruct.(fieldName).FRF_X, dataStruct.(fieldName).FRF_Y, 50, dataStruct.(fieldName).landClass, "filled", 'MarkerEdgeColor', 'k');  % Add black edges
    colormap(gca, landClass_cmap); % Use the distinct colors for geolocation flags
    caxis([1 numel(landClass_flags)]); % Ensure proper color scaling

    % Colorbar setup with discrete flags as labels
    cb4 = colorbar;
    cb4.Ticks = 1:numel(landClass_flags); % Place ticks at discrete levels
    cb4.TickLabels = landClass_flags; % Label them with flag names
    cb4.Label.String = 'Land Class Flags (Dataset 3 - Land Class)';
    cb4.TickLabelInterpreter = 'none';  % Disable interpreter for tick labels
    title('Land Class');
    xlabel('FRF X');
    ylabel('FRF Y');
    grid on;

    % Add data tips (hover-over labels) with corresponding flag names
    dataTip = scatter_handle4.DataTipTemplate;
    dataTip.DataTipRows(end) = dataTipTextRow('Flag', landClass_flags(dataStruct.(fieldName).landClass));  % Add custom data tip for flags
    dataTip.Interpreter = 'none';  % Prevent interpreting underscores as subscripts
    
    % Adjust figure properties
    sgtitle('Scatter Plots with Distinct Color Maps');
    
    % Optionally save the figure
    saveas(gcf, fullfile('D:\SWOT\Figures\qualityFlagColored\plusLandCover\',['Pass#' num2str(passNum) '_' fieldName]),'png')
end
