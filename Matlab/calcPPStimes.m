function [tppsrising,tppsfalling]=calcPPStimes(t,pps,DODEBUG)
%% Calculates the times of PPS rising and falling edges from audio data
%
%  Input:
%   t: 1xM : vector of times
%   pps: 1xM: vector of signal amplitudes
%   DODEBUG: {1,0} : Set to 1 for debugging plots and info
%
%  Output:
%   tppsrising: 1xN : time of PPS rising edge
%   tppsfalling: 1xN : time of PPS falling edge
%% Calculate dt
dt = mean(diff(t(1:10)));

PPSWIDTH = 0.1; % PPS Signal Width
PPSPKTHRESH = 0.2; % min peak height

dPPS = diff(pps);
ppsWidthInd = PPSWIDTH * 1/dt;
%% Find PPS Peaks
[~,ind]=findpeaks(abs(dPPS),'MinPeakHeight',PPSPKTHRESH,'MinPeakDistance',ppsWidthInd/2);
if ~isempty(ind)
    ind = ind+2;
    
    if DODEBUG
        figure
        plot(t,pps);
        hold on
        plot(t(ind),pps(ind),'m*');
        title('extracted PPS peaks');
    end
    %% Find indicies of rising and falling peaks
    risingind = ind(pps(ind)>0);
    fallingind = ind(pps(ind)<0);
    
    tppsrising = t(risingind);
    tppsfalling = t(fallingind);
    
    fprintf('Calculated %.0f Rising PPS pulses\n',numel(tppsrising))
    fprintf('Calculated %.0f Falling PPS pulses\n',numel(tppsfalling))
else
    warning('NO PPS peaks detected');
end
end