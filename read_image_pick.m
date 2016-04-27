%%%% Program made to pick curves on an image
clear all
close all

%% Parameter

screen=get(0,'screensize');
map_fig=figure(1);
image_file='Profile_merge.png';
A=imread(image_file);
imagesc(A);
set(map_fig,'position',[screen(3)/2 screen(4)/6 screen(4)/1.2 screen(4)/1.2]);
axis equal
cc_initial=axis;
%set(gca,'Ydir','normal')

%% Read image

Curve(50).name=[];
Curve(50).coord=[];
k=1;
while 1
    cmd=(['Choose the proper key:\n',...
        '"zi": for Zoom In\n',...
        '"zo": for Zoom Out\n',...
        '"z": for selecting zero axis\n',...
        '"x": for selecting x axis\n',...
        '"y": for selecting y axis\n',...
        '"p": for starting picking\n',...
        '"e": for exiting and saving\n']);
    action_butt=input(cmd,'s');
    if action_butt=='zi'
        [xz,yz]=ginput(2);
        xz=sort(xz);
        yz=sort(yz);
        axis([xz' yz']);
        continue
    elseif action_butt=='zo'
        axis(cc_initial);
        continue
    elseif action_butt=='z'
        disp('Set 0 position on figure');
        [x0,y0]=ginput(1);
    elseif action_butt=='x';
        disp('Set x scale');
        [abs_x,abs_y]=ginput(2);
        real_scale_abs=input('Enter value of scale x:\n');
    elseif action_butt=='y';
        disp('Set y scale');
        [ord_x,ord_y]=ginput(2);
        real_scale_ord=input('Enter value of scale y:\n');
    elseif action_butt=='p' 
        flag_pick=1;
        name_curve=input('Start Picking, but first choose curve name:\n','s');
        %%% Check if name already exists
        names_cell={Curve(:).name}';
        indices_remove=find(any(strcmp(names_cell,name_curve))==1);
        if isempty(indices_remove)
            %%% See where there is room in the structure
            emptyCells=cellfun(@isempty,{Curve(:).name}');
            indices_remove=find(emptyCells==1,1,'first');
        end
        if any(strcmp(names_cell,name_curve));
            cmd=('Curve name already exists, overwrite? [y/n]\n');
            answer=input(cmd,'s');
            if strcmp(answer,'y')
                flag_pick=1;
            else
                flag_pick=0;
            end
        end
        if flag_pick==1
            [x,y]=ginput;
            Curve(indices_remove).name=name_curve;
            Curve(indices_remove).coord=[x y];
            hold on
            plot(x,y)
            hold off
        end
    elseif action_butt=='e'
        if ~exist('x0')
            answer=input('you have not set scale, continue? [y/n]\n','s');
            if answer=='n'
                continue
            end
        end
        %%% Remove empty structure
        emptyCells=cellfun(@isempty,{Curve(:).name}');
        indices_remove=find(emptyCells==1);
        Curve(indices_remove)=[];
        
        %%% Convert data if possible
        if exist('x0') & exist('abs_x') & exist('ord_x')
            for i=1:length(Curve)
                x=Curve(i).coord(:,1);
                y=Curve(i).coord(:,2);
                new_x=(x-x0)*real_scale_abs/diff(abs_x);
                new_y=(y-y0)*real_scale_ord/diff(ord_y);
                Curve(i).converted=[new_x new_y];
            end
        end
        %%% Save into file
        filename=input('Define MAT-filename for storing:\n','s');
        save(filename,'Curve');
        break
    end
end