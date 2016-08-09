function [GoPro2GPSConstants,npps] = ...
    calcGoProGPS(logInd,logGPS,logPPS,goproInd,goproPPS,DODEBUG)
%% Calculate Scale, Offset constants to go from GoPro Time to GPS datenum
%  1) GoPro Signal to Arduino Signal time fit
%  2) Arduino GPS to GPS NMEA time fit
%  3) Arduino PPS to GPS time fit
%  4) Round PPS value to nearest second
%  5) GoPro PPS to GPS time
%  6) Find Nearest GoPro PPS to GPS and call it correpsondence
%  7) Fit GoPro PPS to GPS PPS
% * If no PPS, stop after 1 and 2
% 
%  Input:
%   logInd: struct : tA in Teensy time, Val is integer index
%   logGPS: struct : tA in Teensy time, and tGPS in GPS time
%   logPPS: struct : tA in Teensy time
%   goproInd: struct : time and value of signal data
%   goproPPS: struct : tppsrising and tppsfalling times in gopro time
%   DODEBUG: {1,0} : Set to 1 for debugging plots and info
%
%  Output:
%   GoPro2GPSConstants: 1x2: polyfit coefficients for data
%   meta: struct: metadata of how the fit was formed


%% Calc GoPro to Arduino
GoProInd = goproInd.val;
goproInd.tA_correspondence = nan(size(goproInd.tGP));
for i=1:numel(GoProInd)
    indMatch = logInd.val==GoProInd(i);
    goproInd.tA_correspondence(i) = logInd.tA(indMatch);
end

pGoPro2Arduino = polyfit(goproInd.tGP,goproInd.tA_correspondence,1);
goproInd.tA_calc = polyval(pGoPro2Arduino,goproInd.tGP);
V1 = goproInd.tA_calc - goproInd.tA_correspondence;%residual of fit
if DODEBUG
   figure
   plot(V1/1000);
   ylabel('Seconds')
   xlabel('gopro time in seconds');
   title('Residuals for GoPro Count to Arduino Time')
end
%% Calc Arduino to GPS
pArduino2GPS = polyfit(logGPS.tA,logGPS.tGPS,1);
V2 = polyval(pArduino2GPS,logGPS.tA)-logGPS.tGPS;
if DODEBUG
   figure
   plot(logGPS.tGPS,V2*24*60*60);
   ylabel('seconds');
   xlabel('tGPS in seconds');
   title({'Residuals for Arduino Time to GPS time based on NMEA',...
       'These will be large due to NMEA serial port delays'})
end

%% combine fits to go from gopro to GPS

pGoPro2GPS_nopps(1) = pArduino2GPS(1)*pGoPro2Arduino(1);
pGoPro2GPS_nopps(2) = pArduino2GPS(2)+pArduino2GPS(1)*pGoPro2Arduino(2);

try %try catch in case PPS is bad
    %% Calc PPS Arduino to GPS (round) up?
    logPPS.tGPS_calc = polyval(pArduino2GPS,logPPS.tA);
    day = floor(logPPS.tGPS_calc);
    GPSSecond = (logPPS.tGPS_calc-day)*60*60*24;
    roundGPSsecond = round(GPSSecond);
    % figure;plot(GPSSecond-roundGPSsecond); not as good as i'd expect
    logPPS.tGPS = day + roundGPSsecond/60/60/24;
    
    %% PPS GoPro Time - Arduino Time - GPS Time --- PPS GPS
    goproPPS.tA_calc = polyval(pGoPro2Arduino,goproPPS.tGPRising);
    goproPPS.tGPS_calc = polyval(pArduino2GPS,goproPPS.tA_calc);
    
    %% Calculate Correspondences between Calculated PPS Values
    indLogPPS = interp1(logPPS.tGPS,1:numel(logPPS.tGPS),...
        goproPPS.tGPS_calc,'nearest','extrap');
    
    goproPPS.tGPS_calcPPS = logPPS.tGPS(indLogPPS);
    
    pGoPro2GPSpps = polyfit(goproPPS.tGPRising,goproPPS.tGPS_calcPPS,1);
    V3pps = polyval(pGoPro2GPSpps,goproPPS.tGPRising)-goproPPS.tGPS_calcPPS;
    V3 = polyval(pGoPro2GPS_nopps,goproPPS.tGPRising)-goproPPS.tGPS_calcPPS;
    if DODEBUG
       figure
       plot(goproPPS.tGPRising,V3pps*60*60*24);
       ylabel('Seconds')
       xlabel('GoPro Time in Seconds')
       title({'Residuals for GoPro PPS to GPS PPS'})
    end
    npps = numel(indLogPPS);
    GoPro2GPSConstants = pGoPro2GPSpps;
catch
    warning('Couldnt Make PPS Sync work... using time sync without');
    npps = 0;
    GoPro2GPSConstants = pGoPro2GPS_nopps;
end

end