function [allTimeDatetime, allWaterLevel] = combineWaterLevelData(folderPath)
    % PROCESSWATERLEVELDATA Process NetCDF water level data from a folder.
    %
    % INPUT:
    % folderPath - Path to the folder containing NetCDF files
    %
    % OUTPUTS:
    % allTimeDatetime - Array of datetime values for all files
    % allWaterLevel   - Array of water level values for all files

    % Define the time units (adjust if needed based on NetCDF metadata)
    timeUnits = 'seconds since 1970-01-01 00:00:00';

    % Get a list of all the NetCDF files in the folder
    ncFiles = dir(fullfile(folderPath, '*.nc'));

    % Initialize empty arrays to store the data
    allTime = [];
    allWaterLevel = [];

    % Loop through each NetCDF file
    for i = 1:length(ncFiles)
        % Get the full file path
        filePath = fullfile(folderPath, ncFiles(i).name);

        % Read 'time' and 'waterLevel' variables from the current file
        time = ncread(filePath, 'time');
        waterLevel = ncread(filePath, 'waterLevel');

        % Append the data to the new variables
        allTime = [allTime; time];
        allWaterLevel = [allWaterLevel; waterLevel];
    end

    % Parse time reference from units
    % Assuming units like 'seconds since 1970-01-01 00:00:00'
    parts = split(timeUnits, 'since');
    epochStr = strtrim(parts{2}); % Extract the reference date
    timeReference = datetime(epochStr, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');

    % Convert allTime values to datetime format
    allTimeDatetime = timeReference + seconds(allTime);

    % % Plot the water level against the datetime values
    % figure;
    % plot(allTimeDatetime, allWaterLevel);
    % xlabel('Date and Time');
    % ylabel('Water Level');
    % title('Water Level over Time');
    % grid on;
end
