#!/usr/bin/env python

### add_noise

import os
import glob
import sys
from random import gauss
import numpy as np
from proj_cov import *

def proj_xyz(n,file_cov,output_file,option_cov=None):
	''' Program that outputs x,y,z,teta,semi-major,semi-minor from a x,y,z,cxx,cyy,czz,cxy,cxz,cyz
	file (generally given by a nor2cov process). option_cov specifies if COV is given in the non-direct basis Oxyz but z downward.
	n is the viewpoint in the Oxyz direct basis (z upward). You don't care if z is negative in the 3rd column as it only copies this column'''

	#file_cov='test.xyz'
	#output_file='proj_ellipse.xyz'
	f1=open(file_cov,'r')
	f2=open(output_file,'w')
	#n=[0,0,-1]

	lines=f1.readlines()

	for line in lines:
		A=line.split()
		if len(A)!=9:
			f2.write('-999\n')
			continue
		# Assigne COV matrix
		COV=np.zeros((3,3))
		COV[0,0]=A[3]
		COV[1,1]=A[4]
		COV[2,2]=A[5]
		COV[0,1]=A[6]
		COV[0,2]=A[7]
		COV[1,2]=A[8]
		COV=COV+np.transpose(np.triu(COV,1))
		
		#### If Z is positive down then multiply by special matrix
		
		if option_cov != None:
			M=np.array([[1,1,-1],[1,1,-1],[-1,-1,1]])

			COV=COV*M
		
		teta,semi_major,semi_minor=proj_cov(n,COV)
		#print teta
		f2.write('%9s %9s %7s %6.1f %7.2f %7.2f\n' %(A[0],A[1],A[2],teta,semi_major,semi_minor))
		

	f1.close()
	f2.close()
