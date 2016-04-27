#!/usr/bin/env bash

gmtdefaults -D > .gmtdefaults4

gmt psbasemap -Jm10c -R239/240/34/35.2 -B:.:wesn -K -Xc -Yc > test.ps
gmt psmeca -R239/240/34/35.2 -Jm -Sc5c -O -Fa7p/dd -Ggreen << END >> test.ps
239.384 34.556 12. 180 18 -88 0 72 -90 5.5 0 0 0
END

ps2pdf test.ps
open test.pdf