%% Get data
noaaTideData = tide_get('8651370',[datenum(2023, 7, 1) datenum(2024, 12, 31)],'6-minute','navd');

%% Add a datetime field
% Convert allTime values to datetime format
noaaTideData.time_dateTime_UTC = datetime(noaaTideData.t,'ConvertFrom','datenum');


