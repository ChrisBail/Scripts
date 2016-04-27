#!/usr/bin/env python

import os
import re
import sys
import numpy as np
import matplotlib.pyplot as plt


cc_file='final_dt.cc'
ev_file='located.dat'
ev_fileout='event_select_out.dat'
out_file='pairs_nobs.out'
GMT_file='GMT.sh'
scale_fac=10

#----- Project lat lon in x y

center='167/-16'

os.system("awk '{print $4, $3, $5, $10}' %s > %s" % (ev_file,'temp.out'))
print "mapproject %s -Jm%s/7c -R100/180/-16/-14 -C -Fk > %s" %  ('temp.out',center,ev_fileout)
os.system("mapproject %s -Jt%s/7c -R100/180/-16/-14 -C -Fk > %s" %  ('temp.out',center,ev_fileout))

#---- Make dictionary from event.dat file

f1=open(ev_fileout,'r')
dic_ev={}
for line in f1:
	A=line.split()
	index_ev=int(A[-1])
	x,y,z=float(A[0]),float(A[1]),float(A[2])
	dic_ev[index_ev]=[x,y,z]
	#print dic_ev[10][0]

f1.close()

#---- Get the pair in dt file

f2=open(cc_file,'r')
lines=f2.readlines()

number_line=[]
nobs=[]
k=0
corrs=[]
mean_corr=[]

for i,line in enumerate(lines):
	if line[0]=='#':
		number_line.append(i)
		if i>0:
			mean_corr.append(np.mean(np.array(corrs)))
			corrs=[]
			k=k+1
	else:
		A=line.split()
		corr=float(A[2])
		corrs.append(corr)

mean_corr.append(np.mean(np.array(corrs)))

C=np.diff(number_line)-1
nobs=list(C)
nobs.append(len(lines)-number_line[-1]-1)
			

#------ Write into web file

f3=open(out_file,'w')
f2.seek(0,0)
ak=[]
total_index=[]
total_index_seuil=[]
dic_corr={}
dic_corr[1]=[]
dic_corr[2]=[]
dic_corr[3]=[]
dic_corr[4]=[]
dic_corr[5]=[]
k=0
for i,line in enumerate(f2):
	if line[0]=='#':
		A=line.split()
		index1,index2=int(A[1]),int(A[2]) 
		if index1 not in dic_ev or index2 not in dic_ev:
			k=k+1
			continue
		total_index.extend([index1,index2])
		if nobs[k]>=1:
			dic_corr[1].extend([index1,index2])
		if nobs[k]>=2:
			dic_corr[2].extend([index1,index2])
		if nobs[k]>=3:
			dic_corr[3].extend([index1,index2])
		if nobs[k]>=4:
			dic_corr[4].extend([index1,index2])
		if nobs[k]>=5:
			dic_corr[5].extend([index1,index2])
		list1=dic_ev[index1]
		list2=dic_ev[index2]
		#--- Compute interevent distance
		distance=(np.sum((np.array(list1)-np.array(list2))**2))**0.5
		ak.append(distance)
		f3.write('%7.2f %i %.3f\n' % (distance,nobs[k],mean_corr[k]))
		k=k+1
f2.close()
f3.close()

#---- find number of unique elements

A=np.unique(np.array(total_index))
print A,len(A)

xx=[]
yy=[]
for key, value in dic_corr.iteritems():
	xx.extend([key])
	yy.extend([len(np.unique(np.array(value)))])
	
print xx,yy

		
#------- Plot figure

plt.plot(np.array(xx),np.array(yy),'+--')
plt.xlabel('Number of observations threshold')
plt.ylabel('Number of events')
#fig = plt.figure(figsize=(10, 6)) 
#fig.suptitle('Cross-correlations catalog under the network (%i pairs)' % len(ak),fontsize=16)
#plt.subplot2grid((1,3),(0,0),colspan=2)
#plt.plot(np.array(ak),np.array(nobs),'go',markersize=3)
#plt.xlabel('Distance between events pair [km]')
#plt.ylabel('Number of observations per pair')
##plt.title('Relation between inter event distance and number of observations for correlation catalog')
#ax=plt.subplot2grid((1,3),(0,2))
#n, bins, patches = plt.hist(np.array(nobs), 35, normed=1,facecolor='blue', align='left',histtype='step', cumulative=-1,orientation='horizontal')
#plt.xlim(0,1)
#plt.ylim(0,35)
#ax.yaxis.tick_right()
#locs, labels = plt.xticks()
##plt.xticks(locs[2])
#plt.xticks(locs[1:],locs[1:])
#plt.xlabel('Cumulative pdf')
#plt.grid(True)
#plt.subplots_adjust(wspace=0,hspace=0)
plt.savefig('distance.pdf')



plt.show()		
