%%%% 


function histoxyz(x,y,xstep,ystep,CLM)

C=zeros(length(ystep),length(xstep));
axilim=ystep;
for i=1:length(xstep)-1
    %ix=find(x>=xstep(i) & x<xstep(i+1));
    data=y(x>=xstep(i) & x<xstep(i+1));
    n=hist(data,axilim);
    C(:,i)=n;
end
colormap(CLM)
imagesc(xstep,ystep,C);
set(gca,'YDir','normal');

end
