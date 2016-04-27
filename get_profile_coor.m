%%% get prof coordinates

function [xbox,ybox]=get_profile_coor(box_l,box_w,phiA,xshift,yshift)

%%% Define angles

phiB=phiA-90;
phiB=(phiB)*pi/180; 
phiA=(phiA)*pi/180;

%%% Define box coordinates

xbox=nan(5,1);
ybox=nan(5,1);

xbox(1)=(-box_l/2)*cos(phiA)-box_w*cos(phiB)+xshift;
xbox(2)=(-box_l/2)*cos(phiA)+box_w*cos(phiB)+xshift;
xbox(3)=(box_l/2)*cos(phiA)+box_w*cos(phiB)+xshift;
xbox(4)=(box_l/2)*cos(phiA)-box_w*cos(phiB)+xshift;
xbox(5)=xbox(1);

ybox(1)=(-box_l/2)*sin(phiA)-box_w*sin(phiB)+yshift;
ybox(2)=(-box_l/2)*sin(phiA)+box_w*sin(phiB)+yshift;
ybox(3)=(box_l/2)*sin(phiA)+box_w*sin(phiB)+yshift;
ybox(4)=(box_l/2)*sin(phiA)-box_w*sin(phiB)+yshift;
ybox(5)=ybox(1);

end