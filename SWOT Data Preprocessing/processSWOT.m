%% 2km LR_L3_SSH_Expert
% Define the file path
filePath = 'D:\SWOT\Data\SWOTdata\L3_LR_SSH_Expert\rawData';

% L3 2km Spatial processing
[dataStruct]=processSWOT250_L3_LR_SSH_expert_func(filePath);

% Extract points closest to FRF pier water level sensor
extractedTime = structfun(@(x) x.time(x.Water_Level_Index), dataStruct, 'UniformOutput', false);
extractedSSHtemp=structfun(@(x) x.Filtered_SSH_NAVD88(x.Water_Level_Index), dataStruct, 'UniformOutput', false);

% Remove blank fields
extractedTime=removeBlankFields(extractedTime);
extractedSSHtemp=removeBlankFields(extractedSSHtemp);

% Convert all fields in the structure to double
extractedSSH_L3_LR_SSH_2km = cell2mat(struct2cell(extractedSSHtemp));
convertedTimeArray = structfun(@double,extractedTime, 'UniformOutput', false);
convertedTimeArray_L3_LR_SSH_2km = datetime(cell2mat(struct2cell(convertedTimeArray)), 'ConvertFrom', 'epochtime', 'Epoch', '2000-01-01');

save('D:\SWOT\Data\SWOTdata\L3_LR_SSH_Expert\convertedTimeArray_L3_LR_SSH_2km.mat',"convertedTimeArray_L3_LR_SSH_2km");
save('D:\SWOT\Data\SWOTdata\L3_LR_SSH_Expert\extractedSSH_L3_LR_SSH_2km.mat',"extractedSSH_L3_LR_SSH_2km")

%% 2km LR_L2_SSH_Expert
% Define the file path
% filePath = 'D:\SWOT\Data\SWOTdata\frf_raster_LR_L2_250m\Expert';
filePath = 'D:\SWOT\Data\SWOTdata\frf_raster_LR_L2_250m\Expert_versionD';

% 2km Spatial processing
[dataStruct]=processSWOT250_L2_LR_SSH_expert_func(filePath);

% Extract points closest to FRF pier water level sensor
extractedTime = structfun(@(x) x.time(x.Water_Level_Index), dataStruct, 'UniformOutput', false);
extractedSSHtemp=structfun(@(x) x.Filtered_SSH_NAVD88(x.Water_Level_Index), dataStruct, 'UniformOutput', false);

extractedTime=removeBlankFields(extractedTime);
extractedSSHtemp=removeBlankFields(extractedSSHtemp);

% Convert all fields in the structure to double
extractedSSH_250m_LR_L2_SSH_Expert = cell2mat(struct2cell(extractedSSHtemp));
convertedTimeArray = structfun(@double,extractedTime, 'UniformOutput', false);
convertedTimeArray_250m_LR_L2_SSH_Expert = datetime(cell2mat(struct2cell(convertedTimeArray)), 'ConvertFrom', 'epochtime', 'Epoch', '2000-01-01');

save('D:\SWOT\Data\SWOTdata\frf_raster_LR_L2_250m\convertedTimeArray_250m_LR_L2_SSH_Expert.mat',"convertedTimeArray_250m_LR_L2_SSH_Expert");
save('D:\SWOT\Data\SWOTdata\frf_raster_LR_L2_250m\extractedSSH_250m_LR_L2_SSH_Expert.mat',"extractedSSH_250m_LR_L2_SSH_Expert")



%% 100m HR
% Define the file path
filePath = 'D:\SWOT\Data\SWOTdata\frf_raster_HR_100m\SWOT_L2_HR_Raster_2.0_2.0-20241218_192027';

% 100m Spatial processing
[dataStruct]=processSWOT100HRfunc(filePath);

