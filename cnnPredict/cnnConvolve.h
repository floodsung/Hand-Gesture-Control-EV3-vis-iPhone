/*
 * File: cnnConvolve.h
 *
 * MATLAB Coder version            : 2.7
 * C/C++ source code generated on  : 16-Jul-2015 16:22:01
 */

#ifndef __CNNCONVOLVE_H__
#define __CNNCONVOLVE_H__

/* Include Files */
#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include "rt_nonfinite.h"
#include "rtwtypes.h"
#include "cnnPredict_types.h"

/* Function Declarations */
extern void cnnConvolve(const double images[9216], const double W[1620], const
  double b[20], double convolvedFeatures[154880]);

#endif

/*
 * File trailer for cnnConvolve.h
 *
 * [EOF]
 */
