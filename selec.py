#!/usr/bin/env python

### Program made to select some events from the event.dat or event.sel files (which are outputs of ph2dt)

import os
import glob
import re
import sys
from datetime import date
from time import mktime

#################################################################

#filein='event.dat'
#fileoi='event_out.sel'
filein=sys.argv[1]
fileou=sys.argv[2]

#########################
# User defined parameters

fin=open(filein,'r')
fou=open(fileou,'w')
rms_lim=[]
only_located=True
depth_lim=100
lon_range=[166,167.75]
lat_range=[-16.5,-15]
sdate=[2008,04,01]
edate=[2010,04,01]

#########################
# Assign defaults
if not rms_lim:
	rms_lim=999
if not depth_lim:
	depth_lim=9999
if not lon_range:
	lon_range=[-180,180]
if not lat_range:
	lat_range=[-90,90]
if not sdate:
	sdate=[0,0,0]
if not edate:
	edate=[3000,0,0]	

start_time=mktime(date(sdate[0],sdate[1],sdate[2]).timetuple())
end_time=mktime(date(edate[0],edate[1],edate[2]).timetuple())

cond_stat='start_time < current_time < end_time and \
rms < rms_lim and depth < depth_lim and lat_range[0]< lat < lat_range[1] and \
lon_range[0] < lon < lon_range[1]'

if only_located:
	cond_stat_next=' and float(A[2])!=0 and float(A[3])!=0 and float(A[4])!=0'
	cond_stat=cond_stat+cond_stat_next 
	
#########################
k=0

for line in fin:
	A=line.split()
	# assign variables
	date_rec=A[0]
	year=int(date_rec[0:4])
	month=int(date_rec[4:6])
	day=int(date_rec[6:8])
	rms=float(A[-2])
	depth=float(A[4])
	lat=float(A[2])
	lon=float(A[3])
	# convert time
	objd= date(year,month,day)
	current_time=mktime(objd.timetuple())
	# define conditions
	if eval(cond_stat):
		k=k+1
		fou.write(line)

print 'Parameters used are:'
print ' longitude range: %s \n \
latitude range: %s \n \
depth limit: %.3f \n \
starting date: %s \n \
ending date: %s \n \
rms: %.2f \n \
total number of events selected: %i' % (lon_range,lat_range,depth_lim,sdate,edate,rms_lim,k)



sys.exit()