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

#include <time.h>

#ifndef __pdas_player_h
#define __pdas_player_h

#define PP_TRUE 1
#define PP_FALSE 0
#define PP_MAX_NAME_LEN 32
#define PP_CHAN1 0
#define PP_CHAN2 1
#define PP_CHAN3 2

/*
 * In "ms_picker" we are only using the first two typedef structs.
 */

typedef struct {
  char pdasFilename[PP_MAX_NAME_LEN + 1]; //!< name of file data drawn from (at beginning of window in case of file overlap)
  float dt; //!< sample rate (at beginning of window in case of file overlap)
  int ndat; //!< number of samples in window
  double start; //!< start of window measured in calendar time (seconds from the epoch)
  float *values; //!< the samples 
  unsigned char *exists; //!< boolean flags, one per sample: '0' indicates a sample is not valid
  void *user; //!< persistant (user-defined) data storage
} PPfData;

typedef struct {
  char stationName[PP_MAX_NAME_LEN + 1]; //!< e.g. XXX
  float lat, lon, elev; //!< latitude, longditude and elevation
  //time_t start; //!< start of window measured in calendar time (seconds from the epoch)
  int ms; //!< millisecond component of start time of window (usually zero)
  PPfData ch[3]; //!< the three channels of data indexed by PP_CHAN1, PP_CHAN2, etc
} PPPickerFuncInfo;

/*!
The PPProcessInfo structure pickerWindowcontains parameters and functions used by the library when processing the station data.
The 'pickerFunc' member is the address of a function defined by the application. The 'pickerFunc' is called at intervals
of 'bufferSize' as all the station data are processed. 'pickerFunc' is passed the address of a PPPickerFuncInfo structure
which contains 'bufferSize' number of samples in three channels. After each call to 'pickerFunc' the library may call
'progressFunc'. This is an application defined function that may report progress or NULL. The function returns either PP_TRUE
(processing continues) or PP_FALSE (processing ceases and PP_Process returns PP_FALSE immediately. Therefore 'progressFunc'
provides a method to interrupt the (potentially very time-consuming) processing.
*/
typedef struct {
  int (*pickerFunc)(PPPickerFuncInfo *ppPickerFuncInfo, void *userInfo); //!< returns PP_TRUE or PP_FALSE
  int (*progressFunc)(int nPickerFuncCalls, float percentage); //!< returns PP_TRUE or PP_FALSE
  int bufferSize; //!< period of data (measured in seconds) passed into pickerFunc for each channel
  char *start; //!< start playing the data here - format "YYYY.MM.DD HH:MM:SS", if NULL start defined by data
  char *end; //!< end playing the data here - format "YYYY.MM.DD HH:MM:SS", if NULL end defined by data
  char **stations; //!< NULL-terminated list of station names to use in processing 
} PPProcessInfo;

#ifdef __cplusplus
extern "C" {
#endif

/*!
Initialise the library and set defaults in PPProcessInfo struct
\param debugLevel verbosity of output: 0 = (fatal) errors; 1 = level 0 + warnings; 2 = level 1 + information
\param ppProcessInfoPtr struct that will be passed to PP_Process
\param configFilename file containing tag/value parameter pairs which optionally set some of the ppProcessInfoPtr member variables
\return PP_TRUE (success) or PP_FALSE (failure)
\sa PP_Process()
\sa PP_Clean()
*/
extern int PP_Init(int debugLevel, PPProcessInfo *ppProcessInfoPtr, const char *configFilename);

/*!
Prepare to process the station data: determine which stations to use and where data should be sourced. Read thru all file headers and order the data with respect to time. If a 'prepare' file exists, read the contents and skip the lengthy stage of reading thru all the file headers. If the 'prepare' file does not exist, carry out this stage and write the results to the file. If the data files change in any way, any existing 'prepare' files should be regenerated. 
\param pathToPrepareFile full path (including filename) of the prepared file
\param pathToInfoFile full path (including filename) of info file
\param pathToData full path to root directory of data for the stations
\return PP_TRUE (success) or PP_FALSE (failure)
\sa PP_Process()
*/
extern int PP_Prepare(const char *pathToPrepareFile, const char *pathToInfoFile, const char *pathToData);

/*!
Process all station data (in parallel). The picking function is called (notionally simultaneously) on a window of data from each station. Each instance of the picking function (one per station) must complete for the given time window before processing moves to the next window. The picking function is therefore called for all stations throughout all the processing, even if there are no data at certain times in particular stations.
\param ppProcessInfo structure containing various inputs (see definition of data type)
\param userInfo address of user-defined data structure passed unaltered to each invocation of the picking function (global)
\sa PP_Prepare()
\return PP_TRUE (success) or PP_FALSE (failure)
*/
extern int PP_Process(PPProcessInfo *ppProcessInfo, void *userInfo);

/*!
Free memory reserved by library
\param void - no parameters
\return PP_TRUE (success) or PP_FALSE (failure)
\sa PP_Init()
 */
extern int PP_Clean();

#ifdef __cplusplus
}
#endif

#endif /* !__pdas_player_h */
