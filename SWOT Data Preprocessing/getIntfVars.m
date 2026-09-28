function [intfX, intfY, Interferogram, AngleCorr, GeomCorr, NoiseCorr] = getIntfVars(intfFilename)
% Interpolates angle_correction and geom_correction to the pixel cloud grid
% using lat/lon → FRF coordinate conversion.
%
% Inputs:
%   dataStruct  - Struct with pixel cloud data: dataStruct.dataStruct
%   intfFilename - Path to HR_L1B_SLC NetCDF file
%
% Output:
%   dataStruct  - Updated with AngleCorrection_interp and GeomCorrection_interp fields


 % Load HR pixel cloud for mapping
 % dataStruct=load('pixelCloud_Processed_bigArea.mat');

% === 1. Extract date from filename ===
% tokens = regexp(intfFilename, '\d{8}', 'match');
% if isempty(tokens)
%     error('No valid date found in SLC filename.');
% end
% slc_date = tokens{1};
% 
% % === 2. Match pixel cloud field by date ===
% fieldNames = fieldnames(dataStruct.dataStruct);
% matchField = '';
% for i = 1:numel(fieldNames)
%     if contains(fieldNames{i}, slc_date)
%         matchField = fieldNames{i};
%         break;
%     end
% end
% if isempty(matchField)
%     error('No matching pixel cloud field found for date %s', slc_date);
% end
% fprintf('[INFO] Matched pixel cloud field: %s\n', matchField);
% 
% % === 3. Load pixel cloud grid coordinates (FRF) ===
% pix = dataStruct.dataStruct.(matchField);
% Xpix = double(pix.FRF_X);
% Ypix = double(pix.FRF_Y);
% sz = size(Xpix);

% === 4. Load SLC noise corrections and lat/lon ===
% Read NetCDF information and variables
parts = split(intfFilename, '_');
track_number = parts{6};

if strcmp(track_number, '354')
    tmpRefLat=ncread(intfFilename,'left/reference_latitude');
    tmpRefLon=ncread(intfFilename, 'left/reference_longitude');
    tmpIntf=ncread(intfFilename, 'left/interferogram');
    tmpAngCorr = ncread(intfFilename, 'left/angular_correlation');
    tmpGeomCorr = ncread(intfFilename, 'left/geometric_correlation');
    tmpNoiseCorr = ncread(intfFilename, 'left/noise_correlation');
else
    tmpRefLat=ncread(intfFilename,'right/reference_latitude');
    tmpRefLon=ncread(intfFilename, 'right/reference_longitude');
    tmpIntf=ncread(intfFilename, 'right/interferogram');
    tmpAngCorr = ncread(intfFilename, 'right/angular_correlation');
    tmpGeomCorr = ncread(intfFilename, 'right/geometric_correlation');
    tmpNoiseCorr = ncread(intfFilename, 'right/noise_correlation');
end


% Convert from 0-360 longitude to -180 to 180
tmpRefLon = rem((tmpRefLon + 180), 360) - 180;

% % Geographic location mask
minLat = 36.15;
maxLat = 36.22;
minLon = -75.765;
maxLon = -75.69;
%
locationMask = (tmpRefLat >= minLat) & (tmpRefLat <= maxLat) & ...
    (tmpRefLon >= minLon) & (tmpRefLon <= maxLon);

% Combine both masks
combinedMask = locationMask;

% Convert to FRF Coordinates
[~, ~, ~, ~, intfY, intfX] = frfCoord_bigArea(tmpRefLon(combinedMask), tmpRefLat(combinedMask));

Interferogram=tmpIntf(:,combinedMask);
AngleCorr=tmpAngCorr(combinedMask);
GeomCorr=tmpGeomCorr(combinedMask);
NoiseCorr=tmpNoiseCorr(combinedMask);

% % Reshape corrections to match (assume same size as tmpRefLat/Lon)
% szSlc = size(intfY);
% angleCorr = reshape(tmpAngCorr, szSlc);
% geomCorr  = reshape(tmpGeomCorr,  szSlc);
% intfX = reshape(intfX, szSlc);
% intfY = reshape(intfY, szSlc);
% 
% % === 6. Interpolate to pixel cloud FRF grid ===
% fprintf('[INFO] Interpolating corrections to pixel grid...\n');
% 
% % AngleInterp = interp2(intfX, intfY, angleCorr, Xpix, Ypix, 'linear', NaN);
% % GeomInterp  = interp2(intfX, intfY, geomCorr,  Xpix, Ypix, 'linear', NaN);
% 
% F_angle = scatteredInterpolant(intfX(:), intfY(:), angleCorr(:), 'nearest', 'nearest');
% F_geom  = scatteredInterpolant(intfX(:), intfY(:), geomCorr(:),  'nearest', 'nearest');
% 
% AngleInterp = F_angle(Xpix, Ypix);
% GeomInterp  = F_geom(Xpix, Ypix);

% === 7. Save back to struct ===
% dataStruct.dataStruct.(matchField).AngleCorrection_interp = AngleInterp;
% dataStruct.dataStruct.(matchField).GeomCorrection_interp  = GeomInterp;

% dataStructOut=dataStruct.dataStruct;

        % % Store results in the structure under the unique key
        % dataStructOut.(fieldName) = struct( ...
        %     'FRF_X', Xpix, ...
        %     'FRF_Y', Ypix, ...
        %     'AngleCorrelation_interp', AngleInterp, ...
        %     'GeomCorrection_interp',GeomInterp ...
        %     );

% fprintf('[DONE] Interpolated angle and geom correction added to: %s\n', matchField);

end
