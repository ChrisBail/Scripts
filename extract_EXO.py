#!/usr/bin/env python

import netCDF4
import sys
import numpy as np

''' Script made to extract coordinates of a nodeset from an exodus file, generated
by CUBIT

Input:	exodus file name
		nodeset name (make a ncdump exodusfile.exo in a bash terminal to see the names of nodeset)
Output:	file with columns corresponding to x and y coordinates
'''
### Parameter

filein=sys.argv[1]
nodeset_name=sys.argv[2]
#nodeset_name='node_ns7'   # which correspond to our fault surface

### Extract

exodus= netCDF4.Dataset(filein)

### Check if nodeset exist in file

if nodeset_name not in exodus.variables:
	print 'Nodeset %s not present in exodus file: Do a "ncdump %s" to see which nodesets exist' %(nodeset_name,filein)
	sys.exit()

node_num=exodus.variables[nodeset_name][:]

xcoord=exodus.variables['coordx'][:]
ycoord=exodus.variables['coordy'][:]

xnode=xcoord[node_num-1]
ynode=ycoord[node_num-1]

### Print to standard output


for i,c in enumerate(xnode):
	print '%11.3f   %11.3f' %(xnode[i], ynode[i])
	
	
	
