#!/bin/bash
###############################################################
# Uses Nordic files for hypocenters:
#		select.out (selected events from catalog, used as input to velest)
#		hyp.out (calculate using starting model and hypo71, should be similar to select.out)
#   and velout.nor (hypocenters calcualted for new model)
# Also input.mod (original velocity model)
#      invers.out   (final velocity models, plus misfit estimations from original to final model)
#      station.sta   (station positions)
# If you write a line or two in a file named README, it will be displayed on the page
###############################################################

gmtdefaults -D > .gmtdefaults4
gmtset PAPER_MEDIA	a4
gmtset LABEL_FONT_SIZE 12p
gmtset OBLIQUE_ANOTATION 0
gmtset HEADER_FONT_SIZE 15p
export LC_NUMERIC=POSIX


# Input files
bathyfile=1326377043624.grd
selectfile=select.out
#hypfile="start.nor"			# hyps of input model: use when you are doing several iterations
#hypfile=hyp.out
#invfile=velout.nor
stationfile=station.sta
#inVelModel=new2.mod
#inversionOut=invers.out


# Parameters related to the Lucky Strike volcano.  Change these for another region
refVpVs=1.78		# reference Vp/Vs for velocity profile
lscale=5;									# cm/degree for map
xscale=$(echo "scale=3; 5/110" | bc )
#xscale=$(( 5 / 100 )) 	# cm/km for cross-sections (111.12 km/degree)
yscale=$(echo "scale=3; 5/110" | bc )
scale=0.01;

origin='166:57.4/-15:34.0'	# plot origin (center of lava lake for Lucky Strike)
rotation=91
selectsymbol='-Sc -W0.2p'
hypsymbol='-Sc0.08c -Ggreen'
velestsymbol='-Sc0.06c -Gblue'
stationsymbol='-St0.3c -Gyellow -W0.75pt'
scalerange="-Joa${origin}/${rotation}/${lscale}c -R-1.5/1.5/-1.4/1.5"
#scalerange="-Jm${origin}/${lscale}c -R166/168/-16:30/-14:30"
#scalerange="-Jm${origin}/${lscale}c -R-1/1/-1/1"
#bathyfile=/Users/crawford/_Work/Figures_Etc/2_Maps/LuckyStrike/grd/LuckySISMOMAR_40mtr.grd
legendspot="-Lf166:05/-16:45/-15:34/50"
#[ −L[f][x]lon0/lat0[/slon]/slat/length
# Across-axis box parameters
xsecthalflen=120     # defined as kilometer below -Q project
xsecthalfwidth=30
ydists="-60 0 60"
# Along-axis box parameters
lsecthalflen=90
lsecthalfwidth=120
xdists="0"
cptbds='-2400/-1500/100'

###############################################################
# Create a temporary directory, so that this one doesn't get stuffed up
if ! test -d tmp ; then
	mkdir tmp
fi

# Convert Nordic files to hypocenter xyz files
nor2xyz $selectfile > tmp/test.xyz
awk -v scale=$scale -f gmt_makexy.awk tmp/test.xyz > tmp/select.xyz
#nor2xyz $hypfile > tmp/hyp.xyz
#nor2xyz $invfile > tmp/velout.xyz

# Convert station.sta to xyz (THIS IS A NON-STABLE HACK, CONFIRM THE OUTPUT!!!!) #gsub("\\.", ",", $0) ;
awk '(NR>1 && NF>2){ li=substr($0,23,5);la=gsub(/ /,"",li); print substr($0,14,8),-substr($0,5,7),li/1000 }' $stationfile > tmp/stations.xyz

# Prepare magnitude legend USGS/

awk '{print $1, $2,"10 0 1 LM", $5}' legend.xy > legend.xyt


###############################################################
###################### PLOT MAP VIEW  #########################
###############################################################
psf=plot.ps

# Prepare color scale and intensity map
makecpt -Cglobe > tmp/temp.cpt

# PLOT MAP

psbasemap $scalerange $legendspot -B30:."Seismicity 2008/05 -> 2009/03 (~7000 events with RMS < 0.7)":mWeSn -K > $psf

# plot bathy map
#pscoast $scalerange -Di -G255/255/125 -W3 -O -K >> $psf
grdgradient $bathyfile -A0 -Nt -Gtemp_int.grd
grdimage $bathyfile -Itemp_int.grd -Bwesn -Ctmp/temp.cpt $scalerange -O -K >> $psf

psbasemap -Jx${lscale}c -R0/3/0/2.9 -B -O -K >> $psf
psxy legend.xy -J -CEQ_USGS.cpt -R -W0.2p -Sc  -O -K >> $psf
pstext legend.xyt -J -R -Dj0.5/0 -O -K >> $psf

# plot epicenters
psxy tmp/select.xyz $scalerange -CEQ_USGS.cpt $selectsymbol -O -K >> $psf

#psxy tmp/hyp.xyz    $scalerange $hypsymbol    -O -K >> $psf
#psxy tmp/velout.xyz $scalerange $velestsymbol -O -K >> $psf
# Plot cross-section boxes

# Plot stations
psxy  tmp/stations.xyz $scalerange $stationsymbol -O -K >> $psf

#psxy legend.xy -Jx -CEQ_USGS.cpt -R -W0.2p -Sc -X2c -O -K >> $psf

psbasemap $scalerange $legendspot -Xr -Yr -O -K >> $psf
psscale -D1c/6c/-3.5c/0.25c -Y1c -A -CEQ_USGS.cpt -B:km: -X17c -L -O -K >> $psf



# sta_cor.out
## CONVERT TO PDF

ps2pdf $psf

open plot.pdf
