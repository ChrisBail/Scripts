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
	parser.add_option("-o","--outputPDF", dest="pdffile", type="string",
						help="output PDF filename [hypoDD.locreloc.pdf]")
	parser.add_option("-p","--outputPNG", dest="pngfile", type="string",
						help="output PNG filename [hypoDD.locreloc.png]")
#	parser.add_option("-a","--allEvents", dest="plotAll",
#						action="store_true", help="print out all events (even unimproved)")
	parser.add_option("-c","--connectHypos", dest="plotConnect",
						action="store_true", help="connect relocated and original events")
	parser.add_option("-u","--uncertLimit", dest="uncertlimit", type="float",
						help="print out only relocated events with all uncertainties (m) less than this (0 means print all) [0]")

	parser.set_defaults(relocfile="hypoDD.reloc",
						locfile='hypoDD.loc', 
						pdffile='hypoDD.locreloc.pdf',
						pngfile='hypoDD.locreloc.png',
						plotConnect=False,
#						plotAll=False,
						uncertlimit=0)
	(options, args) = parser.parse_args()
		
	psfile='temp.ps'
	connectFile='temp.connect'
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

	print('{:20s} has {:d} events'.format(options.locfile,  len(loc))  )
	print('{:20s} has {:d} events'.format(options.relocfile,len(reloc)))
	
	mpdLat=1852*60	# meters per degree latitude
	baseLat=float(loc[0][1])
	lonmult=math.cos(baseLat*math.pi/180)
	print("Base latitude = {:8.4f}, lon multiplier = {:.4f}".format(baseLat,lonmult))
	mpdLon=mpdLat*lonmult
	
	mag_powerfact=3;	mag_ref=2;	# magnitude for 1 cm circle
	magdivisor=pow(mag_powerfact,mag_ref)
	# Print original events in GMT format
	f=open(locXY,'w')
	for line in loc :
		magsize=pow(mag_powerfact,float(line[16]))/magdivisor
		f.write("{} {} {:8.3f} {:8.5f} {:8.5f}\n".format(
					line[2],line[1],magsize,float(line[7])/mpdLon, float(line[8])/mpdLat))
	f.close()
	
	# Write relocated events in GMT format
	f=open(relocXY,'w')
	if options.plotConnect :	# connect original and new locations
		fc=open(connectFile,'w')
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
# 		elif ~options.plotAll :	# comparing to original's error doesn't work because original has zero error????
# 			i = locindex.index(relocLine[0])
# 			#print(i,relocLine[0])
# 			locLine=loc[i]
# 			if locLine[0] != relocLine[0]:
# 				print("ERROR, reloc and loc line #s don't match!!! ({} and {})".format(relocLine[0],locLine[0]));
# 				sys.exit(2)
# 			if float(locLine[7]) < float(relocLine[7]) :	# original x error smaller than relocated
# 				printLine=False
# 			elif float(locLine[8]) < float(relocLine[8]):
# 				printLine=False
# 			if printLine==False:
# 				print('Rejected relocated because worse than original')
# 				print('Original',locLine)
# 				print('Relocated',relocLine)
		if options.plotConnect :	# connect original and new locations
			i = locindex.index(relocLine[0])
			#print(i,relocLine[0])
			locLine=loc[i]
			if locLine[0] != relocLine[0]:
				print("ERROR, reloc and loc index #s don't match!!! ({} and {})".format(relocLine[0],locLine[0]));
			fc.write("{} {}\n{} {}\n>\n".format(locLine[2],locLine[1],relocLine[2],relocLine[1]))
		if printLine :
			magsize=pow(mag_powerfact,float(relocLine[16]))/magdivisor
			f.write("{} {} {:8.3f} {:8.5f} {:8.5f}\n".format(
					relocLine[2],relocLine[1],magsize,
					float(relocLine[7])/mpdLon, float(relocLine[8])/mpdLat) )
	f.close()
	if options.plotConnect :	# connect original and new locations
		fc.close()

	
	# Run GMT
	process = subprocess.Popen("cat {} {} | minmax -I1m".format(locXY,relocXY),
				shell=True, stdout=subprocess.PIPE, universal_newlines=True)
	range=process.communicate()[0].strip();
	print(range)
	print(locXY,relocXY)
	process=subprocess.Popen("psbasemap -JM15c+ {} -B100m -P -K > {}".format(range,psfile),shell=True);
	process.communicate()[0]	# Waits until end of last process
	process=subprocess.Popen("psxy {} -JM -R  -Sc0.1c -Glightgrey -Wlightgrey -O -K >> {}".format(locXY,psfile),shell=True);
	process=subprocess.Popen("pscoast -JM -R -Df -W  -O -K >> {}".format(psfile),shell=True);
	process.communicate()[0]	# Waits until end of last process
	if options.plotConnect :
		process=subprocess.Popen("psxy {} -JM -R -M -W1,darkgrey -O -K >> {}".format(connectFile,psfile),shell=True);
		process.communicate()[0]	# Waits until end of last process
		
	process=subprocess.Popen("psxy {} -JM -R -Sc0.1c -Wblack -O >> {}".format(relocXY,psfile),shell=True);
	process.communicate()[0]	# Waits until end of last process
	process=subprocess.Popen("ps2pdf {} {}".format(psfile,options.pdffile),shell=True);
	process.communicate()[0]	# Waits until end of last process
	process=subprocess.Popen("convert -density 300 {} -trim -alpha off {}".format(options.pdffile,options.pngfile),shell=True);
	process.communicate()[0]	# Waits until end of last process
	process=subprocess.Popen("rm {}".format(psfile),shell=True);
	process.communicate()[0]	# Waits until end of last process
	process=subprocess.Popen("open {}".format(options.pngfile),shell=True);

#########################################################################
if __name__ == "__main__":
	sys.exit(main())


