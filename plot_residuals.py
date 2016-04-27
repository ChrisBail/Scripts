#!/usr/bin/env python

### add_noise

import os
import glob
import sys
from random import gauss
import matplotlib.pyplot as plt
import numpy as np
from script import *
from plot_GMT import *


#--- Get defaults

loc_file='hypoDD.loc'
reloc_file='hypoDD.reloc'
event_file='event.dat'
sorted_loc_file='hypoDD_sorted.loc'

#######################
#-----Plot with same amount of  events in loc and in reloc files

dic_loc=read_loc(loc_file)
dic_reloc=read_loc(reloc_file)
print len(dic_loc)

[dic_loc.pop(k,None) for k in dic_loc.keys() if k not in dic_reloc.keys()]

#print len(dic_loc)	


f1=open(sorted_loc_file,'w')
f2=open(loc_file,'r')

for line in f2:
	A=line.split()
	index=int(A[0])
	if index in dic_loc.keys():
		f1.write(line)	

f1.close()
f2.close()

#------- Plot with residuals as circle

dic_dat=read_loc(event_file)
f1=open('tmp/loc_res.xyz','w')

for k in dic_loc:
	dic_loc[k]['res']=dic_dat[k]['res']
	f1.write('%9.3f %9.3f %8.2f %5.2f %i\n' % (dic_loc[k]['lon'],dic_loc[k]['lat'],dic_loc[k]['depth'],dic_loc[k]['res'],dic_loc[k]['cid']))

f1.close()

#--------- Read cpt to construct properly psxy file
os.system('makecpt -Cjet -I -T1/100/1 > tmp/color.cpt\n')
res_divider=2
dic_color=get_cpt('tmp/color.cpt')

#------- For loc
f1=open('tmp/res.xys','w')
for k in dic_loc:
	cid=dic_loc[k]['cid']
	if cid not in dic_color.keys():
		color_setting='0/0/0'
	else:
		color_setting=dic_color[cid]
	f1.write('> -W0.01p,%s\n' %color_setting)
	f1.write('%9.3f %9.3f %.3f\n' %(dic_loc[k]['lon'],dic_loc[k]['lat'],dic_loc[k]['res']/res_divider))
f1.close()

#------- For Reloc
f1=open('tmp/res_reloc.xys','w')
for k in dic_reloc:
	cid=dic_reloc[k]['cid']
	if cid not in dic_color.keys():
		color_setting='0/0/0'
	else:
		color_setting=dic_color[cid]
	f1.write('> -W0.01p,%s\n' %color_setting)
	f1.write('%9.3f %9.3f %.3f\n' %(dic_reloc[k]['lon'],dic_reloc[k]['lat'],dic_reloc[k]['res_cc']/res_divider))
f1.close()


#---------- Add legend

res=[0.2, 0.5, 1.0, 2.0]
res=list(np.array(res)/res_divider)
xpos=167.7
ypos=[-14.7, -14.75, -14.82, -14.94]
shift=0.1
title_legend='Residuals [s]'
legend_GMT(res,xpos,ypos,shift,title_legend,'tmp/legend.xys','tmp/legend.txt')

#--------- Define main title

#main_title='Residuals for the %i events (.loc)' %len(dic_loc)

main_title='Residuals for the %i events (.reloc)' %len(dic_reloc)

res_file='tmp/res_reloc.xys'

#----- Write GMT

f1=open('GMT.sh','w')
ps_file='plot.ps'

main_block="#!/bin/bash\n\
gmtdefaults -D > .gmtdefaults4\n\
gmtset PAPER_MEDIA	a4\n\
gmtset LABEL_FONT_SIZE 12p\n\
gmtset OBLIQUE_ANOTATION 0\n\
gmtset PAGE_ORIENTATION portrait\n\
gmtset ANNOT_FONT_SIZE_PRIMARY 10p\n\
gmtset HEADER_FONT_SIZE 12p\n\
gmtset COLOR_MODEL=RGB\n\
export LC_NUMERIC=POSIX\n\
\n\
\n\
if ! test -d tmp ; then\n\
mkdir tmp\n\
fi\n\
origin='167/-16'\n\
lscale='7'\n\
scalerange=\"-Jm${origin}/${lscale}c -R166/168/-16.75/-14.5\"\n\
stationsymbol='-St0.2c -Gyellow -W0.5pt'\n\
\n\
#------- Input_files\n\
path_plot='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Grids/'\n\
grid=$path_plot'Vanuatu235m.grd'\n\
#trench=$path_plot'Smooth_Trench_Depth.txt'\n\
trench=$path_plot'Trench.txt'\n\
stationfile='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Stations/station_vanuatu.sta'\n\
\n\
\n\
awk '(NR>1 && NF>2){ li=substr($0,23,5);la=gsub(/ /,\"\",li); print substr($0,14,8),-substr($0,5,7),li/1000 }' $stationfile > tmp/stations.xyz\n\
\n\
#-------- Plot\n"

f1.write(main_block)
f1.write("cat << END > tmp/temp.cpt\n\
-8000 255 255 255 0 255 255 255\n\
0 230 230 230 8000 230 230 230\n\
END\n")
f1.write('makecpt -Cjet -I -T1/100/1 > tmp/color.cpt\n')
f1.write('psbasemap $scalerange -B30m:.\"%s\":WeSn -K > %s\n' %(main_title,ps_file))
f1.write('grdgradient $grid -A0 -Nt -Gtemp_int.grd\n') 
f1.write('grdimage $grid -Bwesn -Ctmp/temp.cpt $scalerange -O -K >> %s\n' % ps_file)   
f1.write('psxy $trench $scalerange -O -K -W1p >> %s\n' % ps_file) 
f1.write('psxy $trench $scalerange -Sf4c/0.3clt -Gblack -O -K >> %s\n' % ps_file) 
f1.write("psxy %s -J -R -Sc -m -O -K >> %s\n" %(res_file,ps_file))
f1.write("psxy tmp/legend.xys -J -R -Sc -W0.1p -O -K >> %s\n" %(ps_file))
f1.write('grdcontour $grid -J -R -Ctmp/contour.out -W0.8p -O -K >> %s\n' % ps_file)   
f1.write('psxy tmp/stations.xyz $scalerange $stationsymbol -O -K >> %s\n' % ps_file) 
f1.write("pstext tmp/legend.txt -J -R -O -K >> %s\n" %(ps_file))
f1.write('ps2pdf %s plot.pdf' %ps_file)
f1.close()
os.system('bash '+'GMT.sh')
os.system('open plot.pdf')
sys.exit()

##################################

pdf_file_loc='plot_loc_cc10.pdf'
pdf_file_reloc='plot_reloc_cc10.pdf'
plot_loc(reloc_file,pdf_file_reloc,'')
plot_loc(loc_file,pdf_file_loc,'')
plot_loc(sorted_loc_file,'test.pdf','')
os.system('open '+pdf_file_loc)
os.system('open '+pdf_file_reloc)
os.system('open '+'test.pdf')
