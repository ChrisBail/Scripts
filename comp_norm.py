#!/usr/bin/env python
# See Stein and WYrsession for details

import numpy as np

def comp_norm(STR,DIP,RAKE):
	print STR,DIP,RAKE
	# convert angle to degrees
	
	STR=STR*np.pi/180
	DIP=DIP*np.pi/180
	RAKE=RAKE*np.pi/180
	#print STR,DIP,RAKE
	
	nx=np.sin(DIP)*np.cos(STR)
	ny=-np.sin(DIP)*np.sin(STR)
	nz=np.cos(DIP)
	#print np.linalg.norm(np.array([nx,ny,nz]))
	# nz is always positive but that's not the case for dz
	
	dx=np.cos(RAKE)*np.sin(STR)-np.sin(RAKE)*np.cos(DIP)*np.cos(STR)
	dy=np.cos(RAKE)*np.cos(STR)+np.sin(RAKE)*np.cos(DIP)*np.sin(STR)
	dz=np.sin(RAKE)*np.sin(DIP)
	#print np.linalg.norm(np.array([dx,dy,dz]))
	#print dx*nx+dy*ny+dz*nz
	
	if dz<0:
		dx=-dx
		dy=-dy
		dz=-dz
	
	
	az_n=np.arctan2(nx,ny)*180/np.pi
	phi_n=np.arctan2(np.sqrt(nx**2+ny**2),nz)*180/np.pi
	
	az_d=np.arctan2(dx,dy)*180/np.pi
	phi_d=np.arctan2(np.sqrt(dx**2+dy**2),dz)*180/np.pi
	
	return [az_n,phi_n],[az_d,phi_d]