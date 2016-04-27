#!/usr/bin/env python

import sys
import os
import numpy as np
import time

def merge_DD_nor(file1,file2,fileo):

	#file1='collect_CLUS_fixed.out'
	#file2='hypoDD_BEST.reloc'
	#fileo='collect_update.out'

	# check if temp directory exists

	if not os.path.exists('tmp'):
		os.makedirs('tmp')
	
	# Convert hypoDD to catalog
	os.system('hypoDD2xyz %s > tmp/%s' %(file2,'temp.out'))

	# Write into the new collect_file

	f1=open(file1,'r')
	fo=open(fileo,'w')
	f2=open('tmp/temp.out','r')
	lines_dd=f2.readlines()
	f2.close()
	lines=f1.readlines()
	f1.close()
	count=0;

	for line in lines:
		if line[-2]!='1':
			if line[-2]!='3':
				fo.write('%s' %line)
		else:
			A=lines_dd[count].split()
			count=count+1
			lon=float(A[0])
			if np.isnan(lon):
				fo.write('%s' %line)
				continue
			
			# Read line
			lat=float(A[1])
			depth=float(A[2])
			times=A[3];
			year=int(times[0:4])
			month=int(times[5:7])
			day=int(times[8:10])
			hour=int(times[11:13])
			min=int(times[14:16])
			sec=float(times[17:])

			# Assign to header
			header=list(line)
			header[1:5]='%4i' %year
			header[6:8]='%2i' %month
			header[8:10]='%2i' %day
			header[11:13]='%02d' %hour
			header[13:15]='%2i' %min
			header[16:20]='%4.1f' %sec
			header[23:30]='%7.3f' %lat
			header[30:38]='%8.3f' %lon
			header[38:43]='%5.1f' %depth
		
			new_header=''.join(header)	
			fo.write('%s' %new_header)
			# Add type 3 line comment
			line_3=list('%80c' %' ')
			line_3[-1]='3'
			now=time.localtime(time.time())
			dat=time.asctime(now)
			st='Relocalised event: Added to database on %s' %dat
			line_3[1:len(st)+1]=st
			nline_3=''.join(line_3)	
			fo.write('%s\n' %nline_3)
		
	fo.close()

