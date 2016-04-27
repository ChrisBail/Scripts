#!/usr/bin/env python

### add_noise

import os
import glob
import sys
from random import gauss
import numpy as np


################ Add noise to dt.ct file
#########################################

def add_noise(file1,file2,param=None):

	#-------- Check file extension
	
	type_file1=file1[file1.index('.')+1:]
	type_file2=file2[file2.index('.')+1:]
	
	if not (type_file1=='cc' or type_file1=='ct'):
		print 'files should be .cc or .ct files'
		return
	if type_file2!=type_file1:
		print 'files should have same extension'
		return

	f1=open(file1,'r')
	f2=open(file2,'w')
	
	#file1='dt.ct'
	#file2='dt_perturbed.ct'

	#------- Define default parameter for noise
	if param is None:
		param=[0,0.1,0,0.1]
	
	mup,sigmap,mus,sigmas=param[0],param[1],param[2],param[3]
	print param

	#----- Start loop (distinguish case ct or cc)
	
	if type_file1=='ct':
		for i,line in enumerate(f1):
			if line[0]=='#':
				f2.write(line)
				continue
			else:
				A=line.split()
				station=A[0]
				time1, time2=float(A[1]), float(A[2])
				phase=A[4]
				corr=float(A[3])
		
				#----- Add Noise
				if phase=='P':
					time1=time1+gauss(mup,sigmap)
					time2=time2+gauss(mup,sigmap)
				else:
					time1=time1+gauss(mus,sigmas)
					time2=time2+gauss(mus,sigmas)
	
			#--- Write into file
			f2.write('%5s %9.3f %7.3f %6.4f %1s\n' % (station,time1,time2,corr,phase))
	else:
		for i,line in enumerate(f1):
			if line[0]=='#':
				f2.write(line)
				continue
			else:
				A=line.split()
				station=A[0]
				dt_time=float(A[1])
				phase=A[3]
				corr=float(A[2])
		
				#----- Add Noise
				if phase=='P':
					dt_time=dt_time+gauss(mup,2*sigmap)
				else:
					dt_time=dt_time+gauss(mus,2*sigmas)
	
			#--- Write into file
			f2.write('%5s %7.3f %6.4f %1s\n' % (station,dt_time,corr,phase))
	#---- Close files

	f1.close(), f2.close()

	#----- For plotting uncomment following lines	  

	#values = []
	#while len(values) < 100000:
	#    value = gauss(0,0.1)
	#    values.append(value)
	#n, bins, patches = ax.hist(values, 50, normed=1, facecolor='green', alpha=0.75)
	#plt.show()

################### Program made to covert reloc file to .dat file
##################################################################

# file1 .reloc file
# file2 new.dat file

def reloc2dat(file1,file2):
	f1=open(file1,'r')
	f2=open(file2,'w')

	for line in f1:
		A=line.split()
		ymd='%4i%02i%02i' % (int(A[10]),int(A[11]),int(A[12]))
		hms='%2i%02i%02i%02i' % (int(A[13]),int(A[14]),int(A[15][-6:-4]),int(A[15][-3:-1]))
		lat=float(A[1])
		lon=float(A[2])
		depth=float(A[3])
		mag=float(A[16])
		CID=int(A[0])
		#print '%s  %s %9.4f %9.4f %9.3f %4.1f %6.2f %6.2f %6.2f %9i' % (ymd,hms,lat,lon,depth,mag,0,0,0,CID)
		f2.write('%s  %s %9.4f %10.4f %10.3f %5.1f %7.2f %7.2f %6.2f  %9i\n' % (ymd,hms,lat,lon,depth,mag,0,0,0,CID))

	f1.close(), f2.close()
	
###################### Program made update dt file in hypoDD 
##################################################################

