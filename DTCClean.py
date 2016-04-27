#!/usr/local/bin/python3
# Author: Wayne Crawford
#
import sys
import subprocess						# New (Python 3) way to call external commands
from subprocess	import PIPE				# New (Python 3) way to call external commands
import math
from argparse import ArgumentParser		# Parser for command line options
import os
import signal
import tempfile
from datetime import datetime, timedelta
from pprint import pprint
import time

####################################################################################################	
def main() :
	"""Plots waveforms aligned by the correlation times given in dt_phase.cc, asks for bad
	correlations and removes them.  Outputs dt_phase.cc_verified and dt.cc_verified 
	Uses cc_pairs.out to associate event numbers with S-file names
	Uses corr.inp to control plotting (time window and filtering)
	
	for manual selection to work:
		1) DAT/SEISAN.DEF must have the WAVEFORM_BASE corresponding to the waveform file names in the S-files
		2) the waveform files must be in SEISAN format
	
	TO DO: Put information about the events being compared in the SEISAN header line (shown in mulplt)
	"""
	
	parser = ArgumentParser(description="Remove bad correlations from a dt.cc file (using SEISAN dt_phase.cc file)")
	parser.add_argument("-i", dest="phasefile",
						help="input dt_phase.cc file [dt_phase.cc]")
	parser.add_argument("-c", dest="ccpfile",
						help="cc_pairs file containing relation between S-files and event #s [cc_pairs.out]")
	parser.add_argument("-k", dest="corrinpfile", 
						help="corr.inp file (for station component, duration and filter bounds to use) [corr.inp]")
	parser.add_argument("-d", dest="dryrun", action="store_true",
						help="Dry run (don't ask which events to remove, don't output a dt.cc-type file)")
	parser.add_argument("--automatic", dest="automatic", action="store_true",
						help="Run automatically, only applying the --maxDT rule (untested)")
	parser.add_argument("-e", dest="maxEvents", type=int,
						help="max # of events to plot at a time [10]")
	parser.add_argument("-t",dest="maxdt", type=float,
						help="max seconds offset to allow in phase (0 means don't check) [0.]")
	parser.add_argument("-b",dest="badMasterPct", type=int, choices=range(10,101,5),
						help="Reject all correlations for a MASTER-STATION-PHASE if at least this percentage of correlations were automatically rejected [50]")
	parser.set_defaults(phasefile="dt_phase.cc",
					 	ccpfile="cc_pairs.out",
					 	corrinpfile="corr.inp",
					 	dryrun=False,
					 	automatic=False,
					 	maxdt=0.,
					 	badMasterPct=50,
					 	maxEvents=10)
	opts = parser.parse_args()
	
	if (opts.automatic==True) :
		opts.dryrun=False
		if opts.maxdt==0:
			print("Can't run automatically if --maxDT is not set")
			sys.exit(2)
	
# 	if opts.maxdt==0:
# 			print("Can't run automatically if --maxDT is not set")
# 			sys.exit(2)
		
	status=1	# flag changes to -1 if user quits early
	# Read "corr.inp": station-channel pairs, filter parameters and durations used by CORR
	chandict=readCorrInp(opts.corrinpfile)
	print('\nchandict: Correlation input parameters (read from "{}")'.format(opts.corrinpfile))
	pprint(chandict)
	
	# Open "dt_phase.cc"
	f=open_read(opts.phasefile,'dt_phase.cc')
		
	# Read "cc_pairs.out": what s-files are associated with what "event" number
	sassoc=readCCPairs(opts.ccpfile)

	# Open output file, or write message that this is a dry run
	if opts.dryrun :
		dryRunMessage()
	else:	
		# CREATE OUTPUT FILES
		(outdtfile,outphasefile)=makeOutputFileNames(opts.phasefile)
		of=open(outdtfile,'w')		# Open output dt.cc file
		opf=open(outphasefile,'w')		# Open output dt_phase.cc file
	
	iMaster_Start=0
	if not opts.automatic :
		# Let user decide where to start	
		while True:	# decide where to start at
			q=input('Hit a Master number to start at (RETURN for the first Master): ')
			if len(q)==0:
				break
			if q.isdigit() :
				iMaster_Start=int(q)
				print('Skipping to Master Event {:d}'.format(iMaster_Start))
				break
	while True :	# Loop through "dt.cc" and same-length "dt_phase.cc" files
		if status==-1:
			break
		iMaster,s_master,eventdict,text=readOneMaster(f,sassoc)
		if len(eventdict)==0 :	# end of file, exit
			break
		else :
			print('\n=======================================================================')
			print('Master #{:d} ({}): '.format(iMaster,s_master))
			if iMaster >= iMaster_Start:
				(text,status)=testOneMaster(s_master,eventdict,chandict,text,opts)
			if not opts.dryrun :
				writeToFiles(text,of,opf)
			if status != 1:	# Quit early
				print("Quitting during Master # {:d}: {}".format(iMaster,s_master))
				if not opts.dryrun :
					print("writing remaing events as is to {} and {}".format(outdtfile,outphasefile))
					flushToFiles(f,of,opf)
				else:
					print("have a nice day!!!!")
				break
	f.close()
	print('======================= FINISHED =======================\n')
	if not opts.dryrun :
		of.close()
		opf.close()

