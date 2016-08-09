function mvss_cameraFlightPlanning2()
%% Use this script to generate some plots to aid in your flight planning
%% Flight Parameter Constants
altmeters=200;%altitude in meters
FlightSpeed=10;%flight speed in meters/second
imagedt=0.5;%difference in seconds between images
maximumCaxis = 300; %time in seconds
%% Change Camera Parameters
% Camera parameters

[intrinsic{1},hpix(1),vpix(1)]=mvss_calcCamIntrinsic('gopro_4k',5.4);%5mm is the widest zoom on canon
[intrinsic{2},hpix(2),vpix(2)]=mvss_calcCamIntrinsic('gopro_4k',2.9);%5mm is the widest zoom on canon
[intrinsic{3},hpix(3),vpix(3)]=mvss_calcCamIntrinsic('gopro_4k',2.9);%5mm is the widest zoom on canon
[intrinsic{4},hpix(4),vpix(4)]=mvss_calcCamIntrinsic('gopro_4k',2.9);%5mm is the widest zoom on canon
% [intrinsic{5},hpix(5),vpix(5)]=mvss_calcCamIntrinsic('gopro_4k',4.35);%5mm is the widest zoom on canon

cam(1,:)=[0 0 90];% [ Xrotate Yrotate Zrotate ]
cam(2,:)=[0 55 0];
cam(3,:)=[0 -55 0];
cam(4,:)=[-40 0 180];
% cam(5,:)=[-45 5 80];

%grid parameters
[DSM.xgrid,DSM.ygrid]=meshgrid(-1500:5:1500,-2000:5:2000);
DSM.zgrid=zeros(size(DSM.xgrid));

%% Processing
% make rotation matricies
for i=1:size(cam,1)
      camExtrinsics{i}=Euler2DCM(cam(i,1),cam(i,2),cam(i,3))*[0 1 0;1 0 0;0 0 -1];
      camExtrinsics{i} = [camExtrinsics{i} [0;0;0];0 0 0 1];
end
% Set Flight altitude
for i=1:numel(camExtrinsics)
    ex=camExtrinsics{i};
    exinv=inv(ex);
    exinv(1:3,4)=[0 0 altmeters];
    camExtrinsics{i}=inv(exinv);
end
%% Calculate an Ortho for each camera
clear ortho
for i=1:numel(camExtrinsics)
    ortho(:,:,i)=makeCamOrtho(intrinsic{i},camExtrinsics{i},DSM,hpix(i),vpix(i));
end
figure(3)
hold off
pcolor(DSM.xgrid,DSM.ygrid,sum(ortho,3));shading flat; axis equal
hold on
plot([0,0],[min(DSM.ygrid(:)) max(DSM.ygrid(:))],'r-');
plot([min(DSM.xgrid(:)) max(DSM.xgrid(:))],[0,0],'r-');
grid on
AllImagesOrtho=double(logical(sum(ortho,3)));

FlightAsPos=min(DSM.ygrid(:)):FlightSpeed*imagedt:max(DSM.ygrid(:));

% OrthoTimeseries=false([size(AllImagesOrtho) numel(FlightAsPos)]);
%% Use this for direct calculation of orthos, so for future iterations when
% Using custom flight paths rather than straight lines, use this
% for i=1:numel(FlightAsPos)
%     % Set Flight altitude and Alongshore position
%     for ii=1:numel(camExtrinsics)
%         ex=camExtrinsics{ii};
%         exinv=inv(ex);
%         exinv(1:3,4)=[0 FlightAsPos(i) altmeters];
%         camExtrinsics{ii}=inv(exinv);
%         orthoInst(:,:,ii)=makeCamOrtho(intrinsic,camExtrinsics{ii},DSM,hpix,vpix);
%     end
%     OrthoTimeseries(:,:,i)=(logical(sum(orthoInst,3)));
% %     figure(4)
% %     pcolor(DSM.xgrid,DSM.ygrid,sum(double(OrthoTimeseries),3));shading flat
% end

