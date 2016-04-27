#!/usr/bin/env bash

gmtset INPUT_DATE_FORMAT yyyy-mm-dd
gmtset PLOT_DATE_FORMAT o
gmtset LABEL_FONT_SIZE 10p
gmtset TIME_FORMAT_PRIMARY abbreviated

scale='14c/5c'
size_line='0.2p'

filename="/Users/baillard/_Moi/Programmation/Matlab/Seismic_Catalogs/ISC_1900_2013_sup_6.8.txt"
read_ISC.py $filename > scratch.txt
awk '{ if ($6>=7.5 && $4<-11.5 && $4>-20.5) print $1,$6,$7}' scratch.txt > test.dm

awk '{print $1,$2}' test.dm > eq.txt
awk '{if ($3=="ms") print $1,$2}' test.dm > ms_eq.txt
awk '{if ($3=="mw") print $1,$2}' test.dm > mw_eq.txt
awk '{if ($2>6.5) print $1,$2+0.15,8,0,0,"CM",$2}' test.dm > test.txt
#
## Convert file to segment file

xy2seg.py eq.txt " " > date_peak.txt
#
##paste <(awk 'statements' file1) <(awk 'statements' file2) > result
#
psbasemap -JX$scale -R1900-01-01T/2014-01-01T/7.4/8.5 -Ba10Yf12o:'Year':/a1f0.2g0.5:'Magnitude':WeSn -K -Xc -Yc > map.ps
psxy date_peak.txt -J -R -O -m -W0.4p,black -K >> map.ps
psxy eq.txt -J -R -O -Sc0.2c -Gblack -W0.4p,black -K >> map.ps
psxy ms_eq.txt -J -R -O -Sc0.2c -Gblue -W0.4p,black -K >> map.ps
psxy mw_eq.txt -J -R -O -Sc0.2c -Ggreen -W0.4p,black -K >> map.ps
#psxy main.txt -J -R -O -Sc0.3c -Gred -W0.4p,black -K >> map.ps
pstext test.txt -J -R -O -K >> map.ps
#
ps2pdf map.ps
open map.pdf