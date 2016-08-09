function [logGPS,logPPS,logInd]=getLogData(logname)
%% Reads data from log file into GPS, PPS and Ind output structures
% This function is solely focused on timing, and therefore does not return
% and GPS spatial information.  Uses GGA for "fix Quality", RMC for "YMD"
%
%  Input:
%   logname: 1xM : vector of times
% 
%  Output:
%   logGPS: struct : tA in Teensy time, and tGPS in GPS time
%   logPPS: struct : tA in Teensy time
%   logInd: struct : tA in Teensy time, Val is integer index

%% Read data
data=fileread(logname);

%% Read time values from data
logGPS.tA = getValue(data,'$MSG',1,0,'$GPGGA');

UTC_hms = getValue(data,'$MSG',3,1,'$GPRMC');
UTC_YMD = getValue(data,'$MSG',11,1,'$GPRMC');
UTC = nan(numel(UTC_YMD),1);
for i=1:numel(UTC)
   H = str2double(UTC_hms{i}{1}(1:2));
   MN = str2double(UTC_hms{i}{1}(3:4));
   S = str2double(UTC_hms{i}{1}(5:10));
   Y = 2000+str2double(UTC_YMD{i}{1}(5:6));
   M = str2double(UTC_YMD{i}{1}(3:4));
   D = str2double(UTC_YMD{i}{1}(1:2));
   UTC(i) = datenum(Y,M,D,H,MN,S);
end
%% Read Fix Quality to determine bad time data
GPS_hms = getValue(data,'$MSG',3,1,'$GPGGA');
fixQuality = getValue(data,'$MSG',8,0,'$GPGGA');
%% Remove data with bad fix quality
badinds = fixQuality==0; %remove inds with fix quality = 0
logGPS = badGPSIndRemoval(logGPS,badinds);
GPS_hms(badinds)=[];
%% Calculate Matching Indices based on hms time
[indUTC, indGPS]=calcMatchingInds(UTC_hms,GPS_hms);

logGPS = goodGPSExtract(logGPS,indGPS);
logGPS.tGPS = UTC(indUTC)';

%% Read Index Time and Values
logInd.tA = getValue(data,'$IND',1);
logInd.val = getValue(data,'$IND',2);
%% Read PPS Times and Values 
logPPS.tA = getValue(data,'$PPS',1);

end
function logGPS = badGPSIndRemoval(logGPS,badinds)
%% Remove bad logical indices in logGPS
fnames = fieldnames(logGPS);
    for i=1:numel(fnames)
        eval(['logGPS.' fnames{i} '(badinds)=[];']);
    end
end
function logGPS = goodGPSExtract(logGPS,indGPS)
%% Extract good indices
fnames = fieldnames(logGPS);
    for i=1:numel(fnames)
        eval(['logGPS.' fnames{i} '=logGPS.' fnames{i} '(indGPS);']);
    end
end

function [ind1, ind2]=calcMatchingInds(A,B)
%% Find matching indicies for each HMS input
count = 1;
for iA=1:numel(A)
    A_hms = A{iA}{1};
    for iB = 1:numel(B)
        B_hms = B{iB}{1};
        if strcmp(A_hms,B_hms)
            ind1(count) = iA;
            ind2(count) = iB;
            count = count + 1;
%             fprintf('%s = %s \n',A_hms,B_hms);
        end
    end
end

end
%% GGA
% 1    Arduino Time (ms)
% 2    GPGGA
% 3    Fix UTC Time HHMMSS
% 4    Latitude DDMM.MMM
% 5    N/S Which Quadrant
% 6    DDDMM.MMM
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