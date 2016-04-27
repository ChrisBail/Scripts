#!/usr/bin/env python

import os
# write GMT

GMT_file='plot_hypoDD2.sh'

f1=open(GMT_file,'w')
event_file='synthetic_001.dat'
reloc_file='noisy_001_001.reloc'
plot_file='plot.ps'
pdf_file='plot.pdf'

#-------- Write common setup

common='#!/bin/bash\n\
gmtdefaults -D > .gmtdefaults4\n\
gmtset PAPER_MEDIA	a4\n\
gmtset LABEL_FONT_SIZE 12p\n\
gmtset OBLIQUE_ANOTATION 0\n\
gmtset PAGE_ORIENTATION portrait\n\
gmtset ANNOT_FONT_SIZE_PRIMARY 10p\n\
gmtset HEADER_FONT_SIZE 12p\n\
gmtset COLOR_MODEL=RGB\n\
export LC_NUMERIC=POSIX\n'

f1.write(common)

f1.write("\
# Defaults\n\
# Create a temporary directory, so that this one doesn't get stuffed up\n\
if ! test -d tmp ; then\n\
	mkdir tmp\n\
fi\n")

f1.write("origin='167/-16'\n\
lscale='5'\n\
scalerange=\"-Jm${origin}/${lscale}c -R166/169/-17/-14\"\n\
stationsymbol='-St0.3c -Gyellow -W0.75pt'\n")

f1.write("#------- Input_files\n\
path_plot='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Grids/'\n\
path_data='/Volumes/donnees/SE_DATA/WOR/CHRIS/HYPODD/ALL_DATA/'\n")

f1.write("grid=$path_plot'Vanuatu235m.grd'\n\
trench=$path_plot'Smooth_Trench_Depth.txt'\n\
stationfile='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Stations/station_vanuatu.sta'\n")

f1.write("event_file=$path_data'"+event_file+"'\n\
reloc_file=$path_data'"+reloc_file+"'\n")

f1.write("#------- Prepare Output files\n")

f1.write("psf="+plot_file+'\n')

f1.write("cat << END > tmp/temp.cpt\n\
-8000 255 255 255 0 255 255 255\n\
0 255 255 255 8000 255 255 255\n\
END\n\
cat << END > tmp/contour.out\n\
0 C\n\
END\n\
awk '(NR>1 && NF>2){ li=substr($0,23,5);la=gsub(/ /,\"\",li); print substr($0,14,8),-substr($0,5,7),li/1000 }' $stationfile > tmp/stations.xyz\n")

f1.write('#-------- Plot\n')
f1.write("psbasemap $scalerange -B30mWeSn -K > $psf \n\
grdgradient $grid -A0 -Nt -Gtemp_int.grd \n\
#grdimage temp_int.grd -Ctmp/temp.cpt -Bwesn $scalerange -O -K >> $psf \n\
grdimage $grid -Itemp_int.grd -Bwesn -Ctmp/temp.cpt $scalerange -O -K >> $psf \n\
grdcontour $grid -J -R -Ctmp/contour.out -O -K >> $psf \n\
psxy tmp/stations.xyz $scalerange $stationsymbol -O -K >> $psf \n")

f1.write("awk '{print $4,$3, $5}' $event_file > tmp/event.xyz\n\
awk '{print $3,$2, $4}' $reloc_file > tmp/reloc.xyz\n")

f1.write("psxy tmp/event.xyz $scalerange -Sc0.02c -Gred -W0.01pt -O -K >> $psf\n\
psxy tmp/reloc.xyz $scalerange -Sc0.02c -Ggreen -W0.01pt -O -K >> $psf\n")

f1.write("ps2pdf $psf "+pdf_file+"\n") 
f1.write("open "+pdf_file+"\n") 

f1.close()

os.system('bash '+GMT_file)