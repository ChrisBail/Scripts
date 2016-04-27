function medianstd(x,y,xstep,abs,color,titles)

s1=subplot(6,1,1:3);
st=(xstep(end)-xstep(1))/(length(xstep)-1);

a1=[];
a2=[];
a3=[];
j=0;
for i=1:length(xstep)
    %ix=find(x>=xstep(i) & x<xstep(i+1));
    data=y(x>=xstep(i)-st/2 & x<xstep(i)+st/2);
    if isempty(data)
        continue
    else
        j=j+1;
        a1(j)=xstep(i);
        a2(j)=median(data);
        a3(j)=intervalstd(data,0.68);
    end
end
errorbar(a1,a2,a3,'ok','MarkerFaceColor',color,'MarkeredgeColor',[0 0 0]);

axis([abs(1) abs(2) min(get(gca,'Ylim')) max(get(gca,'Ylim'))])
%set(gca,'Xticklabel',[]);
yy=get(gca,'YTick');
a=[yy(1):0.1:yy(end)];
yy=[];
yy=a;
set(gca,'Xaxislocation','top','Fontsize',14);%,'ytick',yy(2:end));

ylabel('Residuals [sec]','Fontsize',14)
usergrid(gca,[1:0.5:4],[0],[0.7 0.7 0.7],'--')
title(titles,'Fontsize',14)



s2=subplot(6,1,4:6);


axilim=xstep;
n=hist(x,axilim);
truc=bar(axilim,n/sum(n)*100,0.8,'hist');
set(truc,'facecolor',color)
axis([abs(1) abs(2) min(get(gca,'Ylim')) max(get(gca,'Ylim'))])
xlabel('Local magnitude','Fontsize',14)
ylabel('% of picks','Fontsize',14)
set(gca,'Fontsize',14);
usergrid(gca,[1:0.5:4],[],[0.7 0.7 0.7],'--')

end
