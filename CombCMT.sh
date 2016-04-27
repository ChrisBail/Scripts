#!/usr/bin/env bash

# Script made to combine the CMT_psmeca file and the CMT_psvelomeca file into
# a file that is x,y,z, str,dip,rake,mag, 0,0, Name that can be used to plot with -Sa option 
# of psmeca GMT
# Input, first argument is the CMT_psmeca (Mrr,Mtt....)
# The second argument is the psvelo_meca(str1,dip1...str2,dip2...)

file1=$1
file2=$2

paste -d '   ' <(awk '{print $1,$2}' $file2) \
<(awk 'NR==FNR{a[$NF];next}$NF in a{print $3}' $file2 $file1) \
<(awk '{print $3,$4,$5,(log($9*10^$10)/log(10)-16.1)/1.5,0,0,$NF}' $file2)