function [filteredLat,filteredLon, filteredHeight, filteredTime, filteredU, filteredV] = filterFRFregion_latlong_L3_LR_SSH_unsmoothed(lat, lon, height, time, U, V)
% function [filteredLat,filteredLon, inBox] = filterFRFregion_latlong(lat, lon)
% First Bound in lat long
% Bounding box: [minLat, minLon], [maxLat, maxLon]
% [maxLat,maxLon,~,~,~,~,]=frfCoord(6000, 2000); %  Good for the closer buoy
% [maxLat,maxLon,~,~,~,~,]=frfCoord_bigArea(6.567322391840778e+03, 2.798956943250666e+03); %  Good for the closer buoy
% [minLat, minLon, ~,~,~,~]=frfCoord_bigArea(-2.262781142106977e+03, -2.480968397304855e+03);
minLat = 36;
maxLat = 37;
minLon = -76;
maxLon = -75;

% Create logical indices for points where BOTH lat and lon are within bounds
inBox = (lat >= minLat) & (lat <= maxLat) & (lon >= minLon) & (lon <= -maxLon);

% Filter lat and lon arrays by the paired indices
filteredLat = lat(inBox);
filteredLon = lon(inBox);
filteredHeight=height(inBox);
filteredTime=time(inBox);
filteredU=U(inBox);
filteredV=V(inBox);
end