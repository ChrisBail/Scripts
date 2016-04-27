% Function to set vertical space between subsequent subplots


function space_subplot(fig_obj,delta)
obj_sub=get(fig_obj,'Children');
obj_sub=flipud(obj_sub);
vec=zeros(length(obj_sub),4);


for i=1:length(obj_sub)
vec(i,:)=get(obj_sub(i),'pos');
end

for i=2:length(obj_sub)
    vec(i,2)=vec(i-1,2)-vec(i,4)-delta;
    set(obj_sub(i),'pos',vec(i,:));
end


end
