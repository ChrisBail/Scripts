#!/usr/bin/env python

import netCDF4
import sys
import numpy as np
import os
import shutil

filea=sys.argv[1]
exo_file=sys.argv[2]
#filea='pylithapp.cfg'
#exo_file='test.exo'

fic=open(filea,'r')
lines=fic.readlines()
fic.close()


flag_change=0
for line in lines:

	if line=='[pylithapp.mesh_generator.reader]\n':
		flag_change=1
		print line[:-1]
		continue
	if flag_change==1:
		print 'filename = %s' %exo_file
		flag_change=0
		continue
	print line[:-1]
		

	
