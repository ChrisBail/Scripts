%%% Program made to compute relative plate motion
% http://seismo.berkeley.edu/~rallen/eps122/lectures/L04.pdf

clear all
close all

Pole_lon=1.742;
Pole_lat=60.080;
R_earth=6371;

X_lon=166;
X_lat=-13;

angular_vel=1.0744;

ang2rad=pi/180;

a=acos(sind(X_lat)*sind(Pole_lat)+...
    cosd(X_lat).*cosd(Pole_lat).*cosd(Pole_lon-X_lon));
C=asin(cosd(Pole_lat).*sind(Pole_lon-X_lon)./sin(a));



azimut=90+C*180/pi;
v=angular_vel*ang2rad*R_earth*sin(a);

