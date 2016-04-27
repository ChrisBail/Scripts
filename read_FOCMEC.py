#!/usr/bin/env python

import sys

#file_foc='focmec.dat'
file_foc=sys.argv[1]
file_pol='foc_polar.out'
file_amp='foc_amp.out'

###### Read focmec

f_foc=open(file_foc,'r')
lines=f_foc.readlines()
f_foc.close()

###### Open files

f_pol=open(file_pol,'w')
f_amp=open(file_amp,'w')
f_pol.write('station az takeoff pol_key\n')
f_amp.write('station az takeoff log10(amp) pol_key\n')

###### Start computation

for index,line in enumerate(lines):
	if index==0:
		continue
	station=line[0:4]
	az=float(line[5:12])
	to=float(line[13:20])
	pol=line[20]
	if pol=='H' or pol=='V' or pol=='S':
		log_amp=float(line[22:29])
		f_amp.write('%4s %7.2f %7.2f %8.4f %1s\n' %(station,az,to,log_amp,pol))
	f_pol.write('%4s %7.2f %7.2f %1s\n' %(station,az,to,pol))
		
f_pol.close()
f_amp.close()


