%% LR L2 Unsmoothed- new
% Define the file path
filePath = 'D:\SWOT\Data\SWOTdata\frf_raster_LR_L2_250m\SWOT_L2_LR_SSH_2.0_2.0-20241219_165351';

% 250m Spatial processing
[dataStruct]=processSWOT250LRfunc(filePath);

% Extract points closest to FRF pier water level sensor
extractedTime = structfun(@(x) x.time(x.Water_Level_Index), dataStruct, 'UniformOutput', false);
extractedSSHtemp=structfun(@(x) x.Filtered_SSH_NAVD88(x.Water_Level_Index), dataStruct, 'UniformOutput', false);

% Remove blank fields
extractedTime=removeBlankFields(extractedTime);
extractedSSHtemp=removeBlankFields(extractedSSHtemp);

% Convert all fields in the structure to double
extractedSSH_L2_LR_SSH_unsmoothed = cell2mat(struct2cell(extractedSSHtemp));
convertedTimeArray = structfun(@double,extractedTime, 'UniformOutput', false);
convertedTimeArray_L2_LR_SSH_unsmoothed = datetime(cell2mat(struct2cell(convertedTimeArray)), 'ConvertFrom', 'epochtime', 'Epoch', '2000-01-01');

save('D:\SWOT\Data\SWOTdata\frf_raster_LR_L2_250m\convertedTimeArray_L2_LR_SSH_unsmoothed.mat',"convertedTimeArray_L2_LR_SSH_unsmoothed");
save('D:\SWOT\Data\SWOTdata\frf_raster_LR_L2_250m\extractedSSH_L2_LR_SSH_unsmoothed.mat',"extractedSSH_L2_LR_SSH_unsmoothed")

%% 250m LR_L2_SSH_Expert
% Define the file path
filePath = 'D:\SWOT\Data\SWOTdata\frf_raster_LR_L2_250m\Expert';

% 250m Spatial processing
[dataStruct]=processSWOT250_L2_LR_SSH_expert_func(filePath);

% Extract points closest to FRF pier water level sensor
extractedTime = structfun(@(x) x.time(x.Water_Level_Index), dataStruct, 'UniformOutput', false);
extractedSSHtemp=structfun(@(x) x.Filtered_SSH_NAVD88(x.Water_Level_Index), dataStruct, 'UniformOutput', false);

% Convert all fields in the structure to double
extractedSSH_250m_LR_L2_SSH_Expert = structfun(@double, extractedSSHtemp);
convertedTimeArray = structfun(@double,extractedTime);
convertedTimeArray_250m_LR_L2_SSH_Expert = datetime(convertedTimeArray, 'ConvertFrom', 'epochtime', 'Epoch', '2000-01-01');

save('D:\SWOT\Data\SWOTdata\frf_raster_LR_L2_250m\convertedTimeArray_250m_LR_L2_SSH_Expert.mat',"convertedTimeArray_250m_LR_L2_SSH_Expert");
save('D:\SWOT\Data\SWOTdata\frf_raster_LR_L2_250m\extractedSSH_250m_LR_L2_SSH_Expert.mat',"extractedSSH_250m_LR_L2_SSH_Expert")

%% LR_L1B_INTF (interpolated onto pixel cloud)
% Define the file path
filePath = 'D:\SWOT\Data\SWOTdata\L1B_LR_INTF';

% 250m Spatial processing
processSWOT_L1_LR_INTF(filePath);

