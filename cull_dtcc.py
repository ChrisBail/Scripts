#!/usr/local/bin/python
# Author: Wayne Crawford
#
import sys
from optparse import OptionParser		# Parser for command line options


def main() :
	"""Reads a hypoDD dt.cc file and outputs the lines that have correlation
	above the specified threshold """
	
	usage = """usage: %prog dtccfile corr_threshold"""			

	parser = OptionParser(usage=usage)
	(options, args) = parser.parse_args()
		
	if len(args) != 2:
		print(main.__doc__)
		parser.print_help()
		return 2
	else :
		dtccfile=args[0]
		threshold=float(args[1])

	group=[]
	f=open(dtccfile,'r');
	for line in f :
		if line[0:1]=='#' :
			if len(group) > 1:
				for str in group:
					print(str,end='')
			group=[line];
		else :
			corr=float(line[13:18])
			if corr > threshold :
				group.append(line)
			
	f.close();
	if len(group)>1:
		for str in group :
			print(str,end='')
	

#########################################################################
if __name__ == "__main__":
	sys.exit(main())