def upd_dt(file1,file2,file3):
	
	#-------- Check file extension
	
	type_file1=file1[file1.index('.')+1:]
	type_file2=file2[file2.index('.')+1:]
	type_file3=file3[file3.index('.')+1:]
	
	if type_file1!='res':
		print 'Check file order and extensions'
		return
	if type_file2!=type_file3:
		print '2nd and 3rd files should have same extension'
		return
	if not (type_file2=='cc' or type_file2=='ct'):
		print '2nd and 3rd files should be .cc or .ct files'
		return
	
	#file1='hypoDD.res'
	#file2='dt_out.ct'
	#file3='hypoDD_clus001.ct'
	#file1=sys.argv[1]
	#file2=sys.argv[2]

	f1=open(file1,'r')
	f2=open(file2,'r')
	f3=open(file3,'w')

	id1=[]
	id2=[]

	dict1={}
	data_dict={}

	for i,line in enumerate(f1):
		if i==0:
			continue
		A=line.split()
		index1=int(A[2])
		index2=int(A[3])
		station=A[0]
		DT=float(A[1])
		phase=A[4]
		RES=float(A[6])
		if i>1:
			if index1!=index1_last or index2!=index2_last:
				dict1['%7i%7i'%(index1_last,index2_last)]=data_dict
				data_dict={}
		data_dict[(station,phase)]=RES
	
		index1_last=index1
		index2_last=index2
	#----- Check kind of file
	
	if type_file2=='ct':
		k=0
		for i,line in enumerate(f2):
			if line[0]!='#':
				if flag_write:
					A=line.split()
					station=A[0]
					time1=float(A[1])
					time2=float(A[2])
					corr=float(A[3])
					phase=A[4]
					if phase=='P':
						phase='3'
					else:
						phase='4'
					if data.has_key((station,phase)):
						RES=data[(station,phase)]
						time2=time2+RES/1000
						f3.write('%5s %9.3f %7.3f %6.4f %1s\n' % (station,time1,time2,corr,A[4]))				
				else:
					continue
			else:
				A=line.split()
				index1=int(A[1])
				index2=int(A[2])
				flag_write=False
				if 	dict1.has_key('%7i%7i'%(index1,index2)):
					k=k+1
					flag_write=True
					data=dict1['%7i%7i'%(index1,index2)]
					#print '%7i%7i'%(index1,index2)
					f3.write(line)
	else:
		k=0
		for i,line in enumerate(f2):
			if line[0]!='#':
				if flag_write:
					A=line.split()
					station=A[0]
					dt_time=float(A[1])
					corr=float(A[2])
					phase=A[3]
					if phase=='P':
						phase='1'
					else:
						phase='2'
					if data.has_key((station,phase)):
						RES=data[(station,phase)]
						dt_time=dt_time+RES/1000
						f3.write('%5s %7.3f %6.4f %1s\n' % (station,dt_time,corr,A[3]))				
				else:
					continue
			else:
				A=line.split()
				index1=int(A[1])
				index2=int(A[2])
				flag_write=False
				if 	dict1.has_key('%7i%7i'%(index1,index2)):
					k=k+1
					flag_write=True
					data=dict1['%7i%7i'%(index1,index2)]
					#print '%7i%7i'%(index1,index2)
					f3.write(line)

	#print k

	f1.close()
	f2.close()
	f3.close()

###################### Program made to write hypoDD.inp
##################################################################

