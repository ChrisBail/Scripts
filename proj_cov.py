#!/usr/bin/env python

import sys
import numpy as np

def proj_cov(n,COV):
	''' n and COV has to be define in the direct OENZ Z upward basis'''
	# Define filename
	n=np.array([n])
	#COV=np.array([[53.2900 ,59.1200 ,-85.4900],
	#   [59.1200,184.9600,-28.8100],
	#  [-85.4900 , -28.8100  , 60.8400]])

	# Create normal array

	#n=np.array([[0,0,-1]])
	n=n.transpose()
	n=n/np.linalg.norm(n) # normalize
	#print n
	# Define othonormal base on the plane

	if n[0,0]==0 and n[1,0]==0:
		e1=np.array([[1,0,0]])
	else:
		e1=np.array([[-n[1,0],n[0,0],0]])

	#print e1
	e2=np.cross(n.transpose(),e1)

	#print e2
	A=( np.eye(COV.shape[1]) - np.dot(n,n.transpose()))
	COVP=np.dot(np.dot(A,COV),A)

	eigval,eigvec=np.linalg.eig(COVP);
	v=np.argsort(eigval)
	ind=v[::-1]

	Q=eigvec[:,ind]
	Lam=eigval[ind]
	#print Q
	# 

	#print np.dot(Q[:,0],e1.transpose())
	#print Lam
	teta=np.arctan2(np.dot(Q[:,0],e2.transpose()), np.dot(Q[:,0],e1.transpose()))*180/(np.pi)
	#print Lam
	if Lam[0]>0:
		major=np.sqrt(Lam[0])
	else:
	#	print Lam[0]
		major=0
	if Lam[1]>0:
		minor=np.sqrt(Lam[1])
	else:
	#	print Lam[1]
		minor=0

	return teta[0],major,minor

