function [filteredFrfY, filteredFrfX, filteredHeight, filteredTime, filteredTotalCoherence] = filterFRFregion_frf_LR_L2_SSH(lat, lon, height, time, totalCoherence)
% function [finalBox, filteredFrfX, filteredFrfY] = filterFRFregion_frf(lat, lon, inBox)

% bound in FRF coords
% Bounding box: [minLat, minLon], [maxLat, maxLon]
% minLat = 400;
% maxLat = 1200;
% minLon = 0;
% maxLon = 1000;

minLat = -2.262781142106977e+03;
maxLat = 6.567322391840778e+03;
minLon = -2.480968397304855e+03;
maxLon = 2.798956943250666e+03;

% Create logical indices for points where BOTH lat and lon are within bounds
inBox2 = (lat >= minLat) & (lat <= maxLat) & (lon >= minLon) & (lon <= maxLon);

% finalBox=false(size(inBox));
% finalBox(inBox)=inBox2;

% Filter lat and lon arrays by the paired indices
filteredFrfX=lon(inBox2);
filteredFrfY=lat(inBox2);

filteredHeight=height(inBox2);
filteredTime=time(inBox2);
filteredTotalCoherence=totalCoherence(inBox2);

end
