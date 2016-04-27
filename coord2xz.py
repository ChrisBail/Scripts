#!/usr/bin/env python

import os
import glob
import sys
import numpy as np

def coord2xz(azi,len_prof,width_prof,center,input_file,output_file):
	# Parameters

	#azi=45
	#len_prof=100
	#width=50
	#center='167.25/-15'

	# Define filename

	file1=input_file
	file2=output_file
	f1=open(file1,'r')
	f2=open(file2,'w')

	cmd_proj='-C%s -A%-.2f -L%-.0f/%-.0f -W%-.0f/%-.0f -Q -Fpz' % (center,azi,-len_prof/2,len_prof/2,-width_prof/2,width_prof/2)
	print cmd_proj
	os.system('project %s %s > %s' % (file1,cmd_proj,file2))

	f1.close()
	f2.close()


