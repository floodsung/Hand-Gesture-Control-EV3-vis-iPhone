/*
 * File: sigmoid.c
 *
 * MATLAB Coder version            : 2.7
 * C/C++ source code generated on  : 16-Jul-2015 16:22:01
 */

/* Include Files */
#include "rt_nonfinite.h"
#include "cnnPredict.h"
#include "sigmoid.h"

/* Function Definitions */

/*
 * Arguments    : const double a[7744]
 *                double h[7744]
 * Return Type  : void
 */
void sigmoid(const double a[7744], double h[7744])
{
  int i1;
  for (i1 = 0; i1 < 7744; i1++) {
    h[i1] = 1.0 / (1.0 + exp(-a[i1]));
  }
}

/*
 * File trailer for sigmoid.c
 *
 * [EOF]
 */
