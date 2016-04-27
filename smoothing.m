% function made to smooth
% input:    Nsmooth, number of samples for mean
%           f, function to smooth          

function f_smooth=smoothing(Nsmooth,f)

nsample=length(f);
a=find(isnan(f)==0,1,'first');
b=find(isnan(f)==0,1,'last');
f_val=f(a:b);
f_smooth=NaN(nsample,1);

len1=length(f_val);
len2=Nsmooth+floor(Nsmooth/2);

a=NaN(len1-Nsmooth+1,1);
if len1<Nsmooth
    Nsmooth=len1;
end
a(1)=sum(f_val(1:Nsmooth))/Nsmooth;
    
j=2;
  
while j<=len1-Nsmooth+1
    a(j)=a(j-1)+(f_val(j+Nsmooth-1)-f_val(j-1))./Nsmooth;
    j=j+1;
end

if isnan(a)==1      % In case there is a NaN in a
    f_smooth=f;
else
    f_smooth(len2:len2+length(a)-1)=a;
end
    
end
