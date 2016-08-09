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
FILTSIGMA = 2;
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
datafiltcurv = [0 0 abs(diff(diff(datafilt)))'];
F2 = fspecial('gauss',[1 FILTLENGTH],FILTSIGMA*2);
datafilt2= conv(datafiltcurv,F2,'same');
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
allVals2 = datafilt2(sigInds);
allVals2(allVals<0)=allVals2(allVals<0)*-1;

%% Having issues with the 5th bit not registering high enough
allVals(:,5)=allVals(:,5)*2;

%% convert to binary signal
binarysignal = calcBinaryFromPeaks(allVals, NUMBITS);

%% convert binary to decimal
BinaryBitsString = num2str(binarysignal(:,GOODBITS),'%.0f');
rawval = nan(1,nSignals);
for iRow=1:nSignals
    iBinSig = BinaryBitsString(iRow,:);
    rawval(iRow) = bin2dec(iBinSig);
    if DODEBUG
        txt = sprintf('%10.3f : %s : %.0f\n',tGP(iRow),iBinSig,rawval(iRow));
        figure(11)
        plotInds = sigInds(iRow,1)-100:sigInds(iRow,end)+100;
        plot(plotInds,d_data(plotInds),'k')
        hold on
        plot(plotInds,datafilt(plotInds),'b');
        plot(sigInds(iRow,:),allVals(iRow,:),'r*','markersize',10)
        plot(plotInds,datafilt2(plotInds)*10,'c-');
        for i=1:numel(GOODBITS)
            text(sigInds(iRow,GOODBITS(i)),0.8,iBinSig(i))
            text(sigInds(iRow,GOODBITS(i)),0.9,num2str(i))
        end
        title(txt)
        hold off
        xlim([min(plotInds(:)) max(plotInds(:))]);
        ylim([-1 1])
        drawnow
    end
end
%% filter val to remove outliers
%1) remove big jumps
%2) running mean filter
%3) remove points greater than 15 away from gaussian filtered
%4) linear fit
%5) round

x = 1:numel(rawval);
y = rawval;
%1) 
badInds = logical([0 diff(y)~=1]);
x(badInds)=[];
y(badInds)=[];
%2) 
FILTLEN = 21;
h = ones(1,FILTLEN)./FILTLEN;
ynorm = conv(ones(size(y)),h,'same');
yfilt= conv(y,h,'same')./ynorm;
%3) 
badInds = abs(y-yfilt)>1;
x(badInds)=[];
y(badInds)=[];
%4) 
p = polyfit(x,y,1);
y2 = polyval(p,1:numel(rawval));
%5)
val = round(y2);
%output
fprintf('FIXED');
for iRow=1:nSignals
    iBinSig = BinaryBitsString(iRow,:);
    fprintf('%10.3f : %s : %.0f',tGP(iRow),iBinSig,rawval(iRow));
    if val(iRow) ~= rawval(iRow)
        fprintf(' : %.0f *index fixed via interpolation',val(iRow))
    end
    fprintf('\n');
end
if DODEBUG
   figure
   plot(1:numel(rawval),rawval,'r.')
   hold on
   plot(1:numel(rawval),val,'b.')
end
    %% DEBUG
if DODEBUG
    figure
    plot(d_data,'k-')
    hold on
    plot(datafilt)
    plot(ind,pkval,'m*')
    plot(ind(bigjumps),pkval(bigjumps),'go');
    title('extracted nmea peaks');
end

end