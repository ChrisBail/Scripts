/*
 * This file is part of ms_picker.
 *
 * Copyright (C) 2009 Stuart Nippress, Andy Heath & Andreas Rietbrock,
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

#ifndef _stalta_h
#define _stalta_h

/* Definition of some flags */
#define FOUND_PICK 1
#define END_OF_DATA 2
#define BREAK_IN_DATA 3

/* StaLta structure and definitions */
typedef struct {
  float trigger;              /* User defined trigger level at each seismic station */
  float sta_sec;              /* User defined STA window length in seconds at each seismic station */
  float lta_sec;              /* User defined LTA window length in seconds at each seismic station */
  float deadDelay;            /* User defined time in seconds after a pick that another pick can not be defined */
  float cf1;                  /* User defined LOWER corner frequency used by the butterworth bandpass filter */
  float cf2;                  /* User defined UPPER corner frequency used by the butterworth bandpass filter */
  int sta_samp;               /* STA window length in samples calculated using the sampling rate and sta_sec at each seismic station */
  int lta_samp;               /* LTA window length in samples calculated using the sampling rate and lta_sec at each seismic station */
  float *staBuf;              /* STA buffer */
  float *ltaBuf;              /* LTA buffer */
  float *initBuf;
  int npast;                  /* Number of data samples the picker remembers from the end of the previous data segment */
  float *pastValues;          /* Buffer containing the data samples from the end of the previous data segment */
  unsigned char *pastExists; /* Buffer containing information the pastValues buffer, in particular if a there is data at each sample */
  FILE *out;                  /* User defined output file containing the picks */
  double lastPickTime;        /* Previous pick time in seconds from 01/01/1970 */
} StaLta;

#endif /* !_stalta_h */
