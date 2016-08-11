function [tGP,val] = calcGoproNmeaCounts2(t,nmea,NMEADT,BAUDRATE,DODEBUG)
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
NMEAPEAKTHRESH = 0.5;
FILTLENGTH = 20;
FILTSIGMA = 2;
NUMBITS = 20;
GOODBITS = [9:-1:2 19:-1:12];
dt = mean(diff(t(1:10)));
baudind = 1/BAUDRATE/dt;
SIGWINDOWPAD = 50;
RAWPKOFFSET = 3;
%% Calculate Filtered Signals
F = fspecial('gauss',[1 FILTLENGTH],FILTSIGMA);

raw_data = nmea; %raw data
raw_data_s = conv(raw_data,F,'same');%filtered raw data
d_data = [0 diff(nmea)'];%slope
d_data_s = [0 diff(raw_data_s)'];%filtered slope
d2_data = [0 0 diff(d_data_s)];%curvature

%% normalize Filtered Signals
raw_data = changeScale(raw_data,[-1 1]);
raw_data_s = changeScale(raw_data_s,[-1 1]);
d_data = changeScale(d_data,[-1 1]);
d_data_s = changeScale(d_data_s,[-1 1]);
d2_data = changeScale(d2_data,[-1 1]);

%% debug plot
if DODEBUG
    figure
    plot(raw_data);
    hold on
    plot(raw_data_s);
    plot(d_data);
    plot(d_data_s);
    plot(d2_data);
end
%% Find index of start of nmea
[pkval,ind]=findpeaks(abs(d_data_s),'minpeakheight',NMEAPEAKTHRESH);
pkval(d_data_s(ind)<0)=pkval(d_data_s(ind)<0)*-1; %make negative peaks

% Find First Value after a big jump in time (aka, first signal of binary)
bigjumps = find(diff(ind)>NMEADT/dt/2)+1; %+1 to shift it right

% Calculate Index of Bits for each signal
firstinds = ind(bigjumps);
indoffset = round(0:baudind:baudind*(NUMBITS-1));
alloffset = -SIGWINDOWPAD:FILTLENGTH * baudind+SIGWINDOWPAD;

[indoffsets,pkFirstInds]=meshgrid(indoffset,firstinds);
[alloffsets,allFirstInds]=meshgrid(alloffset,firstinds);

sigInds = indoffsets + pkFirstInds;
allInds = alloffsets + allFirstInds;

% Calculate time of first bit for each signal
nSignals = numel(firstinds);
tGP = t(firstinds);

%% Extract Raw Data from signal for each

allrawdata = raw_data(allInds);
allrawdatas = raw_data_s(allInds);
allddata = d_data(allInds);
allddatas = d_data_s(allInds);
alld2data = d2_data(allInds);

pkrawdata = raw_data(sigInds+RAWPKOFFSET);
pkrawdatas = raw_data_s(sigInds+RAWPKOFFSET);
pkddata = d_data(sigInds);
pkddatas = d_data_s(sigInds);
pkd2data = d2_data(sigInds);

%% debug plot
if DODEBUG
   f = figure;
    for i=1:nSignals
      plot(allInds(i,:),allrawdata(i,:),'.-');
      hold on
      plot(sigInds(i,:),pkrawdata(i,:),'*');
      plot(allInds(i,:),allddatas(i,:),'.-');
      plot(sigInds(i,:),pkd2data(i,:),'*');
      xlim([min(allInds(i,:)) max(allInds(i,:))]);
      ylim([-1 1]);
      hold off
      drawnow
      pause(0.5);
   end
end

%% convert to binary signal
%calculate bit 3

valoverpeak = nan(size(pkddata));

for i=1:nSignals
   
    x = allrawdata(i,:);
    xi = indoffset + 4 + SIGWINDOWPAD;
    yi = lsqest(x,([ones(1,8) zeros(1,4) 0 zeros(1,12)]),1,xi,0);
    
    valoverpeak(i,:) = x(xi)-yi;
    
end
figure
pcolor(valoverpeak(:,GOODBITS));shading flat
%% convert to binary
BIT2THRESH = 0.4;
BITTHRESH = 0.1;

binarysignal = nan(size(pkrawdata));

binarysignal(valoverpeak<-BITTHRESH)=0;
binarysignal(valoverpeak>BITTHRESH)=1;

binarysignal(:,1) = 0;
binarysignal(:,10) = 1;
binarysignal(:,11) = 0;
binarysignal(:,19) = 1;

%calculate bit 2
bit2ones = pkrawdata(:,2)>BIT2THRESH;
binarysignal(bit2ones,2)=1;

%iterate to fill in unknown vals
binarysignalinterp = false(nSignals,16);
rawTimeIndex = nan(1,nSignals);
for i = 1:nSignals
    ibinsig = binarysignal(i,:);
    ix = find(~isnan(ibinsig));
    iy = ibinsig(ix);
    ibin = interp1(ix,iy,1:numel(ibinsig),'previous','extrap');
    binarysignalinterp(i,:) = logical(ibin(GOODBITS));
    strbin = sprintf('%i',binarysignalinterp(i,:));
    rawTimeIndex(i) = bin2dec(strbin);
    fprintf('%s : %i\n',strbin,rawTimeIndex(i))
end

rawTimeIndex(rawTimeIndex>10000)=nan;

%%
binarysignal = calcBinaryFromPeaks(allVals, NUMBITS);
%%
%% convert binary to decimal
BinaryBitsString = char(ones(size(binarysignal,1),16));
for i=1:size(binarysignal,1)
    istring = sprintf('%i',ceil(binarysignal(i,GOODBITS)));
    istring(istring=='-')=[]; %weird sprintf adding a negative 
    BinaryBitsString(i,:) = istring;
end

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
        plot(plotInds,nmea(plotInds),'b');
        plot(plotInds,datafilt(plotInds),'r');
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