% Extract points closest to FRF pier water level sensor
extractedTime = structfun(@(x) x.time(x.Water_Level_Index), dataStruct, 'UniformOutput', false);
extractedSSHtemp=structfun(@(x) x.Filtered_SWE_NAVD88(x.Water_Level_Index), dataStruct, 'UniformOutput', false);

% Convert all fields in the structure to double
extractedSWE_100HR = structfun(@double, extractedSSHtemp);
convertedTimeArray = structfun(@double,extractedTime);
convertedTimeArray_100HR = datetime(convertedTimeArray, 'ConvertFrom', 'epochtime', 'Epoch', '2000-01-01');

save('D:\SWOT\Data\SWOTdata\frf_raster_HR_100m\convertedTimeArray_100HR.mat',"convertedTimeArray_100HR");
save('D:\SWOT\Data\SWOTdata\frf_raster_HR_100m\extractedSWE_100HR.mat',"extractedSWE_100HR")

%% Pixel Cloud HR - Big area
% Define the file path
filePath = 'D:\SWOT\Data\SWOTdata\frf_PointCloud\SWOT_L2_HR_PIXC_2.0_2.0-20241217_171252';

% Pixel Cloud Spatial processing
[dataStruct]=processSWOTpixelCloudHRfunc_bigArea(filePath);

% Extract points closest to FRF pier water level sensor
extractedTime = structfun(@(x) x.time(x.Water_Level_Index), dataStruct, 'UniformOutput', false);
extractedSSHtemp=structfun(@(x) x.Filtered_SWE_NAVD88(x.Water_Level_Index), dataStruct, 'UniformOutput', false);

% Convert all fields in the structure to double
extractedSWE_pixelCloudHR = structfun(@double, extractedSSHtemp);
convertedTimeArray = structfun(@double,extractedTime);
convertedTimeArray_pixelCloudHR = datetime(convertedTimeArray, 'ConvertFrom', 'epochtime', 'Epoch', '2000-01-01');

save('D:\SWOT\Data\SWOTdata\frf_PointCloud\convertedTimeArray_pixelCloudHR_bigArea.mat',"convertedTimeArray_pixelCloudHR");
save('D:\SWOT\Data\SWOTdata\frf_PointCloud\extractedSWE_pixelCloudHR_bigArea.mat',"extractedSWE_pixelCloudHR")

%% Current data L3_LR_SSH_unsmoothed
% Define the file path
filePath = 'D:\SWOT\Data\SWOTdata\L3_LR_SSH_unsmoothed\rawData';

% L3 2km Spatial processing
[dataStruct]=processSWOT_L3_unsmoothed(filePath);

% Extract points closest to FRF pier water level sensor
extractedTime = structfun(@(x) x.time(x.Water_Level_Index), dataStruct, 'UniformOutput', false);
extractedSSHtemp=structfun(@(x) x.Filtered_SSH_NAVD88(x.Water_Level_Index), dataStruct, 'UniformOutput', false);

% Remove blank fields
extractedTime=removeBlankFields(extractedTime);
extractedSSHtemp=removeBlankFields(extractedSSHtemp);

% Convert all fields in the structure to double
extractedSSH_L3_LR_SSH_unsmoothed = cell2mat(struct2cell(extractedSSHtemp));
convertedTimeArray = structfun(@double,extractedTime, 'UniformOutput', false);
convertedTimeArray_L3_LR_SSH_unsmoothed = datetime(cell2mat(struct2cell(convertedTimeArray)), 'ConvertFrom', 'epochtime', 'Epoch', '2000-01-01');

save('D:\SWOT\Data\SWOTdata\L3_LR_SSH_unsmoothed\convertedTimeArray_L3_LR_SSH_unsmoothed.mat',"convertedTimeArray_L3_LR_SSH_unsmoothed");
save('D:\SWOT\Data\SWOTdata\L3_LR_SSH_unsmoothed\extractedSSH_L3_LR_SSH_unsmoothed.mat',"extractedSSH_L3_LR_SSH_unsmoothed")

