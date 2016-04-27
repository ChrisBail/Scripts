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
#include <iomanip>
#include <string>
#include <list>
#include <cstring>

#include <unistd.h>
#include <sys/stat.h>

#include <libmseed.h>

#include "pdas_player.h"
#include "station_trace.h"
#include "station_collection.h"

// variables with global scope in this file 
static std::list<StationTrace> stationTraces;
static char *msFilename = NULL;
static char *outputDir = NULL;
static char *paramFilename = NULL;
static char *activeComponent = NULL;

// this func is in the linked file "cont_*.cpp"
extern int loadParameters(const char *filename);

// picking func is in the linked "cont_*.cpp"
extern int myPickingFunc(PPPickerFuncInfo *ppPickerFuncInfo, void *userInfo, std::string dirName);

/*----------------------------------------*/

static void usage(const char *programName)
{
  std::cerr << "usage: " << programName << " -p <parameter_file> -m <miniseed_file> [-c z|n|e] [-d <output_dir>]" << std::endl;
}

/*----------------------------------------*/

static bool parseOpts(int argc, char *argv[])
{
  int opt;

  while ((opt = getopt(argc, argv, "p:m:c:d:")) != -1) {
    switch (opt) {
    case 'p':
      paramFilename = optarg;
      break;
    case 'm':
      msFilename = optarg;
      break;
    case 'c':
      activeComponent = optarg;
      break;
    case 'd':
      outputDir = optarg;
      break;
   default:
      return false;
      break;
    }
  }

  return true;
}

/*----------------------------------------*/

static bool readMiniseedFile(char *filename)
{
  StationTrace testStationTrace;
  std::list<StationTrace>::iterator stIter;
  int rtnCode;
  MSRecord *msrIn, *msrOut;
  bool found = false;
  hptime_t	end_time;

  msrIn = msrOut = NULL;
  
  end_time = -1;
  while ((rtnCode = ms_readmsr(&msrIn, filename, -1, NULL, NULL, 1, 0, 0)) == MS_NOERROR) {
    msr_unpack(msrIn->record, msrIn->reclen, &msrOut, 1, 1);
    testStationTrace = StationTrace(std::string(msrOut->network), std::string(msrOut->station), std::string(msrOut->channel));
    found = false;
    
    for (stIter = stationTraces.begin(); stIter != stationTraces.end(); stIter++) {
      if (*stIter == testStationTrace) {
        found = true;
        break;
      }
    }

    // print ting start and end
#if 0
    hptime_t diff;
    int	half_sample;
    diff=msrOut->starttime-end_time;
    half_sample=(int)((double)HPTMODULUS/msrOut->samprate/2.0);
    if(end_time>0 && abs(diff)>half_sample) {
	//end_time = msr_endtime(msrOut);
        std::cerr<<"Diff: "<<diff<<" Half_sample: "<<half_sample<<std::endl;
    std::cerr<<std::setiosflags(std::ios::fixed) << std::setprecision(3)<<"Start: "<< (double)MS_HPTIME2EPOCH((double)msrOut->starttime) <<" End: "<< (double)MS_HPTIME2EPOCH((double)msr_endtime(msrOut))<<"HP Start: " << msrOut->starttime << " End: "<< end_time << "Samp: " << (hptime_t)((double)HPTMODULUS/msrOut->samprate) <<std::endl;
    }
    end_time = msr_endtime(msrOut) + (hptime_t)((double)HPTMODULUS/msrOut->samprate);
#endif
    
    
    if (found) {
      stIter->addData(msrOut->starttime, msrOut->sampletype, msrOut->numsamples, msrOut->datasamples, msrOut->samprate);
    }
    else {
      testStationTrace.addData(msrOut->starttime, msrOut->sampletype, msrOut->numsamples, msrOut->datasamples, msrOut->samprate);
      stationTraces.push_back(testStationTrace);
    }
  }

  return true;
}

/*----------------------------------------*/

int main(int argc, char *argv[])
{
  char *programName = basename(argv[0]);

  if (!parseOpts(argc, argv)) {
    usage(programName);
    return -1;
  }

  // check for (required) parameter file and miniseed file arguments
  if (paramFilename == NULL || msFilename == NULL) {
    usage(programName);
    return -1;
  }

  // check for existance of output directory (if specified)
  std::string dirName = std::string(".");
  if (outputDir != NULL) {
    struct stat statBuf;
    dirName = std::string(outputDir);
    if (stat(dirName.c_str(), &statBuf) != 0) {
      std::cerr << programName << ": cannot access output directory '" << dirName << "'" << std::endl;
      return -1;
    }
  }

  // check for legal component code (if specified)
  if (activeComponent != NULL) {
    if (strlen(activeComponent) != 1 || !(activeComponent[0] == 'z' || activeComponent[0] == 'n' || activeComponent[0] == 'e')) {
      std::cerr << programName << ": unrecognised component code, should be one of z, n or e" << std::endl;
      return -1;
    }
  }
  
  // read the parameters
  if (loadParameters(paramFilename) == PP_FALSE) {
    std::cerr << programName << ": error reading parameter file '" << paramFilename << "'" << std::endl;
    return -1;
  }
  
  // read the file and create the traces
  if (!readMiniseedFile(msFilename)) {
    std::cerr << programName << ": problem with seedlink file '" << msFilename << "'" << std::endl;
    return -1;
  }
  
  // collect together traces into each station
  std::list<StationCollection> stationCollections;
  std::list<StationCollection>::iterator scIter;
  std::list<StationTrace>::iterator stIter;  
  
  for (stIter = stationTraces.begin(); stIter != stationTraces.end(); stIter++) {
    bool found = false;
    for (scIter = stationCollections.begin(); scIter != stationCollections.end(); scIter++) {
      if (scIter->stationCode == stIter->stationCode) {
        found = true;
        scIter->addTrace(*stIter);
        break;
      }
    }
    if (!found) {
      stationCollections.push_back(StationCollection(*stIter));
    }
  }
  
  // for each station, load the data into PDAS structures and call the picker
  PPPickerFuncInfo ppPickerFuncInfoStruct;

  for (scIter = stationCollections.begin(); scIter != stationCollections.end(); scIter++) {
    if (scIter->preparePickerFuncInfo(&ppPickerFuncInfoStruct, activeComponent)) {
      if (myPickingFunc(&ppPickerFuncInfoStruct, NULL, dirName) != PP_TRUE) {
        std::cerr << programName << ": picker function failed" << std::endl;
        return -1;
      }
    }
  }
  
  return 0;
}
