#!/usr/bin/env python

##### Precision
# files 
##### Import Modules

import glob
import os
import sys
import shutil
import numpy as np
from run_HASH import *

##### Input Parameters

##### Create directory to put files created

output_dir='temp_MECA/'
if not os.path.exists(output_dir):
    os.makedirs(output_dir)
    print 'No %s directory, Creating one\n' %output_dir

##### Get list of index_files

curr_path=os.getcwd()
data_path='/Volumes/donnees/SE_DATA/WOR/CHRIS/HYPODD/ALL_DATA/FOCMEC/'
mesh_path='/Users/baillard/_Moi/Programmation/Matlab/Cluster_Orientation/tmp/'
os.chdir(data_path)
list_index=glob.glob('index*[0-9][0-9][0-9][0-9].out')
os.chdir(curr_path)

##### Open log file

f_log=open('run_MECA.log','w')
f_log.write('This is a log file containing all info about run_MECA.py run\n')

##### Open Table file

f_table=open('run_MECA.tbl','w')
f_table.write('Cluster# lon lat depth num_polarities STR DIP RAKE error_F error_A pol_mis STDR\n')

##### Go through each index_file in a loop

for index_file in list_index:
	
	clus_number=int(index_file[-8:-4])
	f_log.write('Processing Cluster %i associated with file %s\n' %(clus_number,index_file))
	if clus_number>22:
		continue
		
	##### Run HASH 1st time to get number of polarity pspolar.inp
	
	print 'running HASH for cluster number %i' %clus_number
	run_HASH(data_path+index_file,parameter=None)
	os.system('read_FOCMEC.py focmec.dat')

	f_scratch=open('foc_polar.out','r')
	total_pol=len(f_scratch.readlines())
	f_scratch.close()
	f_log.write('Total number of polarities: %i \n' %total_pol)
	
	print total_pol
	if total_pol!=0:
	
		#### RUN HASH 2nd time with correct parameter
		#### Define parameters for HASH
	
		grid_angle=5
		max_pol_error=np.floor(0.1*total_pol)
		max_amp_error=2
		angle_meca_prob=60
		prob_mul=0.1
		run_HASH(data_path+index_file,[grid_angle,max_pol_error,max_amp_error,angle_meca_prob,prob_mul])
	
		#### Get mechanisms and auxiliary Plane and copy them
	
		display='Reading hash_seisan.out and copying files to %s\n' %output_dir
		print display
		f_log.write(display)
		os.system('read_HASH.py hash_seisan.out')
		os.system('read_FOCMEC.py focmec.dat')
		shutil.copy('mec_hash.out',output_dir+'mec_hash%04d.out'%clus_number)
		shutil.copy('norm_planes.out',output_dir+'norm_planes%04d.out'%clus_number)
		shutil.copy('foc_polar.out',output_dir+'foc_polar%04d.out'%clus_number)
		shutil.copy('foc_amp.out',output_dir+'foc_amp%04d.out'%clus_number)
		shutil.copy('hash_seisan.out',output_dir+'hash_seisan%04d.out'%clus_number)
	
		#### Plot focal Mechanism 
	
		display='Plot focal mechanism\n'
		print display
		f_log.write(display)
		
		os.system("plot_MECA.sh foc_polar.out foc_amp.out mec_hash.out %s/focmec%04d.pdf 'Cluster %i'" %(
		output_dir,clus_number,clus_number))

	#### Get Diagram
	
	#### Retrieve proper mesh_file in the mesh directory
	
	mesh_file=mesh_path+'mesh_cluster%04d.out' %clus_number
	if not os.path.isfile(mesh_file):
		display='No mesh_cluster%04d.out found, Diagram will not be plotted' %clus_number
		print display
		continue
	
	#### Plot Diagram
	
	if total_pol!=0:
		os.system('plot_DIAGRAM.sh %s %i norm_planes.out' %(mesh_file,clus_number))
	else:
		os.system('plot_DIAGRAM.sh %s %i no_file.out' %(mesh_file,clus_number))
	shutil.move('Plot_Polar_Cluster.pdf',output_dir+'Plot_Polar_Cluster%04d.pdf' %clus_number)
	
	#### Create Table in a xyz format resuming focmec errors....
	
	# Read 'resum_read.out' made by read_HASH.py and write into run_MECA.tbl
	
	display='Make resume into run_MECA.tbl'
	print display
	foc=open('resum_read.out','r')
	lines=foc.readlines()
	foc.close()
	if total_pol==0:
		lines=[]
	if not os.path.isfile(mesh_file):
		lon=999
		lat=999
		depth=999
	foc=open(mesh_file,'r')
	for line in foc:
		A=line.split()
		lon,lat,depth=float(A[0]),float(A[1]),float(A[2])
		break
	foc.close()	
	
	for index,line in enumerate(lines):
		if index==0:
			continue
		f_table.write('%i %8.3f %8.3f %7.2f %5i %s' %(
		clus_number,lon,lat,depth,total_pol,line))
		
	##### Generate file for Plotting focal Mechanism on Map
	if clus_number==20:
		break
		

##### Closing all files

f_log.close()
f_table.close()