dy=mean(diff(DSM.ygrid(:,1)));
sOrthoTimeseries=zeros(size(AllImagesOrtho));
for i=1:numel(FlightAsPos)
    sOrthoTimeseries=sOrthoTimeseries+shiftImage(AllImagesOrtho,FlightAsPos(i)/dy);
end
    figure(4)
    pcolor(DSM.xgrid,DSM.ygrid,sOrthoTimeseries*imagedt);shading flat;axis equal
    title({'Time in seconds at each location',['max of ' sprintf('%.0f',max(sOrthoTimeseries(:))) ' images and ' sprintf('%.0f',imagedt*max(sOrthoTimeseries(:))) ' second duration']});
    colorbar
    caxis([0 maximumCaxis]);
    colormap('jet')
end
function B=shiftImage(A,pixY)
pixY=round(pixY);
if abs(pixY)>=size(A,1)
   B=false(size(A));
   return
end
B=false(size(A));
    if pixY>=0
       Bmax=size(A,1);
       Bmin=1+pixY;
       Amax=size(A,1)-pixY;
       Amin=1; 
    else
       Bmax=size(A,1)+pixY;
       Bmin=1;
       Amax=size(A,1);
       Amin=1-pixY;
    end

    B(Bmin:Bmax,:)=A(Amin:Amax,:);

end
function ortho=makeCamOrtho(intrinsic,extrinsic,DSM,hpix,vpix)

    uv=intrinsic*extrinsic(1:3,:)*[DSM.xgrid(:) DSM.ygrid(:) DSM.zgrid(:) ones(size(DSM.zgrid(:)))]';
    u=uv(1,:)./uv(3,:);
    v=uv(2,:)./uv(3,:);
%     figure(2)
%     plot(u,v,'b.')
%     xlim([0 hpix]);ylim([0 vpix]);
    goodvals=ones(size(DSM.xgrid(:)));
    goodvals(u<0 | u>hpix | v<0 | v>vpix | uv(3,:)<0)=0;
    
    ortho=reshape(goodvals,(size(DSM.xgrid)));

end
function [intrinsic,hpix,vpix] = mvss_calcCamIntrinsic(cameraname,focalLength_mm)
    
    %canon elph 115 IS
    if strcmp(cameraname,'canon_ELPH115')
        sensorXdim_mm=6.17;
        sensorYdim_mm=4.55;
        totXpix=4608;
        totYpix=3456;
        hpix=4608;
        vpix=3456;
    elseif strcmp(cameraname,'gopro_4k')
        sensorXdim_mm=6.17;
        sensorYdim_mm=4.55;
        totXpix=4000;
        totYpix=3000;
        hpix=3840;
        vpix=2160;
    elseif strcmp(cameraname,'gopro_img')
        sensorXdim_mm=6.17;
        sensorYdim_mm=4.55;
        totXpix=4000;
        totYpix=3000;
        hpix=4000;
        vpix=3000;
    end
    hpixdim=totXpix/sensorXdim_mm;
    vpixdim=totYpix/sensorYdim_mm;
    fx=hpixdim*focalLength_mm;%assume no funny business
    fy=vpixdim*focalLength_mm;%assume no funny business

    %assume cx, cy are middle of image and distortion is negligible
    cx=hpix/2;
    cy=vpix/2;
    intrinsic=[fx 0 cx; 0 fy cy; 0 0 1];

end

function C = Euler2DCM(x,y,z)
Cx = [[1 0 0]
    [0 cosd(x) sind(x)]
    [0 -1*sind(x) cosd(x)]];

Cy = [[cosd(y) 0 -1*sind(y)]
    [0 1 0]
    [sind(y) 0 cosd(y)]];

Cz = [[cosd(z) sind(z) 0]
    [-1*sind(z) cosd(z) 0]
    [0 0 1]];

C = Cx*Cy*Cz;
end