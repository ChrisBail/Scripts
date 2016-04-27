%%% Function made to load header info (no phases -> see read_nor fot thi
%%% purpose) from nordic file. It uses nor2xyz made by Wayne Crawford
% Input:    file > nordic filename
% Output:   S > structure with all info

% Example: S=load_nor('../Data/all_hypo_select.out')

function S=load_nor(file)

system(['nor2xyz --full ',file,' | awk -F, ''$1 != -999'' > temp_select.xyz']);
fic=fopen('temp_select.xyz','rt');

% x,y,z,datetime,mag1,timeerr,xerr,yerr,zerr,nstations,rms,gap,distid,elevid,mag2,mag3,covxy,covxz,covyz

A=textscan(fic,'%f %f %f %s %f %f %f %f %f %*f %f %*f %*s %*s %*f %*f %f %f %f %*[^\n]','delimiter',',','endofline','\n');
fclose(fic);

time_str=A{4};
matlab_time=datenum(time_str,'yyyy-mm-ddTHH:MM:SSFFF');
A(4)={matlab_time};

%%% Assign variables in structure

fields={'lon','lat','depth', ...
    'time', ...
    'mag', 'timeerr', ...
    'xerr', 'yerr', 'zerr', ...
    'rms', ...
    'Cxy', 'Cxz', 'Cyz'};

S=cell2struct(A,fields,2);

end




