function out = tide_get(station,dates,interval,datum)
%TIDE_GET  Gets COOPS Data from web (https://tidesandcurrents.noaa.gov/index.shtml).
%
%   OUT = TIDE_GET(station,DATES) gets the tide data for STATION from
%   (or between and including) DATE(S) where STATION is an NOS id
%   number and DATE(S) is/are Matlab datenum(s) or a year or '*'
%   (get everything available).
%
%   Input:
%     STATION = num (ex.  station = 8760922) Duck = 8651370 
%     DATE(S) = datenum | [datenum1 datenum2] | year | '*';
%     INTERVAL = 'hourly' (default) | one of: '6-minute','high/low',
%                 'monthly'
%     datum = 'msl' (default) | one of: 'mhhw','mhw','mlw','mllw','navd'
%   Output:
%     OUT = structure:
%           station = BUOY
%           longitude = longitude
%           latitude = latitude
%           time = time
%           predicted = predicted tide
%           measured = measured tide
%
% Check here if there are problems with the urls being generated:
% http://tidesandcurrents.noaa.gov/api/#products
%
% Dave Thompson (dthompson@usgs.gov)
%
%%

% All stations are listed here.
%url = 'https://tidesandcurrents.noaa.gov/station_retrieve.shtml?type=Historic%20Tide%20Data&state=All%20Stations&id1=';

out.station = station;
station = num2str(station);
dates = dates(:)';

% Check interval.
if ~exist('interval','var')
   interval = 'hourly';
end

% Interval option.
intopt = {'6-minute',1,'water_level';'hourly',2,'hourly_height';...
   'high/low',3,'high_low';'monthly',4,'monthly_mean'};
int = find(strcmp(interval,intopt(:,1)));
if ~isempty(int)
   product = intopt{int,3};
else
   disp([9,'Bad interval',10])
   return
end

% DATE
% If one day or a year.
if length(dates)==1 && ~strcmp(dates,'*')
   tmp = datevec(dates); % datevec always returns 5 for the year if it's passed one number?
   % Get one year.
   if tmp(1)==5
      dates = [datenum(dates,1,1) datenum(dates,12,31)];
   else
      dates = [dates dates];
   end
end

% Get all available -> check inventory. Get all the years for which data is
% available.
if strcmp(dates,'*')
   url = ['https://tidesandcurrents.noaa.gov/inventory.html?id=',station];
   tmp = webread(url);
   % These data.push lines define the time periods for which data is
   % available.
   id = regexp(tmp,'data.push');
   if isempty(id)
      disp([10,9,'No data inventory for station ',station,'.',10])
      return
   end
   id = [id id(end)+250];
   for ii=1:length(id)-1
      c(ii) = {tmp(id(ii):id(ii+1))};
   end
   
   % Now just for the interval we're interested in.
   id = regexpi(c,intopt{int,1});
   c = c(~cellfun(@isempty,id));
   
   if isempty(c)
      disp([10,9,'No data for the interval of interest for station ',...
         station,'.',10])
      return
   end
   years = [];
   for ii=1:length(c)
      d = regexp(c{ii},'\d{4}(, \d{1,2})+','match');
      d = str2num(char(d{:}));
      years = [years; [d(1,1):d(2,1)]'];
   end
   years = unique(years);
   
   dates = [];
   for ii=1:length(years)
      dates = [dates; [datenum(years(ii),1,1) datenum(years(ii),12,31)]];
   end
   %if int==1
   %   disp([9,'Really!??! You want 6-minute for all time?"',10,9,'Add to code'];)
   %   return
   %end
end

% Check datum.
if ~exist('datum','var')
   datum = 'MSL';
end
if sum(strcmpi(datum,{'mhhw','mhw','msl','mlw','mllw','navd'}))==0
   datum = 'MSL';
end
datum = upper(datum);
out.datum = datum;

unit = 'metric';
out.units = unit;

out.timezone = 'GMT';

%%
dget = [];
for ii=1:size(dates(1))
   if int==1
      if dates(ii,2)-dates(ii,1)>31
         bdate = dates(ii,1);
         edate = dates(ii,1) + 31;
         dget = [dget; [bdate edate]];
         while edate<=dates(ii,2)
            bdate = edate + 1;
            edate = bdate + 31;
            dget = [dget; [bdate edate]];
         end
         dget(end,2) = dates(ii,2);
      else
         dget = [dget; dates(ii,:)];
      end
   elseif int==2
      if dates(ii,2)-dates(ii,1)>365
         bdate = dates(ii,1);
         tmp = datevec(bdate);
         edate = datenum(tmp(1),12,31);
         dget = [dget; [bdate edate]];
         while edate<=dates(ii,2)
            bdate = edate + 1;
            tmp = datevec(bdate);
            edate = datenum(tmp(1),12,31);
            dget = [dget; [bdate edate]];
         end
         dget(end,2) = dates(ii,2);
      else
         dget = [dget; dates(ii,:)];
      end
   end
end

%%
out.t = [];
out.measured = [];
out.sigma = [];

for ii=1:size(dget,1)
   bdate = datestr(dget(ii,1),'yyyymmdd');
   edate = datestr(dget(ii,2),'yyyymmdd');
   
   % Measured
   url = ['https://tidesandcurrents.noaa.gov/api/datagetter?',...
      'product=',product,'&application=NOS.COOPS.TAC.WL&',...
      'begin_date=',bdate,'&end_date=',edate,'&datum=',datum,...
      '&station=',station,'&time_zone=',out.timezone,...
      '&units=',out.units,'&format=xml'];
   
  % make the weboptions accept the url
  wopts = weboptions;
  wopts.CertificateFilename = [];
  tmp = webread(url, wopts);
   out.longitude = cellfun(@str2num,strrep(regexp(tmp,'lon="-?\d+\.\d+','match'),'lon="',''));
   out.latitude = cellfun(@str2num,strrep(regexp(tmp,'lat="-?\d+\.\d+','match'),'lat="',''));
   
   t = regexp(tmp,'\d+-\d+-\d+ \d+:\d+','match');
   if ~isempty(t)
      out.t = [out.t; datenum(t)];
      
      v = regexp(tmp,'v="(-?\d+\.\d+)?"','match');
      v = regexprep(v,'""','"nan"');
      v = strrep(v,'v="',''); v = strrep(v,'"','');
      v = cellfun(@str2num,v)';
      out.measured = [out.measured; v];
      
      s = regexp(tmp,'s="(-?\d+\.\d+)?"','match');
      s = regexprep(s,'""','"nan"');
      s = strrep(s,'s="',''); s = strrep(s,'"','');
      s = cellfun(@str2num,s)';
      out.sigma = [out.sigma; s];
   end
   
   % Predicted
   if int==1 || int==2
      if ii==1
         out.predicted = [];
      end
      
      if int==1
         url = ['https://tidesandcurrents.noaa.gov/api/datagetter?',...
            'product=predictions&application=NOS.COOPS.TAC.WL&',...
            'begin_date=',bdate,'&end_date=',edate,'&datum=',datum,...
            '&station=',station,'&time_zone=',out.timezone,...
            '&units=',out.units,'&format=xml'];
      else
         url = ['https://tidesandcurrents.noaa.gov/api/datagetter?',...
            'product=predictions&application=NOS.COOPS.TAC.WL&',...
            'begin_date=',bdate,'&end_date=',edate,'&datum=',datum,...
            '&station=',station,'&time_zone=',out.timezone,...
            '&units=',out.units,'&interval=h&format=xml'];
      end
      tmp = webread(url, wopts);
      
      t = regexp(tmp,'\d+-\d+-\d+ \d+:\d+','match');
      t = datenum(t);
      v = regexp(tmp,'v="(-?\d+\.\d+)?"','match');
      v = regexprep(v,'""','"nan"');
      v = strrep(v,'v="',''); v = strrep(v,'"','');
      v = cellfun(@str2num,v)';
      if ~isempty(out.t)
         [~,id,~] = intersect(t,out.t);
         out.predicted = [out.predicted; v(id)];
      else
         out.t = [out.t; t];
         out.measured = [out.measured; nan*ones(length(v),1)];
         out.predicted = [out.predicted; v];
      end
   end
end

% <<<<<<< .mine
%% Wind
% if isempty(intp)
% bdate = datestr(dates(1),'yyyymmdd');
% edate = datestr(dates(2),'yyyymmdd');
% if ~isfield(out,'windt')
%    out.windt = [];out.windd = [];out.winds = [];
% end
% days = diff(dates)+1;
% for mm = 1:ceil(days/31)
%    if ceil(days/31)>floor(days/31) && mm == ceil(days/31)
%       bnum = round(((days/31)-floor(days/31))*31);
%       bdate1 = dates(1)+31*(mm-1); %
%       edate1 = bdate1+bnum-1;
%    else
%       bdate1 = dates(1)+31*(mm-1); %
%       edate1 = bdate1+30;
%    end
%    bdate = datestr(bdate1,'yyyymmdd');
%    edate = datestr(edate1,'yyyymmdd');
%    url = ['http://tidesandcurrents.noaa.gov/api/datagetter?',...
%       'product=wind&application=NOS.COOPS.TAC.WL&',...
%       'begin_date=',bdate,'&end_date=',edate,'&datum=',datum,...
%       '&station=',station,'&time_zone=',out.timezone,...
%       '&units=',out.units,'&format=xml'];
%    
%    % =======
%    % >>>>>>> .r4832
%    tmp = webread(url);
%    
%    t = regexp(tmp,'\d+-\d+-\d+ \d+:\d+','match');
%    t = datenum(t);
%    s = regexp(tmp,'s="(-?\d+\.\d+)?"','match');
%    s = regexprep(s,'""','"nan"');
%    s = strrep(s,'s="',''); s = strrep(s,'"','');
%    s = cellfun(@str2num,s)';
%    d = regexp(tmp,'d="(-?\d+\.\d+)?"','match');
%    d = regexprep(d,'""','"nan"');
%    d = strrep(d,'d="',''); d = strrep(d,'"','');
%    d = cellfun(@str2num,d)';
%    if isempty(t) && mm == ceil(days/31)
%       display('No wind data for this time period')
%       out.windt = ones(size(out.t))*NaN;
%       out.winds = ones(size(out.t))*NaN;
%       out.windd = ones(size(out.t))*NaN;
%    elseif ~isempty(out.windt)
%       [~,id,~] = intersect(t,out.t);
%       out.windt = [out.windt; t(id)];
%       out.winds = [out.winds; s(id)];
%       out.windd = [out.windd; d(id)];
%    elseif isempty(out.windt)
%       [~,id,~] = intersect(t,out.t);
%       out.windt = t(id);
%       out.winds = s(id);
%       out.windd = d(id);
%    end
% end


