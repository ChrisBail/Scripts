#!/usr/bin/env python

# -*- coding: utf-8 -*-
"""
Created on Wed Apr  6 09:38:23 2016

@author: baillard

This function is made to transform scanloc.xml into nordic file
usage: ./xml2nor.py file.xml
nordic file is printed to output
Don't forget to chmod 777 the python script before running it.
Be sure that your python version is > 2.7
"""
import sys
import re,math
import xml2nor
import seiscomp3.scbulletin


def main():
    #filexml='2015_10_01_000000_loc.xml'

    filexml=sys.argv[1]
    filebull='bulletin.txt'
    
    ### Create bulletin
    
    xml2nor.xml2bulletin(filexml,filebull) 
    
    ### Read bulletin
    
    list_event=xml2nor.bulletin2dic(filebull)
    
    ### Loop over events and print
    
    for event in list_event:
        xml2nor.dic2nor(event)
        print ''
        

def xml2bulletin(filexml,file_out):
    #filexml=sys.argv[1]
    #filexml='2015_10_01_000000_loc.xml'
    
    fic=open(file_out,'w')
    
    bulletin = seiscomp3.scbulletin.Bulletin(None)
    bulletin.format = "autoloc3"
    
    ar = seiscomp3.IO.XMLArchive()
    if not ar.open(filexml):
      sys.exit(1)
    
    obj = ar.readObject()
    if obj is None:
      sys.exit(1)
    
    ep = seiscomp3.DataModel.EventParameters.Cast(obj)
    if ep is None:
      sys.exit(1)
    
    for i in xrange(ep.eventCount()):
      evt = ep.event(i)
      fic.write(bulletin.printEvent(evt))
      fic.write('\n')
      #print bulletin.printEvent(evt)

    fic.close()

def bulletin2dic(filein):
    
    fic=open(filein,'r')
    
    ### Initialize list
    
    list_event=[];
    
    ### Read lines
    
    flag_event=0
    flag_origin=0
    
    lines=fic.readlines()  
    fic.close()
    
    k=-1
    while (k<len(lines)-1):
        k=k+1
        line=lines[k]
        line=line.replace("\n", "")
        if line=='Event:':
            flag_event=1
            dic_event=init_event()
            id_event=lines[k+1].split()[2]
            dic_event["id"]=id_event
        if line=='Origin:':
            flag_origin=1
            dic_origin=init_origin()
        if line[4:8]=='Date':
            date=line.split()[1]
            dic_origin["date"]=date
        if line[4:8]=='Time':
            time=line.split()[1]
            dic_origin["time"]=time
        if line[4:8]=='Lati':
            lat=line.split()[1]
            dic_origin["lat"]=lat
        if line[4:8]=='Long':
            lon=line.split()[1]
            dic_origin["lon"]=lon
        if line[4:8]=='Dept':
            depth=line.split()[1]
            dic_origin["depth"]=depth
        if line[4:8]=='Resi':
            rms=line.split()[2]
            dic_origin["rms"]=rms
            dic_event["origin"]=dic_origin    
        if 'Network magnitudes' in line and line[0]!='0':
            k=k+1
            B=lines[k].split()
            dic_origin['mag']=B[1]
        if 'Phase arrivals' in line:
            flag_phase=1
            list_phase=[]
            num_sta=int(line.split()[0])
            k=k+2
            for i in range(num_sta):
                dic_phase=init_phase()
                A=lines[k+i].split()
                station=A[0]
                if '##' in station:
                	continue
                phase=A[4]
                time_phase=A[5]
                weight=A[8]
                dic_phase["station"]=station
                dic_phase["phase"]=phase
                dic_phase["time"]=time_phase
                dic_phase["weight"]=weight
                list_phase.append(dic_phase)
            k=k+num_sta
            dic_event["phase"]=list_phase
            list_event.append(dic_event)
            
    return list_event
 
                  
#### Define functions
            
def init_event():
   "function_docstring"
   event=dict.fromkeys(['origin','id','phase'])
   return event
   
def init_origin():
   "function_docstring"
   origin=dict.fromkeys(['date','time','lon','lat','depth','rms','mag'])
   return origin
   
