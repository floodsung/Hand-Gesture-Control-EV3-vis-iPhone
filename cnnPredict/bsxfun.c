/*
 * File: bsxfun.c
 *
 * MATLAB Coder version            : 2.7
 * C/C++ source code generated on  : 16-Jul-2015 16:22:01
 */

/* Include Files */
#include "rt_nonfinite.h"
#include "cnnPredict.h"
#include "bsxfun.h"

/* Function Definitions */

/*
 * Arguments    : const double a[5]
 *                double b
 *                double c[5]
 * Return Type  : void
 */
void bsxfun(const double a[5], double b, double c[5])
{
  int k;
  for (k = 0; k < 5; k++) {
    c[k] = a[k] / b;
  }
}

/*
 * File trailer for bsxfun.c
 *
 * [EOF]
 */
