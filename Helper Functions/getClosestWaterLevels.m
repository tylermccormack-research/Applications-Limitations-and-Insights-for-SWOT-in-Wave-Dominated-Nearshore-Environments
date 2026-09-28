function [waterLevels, indices] = getClosestWaterLevels(dataStruct, queryPoints)
    % Extract the relevant fields from the structure
    xCoords = dataStruct.HR_pixCloud_001_354_091L_20230802.FRF_X_qualityFiltered;
    yCoords = dataStruct.HR_pixCloud_001_354_091L_20230802.FRF_Y_qualityFiltered;
    waterLevelsData = dataStruct.HR_pixCloud_001_354_091L_20230802.Filtered_SWE_NAVD88_qualityFiltered;
    
    % Initialize output
    numPoints = size(queryPoints, 1);
    waterLevels = NaN(numPoints, 1);
    indices = NaN(numPoints, 1);
    
    % Loop through each query point to find the closest index
    for i = 1:numPoints
        qx = queryPoints(i, 1);
        qy = queryPoints(i, 2);
        
        % Compute squared distances to avoid sqrt computation for efficiency
        distances = (xCoords - qx).^2 + (yCoords - qy).^2;
        
        % Find the index of the minimum distance
        [~, minIdx] = min(distances);
        
        % Store the index and the corresponding water level
        indices(i) = minIdx;
        waterLevels(i) = waterLevelsData(minIdx);
    end
end
