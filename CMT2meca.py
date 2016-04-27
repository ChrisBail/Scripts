#!/usr/bin/env python

import numpy as np
import sys

def main():

	#### Define files
	file=sys.argv[1]
	fic=open(file,'r')
	line='test'

	### Read files
	while len(line)>0:
		line=fic.readline()
		if len(line)==102:
			
			year=float(line[5:9])
			line_short=line[9:]
			A=line_short.split()
			month,day,mags,magw=float(A[0]),float(A[1]),float(A[8]),float(A[9])
			if magw==0:
				mag=mags
			else:
				mag=magw
				
			M=[]
			while len(line)>1:
				line=fic.readline()
				B=line.split()
				if not B:
					break
				if B[0]=='event':
					event_code=B[2]
				elif B[0]=='latitude:':
					lat=float(B[1])
				elif B[0]=='longitude:':
					lon=float(B[1])
				elif B[0]=='depth:':
					depth=float(B[1])
				elif B[0]=='Mrr:':
					M.append(B[1])
				elif B[0]=='Mtt:':	
					M.append(B[1])
				elif B[0]=='Mpp:':	
					M.append(B[1])
				elif B[0]=='Mrt:':	
					M.append(B[1])
				elif B[0]=='Mrp:':	
					M.append(B[1])
				elif B[0]=='Mtp:':	
					M.append(B[1])
		
		
			### Retrieve expo
			
			C=[float(x) for x in M]
			maxx=np.max(C)
			maxx_str=str(maxx)
			### get component of highste
			expo=float('1.%s'%maxx_str[maxx_str.index('e+'):])
			D=np.array(C)/expo
			expo_str=str(expo)
			expo_value=float(expo_str[expo_str.index('e+')+2:])
			
			#### Print into file
		
			#foc.write('%6.2f %6.2f %4.0f %5.2f %5.2f %5.2f %5.2f %5.2f %5.2f %2i X Y %i %2i %2i %3.1f\n'
			#%(lon,lat,depth,D[0],D[1],D[2],D[3],D[4],D[5],expo_value,year,month,day,mag))
		
			print '%6.2f %6.2f %4.0f %5.2f %5.2f %5.2f %5.2f %5.2f %5.2f %2i 0 0 %i %2i %2i %3.1f'\
			%(lon,lat,depth,D[0],D[1],D[2],D[3],D[4],D[5],expo_value,year,month,day,mag)
	
	fic.close()

if __name__ == "__main__":
    main()