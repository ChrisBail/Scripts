% function that reads structure from read_selec and outputs statistics

function stat=get_statistic(structu)

phases=[];
weights=[];
total_picks=sum(cat(1,structu(:).Number_of_picks));
total_events=size(structu,2);
numvent=0;
num_loca=0;
for i=1:length(structu)
    if isempty(structu(i).Cell)
        continue
    else
        numvent=numvent+1;
    Newph=cat(1,structu(i).Cell{2}{:});
    phases=[phases;Newph];
    Newwei=cat(1,structu(i).Cell{3}{:});
    weights=[weights;Newwei];
        if ~isempty(structu(i).Coord)
            num_loca=num_loca+1;
        end
    end
end

total_events_pick=numvent;
phases=cellstr(phases);
total_P=length(phases(strcmp(phases,'P')));
total_S=length(phases(strcmp(phases,'S')));

stat=struct('NumberofEvents',total_events,...
    'NumberofEventswithPicks',numvent,...
    'NumberofPicks',total_picks,...
    'NumberofPPicks',total_P,...
    'NumberofSPicks',total_S,...
    'NumberoflocatedEvents',num_loca);

end
