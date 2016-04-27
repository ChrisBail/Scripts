#!/usr/local/bin/python3
# Author: Wayne Crawford
#
import sys
import subprocess						# New (Python 3) way to call external commands
from subprocess	import PIPE				# New (Python 3) way to call external commands
import math
from optparse import OptionParser		# Parser for command line options
import os
import tempfile
from datetime import datetime, timedelta
from pprint import pprint

####################################################################################################	
def main() :
	"""Plots waveforms aligned by the correlation times given in dt.cc, asks for bad
	correlations and removes those from dt.cc 
	Uses cc_pairs.out to associate event numbers with S-file names
	Uses corr.inp to control plotting (time window and filtering)
	
	TO DO: make output to dt.cc file work
	   limit screen plots to 10 waveforms at a time
	   Put information about the events being compared in the SEISAN header line (shown in mulplt)
	   Change name of first channel to "MASTR"(???)
	   ??? Show the before and after plots at the same time, quit both as soon as the events to remove are specified???
		 """
	
	usage = """usage: %prog [options]
			"""

	print(main.__doc__)

	parser = OptionParser(usage=usage)
	parser.add_option("-i","--infile", dest="dtfile", type="string",
						help="input hypoDD dt.cc file [dt.cc]")
	parser.add_option("-o","--outfile", dest="outdtfile", type="string",
						help="output dt.cc file [dt.cc.verified] *** DOES NOT WORK YET ***")
	parser.add_option("-c","--ccpairsfile", dest="ccpfile", type="string",
						help="cc_pairs file containing relation between S-files and event #s [cc_pairs.out]")
	parser.add_option("-k","--corrinpfile", dest="corrinpfile", type="string",
						help="corr.inp file (for station component, duration and filter bounds to use) [corr.inp]")
	parser.add_option("-d","--dryrun", dest="dryrun", action="store_true",
						help="Dry run (don't ask which events to remove, don't output a dt.cc-type file)")
	parser.set_defaults(dtfile="dt.cc",
					 	outdtfile='dt.cc.verified', 
					 	ccpfile="cc_pairs.out",
					 	corrinpfile="corr.inp",
					 	dryrun=False)
	(opts, args) = parser.parse_args()
	
	
	# Read in the station-channel pairs, filter parameters and duration used by CORR
	chandict=readCorrInp(opts.corrinpfile)
	print('\nCorrelation input parameters (read from "{}")'.format(opts.corrinpfile))
	pprint(chandict)
	# Open input dt.cc file
	try :
		f=open(opts.dtfile,'r')
	except IOError:
		print('Required dt.cc file "{}" could not be opened'.format(opts.dtfile))
		sys.exit(2)
	# Open output dt.cc file
	of=open(opts.outdtfile,'w')
	# Read in what s-files are associated with what "event" number
	sassoc=readCCPairs(opts.ccpfile)
	#print('\nEvent-sFile associations (read from "{}")'.format(opts.ccpfile))
	#pprint(sassoc)	# DEBUG
	if opts.dryrun :
		print("***************************************************************************")
		print("****DRY RUN, will not ask for events to remove, will not output results****")
		print("***************************************************************************")
	
	while True :	# Keep looping until break
		s_master,eventdict,text=readOneMaster(f,sassoc)
		print('\nMaster event "{}"\'s correlations (read from "{}"): '.format(s_master,opts.dtfile))
		pprint(eventdict)
		if len(eventdict)==0 :
			break
		else :
			text=testOneMaster(s_master,eventdict,chandict,text,opts)
			for l in text :
				of.write(l)

####################################################################################################	
def readCorrInp(filename) :
	try :
		f=open(filename,'r')
	except IOError:
		print('Required CORR input file "{}" could not be opened'.format(filename))
		sys.exit(2)
		
	chandict={}
	for l in f:
		if len(l)>=7:
			if l[0:7]=='STATION' :
				if len(l)<14:	# Too short to even read the station name, skip...
					print('{}: Station declaration too short to even read station name!  Skipping...'.format(filename))
					continue
				station=l[10:14].strip()
				if len(l) < 63 :
					print('{}: Station {} description is incomplete in {}, Skipping...'.format(filename,station))
					continue
				comp=          l[20:24].strip()
				selcrit= float(l[30:32])
				duration=float(l[40:48])
				flow=    float(l[50:58])
				fhigh=   float(l[60:])
				if selcrit==1. :
					phase='P'
				elif selcrit==2. :
					phase='S'
				else :
					print('{}: Unknown selcrit ({:g}) for station {}:{}'.format(filename,selcrit,station,comp))
					continue
				chandict[(station,phase)]=[comp,(flow,fhigh),duration]
	f.close()
	return chandict

