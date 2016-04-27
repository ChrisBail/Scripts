% Fucntion to redimensionne figure compared to original size
 

function redim_figure(fig_obj,width_ratio,heigth_ratio)

ss=get(fig_obj,'PaperPosition');
ss(3)=ss(3)*width_ratio;
ss(4)=ss(4)*heigth_ratio;
set(fig_obj,'PaperPosition',ss);


end