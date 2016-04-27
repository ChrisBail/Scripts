#!/usr/bin/env bash

#### flag ellipse permits to determine the kind of data, 3 types of data are supported:
#### x/y/z/mag files > '0'
#### ellipses 	> '1'
#### -Ab focal mechanism file > 'F'

################################
#### Prepare files

cmt_clus='/Users/baillard/_Moi/Programmation/Scripts/foc_santo.txt';

##### Rearrange properly files

awk '{print $1,$2,$3,$4,$5,$6,5,0,0}' $cmt_clus > tmp/clus.meca

##### Define additinal colorpalette and text

cat << EF > tmp/legend.xy
165.4 -17.5 119 5
165.4 -17.56 119 6
165.4 -17.65 119 7
EF
#cat << EF > tmp/legend.xy
#165.4 -17.5 119 0 90 0 5 0 0
#165.4 -17.56 119 0 90 0 6 0 0
#165.4 -17.65 119 0 90 0 7 0 0
#EF
#165.5 -17.5 119 4 4 4 0 0 0 23 X Y
###############################################################
### Give xyz files

#files=("tmp/cmt.meca" "tmp/major.meca" "tmp/clus.meca"\
# "tmp/usgs.xyz" "tmp/selec.xyz" "tmp/reloc.xyz" "tmp/santo.xyz")
files=('tmp/clus.meca')

#flag_ellipse=('F' 'F' 'F' '0' '0' '0' '0') 
flag_ellipse=('F') 


###############################################################
### Common files for plotting

bathy_cpt='/Users/baillard/_Moi/Programmation/GMT/Grids/Bathy_gray.cpt'
usgs_cpt='/Users/baillard/_Moi/Programmation/GMT/Grids/EQ_USGS.cpt'
sub_plane=("/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Programs/Dat_files/Plane_01_mesh_final.dat"\
 "/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Programs/Dat_files/Plane_03_mesh_final.dat"\
 "/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Programs/Dat_files/Plane_02_mesh_final.dat")
stations=('/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Stations_Coord/stations_van.xyz')
bathy='/Users/baillard/_Moi/Programmation/GMT/Grids/Vanuatu235m.grd'
trench=('/Users/baillard/_Moi/Programmation/GMT/Grids/Smooth_Trench.txt')

###############################################################
### Give input parameters

views='-E190/60'
range='166/168.5/-17/-14'
scalem='5c'
scalepx='0.05c'
scalepy='0.05c'
title=''
titlerof='ncg'
figure_dir='figures'
map_grid="1/1"
scale_prop="-D15c/18/7c/0.5c -L -C$usgs_cpt"
scale_prop_foc="-D16.1c/7/7c/0.5c -L -C$usgs_cpt"
#scale_prop_foc="-D11c/-2/7c/0.5ch -B5g5:Depth\[km\]: -C$usgs_cpt"
scale_label="Depth[km]"
km_scale_pos="-L166/-17.5/-17.5/100k"
trench_symbol=("-Sf1i/0.3clt" "-Sf0.8i/0.3crt")
intensity=0

map_attributes="-G210 "
declare -a color_stations=("-W1p -St0.3c -Gwhite")
declare -a eq_attributes=( "-Sc -W1p,green" "-Sc0.05c -Ggray" "-Sc0.1c -W0.5 -Gred" "-W0.5 -Sc0.1c -Gmagenta")
#declare -a eq_attributes=( "-Sc0.05c -Ggray" "-Sc0.05c -Gred" "-Sc0.08c -Gblue" "-Sa1c -Gblue")
declare -a grid_attributes=("-Ctmp/grid_pal.cpt")
declare -a foc_attributes=( "-Sa1.5c -M -L0.2p -Gblack" "-Sa0.4c -L0.2p -Gyellow"  "-Sa0.4c -L0.2p -Gred")

### Give profile parameters if any
 
#centers=()
#centers=("166.33/-15.36" "166.54/-15.86" "166.9/-16.4")
#centers=("166.6/-15.86")
centers=("166/-16")
#rotations=('70' '70')
rotations=('70')
widths=('50')
length_left=('0' )
length_right=('300')
depth=70

rm -f Ab166