####################################################################################################	
def readCorrInp(filename) :
	f=open_read(filename,'CORR input')
		
	chandict={}
	for l in f:
		if len(l)>=7:
			if l[0:10]=='PRE SIGNAL' :
					presignal=float(l[40:])
			elif l[0:7]=='STATION' :
				if len(l)<14:	# Too short to even read the station name, skip...
					print('{}: Station declaration too short to even read station name!  Skipping...'.format(filename))
					continue
				station=l[10:15].strip()
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
				chandict[(station,phase)]=[comp,(flow,fhigh),presignal*duration,duration]
	f.close()
	return chandict

####################################################################################################	
def readCCPairs(fname) :
	# Associates numbers with S-file names  (in Python dictionary)
	f=open_read(fname,'cc_pairs')

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
	currentmaster=0
	S_master=''
	while True :	# loop until break
		lastpos=f.tell()	# save current stream position, in case need to rewind
		l=f.readline()
		if len(l)==0:
			break
		text.append(l)	    # save text
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
			diffttime=m[1]	# difference between travel times
			dt=m[4]			# 2nd event phase pick correction
			corr=m[2]
			phase=m[3]
			key=(station,phase)
			my_tuple=(sassoc[event],float(dt),float(corr),len(text)-1)
			if key in eventdict :
				eventdict[key].append(my_tuple)
			else:
				eventdict[key]=[my_tuple]
	return currentmaster,S_master,eventdict,text
	
	
