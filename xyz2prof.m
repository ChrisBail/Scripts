%%%% function get box parameter and projected data %%%
%%% Input:  x,y,z-> coordinates in meters or km
%           box_l-> length of profile
%           box_w-> half width to get data
%           phiA -> azimuth (positive conter clockwise from East direction)
%           x_center,y_center-> center of profile
%%% Output: xp,zp -> projected coordinates

function [xp,zp,i]=xyz2prof(x,y,z,box_l,box_w,phiA,x_center,y_center)

%%% Define angles

phiA=(phiA)*pi/180;

%%% Get projected data

x0=[];
y0=[];
z0=[];

cond1=abs(-(x-x_center)*sin(phiA)+(y-y_center)*cos(phiA));
cond2=abs((x-x_center)*cos(phiA)+(y-y_center)*sin(phiA));
i=find(cond1<box_w & cond2<box_l/2);
if ~isempty(i);
    x0=x(i)-x_center;y0=y(i)-y_center;z0=z(i);
end

xp=(x0*cos(phiA)+y0*sin(phiA)); % passage matrix
zp=z0;

end