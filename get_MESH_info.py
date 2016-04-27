#!/usr/bin/env python

from __future__ import division
from ang2ell import *
import numpy as np
import glob

def main():

	# Parameter
	
	cat_file='orientation_mesh.out'
	limit=0.1
	f_cat=open(cat_file,'w')
	f_cat.write('Cluster lon lat depth AZ PH ratio\n')
	mesh_path='/Users/baillard/_Moi/Programmation/Matlab/Cluster_Orientation/tmp/'
	mesh_files=glob.glob(mesh_path+'mesh_cluster*.out')
	for mesh_file in mesh_files:
		clus_number=int(mesh_file[-8:-4])
		AZ,PH,ratio,lon,lat,depth=get_MESH(mesh_file,limit)
		f_cat.write('%4i %9.3f %9.3f %8.2f %5.1f %5.1f %4.2f\n' %(
		clus_number,lon,lat,depth,AZ,PH,ratio))
	
	f_cat.close()
	orientation2ellipses(cat_file);

def get_MESH(mesh_file,limit):
	#mesh_file='tmp/mesh_cluster0003.out'
	#limit=0.1


	foc=open(mesh_file,'r')
	lines=foc.readlines()
	foc.close()

	AZ=[]
	PH=[]
	DE=[]

	for index,line in enumerate(lines):
		if index==0:
			A=line.split()
			lon=float(A[0])
			lat=float(A[1])
			depth=float(A[2])
			continue
		A=line.split()
		AZ.append(float(A[0]))
		PH.append(float(A[1]))
		DE.append(float(A[2]))
	
	AZ=np.array(AZ)
	PH=np.array(PH)
	DE=np.array(DE)

	# Get stat

	ratio=1-len(DE[DE>=limit])/len(DE)
	AZ_max=AZ[DE==max(DE)]
	PH_max=PH[DE==max(DE)]

	AZ_max=AZ_max[0]
	PH_max=PH_max[0]

	return AZ_max,PH_max,ratio,lon,lat,depth
	
def orientation2ellipses(file_or);

	#file_or='orientation_mesh.out'
	file_ell='ellipses.out'

	f_ell=open(file_ell,'w')
	f_ell.write('Cluster lon lat depth teta major minor ratio\n')

	f_or=open(file_or,'r')
	lines=f_or.readlines()
	f_or.close()

	n=[0,0,1]

	for index,line in enumerate(lines):
		if index==0:
			continue
		A=line.split();
		clus,lon,lat,depth,AZ,PH,ratio=[float(x) for x in A]

		####### Convert AZ, PH to teta major minor depending on projection normal
		# teta counted from E, or horizontal plane
		teta,major,minor=ang2ell(AZ,PH,n)
	
		##### Indicate if normal point to EST(0) or WEST(1)
		if AZ>=0 and AZ<180:
			indic=0
		else:
			indic=1
	
		###### Write into file
		f_ell.write('%4i %9.3f %9.3f %8.2f %7.1f %5.2f %5.2f %4.2f %i\n' %(
		clus,lon,lat,depth,teta,major,minor,ratio,indic))
	
	
	

if __name__ == "__main__":
    main()