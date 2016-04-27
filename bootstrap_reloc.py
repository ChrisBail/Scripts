#!/usr/bin/env python

### Run bootstrap on relocated files

import os
import glob
import sys
from random import gauss
import matplotlib.pyplot as plt
from script import *

#--- Get defaults

master_event='event_select.dat'
master_dtct='dt_out.ct'
master_dtcc='07_dt_out.cc'
master_hypoDD='master_hypoDD.inp'
station='station.dat'
number_loop=200
dic_error={}
error_file='error.out'
ferr=open(error_file,'w')
ferr.write('CID  EX  EY  EZ\n')

top=' -5.0   2.0   4.0   6.0   8.5  11.0  13.5  19.5  26.0  33.5  42.0 101.0'
vel=' 4.0 4.4 4.8 5.2 5.7 6.8 7.0 7.1 7.5 8.2 8.9 9.0'
id=[]
cluster_ids=range(1,30)		# form of a list

#---- Create list of parameters for hypoDD

hypoDDinp_dic={'dtcc':master_dtcc,'dtct':master_dtct,'dat':master_event,'sta':station,\
'loc':'hypoDD.loc','reloc':'hypoDD.reloc','sta_res':'hypoDD.sta',\
'res':'hypoDD.res','src':'hypoDD.src',\
'idat':1,'ipha':3,'dist':1000,\
'obscc':2,'obsct':15,\
'istart':1,'isolv':2,\
'param':[[10,1.0,0.5,-9.0,5.0,0.01,0.05,3.0,5.0,100.0],[10,1.0, 0.5,3.0,5.0,0.01,0.05,3.0, 5.0,100.0]],\
'ratio':1.78,'top':top,'vel':vel,'cid':999,'id':id}


# 1--------- RUN HypoDD.inp for a given cluster

for cid in cluster_ids:

	print '######### PROCESSING CLUSTER %i ##########' %cid
	# 0 ------- Make directory to move results of bootsrapping
	
	dir_name='CLUSTER%03d'% cid
	if os.path.exists(dir_name):
		os.system('rm -fR %s'% dir_name)
	#	resp=raw_input('Would like to remove dir %s (y/n) ?\n'% dir_name)
	#	if resp=='y':
	#		os.system('rm -fR %s'% dir_name)
	#		os.system('mkdir %s'%dir_name)
	#	else:
	#		sys.exit()

	os.system('mkdir %s'%dir_name)	

	# 1.1--------- Edit hypoDD.inp
	
	print hypoDDinp_dic
	hypoDDinp_dic['cid']=cid		# update CID in list
	hypoDDinp_dic['loc']='master_'+('%03d' % cid)+'.loc'
	hypoDDinp_dic['reloc']='master_'+('%03d' % cid)+'.reloc'
	write_hypoDDinp(master_hypoDD,hypoDDinp_dic)
	
	# 1.2--------- Run hypoDD
	
	os.system('hypoDD '+master_hypoDD)
	
	# 2------------ Make synthetics from final.relocation
	# 2.1----------- Update dat and ct or cc files
	
	synthetic_event='synthetic_'+('%03d' % cid)+'.dat'
	synthetic_dtct='synthetic_'+('%03d' % cid)+'.ct'
	synthetic_dtcc='synthetic_'+('%03d' % cid)+'.cc'
	reloc2dat(hypoDDinp_dic['reloc'],synthetic_event)
	upd_dt('hypoDD.res',master_dtct,synthetic_dtct)
	upd_dt('hypoDD.res',master_dtcc,synthetic_dtcc)
	
	# 2.2------------ Check if synthetic give 0 residuals
	
	prefix='synthetic_'+('%03d' % cid)
	hypoDDinp_check=hypoDDinp_dic.copy()
	hypoDDinp_check['dtct']=synthetic_dtct
	hypoDDinp_check['cid']=1
	hypoDDinp_check['dtcc']=synthetic_dtcc
	hypoDDinp_check['dat']=synthetic_event
	hypoDDinp_check['obsct']=0
	hypoDDinp_check['obscc']=0 # No clustering performed
	hypoDDinp_check['istart']=1
	hypoDDinp_check['idat']=1
	hypoDDinp_check['param']=[[10,1,0.5,-9.0,-9.0,0.01,0.01,-9.0,-9.0,100]]
	hypoDDinp_check['res']=prefix+'.res'
	hypoDDinp_check['reloc']=prefix+'.reloc'
	hypoDDinp_check['loc']=prefix+'.loc'	
	write_hypoDDinp(prefix+'.inp',hypoDDinp_check)
	os.system('hypoDD '+prefix+'.inp')
	
	# 3 Perturb n times the dt.ct or dt.cc file
	
	for i in range(number_loop):
		k=i+1
		# 3.1------------- Add perturbations (gaussian noise) to the synthetic.ct or cc
		
		noisy_dtct='noisy_'+('%03d' % cid)+('_%03d' % k)+'.ct'
		noisy_dtcc='noisy_'+('%03d' % cid)+('_%03d' % k)+'.cc'
		#add_noise(synthetic_dtct,noisy_dtct)
		add_noise(synthetic_dtcc,noisy_dtcc,[0,0.01,0,0.01])
		
		# 3.2------------- Edit new hypoDD.inp by setting unit weights
		
		prefix='noisy_'+('%03d' % cid)+('_%03d' % k)
		hypoDDinp_bootstrap=hypoDDinp_dic.copy()
		hypoDDinp_bootstrap['dtct']=noisy_dtct
		hypoDDinp_bootstrap['cid']=1
		hypoDDinp_bootstrap['dtcc']=noisy_dtcc
		hypoDDinp_bootstrap['dat']=synthetic_event
		hypoDDinp_bootstrap['obsct']=0
		hypoDDinp_bootstrap['obscc']=0
		hypoDDinp_bootstrap['idat']=1
		hypoDDinp_bootstrap['istart']=1
		hypoDDinp_bootstrap['param']=[[10,1,0.5,-9.0,10,0.01,0.01,-9.0,-9.0,100]]
		hypoDDinp_bootstrap['res']=prefix+'.res'
		hypoDDinp_bootstrap['reloc']=prefix+'.reloc'
		hypoDDinp_bootstrap['loc']=prefix+'.loc'	
		write_hypoDDinp(prefix+'.inp',hypoDDinp_bootstrap)
		
		# 3.3------------ Run hypoDD.inp
		
		os.system('hypoDD '+prefix+'.inp')
	
		# 4--------- Move into directory
		
		print dir_name
		print 'mv %s %s/'%(prefix+'.reloc',dir_name)
		os.system('mv %s %s/'%(prefix+'*.reloc*',dir_name))
		os.system('mv %s %s/'%(prefix+'*.loc*',dir_name))
		os.system('mv %s %s/'%(prefix+'*.cc*',dir_name))
		os.system('mv %s %s/'%(prefix+'*.inp*',dir_name))
		os.system('mv %s %s/'%(prefix+'.res',dir_name))
		
	# 5----------- Make error plot and return EX,EY,EZ for each cluster
	
	EX,EY,EZ=get_error(dir_name,cid,'error_plot_'+('%03d' % cid)+'.pdf')
	
	dic_error[cid]={'EX':EX,'EY':EY,'EZ':EZ}
	ferr.write('%i %.f %.f %.f\n'% (cid,EX,EY,EZ))

ferr.close()	
	
	
	
	