####################################################################################################	
def testOneMaster(s_master,eventdict,chandict,text,opts) :
	# for each value in eventdict, align the data, plot and let the user decide which associations to reject
	# Inputs:
	#	s_master: Master event's s-file name
	#	chandict:  dictionary of correlation parameters for each (station,phase) key
	#	eventdict: dictionary of correlations for each (station,phase) key
	#	text: list of dt.cc lines used for this master
	#	opts: command-line options (maxEvents and dryrun are used)
	# Output:
	#	text: modified list of dt.cc lines
	#	status: 1=keep going, -1=quit with only partial mods

	status=1
	# open temporary directories
	odir=tempfile.mkdtemp()	# temporary directory for original pick times
	print(odir)
	mdir=tempfile.mkdtemp()	# temporary directory for modified pick times
	print(mdir)
	
	for key in sorted(eventdict) :	# Sorts the dictionary by station, Phase
		events=eventdict[key]
		station,phase=key
		print('  {}, {}-phase: {:d} correlated events'.format(station,phase,len(events)))
		
		# Automatically remove events with dt > opts.maxdt
		if opts.maxdt > 0. :	# Remove events with phase corrections > maxdt
			badevents=[]
			goodevents=[]
			for event in events:
				sfile,dt,corr,lnum=event
				if abs(dt)>opts.maxdt :
					text[lnum]='*'+text[lnum]
					badevents.append(event)
				else:
					goodevents.append(event)
			if (len(badevents)>0) :
				print('       Rejected {:d} events with pick change > {:g}s: '.format(len(badevents),opts.maxdt),end='')
				[print('{:.2f},'.format(dt),end='') for s,dt,corr,lnum in badevents]
				print('')
				#pprint(badevents)
			# If rejected more than "badMasterPct" % of events, reject them all (bad master)
			if len(badevents) >= len(events)*(float(opts.badMasterPct)/100.):
				print('       BAD MASTER: More than {:d}% of events rejected, rejecting them all!'.format(opts.badMasterPct))
				badevents=badevents+goodevents
				goodevents=0
			events=goodevents									
		
		# Manually process events (plot and ask user to 
		if not opts.automatic :
			nEvents=len(events)
			for i in range(0,nEvents,opts.maxEvents) :
				if status==-1:
					break
				iLast=min(nEvents,i+opts.maxEvents)
				subevents=events[i:iLast]
				print('       {:2d}-{:2d}: '.format(i+1,iLast),end='')
				[print('{:.2f},'.format(dt),end='') for s,dt,corr,lnum in subevents]
				#pprint(subevents)
				# Copy master S-files to the original and modified pick time directories
				sfile_copy(s_master,odir,station,phase,0)
				sfile_copy(s_master,mdir,station,phase,0)
				dts=[]; lnums=[]
				for sfile,dt,corr,lnum in subevents :	# Fill temporary directories with appropriate s-files
					sfile_copy(sfile,odir,station,phase,0)		# copy event S-file to "original" directory	
					sfile_copy(sfile,mdir,station,phase,-dt)		# copy event S-file to "modified" directory, correcting arrival time
					dts.append(dt)
					lnums.append(lnum)
				homedir=os.getcwd()
				print("\ndebug")
		
				# Plot original waveforms
				os.chdir(odir)			
				po=plotAlignedWaveforms(chandict,key,s_master,"ORIG",[-x for x in dts],'C',phase,i,5.)
				print("\ndebug2")
		
				input(' Hit RETURN for aligned')
				# Plot correlation-aligned waveforms
				os.chdir(mdir)
				pa=plotAlignedWaveforms(chandict,key,s_master,"CORR",[x for x in dts],phase,'C',i,1.)
	
				# Wait until events entered or RETURN hit, then close mulplt and eev
				if opts.dryrun == False:
					# Ask for list of events to remove
					eventlist=getEventList(i+1,iLast)
					if len(eventlist) > 0:
						if eventlist[0]==-1:	# User entered 'q': save and quit
							status=-1
						else: 					# Put a * in front of all events to remove in text list
							for j in eventlist :
								iLine=lnums[j-i-1]
								text[iLine]='*'+text[iLine]
								#print('{:d}: {}'.format(iLine,text[iLine]),end='')
				else :
					input("Hit Return to Continue: ")
	
				killplots(po,pa)				
				
				# Clear out the temp directories and go home
				subprocess.call('rm *',shell=True)	# Empty out the directory
				os.chdir(odir)
				subprocess.call('rm *',shell=True)	# Empty out the directory
				os.chdir(homedir)
		#pprint(text)
	# Remove all text lines that start with '*', and then all header lines that no longer have any correl lines following them
	# Remove temporary directories
	os.removedirs(mdir)
	os.removedirs(odir)
	newtext=[line for line in text if text[0]!='*']
	return newtext,status
		
####################################################################################################	
def killplots(proca,procb) :
	# kills all mulplts and the 2 eev processes that called them
	# Kill ALL "mulplt"s
	for line in os.popen("ps xa"):
		fields = line.split()
		pid = fields[0]
		process = fields[4]
		if process.find('mulplt') >= 0:
			#print('KILLING {} (process {}'.format(process,pid))
			os.kill(int(pid), signal.SIGKILL)
	# Kill eevs
	proca.terminate()
	procb.terminate()
