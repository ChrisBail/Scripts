# -*- coding: utf-8 -*-
"""
Created on Mon Jul  6 14:18:53 2015

@author: baillard
"""

from obspy import read
print 'sf'

path='/Users/baillard/_Moi/Projets/Nepal/DATA/EV/T2.mseed'

st=read(path)
print st
