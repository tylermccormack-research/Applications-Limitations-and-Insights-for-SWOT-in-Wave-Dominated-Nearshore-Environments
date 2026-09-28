function [x, y, z] = plotGeoTIFFLatLonContour(filename, numLevels)
% plotGeoTIFFLatLonContour Reads a GeoTIFF and plots filled contours of elevation.
%
% Syntax:
%   [x, y, z] = plotGeoTIFFLatLonContour(filename)
%   [x, y, z] = plotGeoTIFFLatLonContour(filename, numLevels)
%
% Inputs:
%   filename  - String, path to the GeoTIFF file.
%   numLevels - (Optional) Number of contour levels. Default is 20.
%
% Outputs:
%   x - Longitudes (vector or matrix).
%   y - Latitudes (vector or matrix).
%   z - Elevations (matrix).
%
% Example:
%   [x, y, z] = plotGeoTIFFLatLonContour('your_file.tif', 30);

    % Default number of contour levels if not specified
    if nargin < 2
        numLevels = 20;
    end

    % Read the GeoTIFF file
    [z, R] = readgeoraster(filename);

    % Convert to double for processing if needed
    if ~isa(z, 'double')
        z = double(z);
    end

    % Handle missing data by setting no-data values to NaN
    if isfield(R, 'MissingDataIndicator')
        z(z == R.MissingDataIndicator) = NaN;
    end

    % Generate longitude (x) and latitude (y) grids based on the spatial reference
    [x, y] = meshgrid(linspace(R.XWorldLimits(1), R.XWorldLimits(2), size(z, 2)), ...
                      linspace(R.YWorldLimits(2), R.YWorldLimits(1), size(z, 1))); % Flip y-axis

    % Plot the data using filled contours
    figure;
    contourf(x, y, z, numLevels, 'LineColor', 'none');
    colormap(parula); % Use the 'parula' colormap or any other preferred colormap
    colorbar;
    clim([-4 -3])

    % Add labels and a title
    xlabel('Longitude');
    ylabel('Latitude');
    title(['GeoTIFF Elevation Contour Plot: ', filename], 'Interpreter', 'none');

    % Adjust axis for proper map display
    axis equal tight;

end
