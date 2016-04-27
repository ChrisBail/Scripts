%%% Program made to pick the subduction plane on profiles
% It can load different type of data
% Go through all defined profiles

function pick_plane
clear all
close all

%%% Addpath to function directory

addpath(genpath('/Users/baillard/_Moi/Programmation/Scripts'));

%%% Get all data path

coast='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Grids/noaa_vanuatu_clipped.dat';
trench='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Grids/Smooth_Trench_Depth.txt';
plane_file='/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Data/Plane_file.txt';
bat_data='/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Data/vanuatu_global.mat';

%reloc_data='/Users/baillard/_Moi/Programmation/Matlab/Final_Reloc/hypoDD.reloc';
reloc_data='/Users/baillard/_Moi/Programmation/Matlab/Cluster_Orientation/hypoDD_BEST.reloc';
loc_data='/Users/baillard/_Moi/Programmation/Matlab/Cluster_Orientation/hypoDD_BEST.loc';
select_data='/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Data/select.out';
usgs_data='/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Data/usgs.txt';
cmt_file='/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Data/CMTxyz.dat';
santo_2000='/Users/baillard/_Moi/Programmation/Matlab/Santo_2000/santo2000_0.nor';


cmt_major='/Users/baillard/_Moi/Programmation/Matlab/Moment_Major_Events/run_MECA_selec.tbl';
cmt_clus='/Users/baillard/_Moi/Programmation/Matlab/Cluster_Orientation/run_MECA_selec.tbl';


%%% Check existence of files


flag_bat=true;
if ~exist(bat_data,'file')
    flag_bat=false;
end

%%% Parameters

global st_projection
global center_map
global str_p

limx=[165 170];
limy=[-18 -13];
center_map=[167 -16];
angle_trench=-20;
center_trench=[166.6 -15.86];
trench_length=400;
profile_sep=10;     % in km
profile_length=250; % in km
shift=20;           % in km
profile_width=10;   % in km represents portion both sides of profile (2*profile_width)
scale=10;
st_projection='58,''S'',center_map(1),center_map(2));';
str_p='58L';
angle_view=angle_trench+180;

%%% Set projection

dx=max(abs(limx-center_map(1)))+5;
dy=max(abs(limy-center_map(2)))+5;
map_limx=center_map(1)+[-dx +dx];
map_limy=center_map(2)+[-dy +dy];
projection='transverse mercator';
m_proj(projection,'longitudes',map_limx,...
       'latitudes',map_limy);
 