def init_phase():
   "function_docstring"
   phase=dict.fromkeys(['station','phase','time','weight'])
   return phase
   
def dic2nor(event):
    
    ### Parameters
    
    distance_indic='L'
    type_mag='L'

    ### Retrieve times
    
    [year,month,day]=[int(x) for x in event['origin']['date'].split('-')]
    [hour,minute,sec]=[float(x) for x in event['origin']['time'].split(':')]
    
    lon=float(event['origin']['lon'])
    lat=float(event['origin']['lat'])
    depth=float(event['origin']['depth'])
    rms=float(event['origin']['rms'])
    mag=event['origin']['mag']
    if mag!=None:
        mag=float(event['origin']['mag'])
    
    if rms>100:
        rms=' 100'
    elif (rms > 10 and rms <=100):
        rms='%4.0f' % rms
    else:
        rms='%4.1f' % rms
    
    num_sta=len(event["phase"])
    ##### Write first line
    
    if mag!=None:
        type_1=' {:4d} {:2d}{:02d} {:02.0f}{:02.0f} {:4.1f} {:1s} {:7.3f}{:8.3f}{:5.1f}     {:3d}{:s}{:4.1f}{:1s} '.\
        format(   year,month,day,   hour,   minute,  sec,distance_indic,lon,lat,depth,  num_sta, rms,mag,type_mag)
    else:
        type_1=' {:4d} {:2d}{:02d} {:02.0f}{:02.0f} {:4.1f} {:1s} {:7.3f}{:8.3f}{:5.1f}     {:3d}{:s}{:4s}{:1s} '.\
        format(   year,month,day,   hour,   minute,  sec,distance_indic,lon,lat,depth,  num_sta, rms,' ',type_mag)
        
    fill_str='1'.rjust(19)
    type_1=type_1+fill_str
    
    
    type_7=' STAT SP IPHASW D HRMM SECON CODA AMPLIT'+\
        ' PERI AZIMU VELO AIN AR TRES W  DIS CAZ7'
        
    print type_1
    print type_7
    
    ### Start loop and print to console
    
    for phases in event['phase']:
        type_4=xml2nor.write_line_4(phases)
        print type_4


def format_value(vari,format_type):
    """ Create string from floats
    """
    #a=format_type[format_type.find(:)+1:format_type.find]
    ind_start=re.search("[0-9,.]",format_type).start()
    ind_end = re.search("[f,g,s]", format_type).start()
    len_format=format_type[ind_start:ind_end] 
    len_format=math.floor(float(len_format))

    #### 
    
    if vari==None:
        len_format=str(int(len_format))
        str_format='{:>'+len_format+'s}'
        str_out=str_format.format(' ')
    else:
        str_out=format_type.format(vari)
        if len(str_out)>len_format:
            sys.stderr.write("value %s too long\n" % str_out)             
        
    return str_out
    
def write_line_4(phases):
    
    ### Assign values
    
    phase=phases['phase']
    station=phases['station']
    hour_phase,min_phase,sec_phase=[float(x) for x in phases['time'].split(':')]
    weight=float(phases['weight'])


    ### Iniutialize list
        
    type_4_list=[' ']*80    
        
    ### transform float to string
        
    inst_type=None
    component=None

    type_4_list[1:5]=xml2nor.format_value(station,'{:5s}')
    type_4_list[6]=xml2nor.format_value(inst_type,'{:1s}')
    type_4_list[7]=xml2nor.format_value(component,'{:1s}')
    type_4_list[10:13]=xml2nor.format_value(phase,'{:2s}')
    type_4_list[14]=xml2nor.format_value(weight,'{:1.0f}')
    type_4_list[18:19]=xml2nor.format_value(hour_phase,'{:2.0f}')
    type_4_list[20:21]=xml2nor.format_value(min_phase,'{:2.0f}')
    type_4_list[22:27]=xml2nor.format_value(sec_phase,'{:6.2f}')

    ### Join list
    
    type_4_list=type_4_list[0:80]
    type_4_list=''.join(type_4_list)
    
    return type_4_list
            
if __name__ == "__main__":
    main()
        

    
    


