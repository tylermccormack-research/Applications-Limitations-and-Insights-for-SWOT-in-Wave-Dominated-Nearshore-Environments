function navd88_heights = convertToNAVD88(latitudes, longitudes, wgs84_heights)
    % CONVERTTONAVD88 Converts WGS84 heights to NAVD88 heights
    %
    % Inputs:
    %   latitudes     - Array of latitudes (degrees)
    %   longitudes    - Array of longitudes (degrees)
    %   wgs84_heights - Array of heights in WGS84 (meters)
    %
    % Output:
    %   navd88_heights - Array of heights in NAVD88 (meters)
    %
    % Example:
    %   latitudes = [34.0, 36.0];
    %   longitudes = [-120.0, -122.0];
    %   wgs84_heights = [10, 15];
    %   navd88_heights = convertToNAVD88(latitudes, longitudes, wgs84_heights);

    % Ensure inputs are column vectors for consistent processing
    latitudes = latitudes(:);
    longitudes = longitudes(:);
    wgs84_heights = wgs84_heights(:);

    % Validate inputs
    if numel(latitudes) ~= numel(longitudes) || numel(latitudes) ~= numel(wgs84_heights)
        error('Input arrays latitudes, longitudes, and wgs84_heights must have the same length.');
    end

    % Calculate geoid heights using the geoidheight function
    geoid_heights = geoidheight(latitudes, longitudes, 'egm2008');

    % Convert WGS84 heights to NAVD88
    navd88_heights = wgs84_heights- geoid_heights;
end
