% Functi

clear all
close all


file1='manu.out';
file2='stalta.out';
file_out='compare_STA.out';
fic=fopen(file_out,'rt');

% Compare the two files

[BB,CC]=compare_selec(file1,'select',file2,'auto',file_out);

% Set colums to a matrix

A=textscan(fic,'%*3.0f %5s %2c %6.2f %1.0f %1.0f %*6.1f %*6.1f %*6.1f %3.2f %*[^\n]','Headerlines',1);
fseek(fic,0,-1);
AA=textscan(fic,'%3.0f %*5s %*2c %*6.2f %*1.0f %*1.0f %6.1f %6.1f %6.1f %*[^\n]','Headerlines',1);
fseek(fic,0,-1);

eventnum=textscan(fic,'%3.0f %*[^\n]','Headerlines',1);
eventnum=eventnum{1};

phases=cellstr(A{2});

iwmanu=A{5};
iwauto=A{4};
mag=A{6};

ip=find(strcmp('P',phases)==1);
iptime=A{3}(ip);
ipweight=iwauto(ip);
ipweiman=iwmanu(ip);
ipmag=mag(ip);

is=find(strcmp('S',phases)==1);
istime=A{3}(is);
isweight=A{5}(is);
isweiman=A{4}(is);
ismag=mag(is);

ip0=iptime(ipweight==0);
ip1=iptime(ipweight==1);
ip2=iptime(ipweight==2);
ip3=iptime(ipweight==3);

is0=istime(isweight==0);
is1=istime(isweight==1);
is2=istime(isweight==2);
is3=istime(isweight==3);

stdp=intervalstd(iptime,0.68);
stdp95=intervalstd(iptime,0.95);
std3=intervalstd(ip3,0.68);
std2=intervalstd(ip2,0.68);
std1=intervalstd(ip1,0.68);
std0=intervalstd(ip0,0.68);

stds=intervalstd(istime,0.68);
stds95=intervalstd(istime,0.95);
stds3=intervalstd(is3,0.68);
stds2=intervalstd(is2,0.68);
stds1=intervalstd(is1,0.68);
stds0=intervalstd(is0,0.68);

%% Plot histograms for P without any conditions

f1=figure(1);
% P
subplot(211)
axilim=[-2:0.1:2];
[n,xout]=hist(iptime,axilim);
truc=bar(xout,n*100/sum(n),'hist');
set(truc,'FaceColor',[1 0 0]);
xlabel('Deviation between automatic and manual P-picks [sec]','Fontsize',14);
ylabel('%','Fontsize',14)
set(gca,'Fontsize',14);
set(gca,'Xtick',[-5:0.5:5]);
text(0.2*max(get(gca,'Xlim')),0.6*max(get(gca,'Ylim')),sprintf('P-picks: %3.2f +/- %3.2f sec\nNumber of picks compared: %3.0f',...
    median(iptime),stdp,length(iptime)),'Fontsize',14,'BackgroundColor',[1 1 1],'Edgecolor',[0 0 0])
usergrid(gca,[],[20],[0.7 0.7 0.7],'--')
% S
subplot(212)
axilim=[-2:0.1:2];
n=hist(istime,axilim);
truc=bar(axilim,n*100/sum(n),'hist');
set(truc,'FaceColor',[1 0 0]);
set(gca,'Fontsize',14);
set(gca,'Xtick',[-5:0.5:5]);
xlabel('Deviation between automatic and manual S-picks [sec]','Fontsize',14);
ylabel('%','Fontsize',14)
text(0.2*max(get(gca,'Xlim')),0.6*max(get(gca,'Ylim')),sprintf('S-picks: %3.2f +/- %3.2f sec\nNumber of picks compared: %3.0f',...
    median(istime),stds,length(istime)),'Fontsize',14,'BackgroundColor',[1 1 1],'Edgecolor',[0 0 0])
usergrid(gca,[],[10],[0.7 0.7 0.7],'--')

print -depsc2 article_STA1.eps

fclose(fic)