%% Test Script
clear
close all
clc

mp4name = 'C:\Users\Richie\Documents\Sandbox\20150831_testreadbinary\Test030416a\GOPR6864.MP4';
logfilename = 'C:\Users\Richie\Documents\Sandbox\20150831_testreadbinary\Test030416a\LOG00323.TXT';
dodebug=1;

calcGopro2GPStime(mp4name,logfilename,dodebug)