####################################################################################################	
def getEventList(evmin,evmax) :
	while 1 :
		reloop=False
		evstr=input('             Enter list of Evt #s to remove, "a" for all, "q" to quit: ')
		evlist=evstr.split();
		if not len(evlist)==0:
			if evlist[0]=='q':
				evlist[0]=-1
				break
			elif evlist[0]=='a' :
				evlist=[str(a) for a in range(evmin,evmax+1)]
			for n in evlist :
				if not n.isdigit() :
					print('       "{}" is not a digit'.format(n))
					reloop=True
				else:
					ni=int(n)
					if (ni<evmin) | (ni>evmax) :
						print("        {:d} is outside the range {:d}-{:d}".format(ni,evmin,evmax))
						reloop=True
			if reloop :
				continue				
		break	
	return [int(n) for n in evlist]

####################################################################################################	
def plotAlignedWaveforms(chandict,key,s_master,whichType,dts,dtPhase,zeroPhase,firstEvtOffset,winMult) :
# plots waveforms aligned by the pick times given in the directory's s-files
# All picks will be aligned at 2070-11-27 12:00:00 (using p_align)
# Also plot "picks" corresponding to either the correlation based arrival times (if original picks aligned)
#	or the original pick time (if correlation-aligned)
# chandict= dictionary containing the parameters that were used by CORR (filter, correlation intervales)
# key: tuple containing the master station and the phase looked at
# s_master=name of the s-file containing the master event (only used for printing)
# whichType=ORIG or CORR, depending on if the s-file picks are the originals or the correlation corrected (only used for printing)
# dts = array of times to subtract from 2070-11-27 12:00:00 when plotting 'picks'
# dtPhase = phase associated with the dt values
# zeroPhase = phase associated with time zero (2070-11-27 12:00:00)
# firstEvtOffset = Offset of first event index in this list from first event overall)
# winMult= plot this times the correlation window used


	station,phase=key
	basetime=datetime(2070,11,27,12,00)
	# GET THE WAVEFORM FILES (uses get_wav)
	p=subprocess.Popen('collect',shell=True,stdin=PIPE,stdout=PIPE)
	p.communicate(b",,\n\n\n\n")
	p=subprocess.Popen('get_wav',shell=False,stdin=PIPE,stdout=PIPE)
	out=p.communicate(b"collect.out")
	subprocess.call('source copy_wav.out',shell=True) 
	
	# ALIGN THE WAVEFORMS (uses p_align)
	p=subprocess.Popen('p_align > p_align.out',shell=True,stdin=PIPE)
	p.communicate(bytes("collect.out\n{}".format(station),'ascii'))
	
	# APPLY THE FILTERS AND TIMESPANS SPECIFIED IN CORR.INP (uses WAVETOOL)
	presignal=winMult*chandict[key][2]
	isecs=math.floor(presignal)
	usecs=int(1000000*(presignal-isecs))
	temp=basetime-timedelta(0,isecs,usecs)
	start=temp.strftime('%Y%m%d%H%M%S.%f')	# wavetool requires the decimal point for absolute times
	comp=chandict[key][0]
	duration=winMult*chandict[key][3]
	flo,fhi=chandict[key][1]
	# Cut the files to the specified time range
	subprocess.call('dirf 2070-11-27-* > dirf.out',shell=True)
	subprocess.call('wavetool -wav_files filenr.lis -format SAC -filter {:g} {:g} -start {} -duration {:.1f} > wavetool.out'.format(
			flo,fhi,start,duration+presignal),shell=True) 
	# Combine the files into one
	subprocess.call('dirf 2070-*{}_{}_SAC'.format(comp[0:2],comp[3]),shell=True,stdout=PIPE)
	subprocess.call('wavetool -wav_files filenr.lis -wav_out_file paligned.seisan > wavetool.out',shell=True)

	# CHANGE CHANNEL NAMES AND ADD DESCRIPTIVE HEADER (uses WAVFIX)	
	f=open('wavfix.def','w')
	hdr=station[:3]
	masterdate='{}{}{}'.format(s_master[13:19],s_master[0:2],s_master[3:7])
	f.write('Header line text (29 chars) . NetCd (5 Chars), comment in next line\n')
	f.write('{:29s} {:5s} {:44s}\n'.format('{}: MSTR={}'.format(whichType,masterdate),'CORR','blah blah blah'))
	f.write(' chan stati  comi stato  como, In and Out definitions\n')
	f.write('      {:3s}01       -MSTR      \n'.format(hdr))
	for i in range(1,len(dts)+1) :
		iEvt=i+firstEvtOffset
		f.write('      {:3s}{:02d}       {}      \n'.format(hdr,i+1,evtName(iEvt)))
	f.close()
	
	#print('')
	#subprocess.call('cat wavfix.def',shell=True)
	subprocess.call('dirf paligned.seisan > dirf.out',shell=True)
	subprocess.call('rm 2070-*',shell=True)	
	p=subprocess.Popen('wavfix > wavfix.out',shell=True,stdin=PIPE)
	p.communicate(b"\n\n1\nfilenr.lis\n")
	subprocess.call('mv -f 2070-* paligned.seisan',shell=True)	
	#subprocess.call('hexdump -e \'40 "%c"\' -n 40 2070-*',shell=True)	
	
	makeSFile_PickCorr('paligned.seisan',basetime,comp,dts,dtPhase,zeroPhase,firstEvtOffset)
	
	# PLOT THE RESULT
	f=open('MULPLT.DEF','w')
	f.write('X_SCREEN_SIZE      Size in percent      60.0\n')
	f.write('RESOLUTIONX        # points pl. screen  50000.0\n')
	f.write('RESOLUTIONHC       # points pl. hc      30000.0\n')
	f.close
	p=subprocess.Popen('eev',shell=False,stdin=PIPE,stdout=PIPE)	# plot aligned data using eev
	p.stdin.write(b'po\n')
	return p

