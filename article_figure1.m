clear all 
close all

subplot(621)
siz=1000;
x=[1:siz];
a=wgn(siz,1,1);
b=rand(siz,1,1);
 plot(x,a)
 
 subplot(622)
 hist(a)
 kurtosis(a)
 
  subplot(623)
  plot(x,b)
  
  subplot(624)
  hist(b)
 kurtosis(b)
 
  subplot(625)
  plot(x,cos(x))
  
  subplot(626)
  hist(cos(x))
 kurtosis(cos(x))
 
 y=9*cos(x);
 tt=cat(1,a(1:floor(end/2)),y(1:50)');
 tt=cat(1,tt,a(1:floor(end/2)-100));
 
 figure
 plot(tt)
 
 figure
 
 hist(tt)
 
 kurtosis(tt(1:504))