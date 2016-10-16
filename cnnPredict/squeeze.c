/*
 * File: squeeze.c
 *
 * MATLAB Coder version            : 2.7
 * C/C++ source code generated on  : 16-Jul-2015 16:22:01
 */

/* Include Files */
#include "rt_nonfinite.h"
#include "cnnPredict.h"
#include "squeeze.h"

/* Function Definitions */

/*
 * Arguments    : const double a[9216]
 *                double b[9216]
 * Return Type  : void
 */
void b_squeeze(const double a[9216], double b[9216])
{
  memcpy(&b[0], &a[0], 9216U * sizeof(double));
}

/*
 * Arguments    : const double a[7744]
 *                double b[7744]
 * Return Type  : void
 */
void c_squeeze(const double a[7744], double b[7744])
{
  memcpy(&b[0], &a[0], 7744U * sizeof(double));
}

/*
 * Arguments    : const double a[81]
 *                double b[81]
 * Return Type  : void
 */
void squeeze(const double a[81], double b[81])
{
  memcpy(&b[0], &a[0], 81U * sizeof(double));
}

/*
 * File trailer for squeeze.c
 *
 * [EOF]
 */
