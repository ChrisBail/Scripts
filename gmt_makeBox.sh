#!/bin/bash

# Read arguments
case $# in
	8)
		eventfile=$1
		olon=$2
		olat=$3
		azimuth=$4
		xmin=$5
		xmax=$6
		ymin=$7
		ymax=$8
		;;
	*)
		echo "Selects events within a box"
		echo ""
		echo "Usage: gmt_makeBox.sh eventfile olon olat orientation xmin xmax ymin ymax"
		echo "  Inputs:"
		echo "     eventfile     is the event file, column 1 = longitude, column 2 = latitude"
		echo "     olon,olat     are the origin latitude and longitude (where x&y==0)"
		echo "     orientation   is the direction of the x axis (clockwise from due north)"
		echo "     xmin,xmax,ymin,ymax are the box limits in km"
		echo "  Outputs:"
		echo "     boxEvents.xy: Events, columns 1&2=x&y (km), rest as in original file"
		echo "     box.ll:       Box bounds (lon,lat: can be plotted on the map using psxy)"
		echo "     xtrack.ll:    A center line (for grdtrack) from xmin to xmax at (ymin+ymax)/2"
		echo "                   spacing is 0.01 km, or a multiple that gives up to 200 pts"
	exit 1
esac

## CALCULATE LAT/LON RANGE for mapproject
olat=`echo $olat | awk '{split($0,a,":"); if (a[1]>0) {print a[1]+a[2]/60.} else {print a[1]-a[2]/60.}}'`
olon=`echo $olon | awk '{split($0,a,":"); if (a[1]>0) {print a[1]+a[2]/60.} else {print a[1]-a[2]/60.}}'`
maxdist=`gmtmath -Q $ymin ABS $ymax ABS MAX 2 POW $xmin ABS $xmax ABS MAX 2 POW ADD SQRT =`
maxdellon=`echo "$maxdist * .0089" | bc`
maxdellat=`gmtmath -Q $maxdellon $olat 180 MUL PI DIV COS ABS MUL =`
lonmin=`gmtmath -Q $olon $maxdellon SUB =`
lonmax=`gmtmath -Q $olon $maxdellon ADD =`
latmin=`gmtmath -Q $olat $maxdellat SUB =`
latmax=`gmtmath -Q $olat $maxdellat ADD =`
mprange="-R/$lonmin/$lonmax/$latmin/$latmax"

## Set parameters for project and mapproject
projparms="-C${olon}/${olat} -A${azimuth} -L${xmin}/${xmax}"
mpparms="-Joa${olon}/${olat}/${azimuth}/1 $mprange -C -I -Fk"
#mpparms="-Joa${olon}/${olat}/${azimuth}/1  -C -I -Fk"
echo "projparms=$projparms"
echo "mpparms=$mpparms"

echo "Make boxEvents.xy from $eventfile"
# Make boxEvents.xy
project $eventfile $projparms -W${ymin}/${ymax} -Fpqxyz -Q > boxEvents.xy

echo "Make box.ll"
# Make box.ll
cat << END > box.tmp
$xmin $ymin
$xmin $ymax
$xmax $ymax
$xmax $ymin
$xmin $ymin
END
mapproject box.tmp $mpparms > box.ll
rm box.tmp

echo "Make xtrack.ll:"
# Make xtrack.ll:
ymid=`echo "($ymax + $ymin)/2" | bc`
xtrackcenter=`echo "0 $ymid" | mapproject $mpparms | awk '{printf "%s/%s",$1,$2}'`
spacing=`echo "scale=2; ( $xmax - $xmin )/200" | bc`
project $projparms -G${spacing}k -Q > xtrack.ll
