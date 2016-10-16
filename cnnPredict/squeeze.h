/*
 * File: squeeze.h
 *
 * MATLAB Coder version            : 2.7
 * C/C++ source code generated on  : 16-Jul-2015 16:22:01
 */

#ifndef __SQUEEZE_H__
#define __SQUEEZE_H__

/* Include Files */
#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include "rt_nonfinite.h"
#include "rtwtypes.h"
#include "cnnPredict_types.h"

/* Function Declarations */
extern void b_squeeze(const double a[9216], double b[9216]);
extern void c_squeeze(const double a[7744], double b[7744]);
extern void squeeze(const double a[81], double b[81]);

#endif

/*
 * File trailer for squeeze.h
 *
 * [EOF]
 */