def write_hypoDDinp(file1,dic):
	
	dtcc,dtct,dat,sta,loc,reloc,sta_res=dic['dtcc'],dic['dtct'],dic['dat'],dic['sta'],dic['loc'],dic['reloc'],dic['sta_res']
	res,src=dic['res'],dic['src']
	idat,ipha,dist=dic['idat'],dic['ipha'],dic['dist']
	obscc, obsct=dic['obscc'],dic['obsct']
	istart,isolv=dic['istart'],dic['isolv']
	param=dic['param']
	nset=len(param)
	ratio,top,vel,cid,id=dic['ratio'],dic['top'],dic['vel'],dic['cid'],dic['id']
	#file1='hypoDD_test.inp'
	f1=open(file1,'w')

	#---- Define parameters

	#dtcc='dt.cc'
	#dtct='dt.ct'
	#dat='event.dat'
	#sta='station.sta'
	#loc='hypoDD.loc'
	#reloc='hypoDD.reloc'
	#sta_res='hypoDD.sta'
	#res='hypoDD.res'
	#src='hypoDD.src'

	#---

	#idat, ipha, dist = 2, 3, 10000
	#obscc, obsct = 3, 15
	#istart,isolv,nset= 1, 2, 2
	#ratio=1.78
	#cid=1
	#id=[]
	#param=[[7,0.01,0.01,-9,-9,1,0.50,-9,-9,1]]
	#param.extend(param)
	#vel= '4.0 4.4 4.8 5.2 5.7 6.8 7.0 7.1 7.5 8.2 8.9 9.0'
	#top='-5.0   2.0   4.0   6.0   8.5  11.0  13.5  19.5  26.0  33.5  42.0 101.0'

	#---- Check parameters

	nlay=len(top.split())
	if len(vel.split()) != nlay:
		print 'VEL and TOP not same length'
		sys.exit()


	txt='* hypoDD.inp:\n\
*--- INPUT FILE SELECTION\n\
* filename of cross-corr diff. time input(blank if not available);:\n'+\
	dtcc+'\n'+\
	'* filename of catalog travel time input(blank if not available);:\n'+\
	dtct+'\n'+\
	'* filename of initial hypocenter input:\n'+\
	dat+'\n'+\
	'* filename of station input:\n'+\
	sta+'\n'+\
	'*\n\
*--- OUTPUT FILE SELECTION\n\
* filename of initial hypocenter output (if blank: output to hypoDD.loc);:\n'+\
	loc+'\n'+\
	'* filename of relocated hypocenter output (if blank: output to hypoDD.reloc);:\n'+\
	reloc+'\n'+\
	'* filename of station residual output (if blank: no output written);:\n'+\
	sta_res+'\n'+\
	'* filename of data residual output (if blank: no output written);:\n'+\
	res+'\n'+\
	'* filename of takeoff angle output (if blank: no output written);:\n'+\
	src+'\n'+\
	'*\n\
*--- DATA SELECTION:\n\
* IDAT IPHA DIST\n'
	f1.write(txt)
	f1.write('%i %i %7.0f\n' % (idat,ipha,dist))

	f1.write('*\n\
*--- EVENT CLUSTERING:\n\
* OBSCC OBSC\n')
	f1.write('%i %i\n' % (obscc,obsct))

	f1.write('*\n\
*--- SOLUTION CONTROL\n\
* ISTART ISOLV NSET\n')
	f1.write('%i %i %i\n' % (istart,isolv,nset))

	f1.write('*\n\
*--- DATA WEIGHTING AND REWEIGHTING:\n\
* NITER WTCCP WTCCS WRCC WDCC WTCTP WTCTS WRCT WDCT DAMP\n')
	k=0
	for li in param:
		f1.write('%4i %5.2f %5.2f %5.2f %5.2f %5.2f %5.2f %5.2f %5.2f %5.1f\n' \
		% (li[0],li[1],li[2],li[3],li[4],li[5],li[6],li[7],li[8],li[9]))
		k=k+1

	f1.write('*\n\
*--- MODEL SPECIFICATIONS:\n\
* NLAY RATIO\n')
	f1.write('%i %.2f\n' % (nlay,ratio))

	f1.write('* TOP:\n')
	f1.write('%s\n' % top)

	f1.write('* VEL:\n')
	f1.write('%s\n' % vel)

	f1.write('*\n\
*--- CLUSTER/EVENT SELECTION:\n\
* CID\n')
	f1.write('%i\n' % cid)
	f1.write('* ID\n')

	if len(id)!=0:
		for val in id:
			f1.write('%i ' % val)
	f1.write('\n')
	
	f1.close()
	
	#!/usr/bin/env python

###################### Program made to read hypoDD.inp
##################################################################

