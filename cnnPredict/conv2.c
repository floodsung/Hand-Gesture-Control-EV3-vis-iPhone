/*
 * File: conv2.c
 *
 * MATLAB Coder version            : 2.7
 * C/C++ source code generated on  : 16-Jul-2015 16:22:01
 */

/* Include Files */
#include "rt_nonfinite.h"
#include "cnnPredict.h"
#include "conv2.h"

/* Function Definitions */

/*
 * Arguments    : const double arg1[7744]
 *                const double arg2[4]
 *                double c[7569]
 * Return Type  : void
 */
void b_conv2(const double arg1[7744], const double arg2[4], double c[7569])
{
  int j;
  int k;
  int b_j;
  int iC;
  int b_c;
  int iB;
  int i;
  int firstRowA;
  int a_length;
  int cidx;
  int r;
  memset(&c[0], 0, 7569U * sizeof(double));
  for (j = 0; j < 2; j++) {
    if (j < 1) {
      k = 1;
    } else {
      k = 0;
    }

    while (k <= 87 - j) {
      if (j + k > 1) {
        b_j = (j + k) - 1;
      } else {
        b_j = 0;
      }

      iC = b_j * 87;
      b_c = k * 88;
      iB = j << 1;
      for (i = 0; i < 2; i++) {
        if (i < 1) {
          firstRowA = 1;
        } else {
          firstRowA = 0;
        }

        a_length = 88 - (i + firstRowA);
        firstRowA += b_c;
        cidx = iC;
        for (r = 1; r <= a_length; r++) {
          c[cidx] += arg2[iB] * arg1[firstRowA];
          firstRowA++;
          cidx++;
        }

        iB++;
        if (i >= 1) {
          iC++;
        }
      }

      k++;
    }
  }
}

/*
 * Arguments    : const double arg1[9216]
 *                const double arg2[81]
 *                double c[7744]
 * Return Type  : void
 */
void conv2(const double arg1[9216], const double arg2[81], double c[7744])
{
  int j;
  int k;
  int b_j;
  int iC;
  int b_c;
  int iB;
  int i;
  int firstRowA;
  int a_length;
  int cidx;
  int r;
  memset(&c[0], 0, 7744U * sizeof(double));
  for (j = 0; j < 9; j++) {
    if (j < 8) {
      k = 8 - j;
    } else {
      k = 0;
    }

    while (k <= 95 - j) {
      if (j + k > 8) {
        b_j = (j + k) - 8;
      } else {
        b_j = 0;
      }

      iC = b_j * 88;
      b_c = k * 96;
      iB = j * 9;
      for (i = 0; i < 9; i++) {
        if (i < 8) {
          firstRowA = 8 - i;
        } else {
          firstRowA = 0;
        }

        a_length = 96 - (i + firstRowA);
        firstRowA += b_c;
        cidx = iC;
        for (r = 1; r <= a_length; r++) {
          c[cidx] += arg2[iB] * arg1[firstRowA];
          firstRowA++;
          cidx++;
        }

        iB++;
        if (i >= 8) {
          iC++;
        }
      }

      k++;
    }
  }
}

/*
 * File trailer for conv2.c
 *
 * [EOF]
 */
