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

#include <string>
#include <list>
#include <cstdio>

#include <libmseed.h>

#include "pdas_player.h"
#include "station_trace.h"
#include "station_collection.h"

StationCollection::StationCollection(StationTrace stationTrace)
{
  stationCode = stationTrace.stationCode;
  
  stationTraces.push_back(stationTrace);
}

/*----------------------------------------------------------*/

void StationCollection::addTrace(StationTrace stationTrace)
{
  stationTraces.push_back(stationTrace);
}

/*----------------------------------------------------------*/

static int lookupChannel(std::string msCode)
{  
  if (!msCode.empty()) {
    switch (msCode[msCode.size() - 1]) {
      // case 'Z': case 'z': return PP_CHAN1; break;  
      // Hack for OBS data, it would be better to actually change the header
      case 'Z': case 'z': case '3': case '2': return PP_CHAN1; break;
      // Done
      case 'N': case 'n': return PP_CHAN2; break;
      case 'E': case 'e': return PP_CHAN3; break;
      default: return -1; break;
    }
  }
  
  return -1;
}

/*----------------------------------------------------------*/

static bool chooseComponent(PPPickerFuncInfo *pickerFuncInfoPtr, std::string stationCode, std::string componentName)
{
  int channelCode;

  if ((channelCode = lookupChannel(componentName)) < 0) {
    fprintf(stderr, "cannot find channel code from component '%s' when choosing data for '%s'\n", componentName.c_str(), stationCode.c_str());
    return false;
  }

  if (pickerFuncInfoPtr->ch[channelCode].ndat == -1) {
    fprintf(stderr, "the requested component '%s' has no data in '%s'\n", componentName.c_str(), stationCode.c_str());
    return false;
  }    

  for (int nchan=0; nchan < 3; nchan++) {
    if (nchan != channelCode) {
      pickerFuncInfoPtr->ch[nchan].ndat = -1;
    }
  }

  return true;
}

/*----------------------------------------------------------*/

bool StationCollection::preparePickerFuncInfo(PPPickerFuncInfo *pickerFuncInfoPtr, const char *activeComponent)
{
  std::list<StationTrace>::iterator stIter;
  int channelIdx;
  int nactive = 0;

  std::string componentName;
  if (activeComponent != NULL) {
    componentName = std::string(activeComponent);
  }

  strncpy(pickerFuncInfoPtr->stationName, stationCode.c_str(), PP_MAX_NAME_LEN);
  
  pickerFuncInfoPtr->lat = 0.0f;
  pickerFuncInfoPtr->lon = 0.0f;
  pickerFuncInfoPtr->elev = 0.0f;
  pickerFuncInfoPtr->ms = 0;

  // initialise all components
  for (int nchan=0; nchan < 3; nchan++) {
    pickerFuncInfoPtr->ch[nchan].ndat = -1;
    pickerFuncInfoPtr->ch[nchan].start = 0;
    pickerFuncInfoPtr->ch[nchan].exists = NULL;
    pickerFuncInfoPtr->ch[nchan].values = NULL;
  }

  for (stIter = stationTraces.begin(); stIter != stationTraces.end(); stIter++) {
    if ((channelIdx = lookupChannel(stIter->channelCode)) < 0) {
      fprintf(stderr, "cannot find channel index from code '%s' when preparing data for '%s'\n", stIter->channelCode.c_str(), stationCode.c_str());
      return false;
    }
    if (!stIter->concatenateRecordsIntoPDAS(&(pickerFuncInfoPtr->ch[channelIdx]))) {
      fprintf(stderr, "problem concatenating trace record data when preparing data for '%s'\n", stationCode.c_str());
      return false;
    }
  }
  
  for (int nchan=0; nchan < 3; nchan++) {
    if (pickerFuncInfoPtr->ch[nchan].ndat != -1) {
      nactive++;
    }
  }

  if (nactive == 0) {
    fprintf(stderr, "no components found in '%s', skipping processing\n", stationCode.c_str());
    return false;
  }

  if (nactive > 1) {
    if (componentName.empty()) {
      fprintf(stderr, "%d components found in '%s', cannot process - specify component with '-c' option\n", nactive, stationCode.c_str());
      return false;
    }
    else {
      return chooseComponent(pickerFuncInfoPtr, stationCode, componentName);
    }
  }
  
  return true;
}
