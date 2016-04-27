%%% Function made to compute all the scale parameters associated to an earthquake
%%% The relations are taken from Strasser et al, 2010, for the
%%% width,surface and length of the rupture whereas the maximum displacment
%%% and average displacement are taken from wells and coppermsith

% ex: A=magnitude_calc('method','strasser','rupture_width',80)

function A=magnitude_calc(varargin)

%%% Initialize structure

A.method='Strasser';
A.Mo=[];
A.Mw=[];
A.average_disp=[];
A.maximum_disp=[];
A.rupture_width=[];
A.rupture_length=[];
A.rupture_surface=[];

cell_str={'method','Mo','Mw','average_disp','maximum_disp','rupture_width','rupture_width','rupture_surface'};

for i=1:length(cell_str)
    if any(strcmp(cell_str{i},varargin))
        index=find(strcmp(cell_str{i},varargin));
        str=['A.',cell_str{i},'=varargin{index+1};'];
        eval(str);
    end
end

%%% Parameters
Mw=A.Mw;
mu=5*10^10;   % in N/m^2
scaling=10^7; % from Nm to dyne.cm

a_avg_disp=6.93;
b_avg_disp=0.82;

a_max_disp=6.69;
b_max_disp=0.74;

a_rup_W=4.410;
b_rup_W=1.805;

a_rup_L=4.868;
b_rup_L=1.392;

a_rup_S=4.441;
b_rup_S=0.846;

if isempty(A.Mw)
    if ~isempty(A.Mo)
        Mw=2/3*log10(A.Mo)-10.7;
    else
        if ~isempty(A.average_disp)
            a=a_avg_disp;
            b=b_avg_disp;
            P_key=A.average_disp;
        end
        if ~isempty(A.maximum_disp)
            a=a_max_disp;
            b=b_max_disp;
            P_key=A.maximum_disp;
        end
        if ~isempty(A.rupture_width)
            a=a_rup_W;
            b=b_rup_W;
            P_key=A.rupture_width;
        end
        if ~isempty(A.rupture_length)
            a=a_rup_L;
            b=b_rup_L;
            P_key=A.rupture_length;
        end
        if ~isempty(A.rupture_surface)
            a=a_rup_S;
            b=b_rup_S;
            P_key=A.rupture_surface;
        end

        Mw=a + b.* log10(P_key);
    end
end

Mo=10.^(3/2*(Mw+10.7));

if ~isempty(A.Mw) & ~isempty(A.rupture_surface)
    disp('sfsd')
    %%% Get Parameters from Mw
    Avg_D=Mo/(mu*A.rupture_surface*10^6*scaling);
    S=A.rupture_surface;
else
    %%% Get Parameters from Mw
    Avg_D=10.^(-4.80+0.69.*Mw);
    S=10.^(-3.476+0.952.*Mw);
end

L=10.^(-2.477+0.582.*Mw);
W=10.^(-0.882+0.351.*Mw);
Max_D=10.^(-5.46+0.82.*Mw);

%Mo=mu*S*D*10^7;

A.Mo=Mo;
A.Mw=Mw;
A.average_disp=Avg_D;
A.maximum_disp=Max_D;
A.rupture_width=W;
A.rupture_length=L;
A.rupture_surface=S;

dd=sqrt((0.226)^2+(7.*0.029).^2);

% Mw=7.4;
% Mo=10^(3/2*(Mw+10.7))
% 
% 
% %%% Magnitude scale
% 
% Mw=7.4;
% Mo=10^(3/2*(Mw+6));
% 
% Dmax=10^((Mw-6.69)/0.74);
% 
% disp(Dmax)
% Dav=10^((Mw-6.93)/0.82);
% 
% disp(Dav)
% 
% %%% Strasser
% 
% a=-0.882+[-0.226 0.226];
% b=0.351+[-0.029 0.029];
% 
% Width_strasser=55;
% Mw_strasser=(log10(Width_strasser)-a)./b;
% disp(Mw_strasser)
% 
% Mw_strasser=4.868+1.392*log10(100)

%%%% Construct structure





