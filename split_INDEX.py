#!/usr/bin/env python

''' Program made to split index file into multiple index_file
for unknown reason hyp only accept files starting with index '''
import os
import sys

file1=sys.argv[1]
fic=open(file1,'r')

for line in fic:
	A=line.split()
	index_num=int(A[0])
	file_path=A[1]
	
	#### Define output_filename

	output_file='index%04d.out' %index_num
	foc=open(output_file,'w')
	foc.write(line+'\n')
	foc.close()
fic.close()