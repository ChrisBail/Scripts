#!/usr/bin/env python

import sys

def get_clus_index(file1,file2,file3):
	#file1='index.out'
	#file2='hypoDD_BEST.reloc'
	#file3='index_CLUS.out'


	# Read index file

	f1=open(file1,'r')
	dic1={}
	for line in f1:
		A=line.split()
		index=int(A[0])
		path=A[1]
		dic1[index]=path
	f1.close()

	# Read reloc or loc file

	f2=open(file2,'r')
	dic2={}
	for line in f2:
		A=line.split()
		index=int(A[0])
		clus=int(A[-1])
		dic2[index]=clus

	f2.close()

	# Rearrange dic so that each cluster has a list of index
	dd={}
	for key, value in dic2.items():
		try:
			dd[value].append(key)
		except KeyError:
			dd[value] = [key]

	# Assign and create files

	f3=open(file3,'w')
	for keys,values in dd.items():
		fi=open('index%04d.out' %keys,'w')
		values.sort()
		for index in values:
			fi.write('%5i  %s\n' %(index,dic1[index]))
			f3.write('%5i  %s\n' %(index,dic1[index]))
		fi.close()
	f3.close()