def read_hypoDDinp(file1):
	#file1='hypoDD.inp'
	f1=open(file1,'r')

	#---- Define parameters

	#dtcc='dt.cc'
	#dtct='dt.ct'
	#dat='event.dat'
	#sta='station.sta'
	#loc='hypoDD.loc'
	#reloc='hypoDD.reloc'
	#sta_res='hypoDD.sta'
	#res='hypoDD.res'
	#src='hypoDD.src'

	#---

	#idat, ipha, dist = 2, 3, 10000
	#obscc, obsct = 3, 15
	#istart,isolv,nset= 1, 2, 2
	#ratio=1.78
	#cid=1
	#id=[]
	#param=[[7,0.01,0.01,-9,-9,1,0.50,-9,-9,1]]
	#param.extend(param)
	#vel= '4.0 4.4 4.8 5.2 5.7 6.8 7.0 7.1 7.5 8.2 8.9 9.0'
	#top='-5.0   2.0   4.0   6.0   8.5  11.0  13.5  19.5  26.0  33.5  42.0 101.0'

	#---- Check parameters

	filenames=[]
	all_lines=f1.readlines()
	k=0
	param=[]
	i_nset=1

	for i,line in enumerate(all_lines):
		if line[0]=='*':
			continue
		else:
			k=k+1
			if k<10:
				filenames.append(line.strip())
			else:
				A=line.split()
				if all_lines[i-1]=='* IDAT IPHA DIST\n':
					idat,ipha,dist=int(A[0]),int(A[1]),float(A[2])
				elif all_lines[i-1]=='* OBSCC OBSCT\n':
					obscc,obsct=[int(val) for val in A]
				elif all_lines[i-1]=='* ISTART ISOLV NSET\n':
					istart,isolv,nset=[int(val) for val in A]
				elif all_lines[i-i_nset]=='* NITER WTCCP WTCCS WRCC WDCC WTCTP WTCTS WRCT WDCT DAMP\n':
					i_nset=i_nset+1
					par=[[float(val) for val in A]]
					param.extend(par)
				elif all_lines[i-1]=='* NLAY RATIO\n':
					nlay=int(A[0])
					ratio=float(A[1])
				elif all_lines[i-1]=='* TOP:\n':
					top=line[:-1]
				elif all_lines[i-1]=='* VEL:\n':
					vel=line[:-1]
				elif all_lines[i-1]=='* CID\n':
					cid=int(A[0])
				elif all_lines[-1]=='* ID\n':
					id=[]
				elif all_lines[i-1]=='* ID\n':	
					id=[int(val) for val in A]
				else:
					continue

	dtcc,dtct,dat,sta,loc,reloc,sta_res,res,src=[filename for filename in filenames]

	return dtcc,dtct,dat,sta,loc,reloc,sta_res,res,src,\
	idat,ipha,dist,\
	obscc, obsct,\
	istart,isolv,nset,\
	param,\
	ratio,top,vel,cid,id

	f1.close()
	
