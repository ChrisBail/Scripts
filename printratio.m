%%% function made to print figures as it appears on screen
%%% Just define correctly the aspectration option which has to be a two
%%% element array
%%% Exemple printratio(gcf,'file.eps','-dpdf','aspectratio',[1 2])

function printratio(handle,filename,varargin)

check_vec=strcmpi('Aspectratio',varargin);
if any(check_vec)
    ind=find(check_vec==1);
    if length(ind)>1
        disp('Do not use Aspectratio more than one time');
        return
    else
        if ind==length(varargin) | ~strcmp(class(varargin{ind+1}),'double')
            disp('Give one matrix as option input')
        else      
            if length(varargin{ind+1})~=2
                disp('Give a two element array')
            else
                vec=varargin{ind+1};
                vec=vec(:);
                Posi=get(handle,'position');
                set(handle,'position',[Posi(1:2) Posi(3)*vec(1) Posi(4)*vec(2)]);
                set(handle, 'PaperPositionMode','auto');
            end
        end
    end
    varargin([ind ind+1])=[];
end

print(handle,filename,varargin{:})

end