####################################################################################################	
def evtName(i) :	
	# Returns a 5-letter event name depending on the event #:
	# EvtXX if XX is < 100
	# EvXXX if 100 <= i < 1000
	# EXXXX if 1000 <= i < 10000
	# quits on error if i>=10000	
	if (i < 100) :
		return 'Evt{:02d}'.format(i)
	elif (i < 1000) :
		return 'Ev{:03d}'.format(i)
	elif (i < 1000) :
		return 'E{:04d}'.format(i)
	else :
		print('Mare than 9999 correlations for this station/phase/master: quitting!')
		sys.exit(2)
####################################################################################################	
def makeSFile_PickCorr(wavfile,basetime,comp,dts,dtPhase,zeroPhase,firstEvtOffset) :
	# MAKE S-FILE WITH PICKS AND CORRECTED TIMES
	subprocess.call('rm -f ??-????-???.S??????',shell=True)	# Remove all existing S-files
	sfilename='27-1159-00L.S207011'
	f=open(sfilename,'w')
	f.write(' 2070 1127 1159 00.0 L                                                         1\n')
	f.write(' {:78s}6\n'.format(wavfile))
	f.write(' STAT SP IPHASW D HRMM SECON CODA AMPLIT PERI AZIMU VELO AIN AR TRES W  DIS CAZ7\n')
	i=1+firstEvtOffset
	f.write(' {:5s}{}{}  {:4s}    {:2d}{:2d}{:6.2f}{:52s}\n'.format('-MSTR',comp[0],comp[3],'P',12,0,0.,''))
	for dt in dts :
		stat=evtName(i)
		i=i+1
		phase=zeroPhase
		f.write(' {:5s}{}{}  {:4s}    {:2d}{:2d}{:6.2f}{:52s}\n'.format(stat,comp[0],comp[3],phase,12,0,0.,''))
		phase=dtPhase
		if dt >= 0 :
			idt=math.floor(dt)
			udt=int(1000000*(dt-idt))
		else:
			idt=math.ceil(dt)
			udt=int(1000000*(dt-idt))
		#print(idt,udt)
		time=basetime-timedelta(0,idt,udt)
		f.write(' {:5s}{}{}  {:4s}    {:2d}{:2d}{:6.2f}{:52s}\n'.format(stat,comp[0],comp[3],phase,
				time.hour,time.minute,time.second+time.microsecond/1000000.,''))
	f.write('\n')
	f.close()
	#subprocess.call('cat {}'.format(sfilename),shell=True)
