#!/usr/bin/env python

import numpy as np
import argparse
    
### Parse the command line
parser = argparse.ArgumentParser(description='Print catalog')
parser.add_argument("filename", type=str)
args = parser.parse_args()
filein=args.filename

### Read file
#filein='/Users/baillard/_Moi/Programmation/Matlab/Seismic_Catalogs/ISC_1900_2013_sup_6.8.txt'
f = open(filein,'r')
lines = f.readlines()[:]
f.close()

### Start loop
for line in lines:
    A=line.split(',')
    date=A[2]
    time=A[3]
    lon=A[5]
    lat=A[4]
    depth=A[6].strip()
    if depth == '':
        depth='999'
    author_mag=A[8::3]
    type_mag=map(str.strip,A[9::3])
    if type_mag == ['']:
        continue
    mag=np.array(map(float,A[10::3]))
    indice_m=[i for i, x in enumerate(type_mag) if x.lower() == "m"]
    indice_ms=[i for i, x in enumerate(type_mag) if 'ms' in x.lower()]
    indice_mw=[i for i, x in enumerate(type_mag) if x.lower() == "mw"]
    

    ### Priotarize magnitude type
    if indice_mw:
        mag_value=np.mean(mag[[indice_mw]])
        new_mag_type="mw"
    elif indice_ms:
        mag_value=np.mean(mag[[indice_ms]])
        new_mag_type="ms"
    elif indice_m:
        mag_value=np.mean(mag[[indice_m]])
        new_mag_type="m"

    ### Print output
    print "%s %s %s %s %s %4.1f %2s" %(date, time, lon, lat, depth, mag_value, new_mag_type)
    
