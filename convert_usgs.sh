#!/usr/bin/env bash

# Program made to take a USGS.txt file into a new file made to compare with CMT
file1=$1
file='tmp.txt'

tail -n+3 $file1 > $file
paste -d '  ' <(awk  '{print $4,$3,$5}' $file) \
<(paste -d '\0' \
<(awk '{print $1}' $file | awk -F'-' '{for(i=1;i<=3;i++) printf "%s/",$i;printf "\n"}') \
<(awk '{print $2}' $file | awk -F':' '{printf "%s/",$1;printf "%s",$2;printf "\n"}')) \
| tail -r 


rm -f $file