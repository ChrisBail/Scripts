%%% Program made to read CMT file and return x y z mag str dip rake T and P axis
% Input: filein > xyz file obtained by ndk2xyz
% Output: fileout > file with desired axus

function read_cmt2tp(filein,fileout,flag)

%cmt_file='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Grids/Global_CMT_1976_2013.txt';
%cmt_tensor_file='/Users/baillard/_Moi/Programmation/GMT/Grids/CMT_1976_2013.xyz'; 
%fileout='test2.txt';

foc=fopen(fileout,'wt');

if flag==1
    
    %% Skip header line

    nheaders=1;

    %% Read file

    fic=fopen(filein);
    A=textscan(fic,'%f %f %f %f %f %f %f %f %*[^\n]','headerlines',nheaders,'collectoutput',1);
    fclose(fic);

    A=A{1};
    
    strike=A(:,6);
    dip=A(:,7);
    rake=A(:,8);

    sdr=[strike dip rake];

    %%% Get T and P axes from strike dip rake

    [t,p,b]=sdr2tpb(sdr);

    str='Cluster# lon lat depth STR DIP RAKE Tplunge Tazimuth Pplunge Pazimuth';
    fprintf(foc,'%s\n',str);
    for i=1:size(A,1)
        fprintf(foc,'%3i %8.3f %8.3f %5.1f %7.2f %7.2f %7.2f %10.4f %10.4f %10.4f %10.4f\n',...
            A(i,1),A(i,2),A(i,3),A(i,4),strike(i),dip(i),rake(i),t(i,2),t(i,3),p(i,2),p(i,3));
    end
    fclose(foc); 

else
    
    %% Skip header line

    nheaders=1;

    %% Read file

    fic=fopen(filein);
    A=textscan(fic,'%f %f %f %f %f %f %f %f %f %f %*[^\n]','headerlines',nheaders,'collectoutput',1);
    fclose(fic);

    A=A{1};

    %[t,p,b]=mt2tpb(mt)

    Mrr=A(:,4);
    Mtt=A(:,5);
    Mpp=A(:,6);
    Mrt=A(:,7);
    Mrp=A(:,8);
    Mtp=A(:,9);

    MT=[Mrr Mtt Mpp Mrt Mrp Mtp];

    % strike=A(:,6);
    % dip=A(:,7);
    % rake=A(:,8);

    %%% Get T and P axes from strike dip rake

    %[t,p,b]=sdr2tpb([strike dip rake]);
    [t,p,b]=mt2tpb(MT);

    str='lon lat depth mrr mtt mpp mrt mrp mtp iexp Tplunge Tazimuth Pplunge Pazimuth';
    fprintf(foc,'%s\n',str);
    for i=1:size(A,1)
        fprintf(foc,'%8.3f %8.3f %8.3f %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f %2i %10.4f %10.4f %10.4f %10.4f\n',...
            A(i,1),A(i,2),A(i,3),Mrr(i),Mtt(i),Mpp(i),Mrt(i),Mrp(i),Mtp(i),A(i,10),t(i,2),t(i,3),p(i,2),p(i,3));
    end
    fclose(foc);
end