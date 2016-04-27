#!/usr/bin/env python

from fix_nor import *
from apply_res import *
import os

filename=sys.argv[1]
fileo=sys.argv[2]

print filename
print fileo
sta_lis=['VKOLH','VSARA','VANGO','VTURT','VBUTM','VWUSI','VLEBE','VIRHO',
'VTAMB','VSULE','VEBEN','VBOKI','VSALE','VAVUN','VASAV',
'VPOTO','VESPI','VNARW','VLAKA','VLEVI']

## Read nor.py

fic=open(filename,'r')

## get lines
lines= fic.read().splitlines()
fic.close()

foc=open('temp1.out','w')

for line in lines:
	if line[-1]=='1':
		foc.write('%s\n' %line)
		hour=float(line[11:13])
		min=float(line[13:15])
		sec=float(line[16:20])
		flag=True
	elif line[-1]!=' ':
		foc.write('%s\n' %line)
	elif flag==True:
		flag=False
		count=0
		while count<len(sta_lis):
			dat_line=[' ']*80;
			dat_line[1:6]=sta_lis[count]
			dat_line[6:8]='BZ'
			dat_line[10:12]='Pg'
			dat_line[18:20]='%2i' %hour
			dat_line[20:22]='%02i' %min
			dat_line[22:28]='%6.2f' %sec
			p_line=''.join(dat_line)
			dat_line[10:12]='Sg'
			s_line=''.join(dat_line)
			foc.write('%s\n' %p_line)
			foc.write('%s\n' %s_line)
			count=count+1
		foc.write('%80c\n' %' ')
foc.close()
			
## Fix file to current location
	
fix_nor('temp1.out','temp2.out','tld')

# Inverse it with hyp

cmd='hyp << EOF\ntemp2.out\nn\nEOF'
os.system(cmd)
os.system('mv hyp.out temp3.out')

# Correct from residual

apply_res('temp3.out','temp4.out')

# Unfix location

fix_nor('temp4.out','temp5.out','')

# Invert it

cmd='hyp << EOF\ntemp5.out\nn\nEOF'
os.system(cmd)
os.system('mv hyp.out %s' %fileo)