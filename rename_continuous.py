#!/usr/bin/env python

import sys
import glob
import os
import IPython
import shutil
import os.path
from obspy.core import read
from obspy.core.stream import Stream

### Choose Parameters

cbase=raw_input('Choose Input SEISAN Base (5 characters):\n')
final_base=raw_input('Choose Output SEISAN Base (5 characters, Make sure you create it with MAKEREA):\n')
wav_format=raw_input('Choose output wave format (MSEED, SEED, GSE...):\n')
suffix=raw_input('Choose suffix (< 5 char is enough):\n')

#IPython.embed()

#final_base='CONTI'
#wav_format='MSEED'
#cbase='CVNRC'
#name='VASAV'
#suffix='VAN'

### Set correctly paths

seisan_top=os.getenv('SEISAN_TOP')
final_base=seisan_top+"/WAV/"+final_base+"/"
cbase=seisan_top+"/WAV/"+cbase+"/"
pwd=os.getcwd()

#IPython.embed()

# Make list of seed files present in top directory cbase

lis_file=[]
for dirpath, dirnames, filenames in os.walk(cbase):
	if len(dirpath)==len(cbase)+7 and dirpath[-3:-2]=='/':
		print dirpath
		lis_file.append(dirpath)
	
#IPython.embed()

	
### Process merging and conversion
	
for path in lis_file:
	os.chdir(path)
	year=path[-7:-3]
	month=path[-2:]
	lifile=glob.glob('*')
	for days in [x+1 for x in range(31)]:
		day=('%02d' % days)
		for hours in [x for x in range(24)]:
			hour=('%02d' % hours)
			wav_files=[wav for wav in lifile if year in wav[0:4] \
			and month in wav[5:7] \
			and day in wav[8:10] \
			and hour in wav[11:13]]
			if not wav_files:
				continue
			else:
				output_name='%s-%s-%s-%s00_%s.%s' % (year,month,day,hour,suffix,wav_format)
				stream_wav=Stream()
				for i in range(len(wav_files)):
					stream_wav+=read(wav_files[i])
				stream_wav.write(output_name,format=("%s" % wav_format))
				stream_wav.clear()
			shutil.move(output_name,("%s%s/%s/" % (final_base,year,month)))
			print "Processing...%s...Please wait" % output_name
				
sys.exit()			
#				cat_wav=(' '.join(wav_files))
#				cat_command('cat %s > %s-%s-%s-%s
#				os.system(cat_command)
#				print wav_files
#				IPython.embed()
#				2008-07-21-1500_VANARC.MSEED

