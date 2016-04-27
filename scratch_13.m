clear all
close all


file='/Users/baillard/_Moi/SCRATCH/bb';
fic=fopen(file,'rt');
A=textscan(fic,'%*f %f %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %*f %f %*f %*f %*f %*f %*f %*f %f %*[^\n]','headerlines',0);

B=[A{2} A{3}];

t=18;
min(B(B(:,2)==t,1))

max(B(B(:,2)==t,1))
