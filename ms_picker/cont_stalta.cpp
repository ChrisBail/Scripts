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

/* any system headers */
#include <iostream>
#include <string>
#include <map>

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cmath>
#include <values.h>

/* local headers */
#include "pdas_player.h"
#include "stalta.h"
#include "utl_time.h"

/* these functions are defined in 'stalta.c' */
extern "C" float *bp_butterworth (float  *x, int ns, float cf1, float cf2, float sps);
extern "C" int staltaPicker(int ndat, float *val, unsigned char *exists, StaLta *stalta, int *pickSample);

static std::map<std::string, StaLta *> paramMap;

/*----------------------------------------------------------*/

/*
 * This routine skips over the exists array to find where the data starts again.
 */
static int skipOverExists(unsigned char *exists, int ndat)
{
  int i;

  for (i = 0; i < ndat; i++) {
    if (exists[i]) return i;
  }

  return ndat;
}

/*----------------------------------------------------------*/

/*
 * write time in more readable format
 */
static const char *timeString(double pickTime)
{
  static char s[255];

  TIME t = do2date(pickTime);
  
  memset(s, 0, 255 * sizeof(char));
  
  sprintf(s, "%04d %02d %02d %02d %02d %06.3f", t.yr, t.mo, t.day, t.hr, t.mn, t.sec);

  return s;
}

/*----------------------------------------------------------*/

/*
 * get station specific parameters
 */
static StaLta *getStaLtaData(const char *stationName, int nchan, int nsamples, std::string dirName)
{
  std::map<std::string, StaLta *>::iterator iter;
  
  iter = paramMap.find(std::string(stationName));
  if (iter == paramMap.end()) {
    iter = paramMap.find(std::string("*"));
    if (iter == paramMap.end()) {
      fprintf(stderr, "cannot find station (or default) parameters for '%s'\n", stationName); 
      return NULL;
    }
  }
  
  StaLta *stalta = (StaLta *)iter->second;
  
  stalta->sta_samp = -1;
  stalta->lta_samp = -1;
  stalta->npast = 0;
  stalta->lastPickTime = 0.0f;
  stalta->staBuf = (float *)calloc(nsamples, sizeof(float));
  stalta->ltaBuf = (float *)calloc(nsamples, sizeof(float));
  stalta->initBuf = (float *)calloc(nsamples, sizeof(float));
  stalta->pastValues = (float *)calloc(nsamples, sizeof(float));
  stalta->pastExists = (unsigned char *)calloc(nsamples, sizeof(unsigned char));
  
  // Output file name and location
  char buf[64];
  sprintf(buf, "%s/%s_%1d.picks", dirName.c_str(), stationName, nchan);
  stalta->out = fopen(buf, "a");
  
  if (stalta->staBuf == NULL ||
      stalta->ltaBuf == NULL ||
      stalta->initBuf == NULL ||
      stalta->pastValues == NULL ||
      stalta->pastExists == NULL ||
      stalta->out == NULL) {
    fprintf(stderr, "parameter/working space allocation error or cannot open output file for '%s'\n", stationName);
    return NULL;
  }

  return stalta;
}

/*----------------------------------------------------------*/

/*
 * parse the parameter input line into the station name and required params
 */
static StaLta *parseLine(char *line, std::string& stationName)
{
  char *tok = NULL;
  char *toks[7];
  
  for (int i=0; i<7; i++) {
    if ((tok = strtok(i == 0 ? line : NULL, " \t\n")) != NULL) {
      toks[i] = tok;
    }
    else {
      fprintf(stderr, "not enough tokens in parameter record\n");
      return NULL;
    }
  }
  
  stationName = std::string(toks[0]);
  
  StaLta *stalta = (StaLta *)malloc(sizeof(StaLta));
  if (!stalta) {
    fprintf(stderr, "cannot allocate memory for parameter record\n");
    return NULL;
  }
  
  stalta->trigger = float(atof(toks[1]));
  stalta->sta_sec = float(atof(toks[2]));
  stalta->lta_sec = float(atof(toks[3]));
  stalta->deadDelay = float(atof(toks[4]));  
  stalta->cf1 = float(atof(toks[5]));
  stalta->cf2 = float(atof(toks[6]));
  stalta->sta_samp = -1;
  stalta->lta_samp = -1;
  stalta->staBuf = NULL;
  stalta->ltaBuf = NULL;
  stalta->initBuf = NULL;
  stalta->npast = 0;
  stalta->pastValues = NULL;
  stalta->pastExists = NULL;
  stalta->out = NULL;
  stalta->lastPickTime = 0.0f;

  return stalta;
}

/*----------------------------------------------------------*/

/*
 * read parameter file
 */
