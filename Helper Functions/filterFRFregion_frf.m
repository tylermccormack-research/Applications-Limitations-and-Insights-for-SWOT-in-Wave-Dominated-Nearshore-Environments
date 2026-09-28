% function [filteredLat,filteredLon, filteredHeight, filteredTime] = filterFRFregion_frf(lat, lon, height, time)
function [finalBox, filteredFrfX, filteredFrfY] = filterFRFregion_frf(lat, lon, inBox)

% bound in FRF coords
% Bounding box: [minLat, minLon], [maxLat, maxLon]
minLat = 0;
maxLat = 1200;
minLon = 0;
maxLon = 1000;

% Create logical indices for points where BOTH lat and lon are within bounds
inBox2 = (lat >= minLat) & (lat <= maxLat) & (lon >= minLon) & (lon <= maxLon);

finalBox=false(size(inBox));
finalBox(inBox)=inBox2;

% Filter lat and lon arrays by the paired indices
filteredFrfX=lon(inBox2);
filteredFrfY=lat(inBox2);

end
