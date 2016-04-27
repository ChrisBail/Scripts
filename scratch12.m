function M
close all
file='/Users/baillard/_Moi/Programmation/Matlab/Global_Seismicity/neic_van.xyz';


trench='/Users/baillard/_Moi/Programmation/GMT/Grids/Global_trench.txt';

T=load(trench);

A=load(file);


A((A(:,2)>=-11.4 | A(:,2)<=-22.611),:)=[];

lon=A(:,1);
lat=A(:,2);


% Interpt trench

lon_trench=interp1(T(:,2),T(:,1),lat);
lat_trench=lat;

new_T=[lon_trench lat_trench];

new_T((new_T(:,2)>=-11.4 | new_T(:,2)<=-22.611),:)=[];

% plot(lon_trench,lat,'+r')
% hold on
% plot(new_T(:,1),new_T(:,2),'+b')
% hold off

lon_corr=lon-new_T(:,1);

A_shallow=A((lon_corr>0 & lon_corr <1),:);
A_deep=A((lon_corr>0 & lon_corr <5),:);



%%%%%%

lat_step=0.5;
lat_array=-21:lat_step:-11;

num_earth_1=get_num(A_deep,[70 300],lat_array);
num_earth_2=get_num(A_shallow,[0 70],lat_array);
h=stairs(lat_array(1:end-1),num_earth_1,'g');

hold on
stairs(lat_array(1:end-1),num_earth_2,'b')
hold off
%set(gca,'ydir','reverse')
export_fig 'histrogram' -pdf -transparent

end


function num_earth=get_num(A,z_int,lat_array)
z=A(:,3);
B=A((z>z_int(1) & z<=z_int(2)),:);
num_earth=zeros(length(lat_array)-1,1);

for i=1:length(lat_array)-1
   C=B((B(:,2)>=lat_array(i) & B(:,2)<lat_array(i+1)),:);

   %%% Get stat
   

   num_earth(i)=size(C,1);
   
end


end