eval(['[Xlimi,Ylimi]=wgs2utm(limx,limy,',st_projection]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Define all profiles orthogonal to the trench

eval(['[ctx,cty]=wgs2utm(center_trench(1),center_trench(2),',st_projection]);

angle=90-angle_trench;  % to be in trigo circle
k=2;
xt(1)=ctx+(trench_length*cosd(angle+180))/2;    % start with end at south if azimuth is north
yt(1)=cty+(trench_length*sind(angle+180))/2;
while (k-1)*profile_sep<=trench_length
    xt(k)=xt(1)+(k-1)*profile_sep*cosd(angle);
    yt(k)=yt(1)+(k-1)*profile_sep*sind(angle);
    k=k+1;
end
xt=xt(:);
yt=yt(:);

angle_profile=angle-90;

if shift>trench_length;
    shift=0;
end

xp=zeros(size(xt));
yp=xp;

for i=1:length(xt)
    xp(i)=xt(i)+(profile_length/2-shift)*cosd(angle_profile);
    yp(i)=yt(i)+(profile_length/2-shift)*sind(angle_profile);
end

PRcenter=[xp yp];
PRcoordx=[...
xp+profile_length/2*cosd(angle_profile+180),...
xp+profile_length/2*cosd(angle_profile)];
PRcoordy=[...
yp+profile_length/2*sind(angle_profile+180),...
yp+profile_length/2*sind(angle_profile)];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% load Bathy
if flag_bat
    BAT=load(bat_data);
    Xbat=BAT.X;Ybat=BAT.Y;Zbat=-(BAT.Z)/1000;
end


if ~exist('DATA.mat', 'file')

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% load hypocenters and focal meca

    system(['hypoDD2xyz ',reloc_data,'> temp_reloc.xyz']);
    system(['hypoDD2xyz ',loc_data,'> temp_loc.xyz']);
    HYPrel=load('temp_reloc.xyz');
    Snor=load_nor(select_data); % Structure containing informations from select file
    Ssanto=load_nor(santo_2000); % Structure containing informations from select file
    HYPus=read_USGS(usgs_data,2);
    HYPcmt=importdata(cmt_file,' ',1);
    HYPcmt=HYPcmt.data;
    [CMT_major,ID_major]=read_FOCTBL(cmt_major);
    [CMT_clus,ID_clus]=read_FOCTBL(cmt_clus);

    %%% Convert strike dip rake to cmt

    CMT_M=sdr2mt(CMT_major(:,4:6));
    CMT_C=sdr2mt(CMT_clus(:,4:6));
    CMT_H=sdr2mt(HYPcmt(:,6:8));

    HYPcmt=[HYPcmt(:,1:3) CMT_H];
    CMT_major=[CMT_major(:,1:3) CMT_M];
    CMT_clus=[CMT_clus(:,1:3) CMT_C];

    %%% Convert lon/lat to x/y

    eval(['[Xus,Yus]=wgs2utm(HYPus(:,2),HYPus(:,3),',st_projection]);
    eval(['[Xcmt,Ycmt]=wgs2utm(HYPcmt(:,1),HYPcmt(:,2),',st_projection]);
    eval(['[Xnor,Ynor]=wgs2utm(Snor.lon,Snor.lat,',st_projection]);
    eval(['[Xrel,Yrel]=wgs2utm(HYPrel(:,1),HYPrel(:,2),',st_projection]);
    eval(['[Xmajor,Ymajor]=wgs2utm(CMT_major(:,1),CMT_major(:,2),',st_projection]);
    eval(['[Xclus,Yclus]=wgs2utm(CMT_clus(:,1),CMT_clus(:,2),',st_projection]);
    eval(['[Xsan,Ysan]=wgs2utm(Ssanto.lon,Ssanto.lat,',st_projection]);
    
    Mnor=Snor.mag;
    Mus=HYPus(:,5);
    Zus=HYPus(:,4);
    Zcmt=HYPcmt(:,3);
    Znor=Snor.depth;
    Zrel=HYPrel(:,3);
    Zmajor=CMT_major(:,3);
    Zclus=CMT_clus(:,3);
    Zsan=Ssanto.depth;

    %%%%%%%%% Construct structure

    DATA(1).name='Harvard CMT';
    DATA(1).path='/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Data/CMTxyz.dat';
    DATA(1).lon=HYPcmt(:,1);
    DATA(1).lat=HYPcmt(:,2);
    DATA(1).X=Xcmt;
    DATA(1).Y=Ycmt;
    DATA(1).Z=Zcmt;
    DATA(1).sdr=HYPcmt(:,6:8);
    DATA(1).mnt=CMT_H;
    DATA(1).mag=[];
    DATA(1).color='b';
    DATA(1).keys='f';

    DATA(2).name='Major Moments';
    DATA(2).path='/Users/baillard/_Moi/Programmation/Matlab/Moment_Major_Events/run_MECA_selec.tbl';
    DATA(2).lon=CMT_major(:,1);
    DATA(2).lat=CMT_major(:,2);
    DATA(2).X=Xmajor;
    DATA(2).Y=Ymajor;
    DATA(2).Z=Zmajor;
    DATA(2).sdr=CMT_major(:,4:6);
    DATA(2).mnt=CMT_M;
    DATA(2).mag=[];
    DATA(2).color='g';
    DATA(2).keys='a';
    DATA(2).id=cellstr(num2str(ID_major(:)));


    DATA(3).name='Cluster Moments';
    DATA(3).path='/Users/baillard/_Moi/Programmation/Matlab/Cluster_Orientation/run_MECA_selec.tbl';
    DATA(3).lon=CMT_clus(:,1);
    DATA(3).lat=CMT_clus(:,2);
    DATA(3).X=Xclus;
    DATA(3).Y=Yclus;
    DATA(3).Z=Zclus;
    DATA(3).sdr=CMT_clus(:,4:6);
    DATA(3).mnt=CMT_C;
    DATA(3).mag=[];
    DATA(3).color='r';
    DATA(3).keys='b';
    DATA(3).id=cellstr(num2str(ID_clus(:)));

    DATA(4).name='USGS';
    DATA(4).path='/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Data/usgs.txt';
    DATA(4).lon=HYPus(:,2);
    DATA(4).lat=HYPus(:,3);
    DATA(4).X=Xus;
    DATA(4).Y=Yus;
    DATA(4).Z=Zus;
    DATA(4).sdr=[];
    DATA(4).mnt=[];
    DATA(4).mag=Mus;
    DATA(4).color='g';
    DATA(4).keys='1';

    DATA(5).name='Select';
    DATA(5).path='/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Data/usgs.txt';
    DATA(5).lon=Snor.lon;
    DATA(5).lat=Snor.lat;
    DATA(5).X=Xnor;
    DATA(5).Y=Ynor;
    DATA(5).Z=Znor;
    DATA(5).sdr=[];
    DATA(5).mnt=[];
    DATA(5).mag=Mnor;
    DATA(5).color='r';
    DATA(5).keys='2';

    DATA(6).name='Reloc';
    DATA(6).path='/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Data/usgs.txt';
    DATA(6).lon=HYPrel(:,1);
    DATA(6).lat=HYPrel(:,2);
    DATA(6).X=Xrel;
    DATA(6).Y=Yrel;
    DATA(6).Z=Zrel;
    DATA(6).sdr=[];
    DATA(6).mnt=[]; 
    DATA(6).mag=[];
    DATA(6).color='m';
    DATA(6).keys='3';

    DATA(7).name='Santo';
    DATA(7).path='/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Data/usgs.txt';
    DATA(7).lon=Ssanto.lon;
    DATA(7).lat=Ssanto.lat;
    DATA(7).X=Xsan;
    DATA(7).Y=Ysan;
    DATA(7).Z=Zsan;
    DATA(7).sdr=[];
    DATA(7).mnt=[];
    DATA(7).mag=[];
    DATA(7).color='k';
    DATA(7).keys='4';

    save('DATA','DATA')
else
    DATA=load('DATA.mat');
    DATA=DATA.DATA;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% START DISPLAY %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

map_fig=figure(1);


h=get(gca);
set(gca,'color',[0 0 0])
hold on

%%% Define figures properties (map + profile)

%% Get screen resolution

screen=get(0,'screensize');
set(map_fig,'position',[screen(3)/10 screen(4)/6 screen(4)/1.2 screen(4)/1.2]);
prof_fig=get(map_fig,'position');
%profile_option=('set(profile_fig,''position'',[prof_fig(1)+prof_fig(3)/2 prof_fig(2) screen(3)/1.4 screen(4)/1.6]);');

%export_fig test -pdf -transparent

%% Ploat coast

C=load(coast);
eval(['[Xc,Yc]=wgs2utm(C(:,1),C(:,2),',st_projection]);
plot_coast(Xc,Yc,'w',[],0);
axis([Xlimi Ylimi])
axis manual

%% Plot trench

T=load(trench);
eval(['[Xt,Yt]=wgs2utm(T(:,1),T(:,2),',st_projection]);
plot(Xt,Yt,'w')
Zt=-T(:,3)/1000;    % Given in km

%% Plot profiles

for i=1:size(PRcenter,1)
    plot(PRcoordx(i,:),PRcoordy(i,:),'b');
    text(PRcoordx(i,1)-20,PRcoordy(i,1),sprintf('%2.0f',i),'color','w')
end

%%% Plot legend
% 1 cm = 28 pt (help to correspondance with GMT)

scale_p=2;
Mleg=[5 6 7 8];
Xleg=repmat(Xlimi(2)-50,length(Mleg),1);
Yleg=Ylimi(2)-50-[0 10 20 40];

scatter(Xleg,Yleg,size_scatter(scale_p,Mleg),'w');  % Circles
for i=1:length(Mleg)
    text(Xleg(1)+10,Yleg(i),sprintf('%2d',Mleg(i)),'color','w');% Text
end

%% Plot data but don't show them on figure

for i=1:length(DATA)
    if isempty(DATA(i).mnt)
        if strcmp(DATA(i).name,'USGS')  
            h1(i)={scatter(DATA(i).X,DATA(i).Y,size_scatter(scale_p,DATA(i).mag),DATA(i).color,'visible','off')};
        else
            h1(i)={scatter(DATA(i).X,DATA(i).Y,size_scatter(scale_p,5+zeros(size(DATA(i).Y))),DATA(i).color,'visible','off')};
        end
    else
        ha=plotmt(DATA(i).X,DATA(i).Y,DATA(i).mnt,'radius',2,'pcolor',DATA(i).color);
        hb=[];
        if ~isempty(DATA(i).id)
        hb=text(DATA(i).X,DATA(i).Y,DATA(i).id);
        end
        ha=cat(1,ha{:,:});
        h1(i)={[ha;hb]};
        set(h1{i},'visible','off');
    end
end
hando=[];
count_s=0;

while 1
    profile_mode=false;
    vv=double(cat(1,DATA(:).keys));
    figure(map_fig);
    [~,~,butt]=ginput(1);
    if any(butt==vv)
        handi=h1{butt==vv};
    elseif butt==double('z')
        [xz,yz]=ginput(2);
        xz=sort(xz);
        yz=sort(yz);
        axis([xz' yz']);
        continue
    elseif butt==double('r')
        axis([Xlimi Ylimi])
        axis manual
        continue
    elseif butt==double('s')
        
        %%% Plot existing planes

        count_s=count_s+1;
        Struct_map=getinfile([],[],plane_file);
        all_planes=cat(1,Struct_map.plane_number);
        all_planes=sort(unique(all_planes));
        if count_s>length(all_planes)
            count_s=0;
            delete(hando);
            clear hando
            hando=[];
            continue
        end
        S_sel_plane=getinfile([],all_planes(count_s),plane_file);
        if ~isempty(hando)

            delete(hando);
        end
        clear hando
        for i=1:length(S_sel_plane)
            xx=(S_sel_plane(i).x);
            [~,indd]=sort(xx);
            zz=S_sel_plane(i).z;
            yy=S_sel_plane(i).y;
            xx_sort=xx(indd);
            yy_sort=yy(indd);
            zz_sort=zz(indd);
            A=interparc(floor(sqrt((yy_sort(end)-yy_sort(1)).^2+(xx_sort(end)-xx_sort(1)).^2)/5),...
                xx_sort,yy_sort,'linear');
            ZI = interp1(xx(indd),zz(indd),A(:,1));
            hando(i)=scatter(A(:,1),A(:,2),20,log(ZI),'filled');
            caxis([log(1) log(200)]);

        end
        hando(end+1)=text(Xleg(1),min(Yleg)-30,sprintf('Plane n°%2d\n',all_planes(count_s)));

        continue
        
        elseif butt==double('p')
            pick=[];
            pi_x=[];
            pi_y=[];
            k_pp=0;
            while 1
                if profile_mode==false;
                    %%% Enter profile number
                    correc_flag=false;
                    while correc_flag==false
                        pro_num=input('Choose profile number:\n');
                        if ischar(pro_num) || pro_num < 1 || pro_num > size(PRcenter,1)
                            disp('Enter a correct profile number! \n')
                        else 
                            correc_flag=true;
                        end
                    end
                    %%% Project trench and take the mean
                    [Xt_p,Zt_p,~]=xyz2prof(Xt,Yt,Zt,...
                        profile_length,profile_width,angle_profile,...
                        PRcenter(pro_num,1),PRcenter(pro_num,2));
                    Xt_p=mean(Xt_p);
                    Zt_p=mean(Zt_p);
                    
                    if flag_bat
                        %%% Project bathy
                        [Xbat_p,Zbat_p]=get_bathy(Xbat,Ybat,Zbat,profile_length,angle_profile,...
                            PRcenter(pro_num,1),PRcenter(pro_num,2));
                    end
                    
                    %%% Project hypocenters
                    
                    DATA_p=DATA;
                    for i=1:length(DATA)
                        [DATA_p(i).X,DATA_p(i).Y,DATA_p(i).ind]=...
                            xyz2prof(DATA(i).X,DATA(i).Y,DATA(i).Z,...
                            profile_length,profile_width,angle_profile,...
                            PRcenter(pro_num,1),PRcenter(pro_num,2));
                    end
                                     
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %%% START PROFILE FIGURE %%%%%%%%%%%%
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                    profile_fig=figure(2);
                    posi=get(profile_fig,'position');
                    set(gcf,'position',[500 500 posi(3)*3 posi(4)*3])
                    %Position = [1000 896 560 420]
                    %eval(profile_option);
                    hold on
                    box on
                    axis equal
                    xlim([-profile_length/2 profile_length/2])
                    ylim([-300 5])
                    grid on

                    if flag_bat
                        %%% Plot Bathy
                        area(Xbat_p,-Zbat_p,0,'facecolor',[0.9 0.9 0.9]);
                    end
                    
                    %%% Plot projected trench
                    
                    plot(Xt_p,-Zt_p,'+k','linewidth',2)
                    
                    %%% Plot projected hypocenter
                    
                    for i=1:length(DATA_p)
                        if isempty(DATA_p(i).mnt)
                            if strcmp(DATA(i).name,'USGS')  
                                h1_p(i)={scatter(DATA_p(i).X,-DATA_p(i).Y,size_scatter(scale_p,DATA_p(i).mag(DATA_p(i).ind)),DATA_p(i).color,'visible','off')};
                            else
                                h1_p(i)={scatter(DATA_p(i).X,-DATA_p(i).Y,size_scatter(scale_p,5+zeros(size(DATA_p(i).Y))),DATA_p(i).color,'visible','off')};
                            end
                        else
                            ha=plotmt(DATA_p(i).X,-DATA_p(i).Y,DATA(i).mnt(DATA_p(i).ind,:),'radius',2,'pcolor',DATA_p(i).color,'pov',[90 angle_view]);
                            ha=cat(1,ha{:,:});
                            h1_p(i)={ha};
                            set(h1_p{i},'visible','off');
                        end
                    end
                    profile_mode=true;

                else
                    vv=double(cat(1,DATA(:).keys));
                    [scr_x,scr_y,butt]=ginput(1);
                    if any(butt==vv)
                        handi=h1_p{butt==vv};
                    elseif butt==double('z')
                        [xz,yz]=ginput(2);
                        xz=sort(xz);
                        yz=sort(yz);
                        axis([xz' yz']);
                        continue
                    elseif butt==double('r')
                        axis equal
                    xlim([-profile_length/2 profile_length/2])
                    ylim([-300 5])
                        continue
                    

                    elseif (butt==double('m')) | (butt==double('e')) % Return back to map_view
                        if ~isempty(pi_x)
                            %%% convert plane coordinates
                            [x_plane,y_plane,z_plane]=prof2xyz(pi_x,pi_y,...
                            angle_profile,...
                            PRcenter(pro_num,1),PRcenter(pro_num,2));

                            %%% Write into file
                            fic=fopen(plane_file,'at');
                            fprintf(fic,'%s %03d %s %03d\n','profile',pro_num,'plane',plane_num);
                            fprintf(fic,'%8.3f %8.3f %7.2f\n',[x_plane y_plane -z_plane]'); % lon/x lat/y depth
                            fclose(fic);
                            pi_x=[];
                            pi_y=[];
                        end
                        if butt==double('e')
                            figure(map_fig)
                            close(profile_fig)
                            break
                        end
                        continue
                    elseif butt==31 %middle arrow downward (made to plot planes aready picked)
                        k_pp=k_pp+1;
                        if existinfile(pro_num,plane_file) 
%                               if k_pp==1;
                            S=getinfile(pro_num,[],plane_file);
                            for i=1:length(S)
                                [xpp,zpp]=xyz2prof(S(i).x,S(i).y,S(i).z,...
                                profile_length,profile_width,angle_profile,...
                                PRcenter(pro_num,1),PRcenter(pro_num,2));
                                visible_mode='on';
                                if mod(k_pp,2)
                                    visible_mode='off';
                                end

                                tb(i)=plot(xpp,-zpp,'-og','visible',visible_mode); % plot plane
                                tt(i)=text(xpp(ceil(length(xpp)/2)),-zpp(ceil(length(zpp)/2))-5,sprintf('%3.0f',S(i).plane_number),'visible',visible_mode);% plot plane number
                            end
                        end
                        continue
                    elseif butt==1
                        if isempty(pi_x)
                            plane_num=input('Select plane number:\n');
                            pick_plane=true;
                            if existinfile(pro_num,plane_num,plane_file)
                                ans_discard=input('Plane already picked on this profile, do you want to discard it? (y/n)\n','s');
                                if strcmpi(ans_discard,'n')
                                    pick_plane=false;
                                else
                                    discardinfile(pro_num,plane_num,plane_file);
                                end
                            end
                        end
                        if pick_plane==true
                            delete(pick)
                            pi_x=[pi_x;scr_x];pi_y=[pi_y;scr_y];
                            pick=plot(pi_x,pi_y,'-ok');
                        end
                        continue
                    elseif butt==8 % backspace ascii code
                        if length(pi_x)==1
                            continue
                        else
                            pi_x(end)=[];
                            pi_y(end)=[];
                            delete(pick)
                            pick=plot(pi_x,-pi_y,'-ok');
                            continue
                        end
                    else
                        continue
                    end
                    visib=get(handi,'visible');
                    if strcmp(visib,'on')
                        set(handi,'visible','off');
                    else
                        set(handi,'visible','on');
                    end
                end
            end
    elseif butt==double('e')
        break
    else
        handi=[];
    end
    if profile_mode==true
        continue
    else
        visib=get(handi,'visible');
        if strcmp(visib,'on')
            set(handi,'visible','off');
        else
            set(handi,'visible','on');
            %uistack(handi,'top') 
        end
    end
end

%%% Convert XY plane file into lon lat file

xy2ll_plane(plane_file,'Plane_file_Lon_Lat.txt',0,center_map(1),center_map(2));

end

%%%%%%%%%% FUNCTIONS %%%%%%%%%%%%%%%%%%

%%% function to convert xyz into lat lon

function xy2ll_plane(file,outfile,option,Lon0,Lat0)

global str_p

skip_flag=false;
if nargin < 3
    option=0;
end
if option==1
    skip_flag=true;
end


fic=fopen(file,'rt');
foc=fopen(outfile,'wt');
i=0;
k=0;

while ~feof(fic)
    line=fgetl(fic);
    if ~strcmp(line(1),'p')
        i=i+1;
        A=textscan(line,'%f %f %f','collectoutput',1);
        X(i,1)=A{1}(1);
        Y(i,1)=A{1}(2);
        Z(i,1)=A{1}(3);
        clear A  
    else
        k=k+1;
        if k>1
            [lon,lat]=utm2wgs(X,Y,str_p,Lon0,Lat0);
            z=Z;
            fprintf(foc,'%9.3f %9.3f %8.2f\n',[lon lat z]'); 
        end
        i=0;
        if ~skip_flag
            fprintf(foc,'%s\n',line);
        end
        
    end
end
fclose('all');

end

%----------------------------------------------------------

% Function to check if selected profile and plane exist in file
function resp=existinfile(pro_num,plane_num,filename)
flag=false;
if nargin<3
    filename=plane_num;
    flag=true;
end
if ~exist(filename,'file')
    resp=false;
    return
end
    
    A=[];
    fic=fopen(filename,'rt');
    while ~feof(fic)
        line=fgetl(fic);
        if isempty(line)
            continue
        end
        if strcmpi(line(1),'p')
            clear scr
            scr=textscan(line,'%*s %f %*s %f','collectoutput',true);
            A=[A;scr{1}];
        end
    end
    % Check if given input are in matrix
    
    if flag==false
        resp=ismember([pro_num plane_num],A,'rows');
    else
        resp=ismember(pro_num,A(:,1));
    end
    
    fclose(fic);
end

%----------------------------------------------------------
            
% Function to discard selected profile and plane from file
function discardinfile(pro_num,plane_num,filename)
    fic=fopen(filename,'rt');
    foc=fopen('temp.txt','wt');
    while ~feof(fic)
        line=fgetl(fic);
        if isempty(line)
            continue
        end
        if strcmpi(line(1),'p')
            clear_line=false;
            clear scr
            scr=textscan(line,'%*s %f %*s %f','collectoutput',true);
            if ismember([pro_num plane_num],scr{1},'rows');
                clear_line=true;
            end
        end
        if ~clear_line
            fprintf(foc,'%s\n',line);
        end 
    end

    fclose(fic);
    fclose(foc);
    
    delete(filename)
    movefile('temp.txt',filename)  
    
end

%----------------------------------------------------------

% Function to get coordinates of selected profile and plane from file
function S=getinfile(pro_num,plane_num,filename)

cond_pro='ismember(profile,pro_num)';
cond_pla='ismember(plane,plane_num)';
continue_stat=['clear_line=true;','k=k+1;'];

fic=fopen(filename,'rt');
k=0;
while ~feof(fic)
    line=fgetl(fic);
    if isempty(line)
        continue
    end
    if strcmpi(line(1),'p')
        A=[];
        clear_line=false;
        clear scr
        scr=textscan(line,'%*s %f %*s %f','collectoutput',true);
        profile=scr{1}(1);plane=scr{1}(2);
        if isempty(pro_num) & isempty(plane_num)
            eval(continue_stat)
        elseif isempty(pro_num) & eval(cond_pla)
            eval(continue_stat)
        elseif isempty(plane_num) & eval(cond_pro)
            eval(continue_stat)
        elseif eval(cond_pro) & eval(cond_pla)
            eval(continue_stat)
        end
        continue
    end
    if clear_line
        b=textscan(line,'%f %f %f','collectoutput',true);
        A=[A;b{1}];
        x=A(:,1);
        y=A(:,2);
        z=A(:,3);
        S(k)=struct('profile_number',profile,...
            'plane_number',plane,...
            'x',x,'y',y,'z',z);
    end         
end
fclose(fic);
    
end
  
%----------------------------------------------------------

% Function to get size of the scatter point 
% scale > scalar to multiple rayon
% Mag > array containing Magnitude

function size_circle=size_scatter(scale,Mag)

Mag=Mag(:);
size_circle=pi*(scale*((28/2)*0.0005*2.5.^Mag)).^2;

end

%----------------------------------------------------------
%%% Function made to get bathy from X,Y,Z coordinates (X,Y,Z are NxN
%%% matrices)

function [out_x,out_z]=get_bathy(X,Y,Z,profile_length,angle,x_center,y_center)

global st_projection
global center_map

X=X(:);
Y=Y(:);
Z=Z(:);

% Convert lon lat to x y

eval(['[x,y]=wgs2utm(X,Y,',st_projection]);
%[x,y]=m_ll2xy(X,Y);

%%% Project

[xp,zp,i]=xyz2prof(x,y,Z,profile_length,5,angle,x_center,y_center);

%%% Interp for smoothing

new_x=linspace(xp(1),xp(end),1000);
new_z=interp1(xp,zp,new_x);

%%% Smooth

windowSize=20;
filt_z=filter(ones(1,windowSize)/windowSize,1,new_z);
filt_z(1:windowSize)=filt_z(windowSize);

out_z=filt_z;
out_x=new_x;

end
% 
% hold on
% plot(xt,yt,'ob')
% plot(xp,yp,'or')
% scatter(Xus,Yus,2*pi*(0.005*2.5.^HYPus(:,5)).^2,'lineWidth',0.4)
% x=3:9;
% y=rand(size(x));
% s=pi*(0.005*2.5.^x).^2;
% sh=scatter(x,y,s);
% % now...
%      sc=get(sh,'children');
%      ss=get(sc,'markersize');
%      cm=get(sc,'cdata');
%      lh=legend(sc);
%      lc=findall(lh,'type','patch');
%      set(lc,{'markersize'},ss,{'cdata'},cm);
% 
% %[x, y,c] = ginputc( 'Color', 'r', 'LineWidth', 3,'ShowPoints', true, 'ConnectPoints', true);
% 
% T=load(trench);
% [Xt,Yt]=m_ll2xy(T(:,1),T(:,2));
% plot(Xt,Yt)
% 
% 
% figure(1)



