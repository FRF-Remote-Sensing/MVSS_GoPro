function extractFrames(mp4name,outfolder,extractTimesGPS,fitfilename,DODEBUG)
%% Extracts Images from the mp4 file at the extractTimeGPS times and saves
% them to an outfolder.  Uses fitfilename to convert from gopro time to GPS
% time based on a linear fit.
%
%  Input: 
%   mp4name: string : filename of mp4 gopro video 
%   outfolder: string : folder to save imagery to
%   extractTimesGPS: 1xN : vector of time in GPS to extract frames at
%   fitfilename: string : absolute filename of the linear fit data
%
%  Saved Files:
%   *%010.0f_<outfolder>.jpg : saves N images, less if time is out of range
%   imageinfo.txt: CSV + header with imname, extractTimesGPS, actualTimes

%% Set Constants
MAXDTCONST = 1.05; %percentage above nyquist allowable
nFrames = numel(extractTimesGPS);
%% Read mp4 file
mov = VideoReader(mp4name);
[~,justmp4name,~]=fileparts(mp4name);
%% Read Fit filename
data = fileread(fitfilename);
dataParts = strsplit(data,{',','\n'});
gopro2gps = str2double([dataParts(2); dataParts(4)]);
%% Convert mp4 times to GPS times
tGoPro = 0 : 1/mov.FrameRate : mov.Duration;
tGPS = polyval(gopro2gps,tGoPro);
frameinds = 1:numel(tGPS);
%% Calculate indices to extract
MAXDT = (1/mov.FrameRate/2)*MAXDTCONST;
frame2extract = interp1(tGPS,frameinds,extractTimesGPS,'nearest');
isBad = isnan(frame2extract);
frame2extract(isBad)=1;
residuals = (tGPS(frame2extract)-extractTimesGPS)*60*60*24;
isOutOfRange = abs(residuals)>MAXDT | isBad; 

if DODEBUG
    figure
    plot(residuals);
    hold on
    plot(residuals,'g*');
    iRes = 1:numel(residuals);
    plot(iRes(isOutOfRange),residuals(isOutOfRange),'r*')
    ylim([-MAXDT*2 MAXDT*2])
    xlim([1 numel(extractTimesGPS)])
    title('Actual Frame Time - Desired Frame Time');
    ylabel('Time Difference (seconds)');
    xlabel('index');
end
%% Make directory to save images to
mkdir(outfolder);
%% Make text file to save images to
outfilename = [outfolder '/iminfo_' justmp4name '.txt'];
fid = fopen(outfilename,'w+t');
fprintf(fid,'ImageName,ActualTime(yyyymmddHHMMss.fff)');
fprintf(fid,',DesiredTime(yyyymmddHHMMss.fff)\n');
%% Loop over each index
if DODEBUG
   f = figure; 
end
for iTimestep = 1:nFrames
    if ~isOutOfRange(iTimestep)
        iFrame = frame2extract(iTimestep);
        % Extract indices and save Images based on index number
        I = read(mov,iFrame);
        %   ^says it will be removed, but readframe cant extract at exact index
        imname = sprintf('%s/%05.0f_%s.jpg',outfolder,iTimestep,justmp4name);
        imwrite(I,imname);
        % write image info to text file
        [~,imjustname,ext]=fileparts(imname);
        fprintf(fid,'%s,%s,%s\n',...
            [imjustname,ext],...
            datestr(tGPS(iFrame),'yyyymmddHHMMss.fff'),...
            datestr(extractTimesGPS(iTimestep),'yyyymmddHHMMss.fff'));
        fprintf('%s\n',imname);
        fprintf('%s,%s,%s\n',...
            [imjustname,ext],...
            datestr(tGPS(iFrame),'yyyymmddHHMMss.fff'),...
            datestr(extractTimesGPS(iTimestep),'yyyymmddHHMMss.fff'));
        if DODEBUG
           figure(f)
           image(I);
           title({datestr(tGPS(iFrame),'yyyymmdd   HH MM:ss.fff'),...
               datestr(extractTimesGPS(iTimestep),'yyyymmdd   HH MM:ss.fff')});
           drawnow
        end
    else
        fprintf('%05.0f: %s Out Of Range\n',iTimestep,datestr(extractTimesGPS(iTimestep)));
    end
end
%% close iminfo file
fclose(fid);
end