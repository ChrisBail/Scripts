#!/usr/bin/env bash

### Don't forget to specify -I1k if it's a grid il lon/lat
grid_file=$1
count=0

### Read options on command line

for arg; do
	count=$((count + 1)) 
	if [ $count = 1 ]; then
		continue
	fi
	### Get the first two characters
	pattern=${arg:0:2}
	### Assignate arguments
	if [ $pattern = '-J' ];then
		scale=$arg
	elif [ $pattern = '-R' ];then
		range=$arg
	elif [ $pattern = '-I' ];then
		increment=$arg
	elif [ $pattern = '-F' ];then
		smooth=$arg
	elif [ $pattern = '-D' ];then	
		type=$arg
	elif [ $pattern = '-L' ];then	
		grd_format=$arg
	elif [ $pattern = '-G' ];then	
		contour_file=${arg:2}
	else
		echo "option $pattern not recognized"
	fi
done

echo $grid_file
echo $smooth $type $increment $scale $range
echo $contour_file

### Create tmp directory

if [ ! -d tmp ]; then
	mkdir tmp
fi

### Change grid size to force closed contour

va=`grdinfo $grid_file -C | awk '{print $2-5"/"$3+5"/"$4-5"/"$5+5}'`
grd2xyz $grid_file > tmp/grd_test.txt
xyz2grd tmp/grd_test.txt -Gtmp/tmp.grd $increment -R$va

### Start computing

grdmath tmp/tmp.grd ISNAN = tmp/tmp1.grd
#grdfilter tmp/tmp1.grd -D1 -I1k -Fg20 -Gtmp/tmp2.grd
grdfilter tmp/tmp1.grd $type $smooth $increment -R$va -Gtmp/tmp2.grd
#grdfilter tmp/tmp1.grd -D{$type:2} -F{$smooth:2} -I{$increment:2} -Gtmp/tmp2.grd
grdcontour tmp/tmp2.grd $scale -C0.5 -L0.1/0.9 -Dtmp/contour1.xyz -m > /dev/null

num_count=`grep -n '>' tmp/contour1.xyz | wc -l`

if [ $num_count = 1 ]; then
	awk 'NR>1 {print $1,$2}' tmp/contour1.xyz > $contour_file
	awk 'NR==2 {print $1,$2}' tmp/contour1.xyz >> $contour_file	
else
	val=`grep -n '>' tmp/contour1.xyz | awk -F: 'NR==2 {print $1-1}'`
	awk -v val=$val 'NR>1 && NR<=val {print $1,$2}' tmp/contour1.xyz > $contour_file
	awk 'NR==2 {print $1,$2}' tmp/contour1.xyz >> $contour_file
fi

### Remove temp_files

#rm -f tmp/tmp.grd
#rm -f tmp/tmp1.grd
#rm -f tmp/tmp2.grd
#rm -f tmp/contour1.xyz