% % Extract points closest to FRF pier water level sensor
% extractedTime = structfun(@(x) x.time(x.Water_Level_Index), dataStruct, 'UniformOutput', false);
% extractedSSHtemp=structfun(@(x) x.Filtered_SSH_NAVD88(x.Water_Level_Index), dataStruct, 'UniformOutput', false);
% 
% % Convert all fields in the structure to double
% extracted_LR_L1B_INTF = structfun(@double, extractedSSHtemp);
% convertedTimeArray = structfun(@double,extractedTime);
% convertedTimeArray_LR_L1B_INTF = datetime(convertedTimeArray, 'ConvertFrom', 'epochtime', 'Epoch', '2000-01-01');
% 
% save('D:\SWOT\Data\SWOTdata\L1B_LR_INTF\convertedTimeArray_LR_L1B_INTF.mat',"convertedTimeArray_LR_L1B_INTF");
% save('D:\SWOT\Data\SWOTdata\L1B_LR_INTF\extracted_LR_L1B_INTF.mat',"extracted_LR_L1B_INTF")


%% LR_L1B_INTF (not interpoalted, for LR comparison)
% Define the file path
filePath = 'D:\SWOT\Data\SWOTdata\L1B_LR_INTF';

% 250m Spatial processing
dataStructCheck=processSWOT_L1_LR_INTF_noInterp(filePath);

% % Extract points closest to FRF pier water level sensor
% extractedTime = structfun(@(x) x.time(x.Water_Level_Index), dataStruct, 'UniformOutput', false);
% extractedSSHtemp=structfun(@(x) x.Filtered_SSH_NAVD88(x.Water_Level_Index), dataStruct, 'UniformOutput', false);
% 
% % Convert all fields in the structure to double
% extracted_LR_L1B_INTF = structfun(@double, extractedSSHtemp);
% convertedTimeArray = structfun(@double,extractedTime);
% convertedTimeArray_LR_L1B_INTF = datetime(convertedTimeArray, 'ConvertFrom', 'epochtime', 'Epoch', '2000-01-01');
% 
% save('D:\SWOT\Data\SWOTdata\L1B_LR_INTF\convertedTimeArray_LR_L1B_INTF.mat',"convertedTimeArray_LR_L1B_INTF");
% save('D:\SWOT\Data\SWOTdata\L1B_LR_INTF\extracted_LR_L1B_INTF.mat',"extracted_LR_L1B_INTF")


%% 250m HR
% % Define the file path
% filePath = 'D:\SWOT\Data\SWOTdata\frf_raster_HR_250m\SWOT_L2_HR_Raster_2.0_2.0-20241218_191103';
% 
% % 250m Spatial processing
% [dataStruct]=processSWOT250HRfunc(filePath);
% 
% % Extract points closest to FRF pier water level sensor
% extractedTime = structfun(@(x) x.time(x.Water_Level_Index), dataStruct, 'UniformOutput', false);
% extractedSSHtemp=structfun(@(x) x.Filtered_SSH_NAVD88(x.Water_Level_Index), dataStruct, 'UniformOutput', false);
% 
% % Convert all fields in the structure to double
% extractedSSH_250HR = structfun(@double, extractedSSHtemp);
% convertedTimeArray = structfun(@double,extractedTime);
% convertedTimeArray_250HR = datetime(convertedTimeArray, 'ConvertFrom', 'epochtime', 'Epoch', '2000-01-01');
% 
% save('D:\SWOT\Data\SWOTdata\frf_raster_HR_250m\convertedTimeArray_250HR.mat',"convertedTimeArray_250HR");
% save('D:\SWOT\Data\SWOTdata\frf_raster_HR_250m\extractedSSH_250HR.mat',"extractedSSH_250HR")

%% 100m HR
% % Define the file path
% filePath = 'D:\SWOT\Data\SWOTdata\frf_raster_HR_100m\SWOT_L2_HR_Raster_2.0_2.0-20241218_192027';
% 
% % 100m Spatial processing
% [dataStruct]=processSWOT100HRfunc(filePath);
% 
% % Extract points closest to FRF pier water level sensor
% extractedTime = structfun(@(x) x.time(x.Water_Level_Index), dataStruct, 'UniformOutput', false);
% extractedSSHtemp=structfun(@(x) x.Filtered_SWE_NAVD88(x.Water_Level_Index), dataStruct, 'UniformOutput', false);
% 
% % Convert all fields in the structure to double
% extractedSWE_100HR = structfun(@double, extractedSSHtemp);
% convertedTimeArray = structfun(@double,extractedTime);
% convertedTimeArray_100HR = datetime(convertedTimeArray, 'ConvertFrom', 'epochtime', 'Epoch', '2000-01-01');
% 
% save('D:\SWOT\Data\SWOTdata\frf_raster_HR_100m\convertedTimeArray_100HR.mat',"convertedTimeArray_100HR");
% save('D:\SWOT\Data\SWOTdata\frf_raster_HR_100m\extractedSWE_100HR.mat',"extractedSWE_100HR")

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

