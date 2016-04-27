#!/usr/bin/env python

### file made to convert xy file into segment for GMT, specify str into str, for plotting lines

import sys
file=sys.argv[1]
str=sys.argv[2]

### Specify string

#str='-W0.2p'

fic=open(file)
lines=fic.readlines()

for line in lines:
	print "> %s" %str
	A=line.split()
	print "%s 0" %A[0]
	print "%s %s" %(A[0],A[1])

fic.close()
