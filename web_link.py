#!/usr/bin/env python

import os
import re
import sys
import numpy as np
from script import *


cc_file='07_dt_out.cc'
ev_file='event_select.dat'
out_file='web_link.xyz'
GMT_file='GMT.sh'
scale_fac=10
lim_obs=4

#---- Make dictionary from event.dat file

f1=open(ev_file,'r')
dic_ev={}
for line in f1:
	A=line.split()
	index_ev=int(A[-1])
	lon,lat,depth=float(A[3]),float(A[2]),float(A[4])
	dic_ev[index_ev]=[lon,lat,depth]
	#print dic_ev[10][0]

f1.close()

#---- Get the pair in dt file

f2=open(cc_file,'r')
lines=f2.readlines()

number_line=[]
nobs=[]

for i,line in enumerate(lines):
	if line[0]=='#':
		number_line.append(i)

C=np.diff(number_line)-1
nobs=list(C)
nobs.append(len(lines)-number_line[-1]-1)
#print nobs

#--- Edit colormap

os.system('makecpt -Cpolar -I -T-30/25/1 > tmp/color.cpt')
f4=open('tmp/color.cpt','r')
dic_color={}
for line in f4:
		if line[0]=='B':
			break
		elif line[0]=='#':
			continue
		else:
			A=line.split()
			dic_color[int(A[0])]='%i/%i/%i' % (int(A[1]),int(A[2]),int(A[3]))
			

#------ Write into web file

f3=open(out_file,'w')
f2.seek(0,0)
k=0
l=0
for i,line in enumerate(f2):
	if line[0]=='#':
		A=line.split()
		index1,index2=int(A[1]),int(A[2]) 
		list1=dic_ev[index1]
		list2=dic_ev[index2]
		#print nobs[k]
		if float(nobs[k])<lim_obs:
			k=k+1
			continue
		else:
			l=l+1
			if nobs[k]>24:
				nobs[k]=24
			number_obs=float(nobs[k])/10
			#print type(number_obs)
			f3.write('> -W%-.2fpt,%s\n' % (number_obs,dic_color[int(nobs[k])]))
			#f3.write('> -W%-.2fpt,255\n' % (number_obs))
			f3.write('%-9.3f %9.3f %8.2f\n' %(list1[0],list1[1],list1[2]))
			f3.write('%-9.3f %9.3f %8.2f\n' %(list2[0],list2[1],list2[2]))
			k=k+1

f3.close()	
f2.close()

#-------- Write GMT

title='Links between event pairs (CC catalog, %i pairs with obs > %i)' % (l,lim_obs)
write_GMTblock(GMT_file,'plot.ps')
f2=open(GMT_file,'a')
f2.write('psxy %s -J -R -M -B:.\"%s\": -O -K >> %s \n' % (out_file,title,'plot.ps'))
f2.write('grdcontour $grid -J -R -Ctmp/contour.out -O -K >> %s \n' % 'plot.ps')
f2.write('psxy tmp/stations.xyz $scalerange $stationsymbol -O -K >> %s \n' % 'plot.ps')
f2.close()

os.system('bash '+GMT_file)
os.system('ps2pdf plot.ps plot.pdf')
os.system('open plot.pdf')
 

