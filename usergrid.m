% Script to plot grid correctly given the right x and y values
% input:    -figureobj
%           -X
%           -Y
%           -Color
%           -Style

function usergrid(obj,x,y,rgb,style,position)

if nargin==5
    position='back';
end
xl=get(obj,'Xlim');
yl=get(obj,'Ylim');

top=max(yl);
bot=min(yl);
le=min(xl);
ri=max(xl);
    hold on

if ~isempty(x)
for i=1:length(x)

    plot([x(i) x(i)],[bot top],style,'color',rgb)
end
end

if ~isempty(y)
for i=1:length(y)

    plot([le ri],[y(i) y(i)],style,'color',rgb)
end
end

hold off

if ~strcmp(position,'front')
    

h=get(obj,'Children');
h=flipud(h);
set(obj,'Children',h);
end


end
% Plot vertical

