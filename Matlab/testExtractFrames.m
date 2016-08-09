%% test extractFrames

mp4name = 'C:\Users\Richie\Documents\Sandbox\20150831_testreadbinary\Test030416a\GOPR6864.MP4';
fitfilename = 'C:\Users\Richie\Documents\Sandbox\20150831_testreadbinary\Test030416a\GOPR6864_gopro2gps.txt';
dodebug=1;
outfolder = 'C:\Users\Richie\Documents\Sandbox\20150831_testreadbinary\Test030416a\Image1';
extractTimesGPS = datenum(2016,3,4,12,05,0):2*(1/24/60/60):datenum(2016,3,4,12,14,0);

extractFrames(mp4name,outfolder,extractTimesGPS,fitfilename,dodebug)