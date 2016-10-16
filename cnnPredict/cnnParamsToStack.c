/*
 * File: cnnParamsToStack.c
 *
 * MATLAB Coder version            : 2.7
 * C/C++ source code generated on  : 16-Jul-2015 16:22:01
 */

/* Include Files */
#include "rt_nonfinite.h"
#include "cnnPredict.h"
#include "cnnParamsToStack.h"

/* Function Definitions */

/*
 * Converts unrolled parameters for a single layer convolutional neural
 *  network followed by a softmax layer into structured weight
 *  tensors/matrices and corresponding biases
 *
 *  Parameters:
 *   theta      -  unrolled parameter vectore
 *   imageDim   -  height/width of image
 *   filterDim  -  dimension of convolutional filter
 *   numFilters -  number of convolutional filters
 *   poolDim    -  dimension of pooling area
 *   numClasses -  number of classes to predict
 *
 *
 *  Returns:
 *   Wc      -  filterDim x filterDim x numFilters parameter matrix
 *   Wd      -  numClasses x hiddenSize parameter matrix, hiddenSize is
 *              calculated as numFilters*((imageDim-filterDim+1)/poolDim)^2
 *   bc      -  bias for convolution layer of size numFilters x 1
 *   bd      -  bias for dense layer of size hiddenSize x 1
 * Arguments    : const double theta[195245]
 *                double Wc[1620]
 *                double Wd[193600]
 *                double bc[20]
 *                double bd[5]
 * Return Type  : void
 */
void cnnParamsToStack(const double theta[195245], double Wc[1620], double Wd
                      [193600], double bc[20], double bd[5])
{
  int i;

  /* % Reshape theta */
  memcpy(&Wc[0], &theta[0], 1620U * sizeof(double));
  memcpy(&Wd[0], &theta[1620], 193600U * sizeof(double));
  memcpy(&bc[0], &theta[195220], 20U * sizeof(double));
  for (i = 0; i < 5; i++) {
    bd[i] = theta[i + 195240];
  }
}

/*
 * File trailer for cnnParamsToStack.c
 *
 * [EOF]
 */
