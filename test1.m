clear all
close all

%%%% test

sdr=[ 278.0   72.0  -17.0 ];
%sdr=[274.6    43.1    -3.3];
%sdr=[48.7    33.6    69.9];
%sdr=[164.8    48.0    -1.0];
%sdr=[306.5    18.4   157.5];
strike=sdr(1);
dip=sdr(2);
rake=sdr(3);

[t,p,b]=sdr2tpb(strike,dip,rake)

M=sdr2mt(strike,dip,rake);

plotmt(0,0,M)

%[s,d,r]=tpb2sdr(t,p,b)
% num=10000;
% 
% A=normrnd(-0.882,0.226,num,1);
% B=normrnd(0.351,0.029,num,1);
% 
% 
% res=10.^(A+B.*7);
% 
% hist(res,200)
% std(res)
% t=mean(res)