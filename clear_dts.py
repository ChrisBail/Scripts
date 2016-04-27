#!/usr/bin/env python

### Program made to reindex what is in the total_dtcc.out according to index given by index.out
### Each index is assigned according to its sfile_name

import os
import glob
import re
import sys

#################################################################
# read index.out and put it in lists index_num and sfile_name


file_dat='event_select.dat'
file_cc='final_dt.cc'
file_ct='dt.ct'

f_dat=open(file_dat,'r')
f_cc=open(file_cc,'r')
f_ct=open(file_ct,'r')

f_ct_out=open('dt_out.ct','w')
f_cc_out=open('dt_out.cc','w')

event_index=[]

for line in f_dat:
	A=line.split()
	event_index.append(int(A[-1]))

#for line in f_ct:
#	if line[0]!='#' and flag_write:
#		f_ct_out.write(line)
#	elif line[0]=='#':
#		flag_write=False
#		A=line.split()
#		if int(A[1]) in event_index and int(A[2]) in event_index:
#			f_ct_out.write(line)
#			flag_write=True

for line in f_cc:
	if line[0]!='#' and flag_write:
		f_cc_out.write(line)
	elif line[0]=='#':
		flag_write=False
		A=line.split()
		if int(A[1]) in event_index and int(A[2]) in event_index:
			f_cc_out.write(line)
			flag_write=True
		
