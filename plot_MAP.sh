#!/bin/bash

gmtdefaults -D > .gmtdefaults4
gmtset LABEL_FONT_SIZE 14p
gmtset PAGE_ORIENTATION portrait
### Files

bathy_cpt='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Grids/Bathy_white.cpt'
bathy='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Grids/Vanuatu235m.grd'
trench='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Grids/Smooth_Trench.txt'

range='166.3/167/-16.5/-15.7'
scalem='15c'

if [ ! -d tmp ]; then
mkdir tmp
fi

##### Color

makecpt -Cocean -T-8000/0/50 > tmp/test.cpt

#### Contour

cat << EOF > tmp/contour.txt
0 C
EOF

#### Start plotting

psbasemap -Jm$scalem -R$range -B0.1/0.1WeSn -K -Xc -Yc > map.ps

grdimage $bathy -J -R -Ctmp/test.cpt -K -O >> map.ps
grdcontour $bathy -J -R -W0.5p -S100 -Ctmp/contour.txt -K -O >> map.ps
psxy $trench -W1p -Sf1i/0.2clt -Gblack -J -R -O -K >> map.ps

ps2pdf map.ps map.pdf

open map.pdf