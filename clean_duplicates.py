#!/usr/bin/env python
"""
Created on Tue Mar 17 11:19:38 2015

Program created to remove duplicate lines from a nor2xyz file

@author: baillard
"""
import collections
import argparse
import numpy as np

### Parse the command line
parser = argparse.ArgumentParser(description='Remove duplicate events based on datetime')
parser.add_argument("filename", type=str,
                    help="display a square of a given number")
args = parser.parse_args()
filein=args.filename
fic=open(filein,'r')
lines=fic.readlines()

# Get the date column

date=[]
dic_ini={}
for line in lines:
    A=line.split()
    date.append(A[3])

# Get the List of unique elements

uniq_set=set(date)
uniq=sorted(list(uniq_set))

# Check out doublons

dups = collections.defaultdict(list)
for index, item in enumerate(date):
    dups[item].append(index)

doub={}
for key, value in dups.iteritems():
    if len(value)>1:
        doub[key]=value

# Print lines removing the duplicates
for x in uniq:
    if x in doub.keys():
        indices=doub[x]
        RMS=[]
        for i in indices:
            err=lines[i].split()
            rms_scratch=np.sqrt(float(err[5])**2+float(err[6])**2+float(err[7])**2)
            RMS.append(rms_scratch)
        indice_min=indices[RMS.index(min(RMS))]
    else:
        indice_min=dups[x][0]
    print '%s' % lines[indice_min][:-1]
    #foc.write(lines[indice_min])  

# 

fic.close()
#foc.close()