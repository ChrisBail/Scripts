%%% Function made to smooth curve when it's not monotonic, typically like
%%% coastlines, trench coordinates....
% Input: infile> input file
% Output: outfile> smoothed output file 

function smooth1D_coord(infile,outfile,npoints,percent_win)

% percent_win=3;
% npoints=10000;
% infile='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Grids/Global_trench.txt';
% outfile='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Grids/Smooth_Trench.txt';

A=load(infile);
xtr=A(:,1);
ytr=A(:,2);

dist=zeros(length(xtr)-1,1);
xdiff=diff(xtr);
ydiff=diff(ytr);

dist=sqrt(xdiff.^2+ydiff.^2);

v=zeros(length(xtr),1);

for i=2:length(v)
    v(i)=v(i-1)+dist(i-1);
end

% Smooth 

vxsmooth=linspace(v(1),v(end),npoints);
vy=interp1(v,ytr,vxsmooth);
vx=interp1(v,xtr,vxsmooth);
windowSize = percent_win*npoints/100;
vyy=filter(ones(1,windowSize)/windowSize,1,vy);
vxx=filter(ones(1,windowSize)/windowSize,1,vx);

vxx(1:windowSize)=[];
vyy(1:windowSize)=[];

plot(vx,vy,'.r',xtr,ytr,'.b',vxx,vyy,'.g');

fic=fopen(outfile,'wt');

fprintf(fic,'%8.3f %8.3f\n',[vxx;vyy]);

fclose(fic);
end