####################################################################################################	
def readCCPairs(fname) :
	# Associates numbers with S-file names  (in Python dictionary)
	try :
		f=open(fname,'r')
	except IOError:
		print('Required cc_pairs file "{}" could not be opened'.format(fname))
		sys.exit(2)

	assoc={}
	for l in f :
		if len(l.strip()) > 0 :
			x=l.split()
			key1=int(x[0])
			key2=int(x[2])
			if not key1 in assoc :
				assoc[key1]=x[1]
			if not key2 in assoc :
				assoc[key2]=x[3]
	f.close()
	return assoc

	
####################################################################################################	
def readOneMaster(f,sassoc) :
	# Reads associations for one master, 
	# saves information in event dictionary (grouped by station and phase)
	# and original lines in text
	text=[]
	eventdict={}
	while True :	# loop until break
		lastpos=f.tell()	# save current stream position, in case need to rewind
		l=f.readline()
		text.append(l)
		m=l.split()
		if l[0]=='#' :	# New master-event pair
			master,event=(int(m[1]),int(m[2]))
			#event=int(m[2])
			if len(text)==1:
				currentmaster=master
				S_master=sassoc[master]
			elif master != currentmaster :	# different master #, go back to start of line and quit
				f.seek(lastpos)
				break
		else :
			station=m[0]
			delay=m[1]
			corr=m[2]
			phase=m[3]
			key=(station,phase)
			my_tuple=(sassoc[event],float(delay),float(corr),len(text)-1)
			if key in eventdict :
				eventdict[key].append(my_tuple)
			else:
				eventdict[key]=[my_tuple]
	return S_master,eventdict,text
	
	
####################################################################################################	
def testOneMaster(s_master,eventdict,chandict,text,opts) :
	# for each value in eventdict, align the data, plot and let the user decide which associations to reject
	# Uses SEISAN routines GET_WAV, P_ALIGN and MULPLT

	plotbufsecs=0.5	# seconds to plot before and after corr interval
	print('Master={}'.format(s_master))
	# open temporary directories
	odir=tempfile.mkdtemp()	# temporary directory for original pick times
	mdir=tempfile.mkdtemp()	# temporary directory for modified pick times
	#print('original and modified directories are {}, {}'.format(odir,mdir))
	
	#for k,v in eventdict.items() :
	for key in sorted(eventdict) :	# Sorts the dictionary by station, Phase
		v=eventdict[key]
		station,phase=key
		print('  Working on station {}, phase {}: {:d} associated'.format(station,phase,len(v)))
		#print(v)
		# Copy master S-files to the original and modified pick time directories
		#print(' 0: Master: ',s_master)
		sfile_copy(s_master,odir,station,phase,0)
		sfile_copy(s_master,mdir,station,phase,0)
		print('Corrections applied:', end="")
		for x in v :	# Fill temporary directories with appropriate s-files
			sfile,delay,corr,lnum=x	
			sfile_copy(sfile,odir,station,phase,0)		# copy event S-file to "original" directory	
			sfile_copy(sfile,mdir,station,phase,delay)	# copy event S-file to "modified" directory, correcting arrival time
			print('{:.2f},'.format(delay), end="");
		print('s',end='')
		# print('Transcribed {:d} s-files (including master)'.format(1+len(v)))
		homedir=os.getcwd()
		for dir in [odir,mdir] :
			if dir==odir :
				print('..orig',end='')
				sys.stdout.flush()
			else:
				print('..corr')
				sys.stdout.flush()
			# move into the directory
			os.chdir(dir)
			
			plotAlignedWaveforms(plotbufsecs,chandict,key)

			subprocess.call('rm *',shell=True)	# Empty out the directory
		if opts.dryrun == False:
			# Ask for list of events to remove
			eventlist=getEventList(len(v)+1)
			# Put a * in front of all events to remove in text list
			print('  TEXT_MOD NOT IMPLEMENTED')
		os.chdir(homedir)
	# Remove all text lines that start with '*', and then all header lines that no longer have any delay lines following them
	# Remove temporary directories
	os.removedirs(mdir)
	os.removedirs(odir)
	if opts.dryrun == False :
		print('TEXT_MOD NOT IMPLEMENTED')
	return text
		
####################################################################################################	
def getEventList(evmax) :
	while 1 :
		reloop=False
		evstr=input('Enter space-separated list of event #s to remove: ')
		evlist=evstr.split();
		if len(evlist)==0:
			q=input('Keep all events? ')
		else :
			for n in evlist :
				if not n.isdigit() :
					print('"{}" is not a digit'.n)
					reloop=True
				elif int(n)==1:
					print("You can't throw away event #1, it's the master!")
					reloop=True
				elif int(n)>evmax:
					print("There is no event #{}!".format(n))
					reloop=True
			if reloop :
				continue
			else:
				print('Remove events ',end='')
				[print(n,',',end='') for n in evlist]
				q=input('? ')
		if q[0].lower()=='y' :
			break	
	return [int(n) for n in evlist]

