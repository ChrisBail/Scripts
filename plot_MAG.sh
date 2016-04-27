#!/usr/bin/env bash


gmtset INPUT_DATE_FORMAT yyyy-mm-dd
gmtset PLOT_DATE_FORMAT o
gmtset TIME_FORMAT_PRIMARY abbreviated

filein='time.xyz'
ndk_file='/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Data/jan76_dec10.ndk'
read_NDK.py $ndk_file > tmp/ndk1.xyz
awk '{ if ($8 > 0 && $4<60 && $2<169 && $2>165 && $3<-14 && $3>-17) print $1,$2,$3,$4,$5,$6,$7,$8}' tmp/ndk1.xyz > $filein

scale='17c/5c'
size_line='0.2p'

paste <(awk '{print $1}' $filein | awk -F'-' '{print $1"-"$2"-"$3}') <(awk '{print $8}' $filein) > date.txt

echo '1965-08-11  7.5' | cat >> date.txt


awk '{if ($2>6.5) print $0}' date.txt > main.txt
awk '{if ($2>6.5) print $1,$2+0.2,8,0,0,"CM",$2}' date.txt > test.txt

# Convert file to segment file

xy2seg.py date.txt " " > date_peak.txt

#paste <(awk 'statements' file1) <(awk 'statements' file2) > result

psbasemap -JX$scale -R1964-01-01T/2010-01-01T/4/8 -Ba5Yf12o:'Year':/a1f0.5:'Magnitude'::.'CMT Focs 165/169/-17/-15':WeSn -K -Xc -Yc  > map.ps
psxy date_peak.txt -J -R -O -m -W0.4p,black -K >> map.ps
psxy date.txt -J -R -O -Sc0.1c -Ggreen -W0.4p,black -K >> map.ps
psxy main.txt -J -R -O -Sc0.3c -Gred -W0.4p,black -K >> map.ps
pstext test.txt -J -R -O -K >> map.ps

ps2pdf map.ps
open map.pdf