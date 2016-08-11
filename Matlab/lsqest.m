function y = lsqest(x,h,n,xi,dodebug)
if nargin==3
   xi = 1:numel(x); 
   allxi = true;
   dodebug = 0;
elseif nargin ==4
   dodebug = 0;
end
if isempty(xi)
   xi = 1:numel(x);
   allxi = true;
else
    allxi = false;
end
relativeIndH = (1:numel(h))-floor(numel(h)/2)-1;
relativeIndH(h==0)=[];

if dodebug
   f = figure; 
end

y = nan(1,numel(xi));

for i=1:numel(xi);
    iInds = relativeIndH + xi(i);
    
    badInds = iInds<1 | iInds>numel(x);
    
    iInds(badInds)=[];
    
    if numel(iInds)>n
       p = polyfit(iInds,x(iInds),n);
       
       y(i) = polyval(p,xi(i));
       if dodebug
           cmap = jet(4);
           cmap(3,:) = [1 0.5 0];
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