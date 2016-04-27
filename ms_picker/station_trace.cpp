/*
 * This file is part of ms_picker.
 *
 * Copyright (C) 2009 Andy Heath, Stuart Nippress & Andreas Rietbrock,
 *                    University of Liverpool
 *
 * This work was funded as part of the NERIES (JRA5) project.
 * Additional funding for Nippress from NERC research grant NE/C000315/1
 *
 * ms_picker is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * ms_picker is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with ms_picker.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <iostream>
#include <string>
#include <list>
#include <cstdio>

#include <libmseed.h>

#include "pdas_player.h"
#include "station_trace.h"

/*
 * create a new StationRecord
 */
StationTrace::StationRecord::StationRecord(hptime_t _startTime, char sampleType, int nitems, void *items, double _dt)
: startTime(_startTime), dt(_dt)
{
  int i;
  int *intItems = NULL;
  float *floatItems = NULL;
  double *doubleItems = NULL;
  
  switch (sampleType) {
  case 'a':
    std::cerr << "don't know how to interpret 'a' format in the MS record!" << std::endl;
    break;
  case 'i':
    intItems = (int *)items;
    for (i=0; i < nitems; i++) {
      data.push_back(intItems[i]);
    }
    break;
  case 'f':
    floatItems = (float *)items;
    for (i=0; i < nitems; i++) {
      data.push_back(floatItems[i]);
    }
    break;
  case 'd':
    doubleItems = (double *)items;
    for (i=0; i < nitems; i++) {
      data.push_back(doubleItems[i]);
    }
    break;
  }
}

/*----------------------------------------------------------*/

/*
 * add data via creatng a new StationRecord
 */
void StationTrace::addData(hptime_t startTime, char sampleType, int nitems, void *items, double dt)
{
  records.push_back(StationTrace::StationRecord(startTime, sampleType, nitems, items, dt));
}

/*----------------------------------------------------------*/

/*
 * extract the data from the records and fill the arrays in the PPfData structure
 */
bool StationTrace::concatenateRecordsIntoPDAS(PPfData* ppfDataPtr)
{
  std::list<StationTrace::StationRecord>::iterator rIter;
  std::list<double>::iterator dIter;

  double dt = -1.0;
  bool first = true;
  int nitems = 0;
  hptime_t end_time = -1;
  hptime_t diff;
  hptime_t span;
  int samp_add;
  int i;
  
  // sort on startTime
  records.sort();
  
  for (rIter = records.begin(); rIter != records.end(); rIter++) {
    // check for gaps in the record
    diff=rIter->startTime-end_time;
    if(end_time>0 && abs(diff)>(double)(HPTMODULUS/(2.0*rIter->dt))) {
	samp_add=((double)MS_HPTIME2EPOCH(diff)*rIter->dt)+0.5;
	//std::cerr<<"Gap: "<<(double)MS_HPTIME2EPOCH(diff)<<" ==> samples: "<< samp_add<<std::endl;
	nitems+=samp_add;
    }
    span = ((double)(rIter->data.size())/rIter->dt*HPTMODULUS)+0.5;
    end_time=rIter->startTime+span;
        
    // here comes the real trace
    nitems += rIter->data.size();

    if (first) {
      dt = rIter->dt;
      first = false;
    }
    else {
      if (dt != rIter->dt) {
        std::cerr << "inconsistent sample frequency between records for station trace '" << filename << "'" << std::endl;
        return false;
      }
    }
  }

  strncpy(ppfDataPtr->pdasFilename, filename.c_str(), PP_MAX_NAME_LEN);
  ppfDataPtr->dt = dt;
  ppfDataPtr->ndat = nitems;
  
  // get the start time of the first record
  if (!records.empty()) {
    ppfDataPtr->start = (double)MS_HPTIME2EPOCH(records.front().startTime);
  }

  if ((ppfDataPtr->values = (float *)calloc(nitems, sizeof(float))) == NULL) {
    std::cerr << "memory allocation error in trace '" << filename << "'" << std::endl;
    return false;
  }

  if ((ppfDataPtr->exists = (unsigned char *)calloc(nitems, sizeof(unsigned char))) == NULL) {
    std::cerr << "memory allocation error in trace '" << filename << "'" << std::endl;
    return false;
  }
  memset(ppfDataPtr->exists, 0x01, nitems * sizeof(unsigned char));
  
  int count = 0;
  end_time = -1;
  for (rIter = records.begin(); rIter != records.end(); rIter++) {
    // check for gaps in the record
    diff=rIter->startTime-end_time;
    if(end_time>0 && abs(diff)>(double)(HPTMODULUS/(2.0*rIter->dt))) {
	samp_add=((double)MS_HPTIME2EPOCH(diff)*rIter->dt)+0.5;
	std::cerr<<"...Gap: "<<(double)MS_HPTIME2EPOCH(diff)<<" ==> samples: "<< samp_add<<std::endl;
	if(samp_add>0) {
	    for(i=0;i<samp_add;i++) {
	        ppfDataPtr->exists[count++]=0;
	    }
	} else {
	    count-=samp_add;
 	}
    }
    span = ((double)(rIter->data.size())/rIter->dt*HPTMODULUS)+0.5;
    end_time=rIter->startTime+span;

    for (dIter = rIter->data.begin(); dIter != rIter->data.end(); dIter++) {
      ppfDataPtr->values[count++] = *dIter;
    }
  }

  ppfDataPtr->user = NULL;
  
  return true;
}

