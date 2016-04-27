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

#include <stdio.h>
#include <math.h>
#include <stdlib.h>

#include "stalta.h"

/* Define some constants */
#define MY_FALSE 0
#define MY_TRUE ~0
#define PI 3.14159265359

/* forward declarations */
int pickDetected(float sta, float lta, int staS, int ltaS, float trigger);
void bp_butter_coef(float sps, float FC1, float FC2, double *K1, double *K2, double *K3, double *K4, double *H0, double *H2, double *H4);
void calc_A0(double *G, float FC1, float FC2);
void bp_butterworth2(float *x, int ns, double K1, double K2, double K3, double K4, double H0, double H2, double H4);

/*----------------------------------------------------------*/

/*
 * This is the actual STA/LTA picking algorithm.
 * It is called from the data reader cont_stalta.cpp.
 */
int staltaPicker(int ndat, float *val, unsigned char *exists, StaLta *stalta, int *rtnVal)
{
  int i, ista, ilta;
  float sta = (double)0.0f;
  float lta = (double)0.0f;
  float x2old, x2new, x;
  
  /* 
   * Initial check
   * The number of data samples needs to be bigger than the LTA window length.
   * If it is not it returns to the data reader (cont_stalta.cpp) for some more data.
   */
  if (ndat < stalta->lta_samp) {
    return END_OF_DATA;
  }
  
  /* 
   * Initialise the STA and LTA buffers
   */
  for (i = 0; i < stalta->lta_samp; i++) {
    /*
     * Check that there is data at each sample before filling the buffers.
     * If there is not return to the data reader (cont_stalta.cpp) for some more data.
     */
    
    if (!exists[i]) {
      *rtnVal = i;
      return BREAK_IN_DATA;
    }
    /* Calculate the initial LTA and fill the lta buffer */
    stalta->initBuf[i] = val[i];
    stalta->ltaBuf[i] = val[i] * val[i];
    lta += (double)stalta->ltaBuf[i];
  }
  if (lta == 0.0f) lta = (double)1.0f;
  
  ilta = 0;
  for (ista = 0; ista < stalta->sta_samp; ista++) {
    stalta->staBuf[ista] = stalta->ltaBuf[ilta++];
    sta += (double)stalta->staBuf[ista];
  }
  ista = 0;
  /* Now calculate the STA and fill the sta buffer */
  while (ilta < stalta->lta_samp) {
    x2old = stalta->staBuf[ista];
    stalta->staBuf[ista] = x2new = stalta->ltaBuf[ilta++];
    ista++;
    ista %= stalta->sta_samp;
    sta += (double)(x2new - x2old);
  }
  ilta = 0;
  
  /*
   * Now propagate through the entire dataset sent by the data reader cont_stalta.cpp.
   * At each sample update the STA and LTA buffer, calculate the STA/LTA ratio and check against the user defined trigger level.
   * If the STA/LTA ratio exceeds the trigger level, a pick is defined and immediately returned to the cont_stalta.cpp program. 
   */
  for (i = stalta->lta_samp; i < ndat; i++) {
    /*
     * Check there is data at each sample.
     * If there is not return to the data reader (cont_stalta.cpp) for some more data.
     */
    if (!exists[i]) {
      *rtnVal = i;      
      return BREAK_IN_DATA;
    }
    x = val[i];
    /* Update the STA buffer with the new data sample */
    x2old = stalta->staBuf[ista];
    stalta->staBuf[ista] = x2new = x * x;
    ista++;
    ista %= stalta->sta_samp;
    sta += (double)(x2new - x2old);
    /* Update the LTA buffer with the new data sample */
    x2old = stalta->ltaBuf[ilta];
    stalta->ltaBuf[ilta] = x2new = x * x;
    ilta++;
    ilta %= stalta->lta_samp;
    lta += (double)(x2new - x2old);
    
    /*
     * Calculate the STA/LTA ratio and compare to the user defined trigger level.
     * If it is greater, define a pick and return with the sample number to the data reader (cont_stalta.cpp).
     * If it is not greater continue looping through the dataset supplied by the data reader (cont_stalta.cpp).
     */
    if (pickDetected(sta, lta, stalta->sta_samp, stalta->lta_samp, stalta->trigger) == MY_TRUE) {
      *rtnVal = i;
      return FOUND_PICK;
    }
  }
  
  /*
   * If we reach here there has been no picks or breaks in dataset sent by the data reader (cont_stalta.cpp).
   * So return to the data reader (cont_stalta.cpp) for some more data.
   */
  return END_OF_DATA;
}

