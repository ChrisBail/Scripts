#!/usr/bin/env bash

#### Define GMT parameters

gmtdefaults -D > .gmtdefaults4
gmtset HEADER_FONT_SIZE 15p
gmtset LABEL_FONT_SIZE 14p
gmtset COLOR_FOREGROUND 128/0/0
gmtset PAGE_ORIENTATION portrait
gmtset BASEMAP_TYPE plain
gmtset COLOR_NAN 125/125/125


range='166/169.5/-17.5/-13.5'
scale='4.9c'
#makecpt -Cpolar -T-110/110/10 -I > tmp/grid.cpt
makecpt -Cgray -T9/300/10 -I > tmp/grid.cpt

bathy_cpt='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Grids/Bathy_gray.cpt'
usgs_cpt='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Grids/EQ_USGS.cpt'
sub_plane=("/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Programs/Dat_files/Plane_01_mesh_final.dat"\
 "/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Programs/Dat_files/Plane_03_mesh_final.dat")
stations=('/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Stations_Coord/stations_van.xyz')
bathy='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Grids/Vanuatu235m.grd'
trench=('/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Grids/Smooth_Trench.txt' '/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Grids/BATB.ll')


grid_file='/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Data/van_slab1.0_clip.grd'
perimeter='/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Data/perimeter_Hayes.txt'

grid_file_local='/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Programs/Dat_files/Plane_12.grd'
perimeter_local='/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Programs/Dat_files/Contour_01.dat'

grid_file_local1='/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Programs/Dat_files/Plane_2.grd'
perimeter_local1='/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Programs/Dat_files/Contour_03.dat'

#grid_file='/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Programs/Dat_files/Plane_1.grd'
#grid_file2='/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Programs/Dat_files/Plane_2.grd'

### Project onto profile

center='167/-16'
az='45'
grd2xyz $grid_file_local | sed '/NaN/d' > tmp/plane_1.xyz
project tmp/plane_1.xyz -C$center -A$az -S -L-100/250 -W-100/100 -Fpz -Qk | awk '{print $0,100}' > tmp/plane_2.xyz
xyz2grd tmp/plane_2.xyz -I1/0.5 -N9 -Gtmp/proj.grd -R-250/250/0/70
grdfilter tmp/proj.grd -Gtmp/proj2.grd -I0.5/0.5 -Fg5/5 -D0

cat << EF > tmp/cont.txt
10
EF

psbasemap -JX10c/-10c -R-250/250/0/200 -B10/10::WeSn -K > map.ps
#grdimage tmp/proj2.grd -J -R -O -K -Ctmp/grid.cpt -Q >> map.ps
grdcontour tmp/proj2.grd -J -R -Ctmp/cont.txt -O -K >> map.ps
#psxy tmp/plane_2.xyz -J -R -O -K -Sc0.01c -Ctmp/grid.cpt >> map.ps
ps2pdf map.ps
#open map.pdf





makecpt -Chaxby -T0/300/1 > tmp/grid.cpt
cat << EF > tmp/wedge.txt
0.5
EF

#grdsample $grid_file -Gtmp/test.grd -I1k 
#grdmath tmp/test.grd -1 MUL = tmp/test3.grd
#grdfilter tmp/test3.grd -D1 -Fg5 -R$range -I1k -Gtmp/test2.grd
#grdsample $grid_file_local -R$range -I1k -Gtmp/resamp.grd

#grdmath tmp/test2.grd tmp/resamp.grd SUB = tmp/sub_grid.grd

psbasemap -Jm$scale -R$range -B1/1::WeSn -K -Xc -Yc > map.ps
#grdgradient $bathy -A0 -Nt -Gtmp/gradients.grd
#grdimage $bathy -Jm$scale -R$range -Itmp/gradients.grd -C$bathy_cpt -K -O >> map.ps
pscoast -J -R -Df -G180 -O -K >> map.ps

#grdmath $grid_file_local $grid_file_local1 AND = tmp/test.grd

#### Second grid
#grid_file='tmp/test2.grd'
#grid_file=tmp/test.grd
#grid_file=tmp/sub_grid.grd
#mask_file=$perimeter_local
#grid_file=tmp/test2.grd
#mask_file=$perimeter


#psclip $perimeter_local1 -Jm -R -O -K >> map.ps

grdmath $grid_file_local ISNAN = tmp/test1.grd

grdfilter tmp/test1.grd -D1 -Fg20 -I1k -Gtmp/test3.grd
grid_file=tmp/test3.grd

./grid2contour.sh $grid_file_local -Gtmp/new_count.txt -Jm$scale -R$range -D1 -I1k -Fg60

#grdimage $grid_file -Jm$scale -R$range -Ctmp/grid.cpt -O -K >> map.ps
#grdview $filename -Jm$scale -R$range -Ctmp/grid.cpt -O -K -Qm  >> map.ps
#grdcontour $grid_file -Jm$scale -Wc0.1p -R$range -C10 -S50 -A20+g -Wa1p,black -O -K >> map.ps
#grdcontour $grid_file -Jm$scale -Wc0.1p -R$range -D -m -C10 -S50 -A20+g -Wa1p,black > /dev/null
#grdcontour $grid_file -Jm$scale -R -W1p,green -C0.5 -L0.1/0.9 -Dtest_cont.xyz -m -O -K >> map.ps
#psclip -C -J -R -O -K >> map.ps
#awk 'NR>1 {print $1,$2}' test_cont.xyz > tmp/new_count.txt
#awk 'NR==2 {print $1,$2}' test_cont.xyz >> tmp/new_count.txt
#grdimage $grid_file_local -Jm$scale -R$range -Ctmp/grid.cpt -O -K >> map.ps
#psxy tmp/new_count.txt -Jm -R -O -K -W2,red >> map.ps
pscoast -J -R -Df -G180 -O -K >> map.ps
psclip tmp/new_count.txt -Jm$scale -R$range -O -K >> map.ps
grdimage $grid_file_local -Jm$scale -R$range -Ctmp/grid.cpt -O -K >> map.ps
psclip -C -J -R -O -K >> map.ps
#grdcontour $grid_file -Jm$scale -R -W1p,green -C0.5 -L0.1/0.9 -m -O -K >> map.ps
ps2pdf map.ps

open map.pdf
exit
psclip $mask_file -Jm -R -O -K >> map.ps
grdimage $grid_file -Jm$scale -R$range -Ctmp/grid.cpt -O -K >> map.ps
#grdview $filename -Jm$scale -R$range -Ctmp/grid.cpt -O -K -Qm  >> map.ps
grdcontour $grid_file -Jm$scale -Wc0.1p -R$range -C10 -S50 -A20+g -Wa1p,black -O -K >> map.ps
grdcontour $grid_file -Jm$scale -W2p,red -R$range -O -K >> map.ps
psclip -C -J -R -O -K >> map.ps

pscoast -J -R -Df -W0.2p -O -K >> map.ps

trench_symbol=("-Sf1i/0.3clt" "-Sf0.8i/0.3crt")

scale_prop="-D15c/3.5/7c/0.5c -Ctmp/grid.cpt"

psscale $scale_prop -B50g10:"Depth [km]": -O -K >> map.ps

i=0

for tren in ${trench[@]} ; do
	psxy $tren -W1p ${trench_symbol[$i]} -Gblack -J -R -O -K >> map.ps
	i=$(( $i + 1 ))
done

psbasemap -L166.5/-16.8/-16.8/50k -Jm -R -O >> map.ps

ps2pdf map.ps

open map.pdf