def write_GMTblock(filename,ps_file):
	#filename='GMT.sh'
	f1=open(filename,'w')
	#ps_file='plot.ps'

	main_block="#!/bin/bash\n\
gmtdefaults -D > .gmtdefaults4\n\
gmtset PAPER_MEDIA	a4\n\
gmtset LABEL_FONT_SIZE 12p\n\
gmtset OBLIQUE_ANOTATION 0\n\
gmtset PAGE_ORIENTATION portrait\n\
gmtset ANNOT_FONT_SIZE_PRIMARY 10p\n\
gmtset HEADER_FONT_SIZE 12p\n\
gmtset COLOR_MODEL=RGB\n\
export LC_NUMERIC=POSIX\n\
\n\
\n\
if ! test -d tmp ; then\n\
mkdir tmp\n\
fi\n\
origin='167/-16'\n\
lscale='7'\n\
scalerange=\"-Jm${origin}/${lscale}c -R166/168/-16.75/-14.5\"\n\
stationsymbol='-St0.2c -Gyellow -W0.5pt'\n\
\n\
#------- Input_files\n\
path_plot='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Grids/'\n\
grid=$path_plot'Vanuatu235m.grd'\n\
#trench=$path_plot'Smooth_Trench_Depth.txt'\n\
trench=$path_plot'Trench.txt'\n\
stationfile='/Users/baillard/_Moi/Programmation/GMT/Vanuatu/Programs/Stations/station_vanuatu.sta'\n\
\n\
makecpt -Cjet -I -T1/100/1 > tmp/color.cpt\n\
cat << END > tmp/contour.out\n\
0 C\n\
END\n\
\n\
awk '(NR>1 && NF>2){ li=substr($0,23,5);la=gsub(/ /,\"\",li); print substr($0,14,8),-substr($0,5,7),li/1000 }' $stationfile > tmp/stations.xyz\n\
\n\
#-------- Plot\n"

	f1.write(main_block)
	f1.write('psbasemap $scalerange -B30mWeSn -K > %s\n' % ps_file) 
	f1.write('grdgradient $grid -A0 -Nt -Gtemp_int.grd\n') 
	f1.write('grdimage $grid -Itemp_int.grd -Bwesn -Ctmp/temp.cpt $scalerange -O -K >> %s\n' % ps_file)   
	f1.write('grdcontour $grid -J -R -Ctmp/contour.out -O -K >> %s\n' % ps_file)   
	f1.write('psxy tmp/stations.xyz $scalerange $stationsymbol -O -K >> %s\n' % ps_file) 
 

	f1.close()

###################### Function made to read loc file
##################################################################

def read_loc(loc_file):
	"Function made to read .loc .reloc or even .dat files, check hypoDD manual for format specification"
	#loc_file='event_select.dat'
	if loc_file.find('.')==-1:
		print 'No file extension given. Cannot read it'
		return
	
	type_file=loc_file[loc_file.index('.')+1:]
	print type_file
	if type_file=='loc':
		dic_event={}
		f1=open(loc_file,'r')
		for line in f1:
			A=line.split()
			index=int(A[0])
			lon,lat,depth=float(A[2]),float(A[1]),float(A[3])
			cid=int(A[-1])
			event_data={'lon':lon,'lat':lat,'depth':depth,'cid':cid,'res':999,'res_cc':999,'res_ct':999}
			dic_event[index]=event_data
		#print dic_event,len(dic_event)
		f1.close()
	elif type_file=='reloc':
		dic_event={}
		f1=open(loc_file,'r')
		for line in f1:
			A=line.split()
			index=int(A[0])
			lon,lat,depth=float(A[2]),float(A[1]),float(A[3])
			res_cc,res_ct=float(A[-3]),float(A[-2])
			cid=int(A[-1])
			event_data={'lon':lon,'lat':lat,'depth':depth,'cid':cid,'res':999,'res_cc':res_cc,'res_ct':res_ct}
			dic_event[index]=event_data
	
		f1.close()
	elif type_file=='dat':
		dic_event={}
		f1=open(loc_file,'r')
		for line in f1:
			A=line.split()
			index=int(A[-1])
			lon,lat,depth=float(A[3]),float(A[2]),float(A[4])
			res=float(A[-2])
			eh,ez=float(A[-4]),float(A[-3])
			event_data={'lon':lon,'lat':lat,'depth':depth,'eh':eh,'ez':ez,'cid':999,'res':res,'res_cc':999,'res_ct':999}
			dic_event[index]=event_data
			#print dic_event,len(dic_event)
		f1.close()
	else:
		print 'Cannot read file! Wrong extension? Check fffile...'
		return
	return dic_event

###################### Function made to put GMT .cpt info into dictionary
##########################################################################

def get_cpt(filename):
	
	f1=open(filename,'r')
	dic_color={}
	for line in f1:
		if line[0]=='B':
			break
		elif line[0]=='#':
			continue
		else:
			A=line.split()
			dic_color[int(A[0])]='%i/%i/%i' % (int(A[1]),int(A[2]),int(A[3]))
	f1.close()
	return dic_color
	
