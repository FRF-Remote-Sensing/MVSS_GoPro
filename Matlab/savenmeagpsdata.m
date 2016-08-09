function savenmeagpsdata(logfilename)
%% Read in a NMEA logfile and output a CSV file with GPS data
%
%  Input: 
%   logfilename:
%
%  Saved File:
%   logfilename_gps.csv saved in the same location

%% Read logfile
data = fileread(logfilename);

%% Extract GGA Times
% GGA has good GPS info but only HMS, no YMD
% RMC has minimal GPS info in it, but has YMDHMS
% Need to interpolate RMC YMD into GGA so GGA can have absolute time
ggaHMS = getValue(data,'$MSG',3,1,'$GPGGA');

gga_partofdays = nan(numel(ggaHMS),1);
for i=1:numel(ggaHMS)
   H = str2double(ggaHMS{i}{1}(1:2));
   MN = str2double(ggaHMS{i}{1}(3:4));
   S = str2double(ggaHMS{i}{1}(5:10));
   gga_partofdays(i) = H/24+MN/24/60+S/24/60/60; 
end
%% Extract RMC HMS and YMD
rmcHMS = getValue(data,'$MSG',3,1,'$GPRMC');
rmcYMD = getValue(data,'$MSG',11,1,'$GPRMC');

rmcYMD_partofdays = nan(numel(rmcYMD),1);
rmc_seconds = nan(numel(rmcYMD),1);
for i=1:numel(rmcYMD)
   H = str2double(rmcHMS{i}{1}(1:2));
   MN = str2double(rmcHMS{i}{1}(3:4));
   S = str2double(rmcHMS{i}{1}(5:10));
   rmc_seconds(i) = H/24+MN/24/60+S/24/60/60; 
   Y = 2000+str2double(rmcYMD{i}{1}(5:6));
   M = str2double(rmcYMD{i}{1}(3:4));
   D = str2double(rmcYMD{i}{1}(1:2));
   rmcYMD_partofdays(i) = datenum(Y,M,D);
end

%% Interpolate RMC YMD onto GGA HMS times
ggaYMD = interp1(rmc_seconds,rmcYMD_partofdays,gga_partofdays,'nearest','extrap');
gps.UTC = (ggaYMD + gga_partofdays)';

%% Read Rest of GGA data
Lat = getValue(data,'$MSG',4,1,'$GPGGA');
LatNS = getValue(data,'$MSG',5,1,'$GPGGA');
Lon = getValue(data,'$MSG',6,1,'$GPGGA');
LonEW = getValue(data,'$MSG',7,1,'$GPGGA');

for i=1:numel(Lat)
    if ~isempty(Lat{i}{1})
        LatVal = str2double(Lat{i}{1}(1:2))+str2double(Lat{i}{1}(3:8))/60;
        LatN = (LatNS{i}{1}(1)=='N')*2-1;
        gps.lat(i) = LatVal*LatN;
        LonVal = str2double(Lon{i}{1}(1:3))+str2double(Lon{i}{1}(4:9))/60;
        LonE = (LonEW{i}{1}(1)=='E')*2-1;
        gps.lon(i) = LonVal*LonE;
    else
        gps.lat(i)=nan;
        gps.lon(i)=nan;
    end
end

gps.fixQuality = getValue(data,'$MSG',8,0,'$GPGGA');
gps.nSats = getValue(data,'$MSG',9,0,'$GPGGA');
gps.hDOP = getValue(data,'$MSG',10,0,'$GPGGA');
gps.alt = getValue(data,'$MSG',11,0,'$GPGGA');
gps.geoid = getValue(data,'$MSG',13,0,'$GPGGA');

%% Write data to logfile
[dname, fname, ~]=fileparts(logfilename);
outname = [dname '/' fname '_gps.txt'];
fid = fopen(outname,'w+t');
fprintf(fid,'UTCtime(yyyymmddHHMMss.fff),Lat,Lon,fixQuality,nSats,hDOP,');
fprintf(fid,'AltAboveMSL,geoidHeight\n');
for i=1:numel(gps.alt)
    if gps.fixQuality(i)~=0
    fprintf(fid,'%s,%.6f,%.6f,%.0f,%.0f,%.3f,%.3f,%.3f\n',...
        datestr(gps.UTC(i),'yyyymmddHHMMss.fff'),...
        gps.lat(i),...
        gps.lon(i),...
        gps.fixQuality(i),...
        gps.nSats(i),...
        gps.hDOP(i),...
        gps.alt(i),...
        gps.geoid(i));
    end
end
fclose(fid);

end

%% GGA
% 1    Arduino Time (ms)
% 2    GPGGA
% 3    Fix UTC Time HHMMSS
% 4    Latitude DDMM.MMM
% 5    N/S Which Quadrant
% 6    Longitude DDDMM.MMM
% 7    E/W Which Quadrant
% 8    Fix Quality (0 = invalid, 1 = GPS fix(SPS), 2 = DGPS, 3 = PPS)
% 9    Number of Satellites
% 10   HDOP
% 11   Altitude above MSL (m)
% 12   'M' for meters
% 13   Height of Geoid MSL above WGS84 (m)
% 14   'M' for meters
% 15   (empty)
% 16   checksum