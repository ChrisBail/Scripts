%%% Function made to convert kml to lon lat coordinates
% input:    input_file > .kml input file
% output:   output_file > .txt output file

function kml2ll(input_file,output_file)

%trench='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Grids/Trench.kml';

%% Read input

fic=fopen(input_file,'rt');
while ~feof(fic)
    line=fgetl(fic);
    line=strtrim(line);
    if strcmp(line,'<coordinates>')
        line=fgetl(fic);
        data=textscan(line,'%f','delimiter',',','collectoutput',1);
        break
    end
end
fclose(fic);

%% Write into output

B=data{1};
C=[B(1:3:end) B(2:3:end)];
fic=fopen(output_file,'w');
fprintf(fic,'%f   %f\n',C');
fclose(fic);

end