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

#include <stdio.h>
#include <string.h>
#include <math.h>

#include "utl_time.h"

extern long julday(int mm,int id, int iyyy);

/*
 * This routine computes the time difference between the struct of
 * two datetime variables and returns back the seconds
 * between them. string1 has to be older then string2.
 */
double time_diff(TIME time_1,TIME time_2)
{
    double 	diff = 0.0;
    int	diff_sec;
    int	diff_hr;
    int	diff_min;
    long	diff_day;
    long	jul_day1;
    long	jul_day2;

    diff_sec = 0.0;
    diff_min = 0;
    diff_hr = 0;
    diff_day = 0L;
    
    jul_day1 = julday(time_1.mo,time_1.day,time_1.yr);
    jul_day2 = julday(time_2.mo,time_2.day,time_2.yr);

    if((diff_day = jul_day2 - jul_day1) < 0)
	return(-1);
    if((diff_hr = time_2.hr - time_1.hr) < 0)
	return(-1);
    if((diff_min = time_2.mn - time_1.mn) < 0)
	return(-1);
    if((diff_sec = time_2.sec-time_1.sec) < 0)
	return(-1);

    diff += (double)(diff_day * 86400L);
    diff += (double)(diff_hr * 3600L);
    diff += (double)(diff_min * 60L);
    diff += (double)(diff_sec);

    return(diff);
}

/*
 * This routine computes the time difference between the struct of
 * a datetime variables and the base 1970-01-01 00:00:0.000 and gives
 * back the seconds between. 
 */
double base_diff(TIME time_in)
{
  double diff;
  float	diff_sec;
  int		diff_hr;
  int		diff_min;
  long		diff_day;
  int		year2   = 1970;
  int		month2  = 01;
  int		day2    = 01;
  int		hr2     = 0;
  int 		min2    = 0;
  float	sec2    = 0.0;
  FILE		*fp_junk;

  long	jul_day1;
  long	jul_day2;

  diff = 0.0;
  diff_sec = 0.0;
  diff_min = 0;
  diff_hr = 0;
  diff_day = 0L;

  fp_junk=fopen("time.dat","a");
  fprintf(fp_junk,"%d  ", time_in.yr);
  if(time_in.yr < 100)
  {
    if(time_in.yr < 50)
        time_in.yr += 2000;
    else
        time_in.yr += 1900;
  }
  
  jul_day1 = julday(time_in.mo,time_in.day,time_in.yr);
  jul_day2 = julday(month2,day2,year2);
  fprintf(fp_junk,": %ld %ld %d\n", jul_day1,jul_day2, time_in.yr);
  fclose(fp_junk);

  diff_day = jul_day1    - jul_day2;
  diff_hr  = time_in.hr  - hr2;
  diff_min = time_in.mn - min2;
  diff_sec = time_in.sec - sec2;

  diff  = (double)(diff_day * 86400L);
  diff += (double)(diff_hr * 3600L);
  diff += (double)(diff_min * 60L);
  diff += (double)diff_sec;

  return diff;
}

/*
 * This routine computes the TIME struct out of a double
 */
TIME do2date(double do_time)
{
    TIME time_out;
    long diff = 0;
    int  year2 = 1970;
    int  month2 = 01;
    int  day2 = 01;
    long julday(int, int, int);
    long jul_day;
    void caldat(long, int *, int *, int *);

    jul_day = julday(month2,day2,year2);

    diff = (long)do_time / 86400L;
    jul_day += diff;
    caldat(jul_day, &time_out.mo, &time_out.day, &time_out.yr);

    do_time -= diff * 86400L;
    diff = (long)do_time / 3600L;
    time_out.hr = diff;
    do_time -= diff * 3600L;

    diff = (long)do_time / 60L;
    time_out.mn = diff;
    do_time -= diff * 60L;

    time_out.sec = (float)do_time;

    return time_out;
}

