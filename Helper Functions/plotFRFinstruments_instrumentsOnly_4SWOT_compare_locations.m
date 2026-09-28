function hGauges=plotFRFinstruments_instrumentsOnly_4SWOT_compare_locations()

% openfig('bigFrfDEM_5mContours.fig') % Edit in this script: pullAndPlotFRFData_bigArea_1arcSecond.m

% Water level 
load('sensorCoords.mat');

% Pier
fill([0 585 585 0], [514 514 520 520],'k'); % Pier

% Noaa guage
% noaaLat=36.183639;
% noaaLong=-75.74528;
% [~,~, ~, ~, noaaY, noaaX] = frfCoord(noaaLong, noaaLat);
% plot(noaaX, noaaY,'o','MarkerSize',12,'MarkerFaceColor','b','LineWidth',4,'Color','b')

% Waves & water level
% % Paros940-200
% paros940_200Lat=36.18621245;
% paros940_200Long=-75.75078584;
% [~,~, ~, ~, paros940_200Y, paros940_200X] = frfCoord(paros940_200Long, paros940_200Lat);
% plot(paros940_200X, paros940_200Y,'o','MarkerSize',12,'MarkerFaceColor','k','LineWidth',4,'Color','k')

% % Paros940-250
% paros940_250Lat=36.18634661;
% paros940_250Long=-75.75029523;
% [~,~, ~, ~, paros940_250Y, paros940_250X] = frfCoord(paros940_250Long, paros940_250Lat);
% plot(paros940_250X, paros940_250Y,'o','MarkerSize',12,'MarkerFaceColor','k','LineWidth',4,'Color','k')

% % xp340m
% xp340mLat=36.18659;
% xp340mLong=-75.74934;
% [~,~, ~, ~, xp340mY, xp340mX] = frfCoord(xp340mLong, xp340mLat);
% plot(xp340mX, xp340mY,'o','MarkerSize',12,'MarkerFaceColor','k','LineWidth',4,'Color','k')


% 8m array
h3=plot(sensorCoords(12,1), sensorCoords(12,2) ,'^','MarkerSize',12,'MarkerFaceColor','k','LineWidth',4,'Color','k');

% waverider17m
waverider17mLat=36.1995;
waverider17mLong=-75.71483333333333;
[~,~, ~, ~, waverider17mY, waverider17mX] = frfCoord(waverider17mLong, waverider17mLat);
h2=plot(waverider17mX, waverider17mY,'^','MarkerSize',12,'MarkerFaceColor','k','LineWidth',4,'Color','k');
  % ylim([0 waverider17mY+100]);
  % xlim([0 waverider17mX+100]);

% waverider26m
waverider26mLat=36.25833333333333;
waverider26mLong=-75.59333333333333;
[~,~, ~, ~, waverider26mY, waverider26mX] = frfCoord(waverider26mLong, waverider26mLat);
h1=plot(waverider26mX, waverider26mY,'^','MarkerSize',12,'MarkerFaceColor','k','LineWidth',4,'Color','k');
%   ylim([0 waverider26mY+300]);
%   xlim([0 waverider26mX+300]);


% Current meters
% % Awac 11m
% [~,~, ~, ~, awac11mY, awac11mX] = frfCoord(-75.739155100000000, 36.189244500000000);
% plot(awac11mX, awac11mY, 'o','MarkerSize',12,'MarkerFaceColor','r','LineWidth',4,'Color','r')

% Wave and Current Meters
% % sig940-300
% sig940_300Lat=36.18649;
% sig940_300Long=-75.7498;
% [~,~, ~, ~, sig940_300Y, sig940_300X] = frfCoord(sig940_300Long, sig940_300Lat);
% plot(sig940_300X, sig940_300Y,'o','MarkerSize',12,'MarkerFaceColor','r','LineWidth',4,'Color','k')

% % Sig940-400
% plot(400, 940, 'o','MarkerSize',12,'MarkerFaceColor','r','LineWidth',4,'Color','k')

% % AWAC- 4.5m (Dont need to plot this one because its basically same spot as
% % above)
% awac45Lat=36.186779;
% awac45Long=-75.748681;
% [~,~, ~, ~, awac45Y, awac45X] = frfCoord(awac45Long, awac45Lat);
% plot(awac45X, awac45Y,'o','MarkerSize',12,'MarkerFaceColor','r','LineWidth',4,'Color','k')

% sig940-600
sig940_600Lat=36.18734;
sig940_600Long=-75.74651;
[~,~, ~, ~, sig940_600Y, sig940_600X] = frfCoord(sig940_600Long, sig940_600Lat);
h4=plot(sig940_600X, sig940_600Y,'^','MarkerSize',12,'MarkerFaceColor','k','LineWidth',4,'Color','k');

hGauges = [h1 h2 h3 h4];



% Shape file
load("UsShapeFrfX.mat");
load("UsShapeFrfY.mat");
plot(UsShapeFrfX, UsShapeFrfY,'k-')

% legend('','','','','NOAA Water Level Gauge','Wave Gauge', '','','','','','Current Meter','Combined Wave and Current','','')

end