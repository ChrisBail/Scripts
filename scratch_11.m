clear all 
close all

%file='/Volumes/donnees/SE_DATA/WOR/PREV/collect_prevot.xyz';
%file='/Users/baillard/_Moi/SCRATCH/Catalog/ARCVANUATU.cat';
file='/Users/baillard/_Moi/SCRATCH/Catalog/ARCVANUATU_local.cat';
%file='/Users/baillard/_Moi/Programmation/Matlab/Cluster_Orientation/hypoDD_BEST.reloc';
%file='/Users/baillard/_Moi/SCRATCH/bb';
fic=fopen(file,'rt');
%A=textscan(fic,'%*f %f %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %f %*[^\n]','headerlines',0);
A=textscan(fic,'%f %f %f %s %f %f %f %f %f %f','headerlines',0);
% rms=A{end};
% fclose(fic);
% mag=A{5};
% rms(isnan(rms))=[];
% y=quantile(rms,[0.25, 0.5, 0.75]);
% 
% y_mag=quantile(mag,[0 0.25, 0.5, 0.95 1])
% length(rms(rms<0.5))./length(rms).*100

z_e=A{8};

z_e(z_e==999.9)=[]