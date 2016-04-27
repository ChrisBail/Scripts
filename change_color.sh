#!/usr/bin/env bash

filein=$1 
mini=$2
maxi=$3
#filein='ETOPO1.cpt'
#filein='earthquake.cpt'

#mini=0
#maxi=100
num_line=$(sed '/#/d' $filein | sed '/^$/d' | awk 'NF==8 {print $0}' | wc -l)

num_line=$(( $num_line + 1 ))
arrayna=($( linspace $mini $maxi $num_line ))

k=0
while read line
do
	if [ "${line:0:1}" == "#" ]  || [ "${line:0:1}" == "F" ]  || [ "${line:0:1}" == "N" ]  || [ "${line:0:1}" == "B" ]; then
		echo $line
	elif [ "${line:0:1}" == "" ]; then
		continue
	else
		start=${arrayna[$k]} 
		stopi=${arrayna[$k+1]}
		var=$(echo $line | awk -v star=$start -v stopa=$stopi '{print star,$2,$3,$4,stopa,$6,$7,$8}' )
		echo $var
		k=$(( $k + 1 ))
	fi
done < $filein