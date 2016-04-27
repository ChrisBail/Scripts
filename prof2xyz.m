%%%% function get x,y,z coordinates from xp,zp profile coordinates
%%% Output:  x,y,z-> coordinates in meters or km
%           
%%% Input:  xp,zp -> projected coordinates
%           phiA -> azimuth (positive conter clockwise from equator)
%           x_center,y_center-> center of profile

function [x,y,z]=prof2xyz(xp,zp,phiA,x_center,y_center)

%%% Get projected data

x=xp*cosd(phiA)+x_center;
y=xp*sind(phiA)+y_center;
z=zp;
end