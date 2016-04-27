% function to make colormap between color1 and color2 with n colors


function A=usercolormap(M,n)

a=size(M,1);
clear A
for i=1:3
    A(:,i)=interp1([1:a]',M(:,i),[1:(a-1)/(n-1):a]);
end

end

