%%% Program made to plot histogram Number-of-events vs Magnitude
% The user has to define latitude/longitude range of lower left and
% upper right corner of selection box, and also the range of depth desired
% And also select.out file used


clear all
close all
botleft=[166 -17];
topright=[169 -14];
depth=[0 300];
depth2=[0 60]



file='select.out'
%/Users/baillard/_Moi/Programmation/Scripts/
system(['/Users/baillard/_Moi/Programmation/Scripts/nor2xyz ',file,' > depth.xy'])
fic=fopen('depth.xy','r')
A=fscanf(fic,'%f %f %f %*s %f %*f %*f %*f %*f %*f\n',[4 inf]);
A=A';
B=A;

A=A((A(:,1)>=botleft(1) & A(:,2)>=botleft(2)),:);
A=A((A(:,1)<=topright(1) & A(:,2)<=topright(2)),:);
A=A((A(:,3)>=depth(1) & A(:,3)<=depth(2)),:);

B=B((B(:,1)>=botleft(1) & B(:,2)>=botleft(2)),:);
B=B((B(:,1)<=topright(1) & B(:,2)<=topright(2)),:);
B=B((B(:,3)>=depth2(1) & B(:,3)<=depth2(2)),:);

datavec=[0.05:0.1:5];
data=A(:,end);
[n,count]=histc(data,datavec);
h=figure(1);
truc=bar(datavec,n,'style','histc');
set(truc,'FaceColor',[100 149 237]/255)

hold on
data2=B(:,end);
[n,count]=histc(data2,datavec);
truc2=bar(datavec,n,'style','histc');
set(truc2,'FaceColor','red');

set(gca,'Fontsize',15)
xlabel('Magnitude Ml','Fontsize',16)
ylabel('Number of events','Fontsize',16)

fclose(fic)
print -f1 histogram
system('ps2pdf histogram.ps histogram.pdf')

