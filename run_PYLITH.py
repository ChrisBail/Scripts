#!/usr/bin/env python

import netCDF4
import sys
import numpy as np
import os
import shutil
from multiprocessing import Pool
import re

########### Main Prog

def main():

	#### Files

	patch_file=['patch_2_Thrust.dat']
	exo_file=['mesh_2_25_Thrust.exo']
	patch_dir='/Users/baillard/_Moi/Programmation/Pylith/Combination/'
	dirs=['Mesh_2_25_Thrust']
	patch_file=[patch_dir + x for x in patch_file]
	conv_rate1=[4,5,6] #np.arange(7,11,1)
	conv_rate2=[2,3,4,5]
	model_files=['model_2_Thrust.txt']

	#### Create temp directory
	for value in dirs:
		if not os.path.isdir('temp/'+value):
			os.makedirs('temp/'+value)
	
	#### Create temporary directory for pylith runs
	
	if not os.path.isdir('temporary'):
		os.makedirs('temporary')
		
	### Loop over Meshes

	for j in xrange(len(exo_file)):
		
		model=model_files[j]
		model_array=[]
		lines_mod=[]
		
		### Edit pylithapp.cfg
		
		os.system('change_EXO.py pylithapp.cfg %s > tmp.cfg' %exo_file[j])
		shutil.move('tmp.cfg','pylithapp.cfg')
		
		#### Loading patch

		patch=load_patch(patch_file[j])
	
		#sys.exit()
		#patch=[];
		#line='-3.742  -54.857       NaN       NaN     99.000      0.000    -63.389        NaN        NaN   -999.000'
		#A=line.split()
		#patch.append([float(x) for x in A])
			
		#### Edit Model list of arguments for multiproceesing
		
		mod_parameter=[]
		fmo=open(model,'w')
		count=0
		for value_vel1 in conv_rate1:
			for value_vel2 in conv_rate2:
				for aa,value_patch in enumerate(patch):
					mod_parameter.append([value_patch,value_vel1,value_vel2,count])
					fmo.write('%7.3f %7.3f %5.1f %5.1f\n' %(patch[aa][0],patch[aa][1],value_vel1,value_vel2))
					count=count+1
					
		fmo.close()
		

		##### Start Monte Carlo computation
			
		#print mod_parameter[0]
		#forward(mod_parameter[0])
		#sys.exit()
		p=Pool(6)
		p.map(forward,mod_parameter)
		
		### Copy files into proper directory
	
		#os.system('mv temporary/groundsurf0[0-5]* temp/%s/'%dirs[j])
		#os.system('mv temporary/groundsurf0[6-9]* temp/%s/'%dirs[j])
		os.system('mv temporary/groundsurf* temp/%s/'%dirs[j])
	

	
############  Functions
def write_intercfg(input_cfg,output_cfg,output_h5=None,output_dir=None,faultdb=None,velocity=None,total_time=None):
	'''
	Function made to change the fault spatiadb used in the interseismic.cfg file
	Input: 	input cfg file
			output cfg file
			faultdb file
			output h5 file
			velocity parameter
			total_time for run
	'''
	flag=0
	fic=open(input_cfg,'r')
	foc=open(output_cfg,'w')
	for line in fic:
		if 'writer.filename =' in line and flag==0:
			ind_pos=get_last('/',line)
			name_h5=line[ind_pos+1:]
			a='writer.filename = '+output_dir+'/'+name_h5
			foc.write(a+'\n')
			continue
		if 'slip_rate.iohandler.filename' in line:
			if faultdb!=None:
				foc.write('slip_rate.iohandler.filename = %s\n'%faultdb)
				continue
		if 'slip_rate.data' in line:
			if velocity!=None:
				foc.write('slip_rate.data = [%.1f*cm/year, 0.0*cm/year]\n'%(-velocity))
				continue
		if 'total_time' in line:
			if total_time!=None:
				foc.write('total_time = %.1f*year\n'%total_time)
				continue
		if '[pylithapp.problem.formulation.output.subdomain]' in line:
			flag=1
		if 'writer.filename =' in line and flag==1:
			if output_h5!=None:
				foc.write('writer.filename = %s/%s\n'%(output_dir,output_h5))
				flag=0
				continue
		foc.write(line)
	foc.close()
	fic.close()

def write_intercfg2(input_file,output_file,param):

	#param=[12,'fault1.spatialdb',-4.0,'fault2.spatialdb',3.0,'groundsurf.h5','sc/']
	
	#### Read input files
	foc=open(input_file,'r')
	lines=foc.readlines()
	foc.close()

	
	fic=open(output_file,'w')
	count=0
	ind=0
	while ind < len(lines):
		if lines[ind][0:8]=='## Param':
			fic.write(lines[ind])
			if count==0:
				fic.write('total_time = %0.1f*year\n'%param[0])
			elif count==1:
				fic.write('slip_rate.iohandler.filename = %s\n'%param[1])
			elif count==2:
				fic.write('slip_rate.data = [%0.1f*cm/year, 0.0*cm/year]\n'%param[2])
			elif count==3:
				fic.write('slip_rate.iohandler.filename = %s\n'%param[3])
			elif count==4:
				fic.write('slip_rate.data = [%0.1f*cm/year, 0.0*cm/year]\n'%param[4])
			elif count==5:
				fic.write('writer.filename = %s%s\n'%(param[6],param[5]))
			count=count+1;
			ind=ind+1;
		elif 'writer.filename =' in lines[ind]:
			line=lines[ind][:-1]
			ind_pos=get_last('/',line)
			name_h5=line[ind_pos+1:]
			fic.write('writer.filename = %s%s \n'%(param[6],name_h5))
		else:
			fic.write(lines[ind])
		ind=ind+1
	fic.close()

