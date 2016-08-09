function [tGP,val] = calcGoproNmeaCounts(t,nmea,NMEADT,BAUDRATE,DODEBUG)
%% Calculate the time and value of the nmea counter value on the nmea audio 
% The audio values are sent in as a binary signal, but the audio port
% conditions the signal so that any peaks decay back down to zeros.  To
% calculate thei binary values, rising and falling edges are detected.  A
% rising edge means the signal has gone from 0 - 1, a falling edge means
% the signal has gone from 1 - 0.
% 
%  Input:
%   t: 1xN: time vector for each data point
%   data: 1xN: data vector containing signal data
%   NMEADT: 1 : DT between sequential signals
%   BAUDRATE: 1 : Baudrate value that info is encoded at 
%   DODEBUG: {1,0} : Set to 1 for debugging plots and info
%
%  Output:
%   tGP: 1xM : gopro time in seconds of the start of each signal
%   val: 1xM : decimal value for each signal
%% Set constants
NMEAPEAKTHRESH = 0.04;
FILTLENGTH = 20;
FILTSIGMA = 5;
NUMBITS = 20;
GOODBITS = [9:-1:2 19:-1:12];
dt = mean(diff(t(1:10)));
baudind = 1/BAUDRATE/dt;

%% Filter the NMEA signal for jumps
%look for jumps in the signal
d_data = diff(nmea);

%filter data signal to find first peak
F = fspecial('gauss',[1 FILTLENGTH],FILTSIGMA);
datafilt= conv(d_data,F,'same');

%% Detect Peaks
[pkval,ind]=findpeaks(abs(datafilt),'minpeakheight',NMEAPEAKTHRESH);
pkval(datafilt(ind)<0)=pkval(datafilt(ind)<0)*-1; %make negative peaks

%% Find First Value after a big jump in time (aka, first signal of binary)
bigjumps = find(diff(ind)>NMEADT/dt/2)+1; %+1 to shift it right

%% Calculate Index of Bits for each signal
firstinds = ind(bigjumps);
indoffset = round(0:baudind:baudind*(NUMBITS-1));

[indoffsets,allFirstInds]=meshgrid(indoffset,firstinds);

sigInds = indoffsets + allFirstInds;
%% Calculate time of first bit for each signal
nSignals = numel(firstinds);
tGP = t(firstinds);

%% Extract values at each Index
allVals = datafilt(sigInds);

%% Convert values to binary
% set peak as 1/3 max peak for each signal
pkthresh = max(abs(allVals'))/3;
pkthreshMat = repmat(pkthresh',[1,NUMBITS]);

allBinaryPeaks = double(abs(allVals)>pkthreshMat);
negativeVals = allVals<0;
allBinaryPeaks(negativeVals) = allBinaryPeaks(negativeVals)*-1;

binarysignal = ~logical(cumsum(allBinaryPeaks,2));

% [round(allVals(1,:)*100)' allBinaryPeaks(1,:)' binarysignal(1,:)']
%% convert binary to decimal
BinaryBitsString = num2str(binarysignal(:,GOODBITS),'%.0f');
val = nan(1,nSignals);
for iRow=1:nSignals
    iBinSig = BinaryBitsString(iRow,:);
    val(iRow) = bin2dec(iBinSig);
    if DODEBUG
        fprintf('%10.3f : %s : %.0f\n',tGP(iRow),iBinSig,val(iRow));
    end
end

%% DEBUG
if DODEBUG
    figure
    plot(datafilt)
    hold on
    plot(ind,pkval,'m*')
    plot(ind(bigjumps),pkval(bigjumps),'go');
    title('extracted nmea peaks');
end

end