function binarySignal = calcBinaryFromPeaks(allVals, NUMBITS)
%% Calculate the binary signal given an array of 20 raw signals
%
% Background:
% a NMEA ASCII number is sent via the microphone port of the gopro
% the gopro microphone records a change in bit, rather than the raw value
% of the bit, (because it's a microphone and only returns electrical signal
% on a voltage change)
%
% To decode the 20 bit number, the following information is needed
%
%   The 20 bit number is broken up into the LSB and MSB
%   the 16 bit binary number is the indices in this order:
%      GOODBITS = [9:-1:2 19:-1:12]
%   bit 1 and 11 must be FALSE
%   bit 10 and 20 must be TRUE
%   
%   Therefore, the signal recorded by the microphone for bit 1 and 11 must
%   be euqal to negative 1
%
%   Occasionally a -1 bit is missed, and this algorithm is written to try
%   to avoid missing certain bits, and to calculate the correct binary
%   value for each signal.  A separate code will convert the binary signal
%   into an actual number

%% algorithm Sig = signal, Bin = binary
% 1) Calculate Theshhold for Peaks 
%     - 1/3th value of max peak
% 2a) Sig(1,11)=-1
% 2b) Bin(1,10,11,20) = (0,1,0,1)
% 3) if Sig>thresh and positive, Bin =1, else Bin = 0
% 4) 

%% Convert values to binary
% set peak as 1/3 max peak for each signal

% 1
pkthresh = max(abs(allVals'))/3;
pkthreshMat = repmat(pkthresh',[1,NUMBITS]);
threshSignal = double(abs(allVals)>pkthreshMat);
negativeVals = allVals<0;
threshSignal(negativeVals) = threshSignal(negativeVals)*-1;

%2a
threshSignal(:,1) = -1;
threshSignal(:,11) = -1;
%2b
binarySignal = ones(size(threshSignal))*-1;
binarySignal(:,1) = 0;
binarySignal(:,10) = 1;
binarySignal(:,11) = 0;
binarySignal(:,20) = 1;

%3
binarySignal(threshSignal==-1 & binarySignal~=-1) = 0;
binarySignal(threshSignal==1 & binarySignal~=-1) = 1;

% 4
NNUMS = numel(pkthresh);
BYTESTARTS = [1 11];
BYTELEN = 10;
%some hard coded logic to get some skipped bits out.
% look for when the cumulative sum gets to a number that doesnt make sense 
% assume the error was after the last value that exceeded the threshold
% only works when there is one skipped bit
for iIndNum=1:NNUMS
    for iByteNum = 1:2
        byteinds = BYTESTARTS(iByteNum):BYTESTARTS(iByteNum)+BYTELEN-1;
        byteBin = binarySignal(iIndNum,byteinds);
        byteSig = threshSignal(iIndNum,byteinds);
        %figure out if 0s signals are 0s or 1s in binary
%         vrl = fliplr([1 1+cumsum(fliplr(-byteSig(2:end)))]);
        vlr = [0 cumsum(byteSig(2:end))];
        
        if sum(vlr==2)>0
           iBad = find(vlr==2);
           iLastGood = find(byteSig(1:iBad-1)==1,1,'last');
           vlr(iLastGood+1:end)=vlr(iLastGood+1:end)-1;
        end
        if sum(vlr==-1)>0
           iBad = find(vlr==-1);
           iLastGood = find(byteSig(1:iBad-1)==-1,1,'last');
           vlr(iLastGood+1:end)=vlr(iLastGood+1:end)+1;
        end
        
        
%         if sum(vrl ~= vlr)>0
%            fprintf('warning... might have a skipped bit\n');
%         end
        binarySignal(iIndNum,byteinds) = vlr;
        
    end
end

end