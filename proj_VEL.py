#!/usr/bin/env python

import numpy as np
import os
import sys
import shutil

''' Program made to project velocities onto profile
Input	$1 > velocity file
		$2 > profile center
		$3 > angle of profile (CW from north)
		$4 > total Width in km
Output 	to standard output that represents projected file
Example 'proj_VEL.py clean_vel.gmt 166.806/-16.068 85 80 > test.gmt
'''
#filein='clean_vel.gmt'
#centerpro='166.806/-16.068'
#angle_prof=70 # CW from North
#W_p=80

### Parameters

filein=sys.argv[1]
centerpro=sys.argv[2]
angle_prof=float(sys.argv[3])
W_p=float(sys.argv[4])
L_p=500

### Create temp directory

if not os.path.exists('tmp'):
    os.makedirs('tmp')

### Project using GMT command

cmd='project %s -C%s -A%.1f -Qk -Fpqz -L-%.1f/%.1f -W-%.1f/%.1f > tmp/scratch.xyz' %(filein,centerpro,angle_prof,L_p/2.0,L_p/2.0,W_p/2.0,W_p/2.0)
os.system(cmd)

### Project velocity x et y in the profile basis

### Define rotation matrix

angle=(90-angle_prof)*(np.pi)/180

R=[[np.cos(angle),-np.sin(angle)],[np.sin(angle),np.cos(angle)]]

### Print to standard output
fic=open('tmp/scratch.xyz','r')

for line in fic:
	
	C=line.split()
	A=[float(x) for x in C[:-1]]
	velx=float(A[2])
	vely=float(A[3])
	ex=float(A[4])
	ey=float(A[5])
	vel=np.array([velx,vely])
	e=np.array([ex,ey])
	new_vel=np.dot(np.linalg.inv(R),np.transpose(vel))
	new_e=np.dot(np.linalg.inv(R),np.transpose(e))
	
	### Print into new_file
	
	print '%8.2f %8.2f %8.3f %8.3f %7.3f %7.3f %7.3f %s' %(A[0],A[1],new_vel[0],new_vel[1],new_e[0],new_e[1],A[-1],C[-1])
	

fic.close()

os.remove('tmp/scratch.xyz')

