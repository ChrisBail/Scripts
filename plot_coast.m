%%% Function made to plot coastlines taken from NOAA database
% first make a load of the file 'outcoast.txt' into X,Y
% Input:    X,Y > Latitude and longitude
%           edge > color of the coast
%           face > color of inland
%           alpha > transparency
% Output:   plot

function plot_coast(X,Y,edge,face,alpha)

flag=1;
if isempty(face)
    flag=0;
end

k=find(isnan(X(:,1)));
for i=1:length(k)
    clear h
    if i==length(k)
        last=length(X(:,1));
    else 
        last=(k(i+1)-1);
    end
    x=X((k(i)+1:last),1);
    y=Y((k(i)+1:last),1);
    if flag
        h=patch(x,y,'w','edgecolor',edge,'facecolor',face,'FaceAlpha',alpha);
    else
        h=plot(x,y,'w','color',edge);
    end
end;
axis equal

set(gca,'box','on')

end
