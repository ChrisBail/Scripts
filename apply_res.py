#!/usr/bin/env python

def apply_res(filei,fileo):

	#filei='hyp.out'
	#fileo='hyp_o.out'

	## Read nor.py

	fic=open(filei,'r')

	## get lines
	lines= fic.read().splitlines()
	fic.close()

	foc=open(fileo,'w')

	for line in lines:
		if (line[-1]!=' ' or line=='%80c' %' '):
			foc.write('%s\n' %line)
		else:
			hour=float(line[18:20])
			min=float(line[20:22])
			sec=float(line[23:28])
			if line[63:68]=='*****':
				continue
				
			res=float(line[63:68])
			#print res
		
			# CONVERT TO seconds
			tot_time=hour*60*60+min*60+sec 
		
			# correct
			corr_time=tot_time-res
			min_c, sec_c = divmod(corr_time, 60)
			hour_c, min_c = divmod(min_c, 60)
		
			dat_array=list(line)
		
			dat_array[18:20]='%2i' %hour_c
			dat_array[20:22]='%2i' %min_c
			dat_array[23:28]='%5.2f' %sec_c
		
			dat_array=''.join(dat_array)
			foc.write('%s\n' %dat_array)
		
		
	foc.close()
			