function addPositionInfo(imageinfo,positiondata)
%% add gps-ins position data the imageinfo text file based on times
%
%  Input: 
%   imageinfo: string :absolute filename for which to add position info to
%   gpsdata: string : absolute filename for a file with time/position info
% 
%  Saved File: 
%   imageinfo_2:
%    - modifies imageinfo and resaves it with more data as _2

%% Read Imageinfo and extract times
iminfodata = importdata(imageinfo);
imnames = iminfodata.textdata(2:end,1);%first line is header
imtimesDatenum = nan(1,numel(imnames));
for i=1:numel(imnames)
    imtimesStr = sprintf('%.3f\n',(iminfodata.data(i,2)));
    imtimesDatenum(i) = datenum(imtimesStr,'yyyymmddHHMMss.fff');
end
nImages = numel(imnames);
%% Read positiondata and extract times, header, other variables
xyzdat = importdata(positiondata);
positionTimeNum = xyzdat.data(:,1);
positiontimesDatenum = nan(1,numel(positionTimeNum));
for i=1:numel(positionTimeNum)
    strTime = sprintf('%.3f\n',positionTimeNum(i));
    positiontimesDatenum(i) = datenum(strTime,'yyyymmddHHMMss.fff');
end
allposdat = xyzdat.data(:,2:end);
allposHeaders = xyzdat.colheaders(2:end);
nPositionColumns = size(allposdat,2);
%% Interpolate position data onto imageinfo times
InterpPos = nan(nImages,nPositionColumns);
for iColumn=1:nPositionColumns
    InterpPos(:,iColumn) = ...
        interp1(positiontimesDatenum,allposdat(:,iColumn),imtimesDatenum);
end
%% rewrite and save imageinfo with new info, save as new file _2
[dname, fname, ~] = fileparts(imageinfo);
outname = [dname '\' fname '_Pos.txt'];
fid = fopen(outname,'w+t');
%print header
fprintf(fid,'#Position data interpolated from %s\n',positiondata);
fprintf(fid,'ImageName,ActualTime(yyyymmddHHMMss.fff),');
fprintf(fid,'DesiredTime(yyyymmddHHMMss.fff)');
for i=1:nPositionColumns
   fprintf(fid,',%s', allposHeaders{i});
end
fprintf(fid,'\n');
%for each image, print a line with interpolated info
for iIm=1:nImages
    fprintf(fid,'%s,%.3f,%.3f',imnames{iIm},iminfodata.data(iIm,1),...
        iminfodata.data(iIm,2));
        fprintf(fid,',%.6f',InterpPos(iIm,:));
        fprintf(fid,'\n');
end
fclose(fid);
end