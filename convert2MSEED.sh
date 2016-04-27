#!/bin/bash

homepath=$PWD
basereg=RLUCK
#echo "Enter start time yyyymm:"
#read starttime
#echo "Enter end time yyyymm:"
#read endtime

starttime="200909"
endtime="200912"
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
		stopmonth=$endmonth
		elif [ "${year}" == "${startyear}" ];then
		begmonth=$startmonth
		fi
	for ((month=$(printf "%2d\n" $begmonth);month<=$(printf "%2d\n" $stopmonth);month++))
	do
		tt=$(printf "%02d\n" $month)
		cd $year/$tt

		dirf *S.L*
wavetool << END
filenr.lis


MSEED

END
dirf *MSEED
autoreg << END
L
n
$basereg
chb
END
		cd $homepath
		
	done
	done
	
