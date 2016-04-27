#!/usr/bin/env python

import numpy as np
import sys

ndk_file=sys.argv[1]
#ndk_file='/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Data/jan76_dec10.ndk'

fic=open(ndk_file)
lines=fic.readlines()

line_count=1

for line in lines:
	A=line.split()
	if line_count==1:
		if line[0]==' ':
			A.insert(0,'L')
		date1=A[1].split('/')
		date2=A[2].split(':')
		year=int(date1[0])
		month=int(date1[1])
		day=int(date1[2])
		hour=int(date2[0])
		min=int(date2[1])
		sec=float(date2[2])
		lat=float(A[3])
		lon=float(A[4])
		depth=float(A[5])
	elif line_count==4:
		exponent=int(A[0])
		#print exponent
	elif line_count==5:
		#print A[10]
		m0=float(A[10])*10**exponent
		#print m0
		mag=(np.log10(m0)-16.1)/1.5
		str=float(A[11])
		dip=float(A[12])
		rake=float(A[13])
		print '%4i-%02i-%02i-%02i-%02i-%05.2f %9.3f %9.3f %6.2f %6.1f %6.1f %6.1f %3.1f' %(year,month,day,hour,min,sec,lon,lat,depth,str,dip,rake,mag)
		line_count=0
	line_count=line_count+1
		
		

fic.close()