int loadParameters(const char *filename)
{
  FILE *in = fopen(filename, "r");
  if (!in) {
    fprintf(stderr, "cannot open parameter file '%s'\n", filename);
    return PP_FALSE;
  }
  
  paramMap.clear();
  
  char line[255];
  StaLta *stalta = NULL;
  
  while (!feof(in)) {
    memset(line, 0, 255 * sizeof(char));
    if (fgets(line, 255, in) != NULL && line[0] !='#') {
      std::string stationName;
      if ((stalta = parseLine(line, stationName)) != NULL) {
        paramMap.insert(make_pair(stationName, stalta));
      }
      else {
        return PP_FALSE;
      }
    }
  }
  
  fclose(in);
  
  return PP_TRUE;
}

/*----------------------------------------------------------*/

/*
 * Sta/Lta Picker wrapper
 */
int myPickingFunc(PPPickerFuncInfo *ppPickerFuncInfo, void *userInfo, std::string dirName)
{
  PPfData *dataWin = NULL;
  StaLta *stalta = NULL;
  int pickSample;      // Sample a pick has been defined
  int ndat;            // Number of samples
  int offset;          //
  int pickCode;        // Flag used to determine a pick, end of data, or break in data
  int stepForward;     //
  float dt;            // Sampling interval
  float *values;       //
  float *valuesBase;   //
  float *rawValues;    //
  unsigned char *exists, *existsBase;
  double start, pickTime;

  for (int nchan=0; nchan<3; nchan++) {
    // Here is where you define the channel you want to use the picker on.
    // PP_CHAN1 is the Z component, PPCHAN2 & PPCHAN3 are the horizontal components
    dataWin = &(ppPickerFuncInfo->ch[nchan]); // process each of the channels

    if (dataWin == NULL) return PP_FALSE; // force processing to stop

    if (dataWin->ndat != -1) { // if ndat is -1 we don't want to process this channel
      // get the peristant data (stalta) for this station
      if (dataWin->user == NULL) {
        if ((stalta = getStaLtaData(ppPickerFuncInfo->stationName, nchan, dataWin->ndat, dirName)) == NULL) {
          fprintf(stderr, "cannot lookup parameters for station '%s'\n", ppPickerFuncInfo->stationName);
          return PP_FALSE;
        }
        else {
          dataWin->user = stalta;
        }
      }

      stalta = (StaLta *)dataWin->user;

      // This is where to define the sampling frequency
      dt = (dataWin->dt < 0.0f) ? 50.00f : dataWin->dt;
      dt = 1.0 / dt;

      stalta->sta_samp = (int)(stalta->sta_sec / dt);
      stalta->lta_samp = (int)(stalta->lta_sec / dt);

      // In this next section we copy all of the data into arrays ready to process
      rawValues = (float *)malloc(dataWin->ndat * sizeof(float));
      memcpy(rawValues, dataWin->values, dataWin->ndat * sizeof(float));

      // Here is where we filter the data  - don't forget the Nyquist frequency!!!!
      if(stalta->cf1>=(1.0/(2.0*dt)) || stalta->cf2>=(1.0/(2.0*dt)) || stalta->cf2 < stalta->cf1) {
        fprintf(stderr,"Filter parameters are not adequate %f < %f (< nyquist: %f)!\n", stalta->cf1, stalta->cf2, 1.0/(2.0*dt));
        exit(-1);
      }
      values = valuesBase = bp_butterworth(rawValues, dataWin->ndat, stalta->cf1, stalta->cf2, 1.0f/dt);
      ndat = dataWin->ndat;

      exists = (unsigned char *)malloc(dataWin->ndat * sizeof(unsigned char));
      memcpy(exists, dataWin->exists, dataWin->ndat * sizeof(unsigned char));
      existsBase = exists;

      start = dataWin->start; // component start time
      offset = stepForward = 0;

      // This while loop is where we run through all the data and run the picker
      // There are three outcomes - pick, end of data or a break in data stream
      while (PP_TRUE) {
        // Calling the Sta/Lta picker
        pickCode = staltaPicker(ndat, values, exists, stalta, &pickSample);
        if (pickCode == END_OF_DATA) {
          stalta->npast = 0;
          memcpy(stalta->pastValues, dataWin->values + (dataWin->ndat - stalta->npast),  stalta->npast * sizeof(float));
          memcpy(stalta->pastExists, dataWin->exists + (dataWin->ndat - stalta->npast),  stalta->npast * sizeof(unsigned char));
          break;
        }
        else if (pickCode == FOUND_PICK) {
          stepForward = pickSample - stalta->lta_samp + 1;
          pickTime = start + (offset + pickSample) * dt;
          if (pickTime - stalta->lastPickTime > stalta->deadDelay) {
            fprintf(stalta->out, "%s %.2lf %s %.2lf\n", ppPickerFuncInfo->stationName, pickTime, timeString(pickTime),start);
            stalta->lastPickTime = pickTime;
          }
        }
        else if (pickCode == BREAK_IN_DATA) {
          stepForward = pickSample + 1 + skipOverExists(exists + pickSample + 1, ndat - pickSample - 1);
        }
        offset += stepForward;
        values += stepForward;
        exists += stepForward;
        ndat -= stepForward;
      }

      free(rawValues);
      free(valuesBase);
      free(existsBase);
    }
  }

  return PP_TRUE; /* if PP_FALSE is returned, processing will cease */
}

