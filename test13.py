# -*- coding: utf-8 -*-
"""
Created on Sat Apr 11 18:45:31 2015

@author: baillard
"""

from plot_connections import *



lon_lim=[166, 167.75]
lat_lim=[-16.5, -15]
z_lim=[0, 100]

file_local='/Users/baillard/_Moi/SCRATCH/collect_BEST_clean.xyz'

dic_loc=load_xyz(file_local)
dic_loc_sel=select(dic_loc,lon=lon_lim,lat=lat_lim,z=z_lim)
write_xyz(dic_loc_sel,'ta')
