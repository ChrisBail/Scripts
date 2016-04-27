#!/usr/bin/env python

import sys

filein=sys.argv[1]
#filein='/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Data/EHB_raw.txt'
fic=open(filein)
lines=fic.readlines()

for line in lines[1:]:
	A=[x.strip() for x in line.split(',')] # split and strip
	#[x.strip() for x in my_string.split(',')]
	year=int(A[2][0:4])
	month=int(A[2][5:7])
	day=int(A[2][8:10])
	hour=int(A[3][0:2])
	min=int(A[3][3:5])
	sec=float(A[3][6:11])
	
	lat=float(A[4])
	lon=float(A[5])
	depth=float(A[6])
	if 'Mw' in A:
		indic=A.index('Mw')
		type='Mw'
	elif 'Ms' in A:
		indic=A.index('Ms')
		type='Ms'
	elif 'mb' in A:
		indic=A.index('mb')
		type='mb'
	else:
		continue
	print '%4i-%02i-%02i-%02i-%02i-%05.2f %9.3f %9.3f %6.2f %3.1f %s' %(year,month,day,hour,min,sec,lon,lat,depth,float(A[indic+1]),type)


fic.close()