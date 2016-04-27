% article histogramms
% Scriptes made to plot all hisytogramms and associated graphs from
% compare.out

clear all
close all

file1='manu_vanuatu.out';
file2='auto_vanuatu.out';    % Statistic file that containes all statistics for automatic and manual
file='compare.out';


% Read files


[E_auto,E_manu,BB,CC]=compare_selec(file1,file2,file);

% Struct_auto=read_selec(file2);
% Struct_manu=read_selec(file1);
Struct_auto=E_auto;
Struct_manu=E_manu;


fic=fopen(file,'rt');


%% Get statistics
% For manual
get_statistic(Struct_manu)
get_statistic(Struct_auto)



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
usergrid(gca,[],[20 40],[0.7 0.7 0.7],'--')
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
usergrid(gca,[],[10 20],[0.7 0.7 0.7],'--')

print -depsc2 article_histo1.eps


%% Plot histograms for P depending on the automatic weight given
% 
% f2=figure(2);
% 
% axilim=[-4:0.1:4];
% n=hist(iptime,axilim);
% truc=bar(axilim,n,'hist');
% set(truc,'FaceColor',[0 0 1])
% n=hist(ip1,axilim);
% hold on
% truc=bar(axilim,n,'hist');
% set(truc,'FaceColor',[1 0 0])
% n=hist(ip2,axilim);
% hold on
% truc=bar(axilim,n,'hist');
% set(truc,'FaceColor',[0 1 0])
% hold off
% 
% print -depsc2 article_histo2.eps

%% Plot mean and standard deviation

f3=figure(3);
s1=subplot(8,1,1:4);
pos1=get(s1,'pos');


%P

std=[std0 std1 std2 std3];
wei=[0 1 2 3];
med=[median(ip0) median(ip1) median(ip2) median(ip3)];
mea=[mean(ip0(ip0<2 & ip0>-2)) mean(ip1(ip1<2 & ip1>-2)) mean(ip1(ip1<2 & ip1>-2)) mean(ip1(ip1<2 & ip1>-2))];

errorbar(wei,med,std,'ok','MarkerFaceColor','k','Markeredgecolor',[0 0 0],'Markersize',8)
% hold on
% errorbar(wei,mea,std,'or','MarkerFaceColor','r')
% hold off
axis([-0.5 3.5 -0.5 0.5]);
ylabel('Median [sec]','Fontsize',14)
set(gca,'Xtick',wei)
set(gca,'Fontsize',14)

%S

stds=[stds0 stds1 stds2 stds3];
wei=[0 1 2 3];
meds=[median(is0) median(is1) median(is2) median(is3)];
meas=[mean(is0(is0<2 & is0>-2)) mean(is1(is1<2 & is1>-2)) mean(is1(is1<2 & is1>-2)) mean(is1(is1<2 & is1>-2))];

hold on
ty=errorbar(wei+0.1,meds,stds,'ok','MarkerFaceColor','w','Markeredgecolor',[0 0 0],'Markersize',8);

set(gca,'Ytick',[-0.4:0.1:0.4]);
t=legend(gca,'P-picks','S-picks');
set(t,'Fontsize',12);
hold off
usergrid(gca,[0.5 1.5 2.5],[0],[0.7 0.7 0.7],'--')
set(gca,'Xaxislocation','top')
% post=pos1;
% set(s1,'position',[pos1(1) pos1(2) pos1(3) pos1(4)*2])
% pos1=get(s1,'pos');
% dpos=pos1-post;
% newpos=[pos1(1) pos1(2)-dpos(4) pos1(3) pos1(4)];
% pos1=newpos;
% set(s1,'position',pos1)

% P & S
s2=subplot(8,1,5:6);
% pos2=get(s2,'pos');
% pos2(2)=pos1(2)-pos2(end)-0.02;
% set(s2,'pos',pos2);

