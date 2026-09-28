% function [filteredLat,filteredLon, filteredHeight, filteredTime, filteredTotalCoherence] = filterFRFregion_latlong(lat, lon, height, time, totalCoherence)
function [filteredLat,filteredLon, inBox] = filterFRFregion_latlong(lat, lon)
% First Bound in lat long
% Bounding box: [minLat, minLon], [maxLat, maxLon]
[maxLat,maxLon,~,~,~,~,]=frfCoord(6000, 2000); %  Good for the closer buoy

minLat = 36.1;
% maxLat = 36.22;
minLon = -75.765;
% maxLon = -75.69;

% Create logical indices for points where BOTH lat and lon are within bounds
inBox = (lat >= minLat) & (lat <= maxLat) & (lon >= minLon) & (lon <= -maxLon);

% Filter lat and lon arrays by the paired indices
filteredLat = lat(inBox);
filteredLon = lon(inBox);
% filteredHeight=height(inBox);
% filteredTime=time(inBox);
% filteredTotalCoherence=totalCoherence(inBox);
end