#!/bin/bash
# plot hypocenter information as a function of time
# Uses GMT

function tickinterval {
	lo=${1%/*}
	hi=${1#*/}
	#echo "$1 $lo $hi :"
	finterval=`echo "$lo $hi" | awk '{print (($2-$1)/5)}'`
	#echo "$finterval"
	introot=`echo $finterval | awk '{root=log($1)/log(10);printf "%.0f",root}'`
	root=`echo $introot | awk '{print 10^$1}'`
	intmult=`echo $finterval $root | awk '{mult=$1/$2;printf "%.0f",mult}'`
	#echo $intmult
	if test $intmult -lt 1 ; then		# Stupid way to check for round up errors
		introot=$((introot-1))
		root=`echo $introot | awk '{print 10^$1}'`
		intmult=`echo $finterval $root | awk '{mult=$1/$2;printf "%.0f",mult}'`
	fi
	#echo ",  $root *$intmult = "
	echo "$root * $intmult" | bc
}
	
hypofile='hypos.xyz'
origin='-32:16.8/37:17.5'	# center of lava lake for Lucky Strike
rotation=109				# x-direction for Lucky Strike
tbounds="auto"				# "yyyy-mm-ddT/yyyy-mm-ddT"
xbounds="auto"		
ybounds="auto"
zbounds="auto"
mbounds="auto"
histdays=3
refmag="auto"
outbase="plotEQTime"
options=$@ 

if ( ! getopts "f:o:r:t:x:y:z:m:d:s:" opt); then
	echo "Usage: `basename $0` [-f hypofile] [-o origin] [-r rotation] [-t tbounds]"
	echo "          [-x xbounds] [-y ybounds] [-z zbounds] [-m mbounds] [-d histDays]"
	echo " Uses GMT and nor2xyz (which uses Python)"
	echo " The plot is output to ${outbase}.pdf"
	echo " OPTIONS: [defaults in brackets]"
	echo "    -f  hypofile  name of hypocenter file (format: x y z time mag ... [${hypofile}])"
	echo "                  time is in ISO 8601 format (e.g., 2012-06-21T12:20:04)"
	echo "    -o  origin    lon/lat of the <origin> [${origin}])"
	echo "    -r  rotation  direction of the x-axis (degrees CW from N) [${rotation}])"
	echo "    -t  tbounds   range of times to plot (min/max, yyyy-mm-ddT) [$tbounds])"
	echo "    -x  xbounds   x bounds (min/max, km from origin) [$ybounds])"
	echo "    -y  ybounds   y bounds (min/max, km from origin) [$xbounds])"
	echo "    -z  zbounds   depth bounds (min/max, km) [$zbounds])"
	echo "    -m  mbounds   magnitude bounds to plot (min/max)  [$mbounds])"
	echo "    -d  daystobin # of days to bin in histograms [$histdays])"
	echo "    -s  refmag    magnitude to plot at 0.5 cm ('auto' uses max magnitude) [$refmag])"
	exit $E_OPTERROR
fi

while getopts "f:o:r:t:x:y:z:m:d:s:" opt; do
	case $opt in
		f) hypofile=$OPTARG;;
		o) origin=$OPTARG;;
		r) rotation=$OPTARG;;
		t) tbounds=$OPTARG;;
		x) xbounds=$OPTARG;;
		y) ybounds=$OPTARG;;
		z) zbounds=$OPTARG;;
		m) mbounds=$OPTARG;;
		d) histdays=$OPTARG;;
		s) refmag=$OPTARG;;
		*) echo "Unknown argument: quitting"
			exit;;
	esac
done
		
plotheight=4c
psf=${outbase}.ps

# Create a temporary directory, so that this one doesn't get stuffed up
if ! test -d tmp ; then
	mkdir tmp
fi

#nor2xyz -f $norfile > tmp/hypos.xyz	# convert Nordic file lines 1 and 2 to csv

gmtset INPUT_DATE_FORMAT "yyyy-mm-dd" INPUT_CLOCK_FORMAT "hh:mm:ss" 
gmtset TIME_FORMAT_PRIMARY abbreviated TIME_LANGUAGE us TIME_UNIT d
gmtset ANNOT_FONT_SIZE_PRIMARY 10p 
gmtset ANNOT_FONT_SIZE_SECONDARY 12p 
gmtset LABEL_FONT_SIZE 12p
#gmtset FIELD_DELIMITER ,
pd="15c/$plotheight"	# subplot dimensions
po="-Y$plotheight"		# offset between plots
#awk -F, '{print $4,$3}' $hypofile
###################
# PLOT EQ LON
# psbasemap -R${tbounds}/-32.3/-32.25 -JX$pd $po -Bs${xtick_s}/WSe -Bp${xtick_p}/.01:"Lon (deg)":WSen -K > $psf
# awk -F, '{print $4,$1}' $hypofile | psxy -JX -R -Sp -O -K >> $psf
# ###################
# # PLOT EQ LAT
# psbasemap -R${tbounds}/37.27/37.32 -JX$pd $po -Bs${xtick_s}/wsE -Bp${xtick_p}/.01:"Lat (deg)":wsEn -O -K >> $psf
# awk -F, '{print $4,$2}' $hypofile | psxy -JX -R -Sp -O -K >> $psf
###################
# SELECT EVENTS BY POSITION AND TIME, AFTER ROTATING INTO REFERENCE FRAME
# PROJECT EQS ACROSS- and ALONG-AXIS, eliminate events outside of bounds
echo "Projecting events"
project $hypofile -C$origin -A$rotation -Q -Fpqz > tmp/tmpproj.xyz
bounds=`awk '{print $1,$2,$4}' tmp/tmpproj.xyz | minmax -f2T -C`
#echo $bounds
set -- $bounds
if test $xbounds = "auto" ; then 
	xbounds="$1/$2"; 
	echo " Automatically setting xbounds: found $xbounds"
