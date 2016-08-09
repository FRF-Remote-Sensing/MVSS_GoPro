%% Test Script
clear
close all
clc
mp4name = 'D:\Dropbox\FRF_MultiCamera\20160722_FRF_x8flight_files_for_DEBUG\GOPR0402.MP4';
logfilename = 'D:\Dropbox\FRF_MultiCamera\20160722_FRF_x8flight_files_for_DEBUG\LOG00139.TXT';

% mp4name = 'D:\Dropbox\Cormorant\projects\iai\debug4craig\GOPR0460.MP4';
% logfilename = 'D:\Dropbox\Cormorant\projects\iai\debug4craig\LOG00133.TXT';

dodebug=1;

calcGopro2GPStime(mp4name,logfilename,dodebug)