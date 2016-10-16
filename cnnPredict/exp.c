/*
 * File: exp.c
 *
 * MATLAB Coder version            : 2.7
 * C/C++ source code generated on  : 16-Jul-2015 16:22:01
 */

/* Include Files */
#include "rt_nonfinite.h"
#include "cnnPredict.h"
#include "exp.h"

/* Function Definitions */

/*
 * Arguments    : double x[5]
 * Return Type  : void
 */
void b_exp(double x[5])
{
  int k;
  for (k = 0; k < 5; k++) {
    x[k] = exp(x[k]);
  }
}

/*
 * File trailer for exp.c
 *
 * [EOF]
 */
