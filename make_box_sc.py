#!/usr/bin/env python

import os
import glob
import sys
from random import gauss
import numpy as np
from proj_cov import *

'Function made to create a file with box and profile coordinates'
' azi is in degree ( clockwise from north), len_prof and width_prof in km, center is a string of'
" the form 'lon0/lat0' , box_file is the ouput filename"

######## Set Conditions

if len(sys.argv) < 6:
	print 'Enter at least 4 arguments'
	sys.exit()

text_file=None
number=None

###### Assign arguments
	
azi=float(sys.argv[1])
#len_prof=float(sys.argv[3])
L1=float(sys.argv[3])
L2=float(sys.argv[4])
width_prof=float(sys.argv[5])
center=sys.argv[2]
box_file=sys.argv[6]

if len(sys.argv) > 7:
	text_file=sys.argv[7]
if len(sys.argv) > 8:
	number=float(sys.argv[8])

print text_file
	
center=center.strip()


sh=5
# Parameters
# Get lon0/lat0 from center parameter
lon=eval(center[:center.find('/')])
lat=eval(center[center.find('/')+1:])

#azi=45
#len_prof=100
#width_prof=50
#center='167.25/-15'
#box_file='box.xy'

# Define box_coordinates

azi_rad=azi*np.pi/180
beta=np.pi/2-azi_rad
P1=np.array([L2 * np.cos(beta), L2 * np.sin(beta)])
P2=np.array([-L1 * np.cos(beta), -L1 * np.sin(beta)])

C1=np.array([-width_prof/2 * np.sin(beta), width_prof/2 * np.cos(beta)])
C2=np.array([width_prof/2 * np.sin(beta), -width_prof/2 * np.cos(beta)])
A1=P1+C1
A2=P1+C2
A3=P2+C2
A4=P2+C1


#	T1=-np.array([(len_prof-sh)/2 * np.cos(beta), (len_prof-sh)/2 * np.sin(beta)])
#	D1=np.array([-(width_prof-sh)/2 * np.sin(beta), (width_prof-sh)/2 * np.cos(beta)])
#	D2=np.array([(width_prof-sh)/2 * np.sin(beta), -(width_prof-sh)/2 * np.cos(beta)])
#	B4=T1+D1

if text_file!=None and number!=None:
	f2=open('tmp.txt','w')
	f2.write('%10.2f %10.f 10 2 0 CM %-.0f\n' %(A4[0],A4[1],number))
	f2.close()
	os.system('mapproject tmp.txt -Jt%s/1 -R%-.2f/%-.2f/%-.2f/%-.2f -I -Fk -C > %s' %(center,lon-1,lon+1,lat-1,lat+1,text_file))
	

f1=open('tmp.txt','w')
f1.write('%10.2f %10.f\n' %(P1[0],P1[1]))
f1.write('%10.2f %10.f\n' %(P2[0],P2[1]))
f1.write('%10.2f %10.f\n' %(A1[0],A1[1]))
f1.write('%10.2f %10.f\n' %(A2[0],A2[1]))
f1.write('%10.2f %10.f\n' %(A3[0],A3[1]))
f1.write('%10.2f %10.f\n' %(A4[0],A4[1]))
f1.close()

os.system('mapproject tmp.txt -Jt%s/1 -R%-.2f/%-.2f/%-.2f/%-.2f -I -Fk -C > tmp2.txt' %(center,lon-1,lon+1,lat-1,lat+1))
#print 'mapproject tmp.txt -Jt%s/1 -R%-.2f/%-.2f/%-.2f/%-.2f -I -Fk -C > tmp2.txt' %(center,lon-1,lon+1,lat-1,lat+1)
f1=open('tmp2.txt','r')
f2=open(box_file,'w')

lines=f1.readlines()
f2.write('> %s\n' % '-W1p,black')
Coor=[]
for i in range(2,6):
	D=lines[i].split()
	list1 = [float(list_item) for list_item in D] 
	Coor.append(list1)
	f2.write('%s' % lines[i])
f2.write('> %s\n' % '-W2p,black')
f2.write(lines[0])
f2.write(lines[1])
f1.close()
f2.close()

f1=open('tmp3.txt','w')
f1.write(lines[0])
f1.write(lines[1])
f1.close()

os.system("sample1d tmp3.txt -Fl -I0.001 > track.xy")

os.remove('tmp.txt')
os.remove('tmp2.txt')
os.remove('tmp3.txt')

