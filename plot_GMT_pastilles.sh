#!/bin/bash

gmtdefaults -D > .gmtdefaults4
gmtset PAPER_MEDIA	a4
gmtset BASEMAP_TYPE plain
gmtset LABEL_FONT_SIZE 12p
gmtset OBLIQUE_ANOTATION 0
gmtset PAGE_ORIENTATION portrait
gmtset ANNOT_FONT_SIZE_PRIMARY 10p
gmtset HEADER_FONT_SIZE 12p
export LC_NUMERIC=POSIX

########## Input_files

data_file='/Users/baillard/_Moi/Programmation/Matlab/Cluster_Orientation/ellipses.out'
grid_path='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Grids/'
station_path='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Stations_Coord/'
bathy_file='Vanuatu235m.grd'
station_file='stations_van.xyz'
trench_file='Global_trench_smooth.txt'

bathy_file=$grid_path$bathy_file
station_file=$station_path$station_file
trench_file=$grid_path$station_file

scalerange="-JM167/-15.5/15 -R166.7/167.6/-16.55/-15"
stationsymbol="-St0.3c -G255/255/51 -W0.7pt"
line_inf=2
line_sup=30

########## Start Computation

if ! test -d tmp ; then
mkdir tmp
fi

####### Prepare file

mag=1.5
awk -v mag=$mag -v line_inf=$line_inf -v line_sup=$line_sup 'NR>=line_inf && NR<=line_sup {print $2,$3,$9,$5,mag*$6,mag*$7}' $data_file > tmp/data.xyz

# Write text file
awk -v line_inf=$line_inf -v line_sup=$line_sup 'NR>=line_inf && NR<=line_sup {print $2,$3, 10, 0, 0, "CM", $1}' $data_file > tmp/data.txt

####### Define 0 contour file

makecpt -Cocean -Z > tmp/temp.cpt
cat << END > tmp/contour.out
0 C
END

makecpt -Cjet -T-0.5/1.5/0.1 > tmp/ellipse.cpt

#-------- Plot
psbasemap $scalerange -B30mWeSn -K > plot.ps
grdgradient $bathy_file -A0 -Nt -Gtemp_int.grd
grdimage $bathy_file -Itemp_int.grd -Bwesn -Ctmp/temp.cpt $scalerange -O -K >> plot.ps
grdcontour $bathy_file -J -R -Ctmp/contour.out -O -K -W0.7p >> plot.ps
psxy $station_file $scalerange $stationsymbol -O -K >> plot.ps


psxy tmp/data.xyz $scalerange -Se -Ctmp/ellipse.cpt -W0.5p -O -K >> plot.ps
pstext tmp/data.txt -J -R -O -K >> plot.ps


ps2pdf plot.ps test.pdf
open test.pdf