fi
if test $ybounds = "auto" ; then 
	ybounds="$3/$4"; 
	echo " Automatically setting ybounds: found $ybounds"
fi
if test $tbounds = "auto" ; then 
	tbounds="$5/$6"; 
	echo " Automatically setting tbounds: found $tbounds"
fi
# Figure out time span, base time axis labels on this
trange=`echo $tbounds | tr "/" "\n" | minmax -fiT -C`
echo $trange
set -- $trange
trange=`echo $2 - $1 | bc`
if [ $(bc <<< "$trange <= 1") -eq 1 ] ; then
	xtick_s="1D"; xtick_p="a6Hf1H"
	histdays=0.0416666667
elif [ $(bc <<< "$trange <= 3") -eq 1 ] ; then
	xtick_s="1U"; xtick_p="a1df6H"
	histdays=0.25
elif [ $(bc <<< "$trange <= 7") -eq 1 ] ; then
	xtick_s="1U"; xtick_p="a1d"
	gmtset PLOT_DATE_FORMAT "o yyyy"
	histdays=1
elif [ $(bc <<< "$trange <= 31") -eq 1 ] ; then
	xtick_s="1O"; xtick_p="a5df1d"
	gmtset PLOT_DATE_FORMAT "o yyyy"
	histdays=1
elif [ $(bc <<< "$trange <= 200") -eq 1 ] ; then
	xtick_s="0Y"; xtick_p="a1Of1d"	
	gmtset PLOT_DATE_FORMAT "o yyyy"
elif [ $(bc <<< "$trange < 600") -eq 1 ] ; then
	xtick_s="1Y"; xtick_p="a3Of1o"	
elif [ $(bc <<< "$trange < 2000") -eq 1 ] ; then
	xtick_s="1Y"; xtick_p="a3Of1o"	# Secondary=year, primary=ticks every month with word every 3
else
	xtick_s="1Y"; xtick_p="a1Yf3o"	# Secondary=year, primary=ticks every month, words every year
fi
echo "Time range = $trange days: xtick_s=$xtick_s, xtick_p=$xtick_p"

echo "Selecting events within x,y and time bounds"
events=`cat tmp/tmp.xyz | wc -l`
# Select only within the time range
awk '{printf "%s\t%s\n",$4,$0}' tmp/tmpproj.xyz > tmp/tmp.xyz
gmtselect tmp/tmp.xyz -R${tbounds}/$xbounds -f0T  | cut -f 2- | gmtselect -R${xbounds}/$ybounds > tmp/proj.xyz
echo "Selected `cat tmp/proj.xyz | wc -l` of $events events"
###################
echo "Checking other bounds"
if test $mbounds = "auto" ; then 
	awk '{if ($5!=-999) {print $5}}' tmp/proj.xyz > tmp/mags.xyz
	if test -s tmp/mags.xyz	; then	# if file is not empty
		bounds=`awk '{if ($5!=-999) {print $5}}' tmp/proj.xyz | minmax -C`
		set -- $bounds
		mbounds="$1/$2"
		maxmag=$2
		echo " Automatically setting magnitude bounds: found $mbounds"
	else
		mbounds="0/1"; maxmag=1
		echo " No magnitudes in Nordic file: setting bounds to 0/1"
	fi
