#!/usr/bin/env python

import os
import re
import sys
import numpy as np
from script import *

def plot_loc(loc_file,pdf_file,type_color=None):

	#loc_file='noisy_001_001.reloc'
	#pdf_file='plot.pdf'
	
	relief=False
	GMT_file='temp.sh'
	plot_file='plot.ps'
	if type_color is None:
		type_color='green'
	
	#----- Read data in loc file
	
	f1=open(loc_file,'r')
	total_events=len(f1.readlines())
	dic_event=read_loc(loc_file)
	
	#------- Check number of cluster
	
	#------- Get only elements different from nan
	[dic_event.pop(k,None) for k,a in dic_event.items() if np.isnan(a['depth'])]
	
	cid=[dic_event[k]['cid'] for k in dic_event]
	A=np.sort(np.array(cid))
	B=np.diff(A)
	C=np.count_nonzero(B)+1
	f1.close()
	title='\"Total of %i event(s) reparted in %i cluster(s)\"' %(total_events,C)

	fGMT=open(GMT_file,'w')

	type_file=loc_file[loc_file.index('.')+1:]

	#---- Define whether its a loc or a reloc input

	if type_file=='loc':
		cluster_col='18'
	else:
		cluster_col='24'

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

	fGMT.write(common)

	fGMT.write("\
if ! test -d tmp ; then\n\
	mkdir tmp\n\
fi\n")

	fGMT.write("origin='167/-16'\n\
lscale='7'\n\
scalerange=\"-Jm${origin}/${lscale}c -R166/168/-16.75/-14.5\"\n\
stationsymbol='-St0.2c -Gyellow -W0.5pt'\n")

	fGMT.write("#------- Input_files\n\
path_plot='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Grids/'\n")

	fGMT.write("grid=$path_plot'Vanuatu235m.grd'\n\
#trench=$path_plot'Smooth_Trench_Depth.txt'\n\
trench=$path_plot'Trench.txt'\n\
stationfile='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Stations/station_vanuatu.sta'\n")

	fGMT.write("#------- Prepare Output files\n")

	fGMT.write("psf="+plot_file+'\n')

	#----Sort file according to cluster number and awk it

	cmd='sort -k '+cluster_col+' '+loc_file+" | awk  \'{print $3, $2, $4, $"+cluster_col+"}' > tmp/loc_sorted.xyzc\n"

	fGMT.write(cmd)
	
	if relief==True:
		fGMT.write("cat << END > tmp/temp.cpt\n\
-8000 255 255 255 0 255 255 255\n\
0 255 255 255 8000 255 255 255\n\
END\n")
	else:
		fGMT.write("cat << END > tmp/temp.cpt\n\
-8000 255 255 255 0 255 255 255\n\
0 230 230 230 8000 230 230 230\n\
END\n")

	fGMT.write("cat << END > tmp/box.xy\n\
166.2 -16.5\n\
167.75 -16.5\n\
167.75 -15\n\
166.2 -15\n\
166.2 -16.5\n\
END\n\
makecpt -Cjet -I -T1/100/1 > tmp/color.cpt\n\
cat << END > tmp/contour.out\n\
0 C\n\
END\n\
awk '(NR>1 && NF>2){ li=substr($0,23,5);la=gsub(/ /,\"\",li); print substr($0,14,8),-substr($0,5,7),li/1000 }' $stationfile > tmp/stations.xyz\n")

	fGMT.write('#-------- Plot\n')
	fGMT.write("psbasemap $scalerange -B30mWeSn:.%s: -K > $psf \n" %title)
	if relief==True:
		fGMT.write("grdgradient $grid -A0 -Nt -Gtemp_int.grd \n\
grdimage $grid -Itemp_int.grd -Bwesn -Ctmp/temp.cpt $scalerange -O -K >> $psf \n")
	else:
		fGMT.write("grdimage $grid -Bwesn -Ctmp/temp.cpt $scalerange -O -K >> $psf \n")
	fGMT.write("grdcontour $grid -J -R -Ctmp/contour.out -W0.8p -O -K >> $psf \n\
psxy tmp/stations.xyz $scalerange $stationsymbol -O -K >> $psf \n")
	fGMT.write('psxy tmp/box.xy $scalerange -L -O -K -W2pt,,-.- >> $psf \n')
	fGMT.write('#awk \'{ print $1, $2, NR }\' $trench | sample1d -T2 -I0.1 -S1 -Fc | psxy $scalerange -O -K -W1pt >> $psf \n')
	fGMT.write('#filter1D $trench -N2/1 -FG100 | psxy $scalerange -O -K -W1pt >> $psf \n')
	fGMT.write('psxy $trench $scalerange -O -K -W1p >> $psf \n')
	fGMT.write('psxy $trench $scalerange -Sf4c/0.3clt -Gblack -O -K >> $psf \n')

	if len(type_color)>0:
		cmd="awk  '{print $1, $2, $4}' tmp/loc_sorted.xyzc | psxy $scalerange -Sc0.05c -G"+type_color+" -O -K -W0.1pt >> $psf \n"
	else:
		cmd="awk  '{print $1, $2, $4}' tmp/loc_sorted.xyzc | psxy $scalerange -Sc0.05c -Ctmp/color.cpt -O -K  >> $psf \n"
	fGMT.write(cmd)

	fGMT.write("ps2pdf $psf "+pdf_file+"\n") 
	#fGMT.write("open "+pdf_file+"\n") 

	fGMT.close()

	os.system('bash '+GMT_file)	