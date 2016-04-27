#!/usr/local/bin/python3.2
# Author: Wayne Crawford
#
import sys
import subprocess						# New (Python 3) way to call external commands
import math
from optparse import OptionParser		# Parser for command line options


def main() :
	"""Compares hypoDD relocations with originals.  
	Outputs GMT xy files to {relocfile}.xy and {locfile}.xy
	Uses GMT """
	
	usage = """usage: %prog [options]"""			

	parser = OptionParser(usage=usage)
	parser.add_option("-r","--relocfile", dest="relocfile", type="string",
						help="hypoDD relocated file [hypoDD.reloc]")
	parser.add_option("-l","--locfile", dest="locfile", type="string",
						help="hypoDD non-relocated file [hypoDD.loc]")
	parser.add_option("-o","--outputFile", dest="pdffile", type="string",
						help="output PDF filename [compareLocReloc.pdf]")
	parser.add_option("-a","--allEvents", dest="plotAll",
						action="store_true", help="print out all events (even unimproved)")
	parser.add_option("-u","--uncertLimit", dest="uncertlimit", type="float",
						help="print out relocated events with all uncertainties less than this (overrides --allEvents) [100]")

	parser.set_defaults(relocfile="hypoDD.reloc", locfile='hypoDD.loc', 
			pdffile='compareLocReloc.pdf',plotAll=False,uncertlimit=100)
	(options, args) = parser.parse_args()
		
	psfile='temp.ps'
	locXY=options.locfile + '.xy'
	relocXY=options.relocfile + '.xy'
	print(options.locfile, options.relocfile,locXY,relocXY)
	
	if len(args) != 0:
		print(main.__doc__)
		parser.print_help()
		return 2

	# Read relocated events into memory
	f=open(options.relocfile,'r');
	reloc = [line.split() for line in f]
	f.close()
	
	# Read original events into memory
	f=open(options.locfile,'r');
	#loc = [map(float, line.split()) for line in f]	# if I wanted all values as floats
	loc = [line.split() for line in f]
	f.close()
	locindex=[a[0] for a in loc]	# return list of line indices
	
	mpdLat=1852*60	# meters per degree latitude
	baseLat=float(loc[0][1])
	lonmult=math.cos(baseLat*math.pi/180)
	print("Base latitude = {:8.4f}, lon multiplier = {:.4f}".format(baseLat,lonmult))
	mpdLon=mpdLat*lonmult
	# Print original events in GMT format
	f=open(locXY,'w')
	for line in loc :
		f.write("{} {} {:8.3f} {:8.5f} {:8.5f}\n".format(
					line[2],line[1],pow(2.,float(line[16]))/5,float(line[7])/mpdLon, float(line[8])/mpdLat))
	f.close()
	
	# Print relocated events in GMT format
	f=open(relocXY,'w')
	for relocLine in reloc :
		printLine=True
		if options.uncertlimit > 0 :
			if float(relocLine[7]) > options.uncertlimit :
				printLine=False
			elif float(relocLine[8]) > options.uncertlimit :
				printLine=False
			if printLine==False:
				print('#{:5s}: Rejected relocated because x or y error > {:g} meters: x={:5s} y={:5s}'.format(
						relocLine[0],options.uncertlimit,relocLine[7],relocLine[8]))
		elif ~options.plotAll :	# comparing to original doesn't work because original has zero error????
			i = locindex.index(relocLine[0])
			#print(i,relocLine[0])
			locLine=loc[i]
			if locLine[0] != relocLine[0]:
				print("ERROR, reloc and loc line #s don't match!!! ({} and {})".format(relocLine[0],locLine[0]));
				sys.exit(2)
			if float(locLine[7]) < float(relocLine[7]) :	# original x error smaller than relocated
				printLine=False
			elif float(locLine[8]) < float(relocLine[8]):
				printLine=False
			if printLine==False:
				print('Rejected relocated because worse than original')
				print('Original',locLine)
				print('Relocated',relocLine)
			
		if printLine :
			f.write("{} {} {:8.3f} {:8.5f} {:8.5f}\n".format(
					relocLine[2],relocLine[1],pow(2.,float(relocLine[16]))/5,
					float(relocLine[7])/mpdLon, float(relocLine[8])/mpdLat))
			
	f.close()
	
	# Run GMT
	process = subprocess.Popen("cat {} {} | minmax -I1m".format(locXY,relocXY),
				shell=True, stdout=subprocess.PIPE, universal_newlines=True)
	range=process.communicate()[0].strip();
	print(range)
	print(locXY,relocXY)
	process=subprocess.Popen("psbasemap -JM15c+ {} -B100mWesN -K > {}".format(range,psfile),shell=True);
	process.communicate()[0]	# Waits until end of last process
	process=subprocess.Popen("psxy {} -JM -R -Sc2.5p -Ggrey -O -K >> {}".format(locXY,psfile),shell=True);
	process.communicate()[0]	# Waits until end of last process
	process=subprocess.Popen("psxy {} -JM -R -Sc2p -Gblack -O >> {}".format(relocXY,psfile),shell=True);
	process.communicate()[0]	# Waits until end of last process
	process=subprocess.Popen("ps2pdf {} {}".format(psfile,options.pdffile),shell=True);
	process.communicate()[0]	# Waits until end of last process
	process=subprocess.Popen("rm {}".format(psfile),shell=True);
	process.communicate()[0]	# Waits until end of last process
	process=subprocess.Popen("open {}".format(options.pdffile),shell=True);

#########################################################################
if __name__ == "__main__":
	sys.exit(main())


