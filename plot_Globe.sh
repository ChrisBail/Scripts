#!/usr/bin/env bash

###############################################################
#### Define GMT parameters

gmtdefaults -D > .gmtdefaults4
gmtset HEADER_FONT_SIZE 15p
gmtset LABEL_FONT_SIZE 14p
gmtset COLOR_FOREGROUND 128/0/0
gmtset PAGE_ORIENTATION portrait
gmtset BASEMAP_TYPE fancy
gmtset COLOR_NAN 255/255/255

range='130/200/-40/0'
scale='10c'

pscoast -R$range -JS165/-90/$scale -B20g10/20g10wsNE -Df -A10 -Gblack -Xc -Yc -K > map.ps
#pscoast -R$range -JM165/-17/$scale -B20g10/20g10 -Df -A10 -Gblack -Xc -Yc -K > map.ps
#pscoast -Rg -JA165/-17/45/5c -B15g15/15g15 -Dc -A500 -Gblack -Xc -Yc -K > map.ps
psxy -J -R -W2p,red -L -A -O -K >> map.ps << END
164 -10
171 -10
171 -23
164 -23
END


ps2pdf map.ps map.pdf
open map.pdf
rm -f map.ps
