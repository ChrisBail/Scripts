#!/usr/bin/env python

import os
import sys

def run_HASH(ind_file,parameter=None):
	''' Outputs are hash_seisan.out and focmec.dat'''

	######### Retrieve index_directory
	
	index_directory=os.path.dirname(ind_file)
	index_directory=index_directory+'/'

	######### Warning hyp only take unique file as input not fullpath
	
	index_file=ind_file[len(index_directory):]
	
	########## Input Parameters
	
	if parameter==None:
		grid_angle=2
		max_pol_error=10
		max_amp_error=0.2
		angle_meca_prob=30
		prob_mul=0.1
	else:
		grid_angle=parameter[0]
		max_pol_error=parameter[1]
		max_amp_error=parameter[2]
		angle_meca_prob=parameter[3]
		prob_mul=parameter[4]

	#index_file='index0002.out'
	#index_directory='/Volumes/donnees/SE_DATA/WOR/CHRIS/HYPODD/ALL_DATA/FOCMEC/'
	curr_path=os.getcwd()

	############## Launch HYP to build the hyp.out file (it only works if you get in the file directory)

	os.chdir(index_directory)
	print index_directory
	print index_file
	cmd='hyp << END > /dev/null \n%s\nN\nEND' %index_file
	os.system(cmd)
	os.chdir(curr_path)

	############## Move hyp.out and print.out into current directory

	cmd='mv %shyp.out ./' %index_directory 
	os.system(cmd)
	cmd='mv %sprint.out ./' %index_directory 
	os.system(cmd)

	############### Launch HASH

	cmd='hash_seisan << END > /dev/null\n%-i\n%-.0f\n%-f\n%-f\n%-f\nEND' %(grid_angle,
	max_pol_error,max_amp_error,angle_meca_prob,prob_mul)
	os.system(cmd)
	
