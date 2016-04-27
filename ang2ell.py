#!/usr/bin/env python

from __future__ import division
from proj_cov import *
import numpy as np

def ang2ell(az,phi,proj):
	## AZ is the azimuth CW from north, PH is the angle of the norm CW from Z upward
	## proj is the normal to projection define in the ENZ base for ex [0,0,1]

	az=az*np.pi/180
	phi=phi*np.pi/180

	####### Get n 

	nz=np.cos(phi)
	nx=np.sin(phi)*np.sin(az)
	ny=np.sin(phi)*np.cos(az)

	n=np.array([nx,ny,nz])

	####### Get perpendicular vectors to n

	z=np.array([0,0,1])
	u1=np.cross(n,z)
	u1=u1/np.linalg.norm(u1)
	u2=np.cross(n,u1)
	u2=u2/np.linalg.norm(u2)

	####### Reconstruct covariance

	lambda_mat=np.eye(3)
	lambda_mat[2,2]=0
	U=np.zeros(shape=(3,3))
	U[0][:]=u1
	U[1][:]=u2
	U[2][:]=n

	U=U.transpose()

	COV=np.dot(np.dot(U,lambda_mat),np.linalg.inv(U))
	
	### Get angles and major axes
	teta,major,minor=proj_cov(proj,COV)

	return teta,major,minor