#!/bin/bash
# Script to autoreg all base from one date to another
# Specitfy basereg and starttime endtiem
homepath=$PWD

echo "Enter REA base name"
read basereg
echo "Enter start time yyyymm:"
read starttime
echo "Enter end time yyyymm:"
read endtime
echo "Enter user ID"
read userid

startyear=${starttime:0:4}
echo $startyear
startmonth=${starttime:4:2}
echo ${startmonth}

endyear=${endtime:0:4}
endmonth=${endtime:4:2}
echo ${endmonth}

for (( year=$startyear; year<=$endyear; year++ ))
	do
	stopmonth=12;
	begmonth=1
		if [ "${year}" == "${endyear}" ];then
		stopmonth="$(echo $endmonth | sed 's/0*//')"
		elif [ "${year}" == "${startyear}" ];then
		begmonth="$(echo $startmonth | sed 's/0*//')"
		fi
		
	for (( month=$begmonth; month<=$stopmonth; month++ ))
	do
		tt=$(printf "%02d\n" $month)
		cd $year/$tt
dirf *MSEED
autoreg << END
L
n
$basereg
$userid
A
y
END
		cd $homepath
		
	done
	done
	
