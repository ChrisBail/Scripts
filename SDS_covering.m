% Script made to compute the covering of a data from a SDS archive, the output is 
% a nice plot showing stations, components and the covering of the data

clear all
close all

%%% Paramaters

sds_path='/media/baillard_d1/SDS/';

years='*';
stations='*';
comps='*';
networks='N';
temp_file='cat.txt';
titlename='DATA Timespan East Nepal Network';

time_start=datenum([2015 01 01]);
time_end=datenum([2015 10 01]);

%%% Remove file if exist

if exist(temp_file,'file')
    delete(temp_file);
end

%%% Start Program

search_paths=[sds_path,years,'/',networks,'/',stations,'/',comps,'/*'];

%%% Create file with data

cmd=['for i in ',search_paths,' ; do echo $i | awk -F/ ''{print $NF}'' | awk -F. ''{print $1,$2,$4,$6,$7}'' | awk  ''NF==5 {print $0}'' >> ',temp_file,';done'];

system(cmd);

%%% Read file

fic=fopen(temp_file,'rt');

A=textscan(fic,'%s %s %s %f %f\n');

fclose(fic);

for i=1:length(A{1})
    B(i,1)={sprintf('%-5s %-5s',A{2}{i},A{3}{i})};
end

%%% Change year and day to datenum

serial_date=datenum(A{4},0,A{5});

xax=time_start:time_end;

%%% start computing

unique_comb=sort(unique(B));

f=figure(1);

k=0;
for i=1:length(unique_comb)
   val_date=serial_date(strcmp(unique_comb{i},B)); 
   plot([time_start time_end],[k k],'color',[0.8 0.8 0.8]);
   hold on
   h=plot(val_date,k*ones(size(val_date)),'sg','markerfacecolor','g');
   hold on
   k=k+1;
end

hold off
screen=get(0,'screensize');
height=screen(4);
set(f, 'Position', [screen(3)/3 screen(4)/4 height*0.8 height*0.6]);

ax=gca;
xlim([time_start time_end])
set(ax,'Ylim',[-1 length(unique_comb)]);
set(ax,'Ytick',(0:length(unique_comb)-1));
set(ax,'Yticklabel',unique_comb);

datetick('x','mm/yy')
xlim([time_start time_end])

title(titlename,'fontsize',15);

%%% Remove file

delete(temp_file);






