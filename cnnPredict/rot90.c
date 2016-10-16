/*
 * File: rot90.c
 *
 * MATLAB Coder version            : 2.7
 * C/C++ source code generated on  : 16-Jul-2015 16:22:01
 */

/* Include Files */
#include "rt_nonfinite.h"
#include "cnnPredict.h"
#include "rot90.h"

/* Function Definitions */

/*
 * Arguments    : const double A[81]
 *                double B[81]
 * Return Type  : void
 */
void rot90(const double A[81], double B[81])
{
  int j;
  int i;
  for (j = 0; j < 9; j++) {
    for (i = 0; i < 9; i++) {
      B[i + 9 * j] = A[(9 * (8 - j) - i) + 8];
    }
  }
}

/*
 * File trailer for rot90.c
 *
 * [EOF]
 */
