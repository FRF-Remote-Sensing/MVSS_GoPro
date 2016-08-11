function y = lsqest(x,h,n,xi,dodebug)
% LSQEST running least squares polynomial fit to a function
%   a running least squares approximation is used to filter the data using
%   polyfit and polyval, with the order of polynomial depicted by n.  h is
%   a window which can be used to ignore cerain indices surrounding the
%   evaluated location.  For example: [1 1 1 0 0], fits a polynomial to the
%   two preceding numbers in the vector, as well as the value at the
%   evaluated location.  [0 0 0 0 1 1 1] uses only the 3 numbers after the
%   evaluated point in the vector.  xi can optionally be passed in so that
%   the function is only evaluated at specific indices.
% 
% Inputs:
%   - x       : 1xN : data to be filtered
%   - h       : 1xM : window of 1s and 0s centered on evaluated point
%   - n       :  1  : order of polynomial to fit
%   - xi      : 1xP : Optional indices to solve for
%   - dodebug : 1/0 : boolean flag for debugging plots
% 
% Outputs:
%   - y       : 1xP : filtered data
% 
% Example:
%   y = sin(1:0.2:20);
%   h = [ones(1,5) 0 zeros(1,5)]; % fit value based on previous 5 points
%   xi = 10:10:90;
%   y2 = lsqest(y,h,1,xi,1);
%
% Dependencies:
%   - n/a
% 
% Toolboxes Required:
%   - n/a
% 
% TODO:
%   - add functionality to determine when the data is being overfit by
%     calculating the significance of each new Beta
% 
% Author        : Richie Slocum    
% Email         : richie@cormorantanalytics.com
% Date Created  : August 11, 2016   
% Date Modified : August 11, 2016

%% argument handling
if nargin==3
   xi = 1:numel(x); 
   dodebug = 0;
elseif nargin ==4
   dodebug = 0;
end

if isempty(xi) % default to evaluate all points if [] is passed in
   xi = 1:numel(x);
   allxi = true; %flag for type of debugging plot
else
    allxi = false;
end

if dodebug
   f = figure; 
end
%% 
relativeIndH = (1:numel(h))-floor(numel(h)/2)-1;
relativeIndH(h==0)=[];

y = nan(1,numel(xi));
% for each point to be evaluated
for i=1:numel(xi);
    %% determine indices based on window
    iInds = relativeIndH + xi(i);
    
    badInds = iInds<1 | iInds>numel(x);
    
    iInds(badInds)=[];
    %% evaluate polyfit and polyval
    if numel(iInds)>n%only fit if enough valid points
       %fit polynomial to each point
        p = polyfit(iInds,x(iInds),n);
       y(i) = polyval(p,xi(i));
       
       if dodebug % generate debug plots
           cmap = jet(4); %alternate the color of lines plotted
           cmap(3,:) = [1 0.5 0];%replace yellow with orange
           colorind = mod(i,3)+1;
           figure(f);
           plot(x,'k');
           hold on
           plot(iInds,x(iInds),'*','color',cmap(colorind,:))
           plotInds = min(iInds)-numel(h):max(iInds)+numel(h);
           plotInds(plotInds<1 | plotInds>numel(x))=[];
           showX = plotInds;
           showY = polyval(p,plotInds);
           plot(showX,showY,'-','color',cmap(colorind,:));
           
           plot(xi(i),y(i),'o','color',cmap(colorind,:));
            ylim([-1 1]);
            plot(xi,y,'r*')
            if allxi
                hold off
            end
           pause(0.05)
       end
    else
       y(i) = nan; 
    end
    
end

end