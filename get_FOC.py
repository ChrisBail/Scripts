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

##### Create directory to put temp_files

tmp_dir='tmp/'
if not os.path.exists(tmp_dir):
    os.makedirs(tmp_dir)
    print 'No %s directory, Creating one\n' %tmp_dir

##### Create directory to put files created

output_dir='temp_MECA/'
if not os.path.exists(output_dir):
    os.makedirs(output_dir)
    print 'No %s directory, Creating one\n' %output_dir

##### Open Table file

f_table=open('run_MECA.tbl','w')
f_table.write('Cluster# lon lat depth num_polarities STR DIP RAKE error_F error_A pol_mis STDR\n')

###### Get file

index_file=sys.argv[1]

###########################################
###### Split index file

cmd='split_INDEX.py %s' %index_file
os.system(cmd)
list_index=glob.glob('index*[0-9][0-9][0-9][0-9].out')
print list_index

#######  Start loop in index files

for file in list_index:

	event_number=int(file[-8:-4])

	###### Compute Focal Mechanism

	##### Run HASH 1st time to get number of polarity pspolar.inp

	print 'running HASH 1st time to get number of polarities'
	run_HASH('./'+file,parameter=None)

	##### Read hyp.out to get lon/lat/depth of event
	
	cmd='nor2xyz hyp.out > tmp/temp_hyp.xyz' 
	os.system(cmd)

	fat=open('tmp/temp_hyp.xyz','r')
	for line in fat:
		B=line.split()
		lon=float(B[0])
		lat=float(B[1])
		depth=float(B[2])
		print lon,lat,depth
	fat.close()
	os.remove('tmp/temp_hyp.xyz')
	
	######
	
	os.system('read_FOCMEC.py focmec.dat')

	f_scratch=open('foc_polar.out','r')
	total_pol=len(f_scratch.readlines())
	f_scratch.close()
	print 'Total number of polarities: %i \n' %total_pol

	if total_pol!=0:

		#### RUN HASH 2nd time with correct parameter
		#### Define parameters for HASH

		grid_angle=5
		max_pol_error=np.floor(0.1*total_pol)
		max_amp_error=2
		angle_meca_prob=60
		prob_mul=0.1
		print 'running HASH 2nd time'
		run_HASH('./'+file,[grid_angle,max_pol_error,max_amp_error,angle_meca_prob,prob_mul])

		#### Get mechanisms and auxiliary Plane and copy them

		display='Reading hash_seisan.out and copying files to %s\n' %output_dir
		print display
		os.system('read_HASH.py hash_seisan.out')
		os.system('read_FOCMEC.py focmec.dat')
		shutil.copy('mec_hash.out',output_dir+'mec_hash%04d.out'%event_number)
		shutil.copy('norm_planes.out',output_dir+'norm_planes%04d.out'%event_number)
		shutil.copy('foc_polar.out',output_dir+'foc_polar%04d.out'%event_number)
		shutil.copy('foc_amp.out',output_dir+'foc_amp%04d.out'%event_number)
		shutil.copy('hash_seisan.out',output_dir+'hash_seisan%04d.out'%event_number)

		#### Plot focal Mechanism 

		display='Plot focal mechanism'
		print display

	
		os.system("plot_MECA.sh foc_polar.out foc_amp.out mec_hash.out %s/focmec%04d.pdf 'Event %i'" %(
		output_dir,event_number,event_number))

	#### Create Table in a xyz format resuming focmec errors....

	# Read 'resum_read.out' made by read_HASH.py and write into run_MECA.tbl

	display='Make resume into run_MECA.tbl'
	print display
	foc=open('resum_read.out','r')
	lines=foc.readlines()
	foc.close()
	if total_pol==0:
		lines=[]
	
	for index,line in enumerate(lines):
		if index==0:
			continue
		f_table.write('%i %8.3f %8.3f %7.2f %5i %s' %(
		event_number,lon,lat,depth,total_pol,line))


os.system('rm -f index*[0-9][0-9][0-9][0-9].out')
	