/*----------------------------------------------------------*/

/* 
 * This function compares the STA/LTA ratio to the trigger level.
 * It returns MY_TRUE (i.e. a pick) if the STA/LTA ratio is larger than the trigger level.
 */
int pickDetected(float sta, float lta, int staS, int ltaS, float trigger)
{
  /*
   * sta      STA window length in seconds
   * lta      LTA window length in seconds
   * staS     STA window length in samples
   * ltaS     LTA window length in samples
   * trigger  trigger level
   * ratio    STA/LTA ratio
   */
  float ratio;

  ratio = (sta/lta) * (ltaS/staS);

  return (ratio >= trigger) ? MY_TRUE : MY_FALSE;
}

/*----------------------------------------------------------*/

/* 
 * Below are all the routines for the bandpass filter called in cont_stalta.cpp.
 * These were written previously.
 */

/*
 * Function to bandpass filter the data.
 * x        Sample values
 * ns       Number of samples
 * cf1, cf2 Corner frequencies
 * sps      Sampling rate
 */
float *bp_butterworth(float *x, int ns, float cf1, float cf2, float sps)
{
  float  *retv;
  float *y;
  int    i;
  float FC1, FC2;
  double H0, H2, H4;
  double K1, K2, K3, K4;
  int FILTER_ORDER = 4;
  
  /* Define the Corner frequencies */
  FC1 = cf1;
  FC2 = cf2;
  
  /* Calculate the butterworth coefficients */
  bp_butter_coef ( sps, FC1, FC2, &K1, &K2, &K3, &K4, &H0, &H2, &H4 );
  
  /* Malloc memory for output sample values  */
  if ((y = (float *) malloc ( ns * sizeof(float) )) == NULL ) {
    printf( "Malloc 1 failed. NO FILTER USED. \n");
    return NULL;
  }
  
  /* First entry: no previous values  */
  *y     =   H0 * (*x);
  
  *(y+1) =   H0 * (*(x+1)) 
    + K1 * (*y);
  
  *(y+2) =   H0 * (*(x+2))   + H2 * (*(x))
    + K1 * (*(y+1))   + K2 * (*y);
  
  *(y+3) =   H0 * (*(x+3))   + H2 * (*(x+1))
    + K1 * (*(y+2))   + K2 * (*(y+1)) + K3*(*y);
  
  for ( i=4; i<ns; i++ ) {
    *(y+i) =   H0 * (*(x+i)) 
      + H2 * (*(x+(i-2))) 
      + H4 * (*(x+(i-4))) 
      
      + K1 * (*(y+i-1)) 
      + K2 * (*(y+i-2)) 
      + K3 * (*(y+i-3)) 
      + K4 * (*(y+i-4)); 
  }
  
  /* Now filter the data */
  if ( FILTER_ORDER > 2 )
    bp_butterworth2 ( y, ns, K1, K2, K3, K4, H0, H2, H4 );
  
  if ( (retv = (float *) malloc ( ns * sizeof(float) )) == NULL ) {
    printf("Malloc 2 failed. NO FILTER USED. \n");
    return NULL;
  }
  
  for ( i=0; i<ns; i++ ) *(retv+i) = (float) *(y+i);
  
  free (y);
  
  return (retv);
}

/*----------------------------------------------------------*/

/*
 * Function to determine the butterworth coefficients.
 * sps								Sampling rate
 * FC1								Upper corner frequency
 * FC2								Lower corner frequency
 * K1, K2, K3, K4, H0, H2, H4		Filter coefficients
 */
