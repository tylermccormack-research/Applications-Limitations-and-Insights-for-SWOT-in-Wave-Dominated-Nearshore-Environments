% Get version info
% L3 LR

% L2 LR
dataDir='D:\SWOT\Data\SWOTdata\frf_raster_LR_L2_250m\Expert';
[~, ~, versionFlag_LR2km] = getSwotVersionInfo(dataDir, convertedTimeArray_250m_LR_L2_SSH_Expert);

 % HR 100m
dataDir='D:\SWOT\Data\SWOTdata\frf_raster_HR_100m\SWOT_L2_HR_Raster_2.0_2.0-20241218_192027';
[fileNames, versionType, versionFlag_HR100m] = getSwotVersionInfo(dataDir, convertedTimeArray_100HR);

 % HR Pixc
dataDir='D:\SWOT\Data\SWOTdata\frf_PointCloud\SWOT_L2_HR_PIXC_2.0_2.0-20241217_171252';
[~, ~, versionFlag_HRpixc] = getSwotVersionInfo(dataDir, convertedTimeArray_pixelCloudHR);


%% 
save('D:\SWOT\Analysis\Wave height estimation\waveVariables\Versions\versionVariables.mat','versionFlag_LR2km', 'versionFlag_HR100m', 'versionFlag_HRpixc');
