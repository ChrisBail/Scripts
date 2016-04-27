#!/usr/bin/env python

import sys
import numpy as np
from comp_norm import *

####### Define Files


file=sys.argv[1]


ou_file='mec_hash.out'
file_norm='norm_planes.out'
file_resum='resum_read.out'
#file='hash_seisan.out'
#ou_file='mec_hash.out'

######### Read file

fic=open(file,'r')

lines=fic.readlines()
fic.close()
count=0
strike=[]
dip=[]
rake=[]
fault_un,aux_un=[],[]
weighted,amp_error,stdr=[],[],[]
fault_plane,aux_plane=[],[]

for index,line in enumerate(lines):
	if line[0:15]=='Strike,dip,rake':
		A=line.split()
		count=count+1
		STR=float(A[1])
		DIP=float(A[2])
		RAKE=float(A[3])
		strike.append(A[1])
		dip.append(A[2])
		rake.append(A[3])
		
		#### compute normal to fault plane and auxiliary planee (see  STEIN & WYSESSION)
		N,D=comp_norm(STR,DIP,RAKE)
		fault_plane.append(N)
		aux_plane.append(D)
		
	elif line[0:27]=='Fault+aux plane uncertainty':
		A=line[28:].split()
		fault_un.append(float(A[0]))
		aux_un.append(float(A[1]))
	elif line[0:32]=='Weighted fraction of pol misfits':
		A=line[33:].split()
		weighted.append(float(A[0]))
	elif line[0:24]=='Average amplitrude error':
		A=line[25:].split()
		amp_error.append(float(A[0]))
	elif line[0:18]=='Station dist ratio':
		A=line[19:].split()
		stdr.append(float(A[0]))
		
############ Print file

fic=open(file_resum,'w')
fic.write('STR DIP RAKE error_F error_A pol_mis STDR\n')

for index in range(count):
	fic.write('%7s %7s %7s %5.1f %5.1f %5.2f %5.2f\n' %(
	strike[index],dip[index],rake[index],fault_un[index],aux_un[index],weighted[index],stdr[index] ))

fic.close()


############ Print file

fic=open(ou_file,'w')
fic.write('lon lat depth strike dip rake mag offset_lon offset_lat\n')

for index in range(count):
	fic.write('0 0 0 %5s %5s %5s 0 0 0\n' %(strike[index],dip[index],rake[index]))

fic.close()

############ Print file

fic=open(file_norm,'w')
fic.write('AZ_fault PHI_fault AZ_aux PHI_aux error_F error_A\n')

for index in range(count):
	fic.write('%6.1f %6.1f %6.1f %6.1f %5.1f %5.1f\n' %(fault_plane[index][0],fault_plane[index][1],
	aux_plane[index][0],aux_plane[index][1],fault_un[index],aux_un[index]))

fic.close()