####################################################################################################	
def sfile_copy(sfile,destdir,station,phase,dt) :
	# copy an sfile, keeping only the picks associated with the given station and phase
	# adjust time by the correction, set phase to 'P' so that P_ALIGN will work
	f=open(sfile,'r')
	#print(sfile)
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
				isec=int(isec)
				aftertime=l[28:]
				
				astation=beforetime[1:6].strip()
				aphase=beforetime[10]
				
				#Only process station/phase corresponding to current association
				if (astation==station) & (aphase==phase) :
					#print('sfile_copy: hour,minute,second,isec,usec= {:2d},{:2d},{:g},{:2d},{:6d}'.format(hour,minute,second,isec,usec))
					if isec>=60 :
						time=datetime(1,1,1,hour,minute,0,usec)
						#print('sfile_copy: Adjusting isec={:d}, time={}'.format(isec,time))
						time=time+timedelta(0,isec)
					elif isec < 0 :
						time=datetime(1,1,1,hour,minute,0,usec)
						time=time+timedelta(0,-isec)
					else :
						time=datetime(1,1,1,hour,minute,isec,usec)
					time=time-timedelta(0,dt)
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
	
####################################################################################################	
def dryRunMessage() :
	print("\n***************************************************************************")
	print("****DRY RUN, will not ask for events to remove, will not output results****")
	print("***************************************************************************")

####################################################################################################	
def makeOutputFileNames(inphasefile) :
	# CREATE OUTPUT FILES
	endstr='_cleaned'
	outdtfile="dt.cc"+endstr
	# Name the output phase file the same as the input, plus '_clean1' or, if it already ends
	# with "_cleanX", replace "X" with "X+1"
	if not endstr in inphasefile :
		outphasefile=inphasefile+endstr+'1'
	else :
		ind=inphasefile.rfind(endstr)
		cnum=inphasefile[ind+len(endstr):]
		if len(cnum)==0: cnum='0'
		if not cnum.isdigit() : cnum='0'
		outphasefile=inphasefile+endstr+str(int(cnum)+1)
	return (outdtfile,outphasefile)
####################################################################################################	
def open_read(filename,description):
	try :
		f=open(filename,'r')
	except IOError:
		print('{} file "{}" could not be opened for read'.format(description,filename))
		sys.exit(2)
	return f
####################################################################################################	
def writeToFiles(text,of,opf) :
# writes the text in the list 'text' to the new phase and dt.cc files
# Only prints out event lines ('#') if they are followed by accepted phases
# opf is the phase file (gets lines direct from text)
# of is the "dt.cc" file (have to remove last column from text)
	eventpair=[]
	for line in text :
		if line[0] == '#' :
			# Take care of previous event pair
			writeEventPair(eventpair,of,opf)
			# Start a new event pair
			eventpair=[]
			eventpair.append(line)
		elif not line[0] == '*' :
			eventpair.append(line)
	writeEventPair(eventpair,of,opf)	# Write last event pair
####################################################################################################	
def writeEventPair(eventpair,of,opf) :
	if len(eventpair) > 1 :
		opf.write(eventpair[0])
		of.write(eventpair[0])
		for line in eventpair[1:] :
			opf.write(line)
			a=line.split()
			of.write('{:<5s} {:>6s} {:>5s} {}\n'.format(a[0],a[1],a[2],a[3]))
####################################################################################################	
def flushToFiles(f,of,opf) :
# flushes the rest of the file "f" to the new phase and dt.cc files
# Doesn't check anything
# opf is the phase file (gets lines direct from text)
# of is the "dt.cc" file (have to remove last column from text)
	for l in f :
		# Write to the phase file
		opf.write(l)
		# Write to the dt.cc file
		if l[0] == '#' :
			of.write(l)
		else :
			a=l.split()
			of.write('{:<5s} {:>6s} {:>5s} {}\n'.format(a[0],a[1],a[2],a[3]))
#########################################################################
if __name__ == "__main__":
	sys.exit(main())
