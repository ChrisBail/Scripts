#!/usr/bin/env python

import sys

def main():
	file1=sys.argv[1]
	file_ou=sys.argv[2]
	if len(sys.argv)<4:
		type=None
	else:
		type=sys.argv[3]
		
	#file1='collect_CLUS.out'
	#file_ou='collect_CLUS_fixed.out'
	#type='tl'
	
	# Rearrange type
	a=list(type)
	a.sort()
	b=''.join(a)
	type=b

	# Read file

	f1=open(file1,'r')
	fo=open(file_ou,'w')

	lines=f1.readlines()
	f1.close()

	for line in lines:
		if len(line)>81:
			print 'Line exceeds 80 character, check input file'
		if line[-2]!='1':
			fo.write('%s' %line)
		else:
			
			header=list(line)
			if type=='t':
				header[10]='F'
				header[43]=' '
				header[44]=' '
			elif type=='l':
				header[10]=' '
				header[43]=' '
				header[44]='F'
			elif type=='d':
				header[10]=' '
				header[43]='F'
				header[44]=' '
			elif type=='dl':
				header[10]=' '
				header[43]='F'
				header[44]='F'
			elif type=='dt':
				header[10]='F'
				header[43]='F'
				header[44]=' '
			elif type=='lt':
				header[10]='F'
				header[43]=' '
				header[44]='F'
			elif type=='dlt':
				header[10]='F'
				header[44]='F'
				header[43]='F'
			else:
				header[10]=' '
				header[43]=' '
				header[44]=' '

			new_header=''.join(header)	
			fo.write('%s' %new_header)
		
	fo.close()
			
if __name__ == "__main__":
    main()	

		