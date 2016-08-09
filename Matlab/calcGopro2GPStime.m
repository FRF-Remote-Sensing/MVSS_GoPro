function calcGopro2GPStime(mp4name,logfilename,dodebug)
%% Calculate the linear fit to go from gopro time in seconds to GPS datenum
% time in days.  Save the output as a text file based on the mp4name and
% saved location
%
%  Input: 
%   mp4name: string : absolute file location of the mp4 file
%   logfilename: string : absolute file path of the log file
%   dodebug: logical {0 1} : If true, debug plots will appear
% 
%  Saved File:
%   <mp4name>_gopro2gps.txt
%      - contains P1 and P2, the slope and y intercept of a linear fit
%      - also contains metadata about the fit
%% Set constants
BAUDRATE=1660; %baud rate is set to 300, but actually is 1660
NMEADT = 1; % time between signal pulses
ALGORITHMVERSION = 'V0.2';
%% Read audio from mp4name
[y,Fs]=audioread(mp4name);
pps=y(:,1);
nmea=y(:,2);
% make time variable
t=0:1/Fs:(numel(pps)-1)*1/Fs;

%% Calculate goPro Index Count Values and times
[goproInd.tGP,goproInd.val] = ...
    calcGoproNmeaCounts(t,nmea,NMEADT,BAUDRATE,dodebug);
%% Calculate goPro PPS rising and falling edge times
[goproPPS.tGPRising,goproPPS.tGPFalling]=calcPPStimes(t,pps,dodebug);

%% Read SD Card Data with GPS times, PPS times, and Count Index Times
[logGPS,logPPS,logInd]=getLogData(logfilename);

%% Calculate Offset from GoPro time to GPS time
[GoPro2utcConstants,npps] = ...
    calcGoProGPS(logInd,logGPS,logPPS,goproInd,goproPPS,dodebug);

%% Save Output to text file
[d,f,~] = fileparts(mp4name);
outname = [d '/' f '_gopro2gps.txt'];

fid = fopen(outname,'w+t');
fprintf(fid,'P(1),%.20f\n',GoPro2utcConstants(1));
fprintf(fid,'P(2),%.20f\n',GoPro2utcConstants(2));
fprintf(fid,'nPPS,%.0f\n',npps);
fprintf(fid,'Version, %s\n',ALGORITHMVERSION);
%calculate minimum and maximum times
minT = polyval(GoPro2utcConstants,0);
maxT = polyval(GoPro2utcConstants,max(t));
fprintf(fid,'MinTime, %s\n',datestr(minT));
fprintf(fid,'MaxTime, %s\n',datestr(maxT));
fprintf(fid,'Duration, %.2f\n',max(t));
fclose(fid);

end