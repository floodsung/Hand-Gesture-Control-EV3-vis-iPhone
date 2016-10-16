/*
 * File: cnnPool.c
 *
 * MATLAB Coder version            : 2.7
 * C/C++ source code generated on  : 16-Jul-2015 16:22:01
 */

/* Include Files */
#include "rt_nonfinite.h"
#include "cnnPredict.h"
#include "cnnPool.h"
#include "conv2.h"
#include "squeeze.h"

/* Function Definitions */

/*
 * cnnPool Pools the given convolved features
 *
 *  Parameters:
 *   poolDim - dimension of pooling region
 *   convolvedFeatures - convolved features to pool (as given by cnnConvolve)
 *                       convolvedFeatures(imageRow, imageCol, featureNum, imageNum)
 *
 *  Returns:
 *   pooledFeatures - matrix of pooled features in the form
 *                    pooledFeatures(poolRow, poolCol, featureNum, imageNum)
 * Arguments    : const double convolvedFeatures[154880]
 *                double pooledFeatures[38720]
 * Return Type  : void
 */
void cnnPool(const double convolvedFeatures[154880], double pooledFeatures[38720])
{
  boolean_T b0;
  int filterNum;
  double feature[7744];
  double dv5[4];
  int i2;
  double temp_pooledFeature[7569];
  int i3;
  b0 = false;

  /*  Instructions: */
  /*    Now pool the convolved features in regions of poolDim x poolDim, */
  /*    to obtain the  */
  /*    (convolvedDim/poolDim) x (convolvedDim/poolDim) x numFeatures x numImages  */
  /*    matrix pooledFeatures, such that */
  /*    pooledFeatures(poolRow, poolCol, featureNum, imageNum) is the  */
  /*    value of the featureNum feature for the imageNum image pooled over the */
  /*    corresponding (poolRow, poolCol) pooling region.  */
  /*     */
  /*    Use mean pooling here. */
  /* %% YOUR CODE HERE %%% */
  for (filterNum = 0; filterNum < 20; filterNum++) {
    /*  pool of image */
    /*  Obtain the convolved feature to pool */
    c_squeeze(*(double (*)[7744])&convolvedFeatures[7744 * filterNum], feature);

    /*  Convolve "filter" with "feature", adding the result to pooledFeatures */
    /*  be sure to do a 'valid' convolution */
    /* %% YOUR CODE HERE %%% */
    if (!b0) {
      for (i2 = 0; i2 < 4; i2++) {
        dv5[i2] = 1.0;
      }

      b0 = true;
    }

    b_conv2(feature, dv5, temp_pooledFeature);
    for (i2 = 0; i2 < 44; i2++) {
      for (i3 = 0; i3 < 44; i3++) {
        pooledFeatures[(i3 + 44 * i2) + 1936 * filterNum] = temp_pooledFeature
          [(i3 << 1) + 87 * (i2 << 1)] / 4.0;
      }
    }
  }
}

/*
 * File trailer for cnnPool.c
 *
 * [EOF]
 */
