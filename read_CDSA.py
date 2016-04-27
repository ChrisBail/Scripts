#!/usr/bin/env python

import os
import re
import sys
import numpy as np

filein=sys.argv[1]
#filein='/Users/baillard/_Moi/Programmation/Matlab/Picking_Plane/Data/EHB_raw.txt'
fic=open(filein)
lines=fic.readlines()

for line in lines:

	A=[x.strip()  for x in line.split('|')] # split and strip

	# Skip header line
	if A[0]=='id_cdsa':
		continue

	year=int(A[1][0:4])
	month=int(A[1][5:7])
	day=int(A[1][8:10])
	hour=int(A[2][0:2])
	min=int(A[2][3:5])
	sec=float(A[2][6:11])
	
	lat=float(A[4])
	lon=float(A[5])
	depth=float(A[6])
	mag=float(A[7])
	print '%4i-%02i-%02i-%02i-%02i-%05.2f %9.3f %9.3f %6.2f %3.1f' %(year,month,day,hour,min,sec,lon,lat,depth,mag)


fic.close()