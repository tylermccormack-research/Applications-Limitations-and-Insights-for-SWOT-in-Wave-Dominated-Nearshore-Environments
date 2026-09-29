paths = setupPaths();

station=8651370;
dateStart=datenum('01-Aug-2023');
dateEnd=datenum('31-Dec-2025');
dates=[dateStart dateEnd];
interval='6-minute';
datum='msl';

noaaTideData_all = tide_get(station,dates,interval,datum);

noaaTideData_all_navd88 = tide_get(station,dates,interval,'navd');

%% Convert time
noaaTideData_all.time_dateTime=datetime(noaaTideData_all.t, "ConvertFrom","datenum");
noaaTideData_all_navd88.time_dateTime=datetime(noaaTideData_all_navd88.t, "ConvertFrom","datenum");

%% Save

save('D:\SWOT\Data\FRF Hydro data\WaterLevel\noaaTideData_all.mat',"noaaTideData_all")

save('D:\SWOT\Data\FRF Hydro data\WaterLevel\noaaTideData_all_navd88.mat',"noaaTideData_all_navd88")