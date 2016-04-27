%%% Script Made or read hypoDD.loc or .reloc files or event.dat files
% Input:    file > .loc .reloc or event.dat format file
% Output:   OUT > output with [event_indice time lat lon depth (cluster_id)]
 
% loc_dir='/Users/baillard/_Moi/Programmation/Matlab/HypoDD/SUBSET_1/run/locreloc_files/';
% locfile='001_hypoDD.loc';
% event_file='/Volumes/donnees/SE_DATA/WOR/CHRIS/HYPODD/SUBSET_1/HDD/event.dat';
% select_file='/Volumes/donnees/SE_DATA/WOR/CHRIS/HYPODD/SUBSET_1/EVENTS/select.out';
% locfile=[loc_dir,locfile];

function OUT=read_DDLOC(file)

fic=fopen(file);
format_cmd='%f %f %f %f %*s %*s %*s %*s %*s %*s %s %s %s %s %s %s %f %*s %*s %*s %*s %*s %*s %f\n';
A=textscan(fic,format_cmd);
fclose(fic);

% Clean all *** character
for i=5:10
    A{i}(isnan(A{2}))={'nan'};
    A{i}=cellfun(@str2num,A{i},'un',1);
end

A=cell2mat(A);

% Get serial date

Time=A(:,5:10);
serial_time=datenum(Time);


OUT=[A(:,1) serial_time A(:,2:4) A(:,end-1:end)];

    
end
            