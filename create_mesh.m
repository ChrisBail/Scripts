function [Lon,Lat,z1]=create_mesh(Lon0,Lat0,x,y,z,alpha)
%%% alpha is CCW from EAST
close all

alpha=alpha*pi/180;
%alpha=-alpha;

[XM,YM,ZM]=meshgrid(x,y,z);

num_node_x=length(x);
num_node_y=length(y);

%%% Rotation matrix

R=[cos(alpha) -sin(alpha) 0; sin(alpha) cos(alpha) 0;0 0 1];

%%% Define coordinates in cartesian base

X=XM(:);
Y=YM(:);
Z=ZM(:);

C1=R*[X Y Z]';
x1=C1(1,:)';
y1=C1(2,:)';
z1=C1(3,:)';

%%% Shift grid to lat0 lon0

[x0,y0,~,~] = wgs2utm(Lon0,Lat0,58,'S');
x1=x1+x0;
y1=y1+y0;

%%% Convert to lon lat

[Lon,Lat]=utm2wgs(x1,y1,'58L');

plot(Lon,Lat,'.')
axis equal

end