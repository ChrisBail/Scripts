% This function is made to return the 68 percent standard deviation of a
% distribution (we do not approximate to a gaussian)


function std=intervalstd95(ip)


iptome=sort(abs(ip));
if length(iptome)<=1
    std=NaN;
else
std=iptome(floor(size(iptome,1)*0.95));
end


end

 

