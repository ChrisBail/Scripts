% pick_trench
%%% Program made to pick trench

clear all
close all

addpath(genpath('/Users/baillard/_Moi/Programmation/Scripts'));

% gridfile='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Grids/Global940m.grd';
% grid2mesh(gridfile,1,1,'vanuatu_global.mat')

A=load('vanuatu_global.mat');

X=A.X;
Y=A.Y;
Z=A.Z;

x=X(1,:);
y=Y(:,1);
figure
dem(x,y,Z,'Contrast',0.05,'Zlim',[-10000 2000],'legend');
%  
% B=load('trench.mat');
% xt=B.xt;
% yt=B.yt;
% 
% hold on
% 
% plot(xt,yt,'k','linewidth',2)

[x, y,c] = ginputc( 'Color', 'r', 'LineWidth', 3,'ShowPoints', true, 'ConnectPoints', true)
A=[x y]
save('tst','A','-ascii')

tr='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Grids/Global_trench.txt';

A=load(tr)

hold on
plot(A(:,1),A(:,2),'k','linewidth',2)