axilim=[0:1:3];
n=hist(ipweight,axilim);
truc=bar(axilim,n*100/sum(n),0.95,'hist');
axis([-0.5 3.5 0 100]);
set(truc,'Facecolor','k')
set(gca,'Fontsize',14)
set(gca,'Xticklabel',[]);
values=n*100/sum(n);
values=round(values);
text(axilim,values+10,{sprintf('%3.0f %%',values(1)),sprintf('%3.0f %%',values(2)),sprintf('%3.0f %%',values(3)),sprintf('%3.0f %%',values(4))},'fontsize',14','HorizontalAlignment','center')
ylabel('% of P-picks','Fontsize',14)


usergrid(gca,[0.5 1.5 2.5],[],[0.7 0.7 0.7],'--')
% yy=get(gca,'YTick');
% xlabel('Local magnitude','fontsize',18)
% ylabel('% of picks','fontsize',18)
% set(gca,'fontsize',18,'ytick',yy(1:end-1));
% usergrid(gca,[0.95:0.5:4],[],[0.7 0.7 0.7],'--')

s3=subplot(8,1,7:8);
% pos3=get(s3,'pos');
% pos3(2)=pos2(2)-pos3(end)-0.02;
% set(s3,'pos',pos3);

isweight1=isweight;
isweight1(isweight1==0)=[];
n=hist(isweight1,axilim);
truc=bar(axilim,n*100/sum(n),0.95,'hist');
set(truc,'Facecolor','w')
axis([-0.5 3.5 0 100]);
set(gca,'Fontsize',14);
values=n*100/sum(n);
values=round(values);
text(axilim,values+10,{sprintf('%3.0f %%',values(1)),sprintf('%3.0f %%',values(2)),sprintf('%3.0f %%',values(3)),sprintf('%3.0f %%',values(4))},'fontsize',14','HorizontalAlignment','center')
usergrid(gca,[0.5 1.5 2.5],[],[0.7 0.7 0.7],'--')
xlabel('Weights')
ylabel('% of S-picks','Fontsize',14)

print -depsc2 article_histo2.eps
% 
% s2=subplot(212);
% 
% pos2=get(s2,'pos');
% pos2(2)=pos1(2)-pos2(end)-0.02;
% set(s2,'pos',pos2);
% 
% axilim=[0:1:3];
% np=hist(ipweight,axilim);
% ns=hist(isweight,axilim);
% truc=bar(axilim-0.2,np*100/sum(np));
% set(truc,'barwidth',0.4,'Facecolor',[0.33 0.51 0.9]);
% values=np*100/sum(np);
% values=round(values);
% text(axilim-0.2,values+5,{sprintf('%3.0f %%',values(1)),sprintf('%3.0f %%',values(2)),sprintf('%3.0f %%',values(3)),sprintf('%3.0f %%',values(4))},'fontsize',16','HorizontalAlignment','center')
% % ylabel('% of P-picks','Fontsize',14)
% axis([-0.5 3.5 0 100])
% 
% hold on 
% truc2=bar(axilim+0.2,ns*100/sum(ns));
% set(truc2,'barwidth',0.4,'Facecolor',[1 0 0]);
% set(gca,'Fontsize',14)
% set(gca,'Xtick',axilim);
% values=ns*100/sum(ns);
% values=round(values);
% text(axilim+0.2,values+5,{sprintf('%3.0f %%',values(1)),sprintf('%3.0f %%',values(2)),sprintf('%3.0f %%',values(3)),sprintf('%3.0f %%',values(4))},'fontsize',16','HorizontalAlignment','center')
% ylabel('%%','Fontsize',14)
% xlabel('Weights','Fontsize',14)
% axis([-0.5 3.5 0 100])

%% Creating the pie chart to see repartitions of weights

f4=figure(4);
% B1=usercolormap([0 0 205;210 255 255]/255,4);
% colormap(B1);

% For P
subplot(211)
piechart([size(ip0,1) size(ip1,1) size(ip2,1) size(ip3,1)],[0 0 0 0],{'Weight 0: ';'Weight 1: ';'Weight 2: ';'Weight 3: '},[0 0 205;210 255 255]/255);
title('Distribution of weights for P-picks','Fontsize',14)
freezeColors

% For S
subplot(212)
piechart([size(is0,1) size(is1,1) size(is2,1) size(is3,1)],[0 0 0 0],{'Weight 0: ';'Weight 1: ';'Weight 2: ';'Weight 3: '},[0 0 205;210 255 255]/255);
title('Distribution of weights for S-picks','Fontsize',14)



%% Plot the correlations between the two weights by substracting

f5=figure(5);

% for P
subplot(6,2,[1 3 5])
clear n;
weightdiffP=ipweight-ipweiman;
weightdiffP(weightdiffP==4 | weightdiffP==-4)=[];
axilim=[-3:1:3];
n=hist(weightdiffP,axilim);
truc=bar(axilim,n*100/sum(n),0.90,'hist');
set(gca,'Fontsize',14,'XaxisLocation','top')
set(truc,'FaceColor','k')
ylabel('% of P-picks','Fontsize',14)

% for S
subplot(6,2,[7 9 11])
clear n;
weightdiffS=isweight-isweiman;
axilim=[-3:1:3];
n=hist(weightdiffS,axilim);
truc=bar(axilim,n*100/sum(n),0.90,'hist');
set(gca,'Fontsize',14)
set(truc,'FaceColor','w')
ylabel('% of S-picks','Fontsize',14)
xlabel('Weight difference','Fontsize',14)

print -depsc2 article_histo3.eps



%% Plot distribution of Magnitudes

f6=figure(6);

% take magnitudes of each selected events

magevent=cat(1,mag(1),mag(diff(eventnum)>0));
numeventcom=length(magevent);
quartiles=quantile(magevent,[.25 .50 .75]);

axilim=[0:0.1:10];
n=hist(magevent,axilim);
truc=bar(axilim,n*100/sum(n),0.85,'hist');
axis([0.5 4.5 min(get(gca,'Ylim')) max(get(gca,'Ylim'))+2]);
set(gca,'Fontsize',14);
set(truc,'FaceColor',[0 0 0]);
ylabel('% of events','Fontsize',14);
xlabel('Local magnitude','Fontsize',14);
usergrid(gca,quartiles,[],[0 0 0],'--','front');
text(quartiles,repmat(max(get(gca,'Ylim'))-2,1,length(quartiles)),{'Q1','Q2','Q3'},'Fontsize',14,'HorizontalAlignment','center','Backgroundcolor','w');
text(0.53*max(get(gca,'Xlim')),0.8*max(get(gca,'Ylim')),sprintf('Total number of events: %4.0f\nQuartiles (Q1,Q2,Q3) = (%3.1f, %3.1f, %3.1f)',...
    numeventcom,quartiles(1),quartiles(2),quartiles(3)),'Fontsize',12,'BackgroundColor',[1 1 1],'Edgecolor',[0 0 0]);

print -depsc2 article_histo4.eps

%% Plot residuals depending on magnitudes


magp=mag(ip);
mags=mag(is);

% for P
f7=figure(7);


axilim=[-5:0.1:5];
n=hist(magp,axilim);
truc=bar(axilim,n,'hist');

histoxyz(magp,iptime,[1:0.1:4],[-2:0.1:2],jet)
set(gca,'fontsize',18,'Tickdir','out')
xlabel('Local magnitude','fontsize',18);
ylabel('Residuals [sec]','fontsize',18);
title('P-picks','fontsize',18);
t=colorbar;
set(t,'fontsize',18)
set(get(t,'Ylabel'),'string','Number of picks','fontsize',18)
usergrid(gca,[1.05:0.1:4],[-2.05:0.1:2],[0.5 0.5 0.5],'-','front')

f8=figure(8);

medianstd(magp,iptime,[0:0.1:6],[0.5 4.5],[0 0 0],'P-picks');
hh=get(f8,'Children');
set(hh(2),'Ylim',[-0.4 0.4])
print -depsc2 article_histo5.eps

% for S

f9=figure(9);

axilim=[-5:0.1:5];
n=hist(mags,axilim);
truc=bar(axilim,n,'hist');

histoxyz(mags,istime,[1:0.1:4],[-2:0.1:2],jet)
set(gca,'fontsize',18,'Tickdir','out')
xlabel('Local magnitude','fontsize',18);
ylabel('Residuals [sec]','fontsize',18);
title('S-picks','fontsize',18);
t=colorbar;
set(t,'fontsize',18)
set(get(t,'Ylabel'),'string','Number of picks','fontsize',18)
usergrid(gca,[1.05:0.1:4],[-2.05:0.1:2],[0.5 0.5 0.5],'-','front')

f10=figure(10);
medianstd(magp,iptime,[0:0.1:6],[0.5 4.5],[0 0 0],'P-picks');
subplot(12,6,1)
medianstd(mags,istime,[1:0.1:6],[0.5 4.5],[0 0 0],'S-picks');
print -depsc2 article_histo6.eps

%% See location errors

f11=figure(11)
eve=AA{1};
ind=cat(1,1,diff(eve));
ind(ind>=1)=1;
indice=find(ind==1);


loca=cell2mat(AA(2:end));
loca=sqrt(sum(loca.^2,2));
loca=loca(indice,:);

num=eve(indice);


plot(num,loca,'+');
axis([0 200 0 200])


f12=figure(12);
hist(loca,200)

%% Declare functions


% hold on
% 
% 
% 
% n=hist(iptime,axilim);
% truc=bar(axilim,n,'hist');
% set(truc,'FaceColor',[0 0 1],'FaceAlpha',0.35,'EdgeColor',[0 0 0]);
% s={sprintf('S picks %4.2f +/- %3.2f s',median(istime),tests),...
%    sprintf('P picks %4.2f +/- %3.2f s',median(iptime),testp)};
% pp=legend(s)
% legend('boxoff')
% set(gca,'Fontsize',18,'Xtick',[-5:1:5])
% set(pp,'Fontsize',16)
% hold off
% xlabel('Residuals')
% ylabel('Number of picks')
% figure('Renderer','painters')
% saveas(f1,'histogram.eps','epsc')
% 
% 
% 
% 