% save('D:\SWOT\Data\SWOTdata\frf_PointCloud\convertedTimeArray_pixelCloudHR_bigArea.mat',"convertedTimeArray_pixelCloudHR");
% save('D:\SWOT\Data\SWOTdata\frf_PointCloud\extractedSWE_pixelCloudHR_bigArea.mat',"extractedSWE_pixelCloudHR")

%% Pixel Cloud HR - OG small area
% % Define the file path
% filePath = 'D:\SWOT\Data\SWOTdata\frf_PointCloud\SWOT_L2_HR_PIXC_2.0_2.0-20241217_171252';
% 
% % Pixel Cloud Spatial processing
% [dataStruct]=processSWOTpixelCloudHRfunc(filePath);
% 
% % Extract points closest to FRF pier water level sensor
% extractedTime = structfun(@(x) x.time(x.Water_Level_Index), dataStruct, 'UniformOutput', false);
% extractedSSHtemp=structfun(@(x) x.Filtered_SWE_NAVD88(x.Water_Level_Index), dataStruct, 'UniformOutput', false);
% 
% % Convert all fields in the structure to double
% extractedSWE_pixelCloudHR = structfun(@double, extractedSSHtemp);
% convertedTimeArray = structfun(@double,extractedTime);
% convertedTimeArray_pixelCloudHR = datetime(convertedTimeArray, 'ConvertFrom', 'epochtime', 'Epoch', '2000-01-01');
% 
% save('D:\SWOT\Data\SWOTdata\frf_PointCloud\convertedTimeArray_pixelCloudHR.mat',"convertedTimeArray_pixelCloudHR");
% save('D:\SWOT\Data\SWOTdata\frf_PointCloud\extractedSWE_pixelCloudHR.mat',"extractedSWE_pixelCloudHR")

%% Pixel Cloud HR - Big area L1_SLC
% Define the file path
filePath = 'D:\SWOT\Data\SWOTdata\L1B_HR_SLC';

% Pixel Cloud Spatial processing
[dataStruct]=processSWOTpixelCloudHRfunc_bigArea_L1_SLC(filePath);

% Extract points closest to FRF pier water level sensor
extractedTime = structfun(@(x) x.time(x.Water_Level_Index), dataStruct, 'UniformOutput', false);
extractedSSHtemp=structfun(@(x) x.Filtered_SWE_NAVD88(x.Water_Level_Index), dataStruct, 'UniformOutput', false);

% Convert all fields in the structure to double
extractedSWE_pixelCloudHR_L1_SLC = structfun(@double, extractedSSHtemp);
convertedTimeArray = structfun(@double,extractedTime);
convertedTimeArray_pixelCloudHR_L1_SLC = datetime(convertedTimeArray, 'ConvertFrom', 'epochtime', 'Epoch', '2000-01-01');

save('D:\SWOT\Data\SWOTdata\L1B_HR_SLC\convertedTimeArray_pixelCloudHR_bigArea_L1_SLC.mat',"convertedTimeArray_pixelCloudHR_L1_SLC");
save('D:\SWOT\Data\SWOTdata\L1B_HR_SLC\extractedSWE_pixelCloudHR_bigArea_L1_SLC.mat',"extractedSWE_pixelCloudHR_L1_SLC")