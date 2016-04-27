#!/usr/bin/env python

import sys
import glob
import os
import shutil
import os.path

### Choose Parameters

seisan_top=os.getenv('SEISAN_TOP')
cbase=raw_input('Choose Input SEISAN Base (5 characters):\n')
cbase=seisan_top+"/WAV/"+cbase+"/"

lis_file=[]
for dirpath, dirnames, filenames in os.walk(cbase):
	if len(dirpath)==len(cbase)+7 and dirpath[-3:-2]=='/':
		print dirpath
		lis_file.append(dirpath)
		
for path in lis_file:
	os.chdir(path)
	lifile=glob.glob('*')
	if not lifile:
		continue
	else:
		os.system('dirf *MSEED')
		os.system('autoreg << END\n\
L\n\
n\n\
CONTI\n\
chb\n\
A\n\
y\n\
END\n')

