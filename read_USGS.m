%%% Function made to read USGS file and return classical data
% Input:    file > input usgs file
%           nheaders > number of header line
% Output:   OUT > output matrix [Time lon lat depth mag]

function OUT=read_USGS(file,nheaders)

fic=fopen(file,'rt');
k=0;
j=0;
while ~feof(fic)
    line=fgetl(fic);
    k=k+1;
    if k<=nheaders
        continue
    else
        [A]=textscan(line,'%*s %*s %f %f %f %f %*[^\n]','collectoutput',1);
        serial_date=datenum(line(1:23),'yyyy-mm-dd HH:MM:SS.FFF');
        j=j+1;
    end
    OUT(j,:)=[serial_date A{1}([2 1 3 4])];
end
fclose(fic);
OUT(OUT(:,end)==0,:)=[];

end