###################### Return GMT .xyz and .txt legend files
##########################################################################
#res=[0.2, 0.5, 1.0, 2.0]
#xpos=167.7
#ypos=[-14.7, -14.75, -14.82, -14.94]
#shift=0.1
#title_legend='Residuals [s]'

def legend_GMT(data,text,xpos,ypos,shift,title,file_xys,file_txt):

	if len(ypos)!=len(data):
		print 'Check size of lists given as inputs'
		return

	f1=open(file_xys,'w')
	f2=open(file_txt,'w')
	for i,val in enumerate(data):
		if i==0:
			top=np.max(ypos)
			f2.write('%.3f %.3f 12 0 0 CM %s\n' %(xpos+shift/2,top+0.15,title))
		f1.write('%.3f %.3f %.3f\n' %(xpos,ypos[i],val))
		f2.write('%.3f %.3f 10 0 0 LM %s\n' %(xpos+shift,ypos[i],text[i]))
	f1.close()
	f2.close()
	
###################### get error from bootstrap
##########################################################################

def get_error(path_cluster,cid,output_filename):
	"""
	Function made to read reloc files from a bootstrap cluster and returns error plot and errors
	"""
	#---------- Function made to read

	#-----Parameters
	import matplotlib.pyplot as plt
	from matplotlib.patches import Ellipse
	
	dx=[]
	dy=[]
	dz=[]
	xx=[]
	yy=[]
	zz=[]
	#cid=3
	center='167/-16' # projection center
	dic_diff={}
	files=glob.glob(path_cluster+'/*reloc')
	k=0

	#------ Compute difference

	for f in files:
		dic_event={}
		os.system("awk '{print $3, $2, $4, $1}' %s | mapproject -Jt%s/7c -R100/180/-16/-14 -C -Fk > %s" %  (f,center,'tmp/temp.out'))
		f1=open('tmp/temp.out','r')
		for line in f1:
			A=line.split()
			index=int(A[-1])
			x,y,z=float(A[0]),float(A[1]),float(A[2])
			dic_event[index]={'x':x,'y':y,'z':z}
		f1.close()
		if k==0:
			dic_test=dic_event.copy()
		
		#---- Substract the two dic to get dx,dy,dz

		for k,val in dic_event.items():
			dic_diff.setdefault(k,{'x':[],'y':[],'z':[]})
			if k in dic_diff.keys():
				dic_diff[k]['x'].append(dic_event[k]['x'])
				dic_diff[k]['y'].append(dic_event[k]['y'])
				dic_diff[k]['z'].append(dic_event[k]['z'])
				dx.append(val['x'])#-dic_test[k]['x'])
				dy.append(val['y'])#-dic_test[k]['y'])
				dz.append(val['z'])#-dic_test[k]['z'])
		
	
		k=k+1;

	
	# 
	for k,val in dic_diff.iteritems():
		xx.extend(list(np.array(val['x'])-np.median(val['x'])))
		yy.extend(list(np.array(val['y'])-np.median(val['y'])))
		zz.extend(list(np.array(val['z'])-np.median(val['z'])))
	
	#print xx
	#print np.mean(xx),np.mean(yy),np.mean(zz)
	#sys.exit()
	#--------- Get ellipse error


	def plot_point_cov(points, nstd=2, ax=None, **kwargs):
		"""
		Plots an `nstd` sigma ellipse based on the mean and covariance of a point
		"cloud" (points, an Nx2 array).

		Parameters
		----------
			points : An Nx2 array of the data points.
			nstd : The radius of the ellipse in numbers of standard deviations.
				Defaults to 2 standard deviations.
			ax : The axis that the ellipse will be plotted on. Defaults to the 
				current axis.
			Additional keyword arguments are pass on to the ellipse patch.

		Returns
		-------
			A matplotlib ellipse artist
		"""
		pos = points.mean(axis=0)
		cov = np.cov(points, rowvar=False)
		return plot_cov_ellipse(cov, pos, nstd, ax, **kwargs)

	def plot_cov_ellipse(cov, pos, nstd=2, ax=None, **kwargs):
		"""
		Plots an `nstd` sigma error ellipse based on the specified covariance
		matrix (`cov`). Additional keyword arguments are passed on to the 
		ellipse patch artist.

		Parameters
		----------
			cov : The 2x2 covariance matrix to base the ellipse on
			pos : The location of the center of the ellipse. Expects a 2-element
				sequence of [x0, y0].
			nstd : The radius of the ellipse in numbers of standard deviations.
				Defaults to 2 standard deviations.
			ax : The axis that the ellipse will be plotted on. Defaults to the 
				current axis.
			Additional keyword arguments are pass on to the ellipse patch.

		Returns
		-------
			A matplotlib ellipse artist
		"""
		def eigsorted(cov):
			vals, vecs = np.linalg.eigh(cov)
			order = vals.argsort()[::-1]
			return vals[order], vecs[:,order]

		if ax is None:
			ax = plt.gca()
		
		vipal, vipvec = np.linalg.eig(cov)
		xd, yd = 2 * nstd * np.sqrt(vipal)
	
		vals, vecs = eigsorted(cov)
		theta = np.degrees(np.arctan2(*vecs[:,0][::-1]))

		# Width and height are "full" widths, not radius
		width, height = 2 * nstd * np.sqrt(vals)
		ellip = Ellipse(xy=pos, width=width, height=height, angle=theta, **kwargs)

		ax.add_artist(ellip)
	
		return ellip,xd,yd


	#------- Make plot

	fig=plt.figure()

	vx=np.array(xx)*1000	# Convert to m
	vy=np.array(yy)*1000
	vz=np.array(zz)*1000

	s1=plt.subplot(121)
	aa=np.extract(np.abs(vz<500),vx)
	#print len(aa),len(vx)
	#sys.exit()
	points1=np.array([np.clip(vx,-500,500),np.clip(vy,-500,500)]).transpose()
	plt.plot(vx,vy, '+',markersize=5,zorder=1,color='0.75',lw=0.1)
	a,XERR,YERR=plot_point_cov(points1, nstd=2,edgecolor='black',linewidth=2,fill=False)
	plt.xlabel('DX [m]')
	plt.ylabel('DY [m]')
	a=s1.axis()
	plt.axis('equal')
	plt.axis([-300,300,-300,300]) 
	#a=s1.axis()
	#plt.xticks(np.arange(-np.max(a[:1]), np.max(a[:1]), 5))
	#plt.yticks(np.linspace(-np.max(a[2:]), np.max(a[2:]), 7))
	
	s2=plt.subplot(122)
	points=np.array([np.clip(vx,-500,500),np.clip(vz,-500,500)]).transpose()
	plt.plot(vx,vz, '+',markersize=5,zorder=1,color='0.75',lw=0.1)
	a,XERR,ZERR=plot_point_cov(points, nstd=2, edgecolor='black',linewidth=2,fill=False)
	plt.axis([-300,300,-300,300]) 
	plt.xlabel('DX [m]')
	plt.ylabel('DZ [m]')
	#a=s2.axis()
	#plt.axis([-np.max(a[:1]),np.max(a[:1]),-np.max(a[2:]),np.max(a[2:])])
	#a=s1.axis()
	#plt.xticks(np.linspace(-np.max(a[:1]), np.max(a[:1]), 5))
	#plt.yticks(np.linspace(-np.max(a[2:]), np.max(a[2:]), 7))
	
	#plt.show()
	plt.subplots_adjust(wspace=0.4,hspace=0)
	fig.suptitle('Spatial errors [m] for cluster %i (EX=%.f, EY=%.f, EZ=%.f)' % (cid,XERR,YERR,ZERR),fontsize=14)
	plt.savefig(output_filename)

	return XERR,YERR,ZERR
	
def test():
	return 'helflffo'