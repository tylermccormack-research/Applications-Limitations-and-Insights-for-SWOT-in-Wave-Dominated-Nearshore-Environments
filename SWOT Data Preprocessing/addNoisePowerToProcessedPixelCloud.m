function [noise_plus_y_remapped, noise_minus_y_remapped] = addNoisePowerToProcessedPixelCloud(filename)
noise_plus_y=ncread(filename,'noise/noise_plus_y');
noise_minus_y=ncread(filename,'noise/noise_minus_y');

pixc_line_to_tvp=ncread(filename, 'pixel_cloud/pixc_line_to_tvp')+1;
azimuth_index=ncread(filename, 'pixel_cloud/azimuth_index') + 1;
slc_first_line_index_in_tvp=double(ncreadatt(filename,'/', 'slc_first_line_index_in_tvp'))+1;
pixel_cloud_index=1:length(azimuth_index);

noise_index=pixc_line_to_tvp(azimuth_index(pixel_cloud_index))-slc_first_line_index_in_tvp;

% === Remapping ===
% Preallocate outputs for speeeed
noise_plus_y_remapped=nan(length(noise_index),1);
noise_minus_y_remapped=nan(length(noise_index),1);

% Find all unique noise indices
unique_noise_ids = unique(noise_index);

% Loop over each unique noise index
for i = 1:numel(unique_noise_ids)
    this_noise_idx = unique_noise_ids(i);

    % Find pixels associated with this noise index
    pixel_mask = (noise_index == this_noise_idx);

    % Assign the corresponding noise value to all these pixels
    noise_plus_y_remapped(pixel_mask) = noise_plus_y(this_noise_idx);
    noise_minus_y_remapped(pixel_mask) = noise_minus_y(this_noise_idx);
end






end