void bp_butter_coef(float sps, float FC1, float FC2,
                    double *K1, double *K2, double *K3, double *K4,
                    double *H0, double *H2, double *H4)
{
  float fs; /* Sampling frequency */
  double A,B,C,D,E;
  double F1,F2,F3,F4,F5;
  double wc, wk, fct;
  double sqrt2, G;
  int SPS;
  
  SPS = (int) sps;
  fs  = (float) sps;
  
  if ( FC1 < FC2 ) {
    fct = FC1;
    FC1 = FC2;
    FC2 = fct;
  }
  
  /* Filter normalization factor */
  calc_A0 (&G, FC1, FC2);
  
  /* From Z-transform:  A0  ->  A0/( 2/dt * 2/dt ) */
  G = G / ( 2*SPS * 2*SPS );
  
  /* Perform z-transform */
  wc = tan((double)(PI*FC1/fs));
  wk = tan((double)(PI*FC2/fs));
  
  sqrt2 = 1.414213562;
  
  /* Determine filter coefficients */
  A = 1;
  B = sqrt2*wk + sqrt2*wc;
  C = wk*wk + 2*wc*wk + wc*wc;
  D = sqrt2*wc*wk*wk + sqrt2*wk*wc*wc;
  E = wc*wc*wk*wk;
  
  F1 = A+B+C+D+E;
  F2 = (-4*A) - (2*B) + (2*D) + (4*E);
  F3 = (6*A) - (2*C) + (6*E);
  F4 = (-4*A) + (2*B) + (-2*D) + (4*E);
  F5 = A-B+C-D+E;
  
  *H0 = G/F1;
  *H2 = -2*G/F1;
  *H4 = G/F1;
  
  *K1 = -F2/F1;
  *K2 = -F3/F1;
  *K3 = -F4/F1;
  *K4 = -F5/F1;
}

/*----------------------------------------------------------*/

/*
 * Function to determine the filter normalization factor
 * G    Filter normalization factor
 * FC1  Corner frequency
 * FC2  Corner frequency
 */
void calc_A0(double *G, float FC1, float FC2)
{
  double fr, om;
  double wc, wk;
  double b,c,d,e;
  double sqrt2, R,I;
  
  /* Determine the resonant frequency */
  fr = (double) 1 / ((1/FC1+1/FC2)/2);
  
  wk = 2*PI*FC2; 
  wc = 2*PI*FC1; 
  
  sqrt2 = 1.414213562;
  b = sqrt2*wk + sqrt2*wc;
  c = wk*wk + 2*wc*wk + wc*wc;
  d = sqrt2*wc*wk*wk + sqrt2*wk*wc*wc;
  e = wc*wc*wk*wk;
  
  /* Calculate normalisation factor A0 at frequency fr */
  om = 2*PI*fr;
  R  = om*om*om*om - c*om*om + e;
  I  = -b*om*om*om + d*om;
  
  *G = ( sqrt ( R*R + I*I ) ) / (om*om);
}

/*----------------------------------------------------------*/

/*
 * This function actually filters the data.
 * x                           Data
 * ns                          Number of samples
 * K1, K2, K3, K4, H0, H2, H4  Filter coefficients
 */
void bp_butterworth2(float *x, int ns,
                     double K1, double K2, double K3, double K4,
                     double H0, double H2, double H4)
{
  float *z;
  int   i;
  
  /* Malloc memory for output sample values  */
  if (( z = (float *) malloc ( ns * sizeof(float) )) == NULL ) {
    printf("Malloc failed. NO FILTER USED. \n");
    return;
  }
  
  /* First block: no previous values  */
  *z     =   H0 * (*x);
  
  *(z+1) =   H0 * (*(x+1)) 
    + K1 * (*z);
  
  *(z+2) =   H0 * (*(x+2))   + H2 * (*(x))
    + K1 * (*(z+1))   + K2 * (*z);
  
  *(z+3) =   H0 * (*(x+3))   + H2 * (*(x+1))
    + K1 * (*(z+2))   + K2 * (*(z+1)) + K3*(*z);
  
  
  for ( i=4; i<ns; i++ ) {
    *(z+i) =   H0 * (*(x+i)) 
      + H2 * (*(x+i-2)) 
      + H4 * (*(x+i-4)) 
      
      + K1 * (*(z+i-1)) 
      + K2 * (*(z+i-2)) 
      + K3 * (*(z+i-3)) 
      + K4 * (*(z+i-4)); 
  }
  
  /* Give filtered samples back to main program */
  for ( i=0; i<ns; i++ ) *(x+i) = *(z+i);
  
  free(z);
}


