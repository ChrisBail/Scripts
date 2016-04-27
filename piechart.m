% Script to do a proper pie chart, choosing the color, the text to append
% Input:-Data as a vector
%       -explode: by default it we be not exploded pie chart
%       -text cell taking the form {'text1';'text2';...;'textn'} the size of
%       Cell must be the same than the data
%       -Color: RGB matrix should take the form [1 0 1;0 0 1;...;0 1 0 1]


function piechart(data,explode,textlegend,color)

% Define properly the Colormap even if there is a 0 value

len=length(data);
B=usercolormap(color,len);
B(data==0,:)=[];
colormap(B);

% Check is there are 0 values in the data matrix, if so we need to skip
% textstring associated to those 0 values

explode(data==0)=[];
textlegend(data==0)=[];
data(data==0)=[];


% Plot the pie

pieh=pie(data,explode);
textObjs = findobj(pieh,'Type','text');
oldStr = get(textObjs,{'String'});
val = get(textObjs,{'Extent'});
oldExt=cat(1,val{:});
newStr = strcat(textlegend,oldStr);
set(textObjs,{'String'},newStr)
set(pieh(2:2:end),'Fontsize',18)

val1 = get(textObjs, {'Extent'});
newExt = cat(1, val1{:});
offset = sign(oldExt(:,1)).*(newExt(:,3)-oldExt(:,3))/2;
pos = get(textObjs, {'Position'});
textPos =  cat(1, pos{:});
textPos(:,1) = textPos(:,1)+offset;
set(textObjs,{'Position'},num2cell(textPos,[3,2]));

end