####################################################################################################	
def plotAlignedWaveforms(plotbufsecs,chandict,key) :
	station,phase=key
	# GET THE WAVEFORM FILES (uses get_wav)
	p=subprocess.Popen('collect',shell=True,stdin=PIPE,stdout=PIPE)
	p.communicate(b",,\n\n\n\n")
	#subprocess.call('cat collect.out',shell=True)
	p=subprocess.Popen('get_wav',shell=False,stdin=PIPE,stdout=PIPE)
	out=p.communicate(b"collect.out")
	subprocess.call('source copy_wav.out',shell=True) 
	
	# ALIGN THE WAVEFORMS (uses p_align)
	p=subprocess.Popen('p_align > p_align.out',shell=True,stdin=PIPE)
	p.communicate(bytes("collect.out\n{}".format(station),'ascii'))
	
	# APPLY THE FILTERS AND TIMESPANS SPECIFIED IN CORR.INP
	isecs=math.floor(plotbufsecs)
	usecs=int(1000000*(plotbufsecs-isecs))
	temp=datetime(2070,11,27,12,00)-timedelta(0,isecs,usecs)
	start=temp.strftime('%Y%m%d%H%M%S.%f')	# wavetool requires the decimal point for absolute times
	comp=chandict[key][0]
	duration=chandict[key][2]
	flo,fhi=chandict[key][1]
	# I don't use tsd.out as an sfile because it has bad filenames
	subprocess.call('dirf 2070-11-27-* > dirf.out',shell=True)
	subprocess.call('wavetool -wav_files filenr.lis -format SAC -filter {:g} {:g} -start {} -duration {:.1f} > wavetool.out'.format(
			flo,fhi,start,duration+2*plotbufsecs),shell=True) #,stdout=PIPE)
	subprocess.call('dirf 2070-*{}_{}_SAC'.format(comp[0:2],comp[3]),shell=True,stdout=PIPE)
	subprocess.call('wavetool -wav_files filenr.lis -wav_out_file paligned.seisan > wavetool.out',shell=True) #,stdout=PIPE)
	
	# PLOT THE RESULT
	p=subprocess.Popen('mulplt',shell=True,stdin=subprocess.PIPE, stdout=PIPE)	# plot aligned data using eev
	p.communicate(bytes('{}\n0\n\n'.format('paligned.seisan'),'ascii'))
			
####################################################################################################	
def sfile_copy(sfile,destdir,station,phase,delay) :
	# copy an sfile, keeping only the picks associated with the given station and phase
	# adjust time by the delay, set phase to 'P' so that P_ALIGN will work
	f=open(sfile,'r')
	of=open(os.path.join(destdir,sfile),'w')
	# print('Transcribing from {} to {}'.format(sfile,os.path.join(destdir,sfile)))
	inPhases=False
	for l in f :
		if not inPhases :
			of.write(l)
			#print(l,end='')			# DEBUG
		else :
			if len(l.strip()) > 0:
				beforetime=l[0:18]
				#print(beforetime)
				hour=int(l[18:20])
				minute=int(l[20:22])
				second=float(l[22:28])
				isec=math.floor(second)
				usec=int(1000000*(second-isec))
				aftertime=l[28:]
				
				astation=beforetime[1:6].strip()
				aphase=beforetime[10]
				
				#Only process station/phase corresponding to current association
				if (astation==station) & (aphase==phase) :
					if isec>=60 :
						time=datetime(1,1,1,hour,minute,isec-60,usec)
						time=time+timedelta(0,60)
					else :
						time=datetime(1,1,1,hour,minute,isec,usec)
					time=time-timedelta(0,delay)
					if time < datetime(1,1,1) :
						time=datetime(1,1,1)
						print('Event {} will be improperly shifted'.format(sfile))
					if aphase != 'P' :
						beforetime=beforetime[0:10]+'P'+beforetime[11:]
					of.write('{}{:02d}{:02d} {:5.2f}{}'.format(beforetime,
							time.hour,time.minute,time.second+time.microsecond/1000000,
							aftertime))	
					#print('{}: {:2d}{:2d} {:5.2f}'.format(sfile,time.hour,time.minute,time.second+time.microsecond/1000000))
		if l[79]=='7' :
			inPhases=True
	f.close()
	of.close()	
	

#########################################################################
if __name__ == "__main__":
	sys.exit(main())