fi
if test $refmag = "auto" ; then
	refmag=${mbounds#*/};
	echo " Automatically set plot reference magnitude to $refmag"
fi
if test $zbounds = "auto" ; then 
	bounds=`awk '{if ($3!=-999) {print $3}}' tmp/proj.xyz | minmax -C`
	set -- $bounds
	zbounds="$1/$2"
	echo " Automatically setting depth bounds: found $zbounds"
fi
# AWK script to change x,y,mag to x,y,size
cat << END > tmp/xym2xys.awk
{relmag=\$3-$refmag; size=0.5*(2^relmag); if (size<0.01) size=0.01; print \$1,\$2,size}
END
#####################
echo "Plotting event depths"
ylabel="Depth (km)"
ytick=`tickinterval $zbounds`
bounds=${tbounds}/$zbounds
#echo $zbounds $ytick
psbasemap -R$bounds -JX15c/-$plotheight -Bs${xtick_s}/WSe -Bp${xtick_p}/${ytick}:"$ylabel":WSen -P -K > $psf
awk '{print $4,$3,$5}' tmp/proj.xyz | awk -f tmp/xym2xys.awk | psxy -JX -R -Sc -O -K >> $psf
###################
echo "Plotting events along x-axis..."
ylabel="along x-axis (km)"
ytick=`tickinterval $xbounds`
bounds=${tbounds}/$xbounds
psbasemap -R$bounds -JX$pd $po -Bs${xtick_s}/Wse -Bp${xtick_p}/$ytick:"$ylabel":Wsen -O -K >> $psf
awk  '{print $4,$1,$5}' tmp/proj.xyz | awk -f tmp/xym2xys.awk | psxy -JX -R -Sc -O -K >> $psf
###################
echo "Plotting events along y-axis..."
ylabel="along y-axis (km)"
ytick=`tickinterval $ybounds`
bounds=${tbounds}/$ybounds
psbasemap -R$bounds -JX$pd $po -Bs${xtick_s}/Wse -Bp${xtick_p}/$ytick:"$ylabel":Wsen -O -K >> $psf
awk  '{print $4,$2,$5}' tmp/proj.xyz | awk -f tmp/xym2xys.awk | psxy -JX -R -Sc -O -K >> $psf
###################
echo "Plotting event magnitudes..."
ylabel="Ml"
ytick=`tickinterval $mbounds`
bounds=${tbounds}/$mbounds
psbasemap -R$bounds -JX$pd $po -Bs${xtick_s}/wsE -Bp${xtick_p}/$ytick:"$ylabel":Wsen -O -K >> $psf
awk '{print $4,$5,$5}' tmp/proj.xyz | awk -f tmp/xym2xys.awk | psxy -JX -R -Sc -O -K >> $psf
###################
echo "Plotting events histogram..."
ylabel="events/day"
awk '{print $4}'  tmp/proj.xyz | pshistogram -R${tbounds}/0/1000 -W$histdays -f0T -Io > tmp/tmp.xy 2> tmp/stderr.text
awk -v hd=$histdays '{print $1,$2/hd}' tmp/tmp.xy > tmp/hist.xy
bounds=`minmax tmp/hist.xy -C`
set $bounds
ybds="0/$4"
ytick=`tickinterval $ybds`
bounds=${tbounds}/$ybds
psbasemap -R$bounds -JX$pd $po -Bs${xtick_s}/wsE -Bp${xtick_p}/$ytick:"$ylabel":Wsen -O -K >> $psf
psxy tmp/hist.xy -JX -R${tbounds}/$ybds -f0t -Sb${histdays}u -Bwe  -G64 -O -K >> $psf
###################
echo "Plotting cumulative sum of events..."
ylabel="Cum events"
awk '{print $4}' tmp/proj.xyz | pshistogram -JX -R -Bw -f0T -W1 -Lthin,,-- -Q -S -Io > tmp/histc.xy 2> tmp/stderr.txt
bounds=`minmax tmp/histc.xy -C`
set $bounds
ybds="0/$4";
ytick=`tickinterval $ybds`
psbasemap -R${tbounds}/$ybds -JX$pd $po -Bs${xtick_s}/Wsn -Bp${xtick_p}/$ytick:"$ylabel":Wsn -O -K >> $psf
psxy tmp/histc.xy -JX -R${tbounds}/$ybds -f0t -Bwe -Wthin,,-- -O -K >> $psf
###################
echo -n "Evaluating cumulative moment of events ..."
awk 'BEGIN{cm=0}{if ($5!=-999){moment=10^(1.5*$5+9.1); cm=cm+moment; print $4,cm}}'  tmp/proj.xyz > tmp/cummom.xy
if test -s tmp/cummom.xy	; then	# if file is not empty
	echo "found some.. plotting on same plot "
	bounds=`minmax tmp/cummom.xy -f0T -C`
	set $bounds
	if test $4 -eq "0" ; then
		ybds="0/1"
	else
		ybds="0/$4"
	fi
	ytick=`tickinterval $ybds`
	psbasemap -R${tbounds}/$ybds -JX$pd -Bs${xtick_s}/E -Bp${xtick_p}/$ytick:"Cum moment (N-m)":E -O -K >> $psf
	psxy tmp/cummom.xy -JX -R  -O -K >> $psf
else
	echo "none found, not plotting"
fi
###############################################################
############# PRINT INFO ##############
###############################################################
psbasemap -JX0.1c/0.1c -R0/1/0/1 $po -B0 -O -K >> $psf
psbasemap -JX15c/-1c -R0/15/0/3 -X-2c -Y0.4c -G250 -O -K >> $psf
echo 0 1 8 0 8 BL directory=  `pwd`  | pstext -Jx -R -O -K >> $psf
echo 0 2 8 0 8 BL opts=$options     | pstext -Jx -R -O  >> $psf

echo "Converting to pdf..."
ps2pdf $psf ${outbase}.pdf &> ps2pdf.out
rm $psf
echo "Opening pdf"
open ${outbase}.pdf
