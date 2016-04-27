#!/bin/bash

polar_file=$1
amp_file=$2
mec_file=$3
output_filename=$4
title=$5


gmtdefaults -D > .gmtdefaults4
#LC_NUMERIC==POSIX
#gmtset FRAME_WIDTH 0c
#polar_file='pspolar.inp'
#mec_file='mec_hash.out'
#output_filename='test.pdf'
#title='Hello'

######### Plot Meca

head -2 $mec_file | psmeca -JX7c -Sa5c -R-7/7/-7/7 -Hi1 -T0,0.8p,red -Ered -K -M5c -K -Xc -Yc > plot.ps
tail -n +2 $mec_file | psmeca -JX7c -Sa5c -R-7/7/-7/7 -Hi1 -T0 -K -M5c -O >> plot.ps

######## Plot Polarities

pspolar $polar_file -Hi1 -JX7c -R-7/7/-7/7 -Ewhite -e0.1p,black -f1.5p,black -D0/0 -M5c -Sc0.1c -K -O >> plot.ps

######## Plot amplitudes

# num_lines
num_line=$(wc -l < foc_amp.out)

for (( i=2; i<=$num_line; i++ ))
do
amp=$(awk "NR==$i {print}" $amp_file | awk '{print 1*$4}')

awk "NR==$i {print }" $amp_file | awk '{print $1,$2,$3,"U"}' | pspolar -JX7c -R-7/7/-7/7 -g0.8p,red -G -D0/0 -M5c -Sc${amp}c -K -O >> plot.ps

done

######## Plot title

pstext -J -R -O -K << EOF >> plot.ps
0 6.5 12 0 0 CM $title
EOF

ps2pdf plot.ps $output_filename
