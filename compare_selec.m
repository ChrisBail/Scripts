% Program to compare two select.out, collect.out or autosig.out
% especially designed for Manual/Automatic picking comparaison
% Identification between events is based on SEED filename, i.e. two events
% are compared if they have the same SEED filename, so it's important to
% use two coherents bases that can be compared
% Output of this program is a file that compiles all information for each
% pick
% Convention automatic-manual
% Inputs:   file_manu: Manual collect/select file
%           file_auto: Automatic collect/select/autosig file
% Outpu:    file_out: Output comparison file

function [Event_auto,Event_manu,BB,CC]=compare_selec(file_manu,file_auto,file_out)
% Filenames

file1=file_manu;
file2=file_auto;
fileo=file_out;        % Comparaison between automatic and manual

% Read files

system(['rm -f ',fileo]);
Struct_auto=read_selec(file2);
Struct_manu=read_selec(file1);
fid=fopen(fileo,'w');


% Write the header
fprintf(fid,'%3s %5s %2s %6s %2s %2s %6s %6s %6s %6s %s \n','N#','STAT','PH','dTime','W1','W2','dZ','dLa','dLo','Mag','SEED_name');

% Find corresponding events taking indices in the structure

clear seedau seedma
seedau={Struct_auto.SEED_file}';
seedma={Struct_manu.SEED_file}';
seedau=cell2mat(seedau);
seedma=cell2mat(seedma);
seedau=cellstr(seedau(:,1:19));
seedma=cellstr(seedma(:,1:19));


[C,ia,im]=intersect(seedau,seedma);

Event_a=Struct_auto(ia);
Event_b=Struct_manu(im);

% Compare pickings

tt=0;
Cot=[];
sizeB=0;
for i=1:size(Event_a,2)
    clear A B C New_a New_b
    if isempty(Event_b(i).Cell) || isempty(Event_a(i).Cell)   % Skip if no picks
        continue
    else    
        A=cellstr(cell2mat([Event_a(i).Cell{1:2}]));
        B=cellstr(cell2mat([Event_b(i).Cell{1:2}]));
        sizeB=sizeB+size(B,1);
        [C,ia,ib]=intersect(A,B);    
        % Sort correctly cells in order to compare
        Event_a(i);
        Event_b(i);
        New_a=[Event_a(i).Cell{:}];
        New_b=[Event_b(i).Cell{:}];
        New_a=New_a(ia,:);
        New_b=New_b(ib,:);
        % Compute time difference
        Diff=cell2mat(New_a(:,4))-cell2mat(New_b(:,4));
        if isempty(Diff)
            continue;
        end
        tt=tt+1;
        Diff=repmat(sign(Diff),[1 6]).*datevec(abs(Diff));
        Diff=Diff(:,end);
        Cot=[Cot;Diff];
        %%% Write into the outputfile
        for j=1:size(C,1)
            if isempty(Event_a(i).Depth) || isempty(Event_b(i).Depth)
                depth_diff=999;
                lat_diff=999;
                lon_diff=999;
            else
                depth_diff=Event_a(i).Depth-Event_b(i).Depth;
                lat_diff=(Event_a(i).Coord(:,1)-Event_b(i).Coord(:,1))*110;
                lon_diff=(Event_a(i).Coord(:,2)-Event_b(i).Coord(:,2))*110;
            end
            if isempty(Event_a(i).Mag)
                Event_a(i).Mag=999;
            end
            if isempty(New_b{j,3})
                New_b{j,3}=9;
            end
   
            fprintf(fid,'%3.0f %5s %2c %6.2f %2.0f %2.0f %6.1f %6.1f %6.1f %6.1f %s \n',i,C{j}(1:5),C{j}(end),Diff(j),New_a{j,3},New_b{j,3},...
                depth_diff,...
                lat_diff,...
                lon_diff,...
                Event_a(i).Mag,...
                Event_a(i).SEED_file);      
        end  
    end
end

fclose(fid);

% Get statistics

tt
BB=get_statistic(Event_a);
CC=get_statistic(Event_b);
Event_auto=Event_a;
Event_manu=Event_b;



end




