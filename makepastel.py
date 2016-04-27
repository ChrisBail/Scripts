#!/usr/bin/python2.7
# Author: Wayne Crawford
#
import sys
from optparse import OptionParser		# Parser for command line options


def main() :
	"""Lighten a GMT cpt file to pastel colors
	"""
	
	usage = """usage: %prog infile"""
	parser = OptionParser(usage=usage)
	(options, args) = parser.parse_args()
	if len(args) < 1:
		print main.__doc__
		parser.print_help()
		return 2
		
	isHSV=False
	f=open(args[0],'r')
	lines = f.readlines()
	for line in lines:
		if line[0]=='#' :	# This is a comment line, write as is
			print line,
			if line.find('HSV')	!= -1: # Colors in Hue-Saturation-Value format
				isHSV=True;
		else:				# colormap value, convert to pastel
			d=line.split();
			if len(d)==8:
				if isHSV:
					print "%6s %7s %3.1f %4s %6s %7s %3.1f %4s" % \
							(d[0],d[1],0.5,d[3],d[4],d[5],0.5,d[7])
				else:
					print "%6s %3d %3d %3d %6s %3d %3d %3d" % \
							(d[0],toPas(d[1]),toPas(d[2]),toPas(d[3]), \
							 d[4],toPas(d[5]),toPas(d[6]),toPas(d[7]) )
			elif len(d)==4 and (d[0]=='B' or d[0]=='F'):
				if isHSV:
					print "%-4s %7s %3.1f %4s" % (d[0],d[1],0.5,d[3])
				else:
					print "%-4s %3d %3d %3d" % \
							(d[0],toPas(d[1]),toPas(d[2]),toPas(d[3]) )
			else:
				print line,
	f.close()
	return 0

#########################################################################
def toPas(inp) :
	return int(127+float(inp)/2)

	
#########################################################################
if __name__ == "__main__":
	sys.exit(main())
