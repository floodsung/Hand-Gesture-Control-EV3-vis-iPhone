/*
 * File: sum.c
 *
 * MATLAB Coder version            : 2.7
 * C/C++ source code generated on  : 16-Jul-2015 16:22:01
 */

/* Include Files */
#include "rt_nonfinite.h"
#include "cnnPredict.h"
#include "sum.h"

/* Function Definitions */

/*
 * Arguments    : const double x[5]
 * Return Type  : double
 */
double sum(const double x[5])
{
  double y;
  int k;
  y = x[0];
  for (k = 0; k < 4; k++) {
    y += x[k + 1];
  }

  return y;
}

/*
 * File trailer for sum.c
 *
 * [EOF]
 */
