#!/usr/bin/env python

import numpy as np
import sys

file_b=sys.argv[1]
file_p=sys.argv[2]
file_o=sys.argv[3]

#file_b=bathy
#file_p=plane
#file_o=output


B=np.genfromtxt(file_b,dtype=None)
P=np.genfromtxt(file_p,dtype=None)

# find minimun ind
ind=np.where(np.absolute(B[:,0]) == np.min(np.absolute(B[:,0])))[0]
trench_y=B[ind,1]

P[P[:,0]<=0,1]=np.nan

ind_P=np.where(np.absolute(P[:,0]) == np.min(np.absolute(P[:,0])))[0]
P[ind_P,1]=trench_y
P[P[:,1]>=trench_y,1]=trench_y

# Remove nan values
P = P[np.logical_not(np.isnan(P[:,1])),:]

np.transpose(P)
np.savetxt(file_o, P,fmt='%8.3f')