def forward(mod_parameter):

	# Get parameters
	
	patch2=[0,-50,float('NaN'), float('NaN'),99.000 , 10.000 ,-60 ,float('NaN'),float('NaN'),-999.000]
	print patch2
	patch=mod_parameter[0] # list
	velocity1=mod_parameter[1] # float
	velocity2=mod_parameter[2] # float
	num_model=mod_parameter[3] # int
	
	# Write faultdb
	
	faultdb1='fault1_%05d.spatialdb'%num_model
	write_spatialdb(faultdb1,patch,velocity1)
	faultdb2='fault2_%05d.spatialdb'%num_model
	write_spatialdb(faultdb2,patch2,-velocity2)
	
	# Write h5 output file and make dir for output
	
	dir_ou='output_%05d'%num_model
	if not os.path.exists(dir_ou):
		os.makedirs(dir_ou)
	output_h5='temp_groundsurf_%05d.h5'%num_model
	
	# Write  pylith cfg file ('interseismic.cfg')
	
	output_cfg='interseismic_%05d.cfg'%num_model
	param=[12,faultdb1,-velocity1,faultdb2,velocity2,output_h5,dir_ou+'/']
	
	write_intercfg2('interseismic_Thrust.cfg',output_cfg,param)
	#write_intercfg('interseismic_Thrust.cfg',output_cfg,output_h5=output_h5,output_dir=dir_ou,faultdb=faultdb,velocity=velocity,total_time=12)
	
	# Run pylith
	
	try:
		output_dir='temporary/groundsurf%05d.h5'%num_model
		os.system('pylith %s'%output_cfg)
		shutil.copy('%s/%s'%(dir_ou,output_h5),output_dir)
	except:
		print 'model %i did not processed' %(i+1)
	
	# Remove files
	
	os.remove(output_cfg)
	os.remove(faultdb1)
	os.remove(faultdb2)
	shutil.rmtree(dir_ou)


def write_spatialdb(faultdb,patch,rate):
	''' Made to write the spatialdb file with given patch and velocity 
	Input: 	faultdb name of file
			patch list of depth to put into faultdb file
			velocity of rate for non -locked fault
	'''
	
	# Get number of localization
	check=np.isnan(patch)
	slip=[]
	loc_z=[]
	if np.any(check):
		num_loc=6
		loc_z=patch[4:6]+patch[0:2]+[patch[6]]+[patch[-1]]
		slip=[rate, rate,0 ,0 ,rate ,rate]
	else:
		num_loc=10
		loc_z=patch[4:6]+patch[0:2]+patch[6:8]+patch[2:4]+patch[8:10]
		slip=[rate, rate,0 ,0 ,rate ,rate, 0,0 ,rate,rate]
	
	fic=open(faultdb,'w')
	fic.write('// -*- C++ -*- (syntax highlighting)\n')
	fic.write('//\n')
	fic.write('// This spatial database specifies the distribution of slip rate\n')
	fic.write('// associated with aseismic creep on the interface between the mantle\n')
	fic.write('// below the continental crust and the subducting oceanic crust.\n')
	fic.write('// \n')
	fic.write('// We specify a uniform creep rate below a depth of 75 km, tapering to\n')
	fic.write('// 0 at a depth of 60 km.\n')
	fic.write('//\n')
	fic.write('#SPATIAL.ascii 1\n')
	fic.write('SimpleDB {\n')
	fic.write('  num-values = 2\n')
	fic.write('  value-names =  left-lateral-slip  fault-opening\n')
	fic.write('  value-units =  cm/year  cm/year\n')
	fic.write('  num-locs = %i\n'%num_loc)
	fic.write('  data-dim = 1 // Data is specified along a line.\n')
	fic.write('  space-dim = 2\n')
	fic.write('  cs-data = cartesian {\n')
	fic.write('	to-meters = 1.0e+3 // Specify coordinates in km for convenience.\n')
	fic.write('	space-dim = 2\n')
	fic.write('  } // cs-data\n')
	fic.write('} // SimpleDB\n')
	fic.write('// Columns are\n')
	fic.write('// (1) x coordinate (km)\n')
	fic.write('// (2) y coordinate (km)\n')
	fic.write('// (3) reverse-slip (cm)\n')
	fic.write('// (4) fault-opening (cm)\n')
	for j in range(num_loc):
		fic.write('%7.1f %7.1f %10.1f %4.1f\n'%(0,loc_z[j],slip[j],0)) 
		
	fic.close()

def load_patch(patch_file):
	fic=open(patch_file,'r')
	lines=fic.readlines()
	fic.close()
	patch=[]
	count=0
	for line in lines:
		count=count+1
		if count==1:
			continue
		A=line.split()
		patch.append([float(x) for x in A])
	return patch

def get_last(patt,line):
	ind_pos=[i for i,ltr in enumerate(line) if ltr ==patt]
	a=ind_pos[-1]
	return a
	
if __name__ == "__main__":
    main()