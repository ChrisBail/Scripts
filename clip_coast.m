%%% Function to clip properly coastlines coming from noa database %%%%%
%%% To be used with patch or plot_coast.m

function clip_coast(infile,oufile)

foc=fopen(oufile,'wt');
coast=load(infile); 

nan_lines=find(isnan(coast(:,1)));

C=cell(100000,1);
C_new=cell(100000,1);
A=cell(100000,1);

for i=1:length(nan_lines)
    if i==length(nan_lines)
        last_line=length(coast(:,1));
    else 
        last_line=nan_lines(i+1);
    end
    C(i,1)={coast(nan_lines(i)+1:last_line-1,:)};
end

C=C(~cellfun(@isempty,C));

%%% Check wich coastlines are not clipped and put it in A

p=0;
l=0;
for k=1:length(C)
    if C{k}(1,:)==C{k}(end,:)
        p=p+1;
        C_new(p,1)=C(k);
    else
        l=l+1;
        A(l,1)=C(k);
    end
end

A=A(~cellfun(@isempty,A));


B=A;

%%%% Clip coastlines

while length(B)>1    
    C_test=B{1};
    for m=2:length(B)
        [~,c,b]=intersect(C_test,B{m},'rows');
        if length(b)==1
            if c==1 & b==1;
                C_test=[flipud(C_test); (B{m})];
            elseif c==1 & b~=1;
                C_test=[flipud(C_test); flipud(B{m})];
            elseif c~=1 & b==1;
                C_test=[C_test; B{m}];
            else c~=1 & b~=1;
                C_test=[C_test; flipud(B{m})];
            end
            B= B(setxor(m,[1:length(B)]));
            B(1)={C_test};
            flag=1;
            break
        elseif length(b)==2
            if b(1)==1
                C_test=[(C_test); (B{m})];
            else
                C_test=[flipud(C_test); (B{m})];
         
            end
            B= B(setxor([1 m],[1:length(B)]));
              p=p+1;
            C_new(p)={C_test};
%                hold on
%             plot(C_new{p}(:,1),C_new{p}(:,2))
          
            flag=1;
         
            break
        else
            flag=2;
            continue
        end
end
if flag==2
    B=B(setxor(1,[1:length(B)]));
end
end  

C_new=C_new(~cellfun(@isempty,C_new));
%%% write output file

for i=1:length(C_new)
%        hold on
%             plot(C_new{i}(:,1),C_new{i}(:,2))
    fprintf(foc,'%s %s\n','nan','nan');
    fprintf(foc,'%8.4f %8.4f \n',C_new{i}');
end

fclose(foc);

end
