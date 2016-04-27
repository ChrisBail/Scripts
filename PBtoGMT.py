#!/usr/bin/python
# Author: Wayne Crawford
#
import sys
from optparse import OptionParser		# Parser for command line options


def main() :
	"""Extract Peter Bird (2003) plate boundaries to GMT xy format
	"""
	

	usage = """usage: %prog minlon maxlon minlat maxlat
  Example: %prog 140 150 30 40 

  Use longitudes from -180 to 180
  
  the file PB2002_boundaries.dig.txt must be
  in the same directory as this script
 """
 	# insert a "--" to allow neg numbers to be read
	sys.argv.insert(1,"--") 
			
	#print sys.argv

	listBoundaries=False
	parser = OptionParser(usage=usage)
	(options, args) = parser.parse_args()
#	if len(args) < 2:
	if len(args) != 4:
		print main.__doc__
		parser.print_help()
		return 2
	else :
		minlon=float(args[0])
		maxlon=float(args[1])
		minlat=float(args[2])
		maxlat=float(args[3])
		if minlon>180 :
			minlon=minlon-360
		if maxlon > 180 :
			maxlon=maxlon-360
	#print "lon=%g to %g, lat=%g to %g" % (minlon,maxlon,minlat,maxlat)
	infile=sys.path[0] + '/PB2002_boundaries.dig.txt';
	
	gotBdy=False
	
	f=open(infile,'r')
	line=f.readline()
	while len(line) > 0 :
		if line[0]==' ' :	# This is a lat/lon line, write if in the lat/lon range
			d=line.split(",")
			lon=float(d[0])
			lat=float(d[1])
			if ((lat>minlat)&(lat<maxlat)&(lon>minlon)&(lon<maxlon)):
				gotBdy=True
				print "%10.5f %10.5f" % (lon,lat)				
		elif line[0]=='*' :
			if gotBdy :
				print ">" + bdyName ,
				gotBdy=False
		else:
			bdyName=line
			gotBdy=False
		line=f.readline()
	f.close()
	return 0

#########################################################################
if __name__ == "__main__":
	sys.exit(main())
