%%% For .ndk format explanation see http://www.ldeo.columbia.edu/~gcmt/projects/CMT/catalog/allorder.ndk_explained
% Function made to transfom .file to .xyz file
% Input:    input_file > .ndk CMT file
% Output:   output_file > .dat file with 
%                           'lon lat depth serial_time mb str dip rake' U1
%                           U2 U3 are the components of the vector normal
%                           to the first nodal plane
% Example ndk2xyz('jan76_dec10.ndk','CMTxyz.dat',[160 180],[-20 -10])


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%  WARNING : This program needs to be corrected because, the
%%%%%%%%%%%%  output of Strike Dip Rake doesn't give the good focal
%%%%%%%%%%%%  mechanism
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function ndk2xyz(input_file,output_file,lim_lon,lim_lat)

% Set defaults

if nargin<4
    lim_lat=[-90 90];
end
if nargin<3
    lim_lon=[-180 180];
end
if nargin<2
    disp('not enough input arguments');
end

% Start

%input_file='jan76_dec10.ndk';
%output_file='test.dat';

foc=fopen(output_file,'wt');
fic=fopen(input_file,'rt');

fprintf(foc,'lon lat depth serial_date mb str dip rake U1 U2 U3(positive downward)\n');

k=0;
line_1=1;
%line_2=2;
%line_3=3;
%line_4=4;
line_5=5;
shift=5;
flag_write=true;
ind_S=0;

while ~feof(fic)
    line=fgetl(fic);
    k=k+1;
    switch k
        case line_1
            line(1)='E'; % Needed for proper textscan
            INFO=textscan(line,'%*5c %s %s %f %f %f %f %f %*[^\n]');
            line_1=line_1+shift;
            
            %%% Transform date
            date=cat(2,INFO{1}{1},INFO{2}{1});
            serial_date=datenum(date,'yyyy/mm/ddHH:MM:SS.FFF');
            lat=INFO{3};
            lon=INFO{4};
            depth=INFO{5};
            mb=INFO{6};
            Ms=INFO{7};
            if lat>=lim_lat(1) & lat<=lim_lat(2) & lon>=lim_lon(1) & lon<=lim_lon(2)
                flag_write=true;
                ind_S=ind_S+1;
            else
                flag_write=false;
            end
        case line_5
            line_5=line_5+shift;
            if flag_write
                DATA=textscan(line,'%*57c %f %f %f %*[^\n]','collectoutput',1);
                str=DATA{1}(1);dip=DATA{1}(2);rake=DATA{1}(3);
                %%% Transform spherical to cartesian coordinates (We want the vector located on the fracture plane)
                % Axes X>Est Y>North Z>upward
                STR_vec=[sind(str);cosd(str);0];
                DIP_vec=[cosd(dip).*cosd(str);-sind(str).*cosd(dip);-sind(dip)];
                NORM_vec=cross(DIP_vec,STR_vec); % So NORM vec points toward the upper block
                U1=NORM_vec(1);U2=NORM_vec(2);U3=NORM_vec(3);
                fprintf(foc,'%8.3f %8.3f %7.2f %14.6f %4.1f %5.1f %5.1f %6.1f %5.2f %5.2f %5.2f \n',...
                    lon,lat,depth,serial_date,mb,str,dip,rake,U1,U2,U3);
            end
        otherwise
            continue
    end    
    
end

fclose(fic);
fclose(foc);

end
