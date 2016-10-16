/*
 * File: repmat.c
 *
 * MATLAB Coder version            : 2.7
 * C/C++ source code generated on  : 16-Jul-2015 16:22:01
 */

/* Include Files */
#include "rt_nonfinite.h"
#include "cnnPredict.h"
#include "repmat.h"

/* Function Definitions */

/*
 * Arguments    : const double a[5]
 *                double b[5]
 * Return Type  : void
 */
void repmat(const double a[5], double b[5])
{
  int k;
  for (k = 0; k < 5; k++) {
    b[k] = a[k];
  }
}

/*
 * File trailer for repmat.c
 *
 * [EOF]
 */
