/*
 * File: cnnPredict.c
 *
 * MATLAB Coder version            : 2.7
 * C/C++ source code generated on  : 16-Jul-2015 16:22:01
 */

/* Include Files */
#include "rt_nonfinite.h"
#include "cnnPredict.h"
#include "bsxfun.h"
#include "sum.h"
#include "exp.h"
#include "repmat.h"
#include "cnnPool.h"
#include "cnnConvolve.h"
#include "cnnParamsToStack.h"

/* Function Definitions */

/*
 * addpath ./opt_parameters;
 * addpath ./data;
 * load('opttheta_8epoches_cnn.mat');
 * images = imread(img);
 * images = img;
 * Arguments    : const double images[9216]
 *                const double opttheta[195245]
 * Return Type  : double
 */
double cnnPredict(const double images[9216], const double opttheta[195245])
{
  double labels;
  double probs[5];
  double bc[20];
  static double Wd[193600];
  double Wc[1620];
  static double dv0[154880];
  static double activationsPooled[38720];
  static double b_activationsPooled[38720];
  double dv1[5];
  double temp_probs[5];
  int ixstart;
  double mtmp;
  int itmp;
  int ix;
  boolean_T exitg1;

  /*  Number of classes (MNIST images fall into 10 classes) */
  /*  Filter size for conv layer */
  /*  Number of filters for conv layer */
  /*  Pooling dimension, (should divide imageDim-filterDim+1) */
  /*  height/width of image */
  /*  weight decay parameter */
  /*  dimension of convolved output */
  /*  dimension of subsampled output */
  cnnParamsToStack(opttheta, Wc, Wd, bc, probs);

  /*  convDim x convDim x numFilters x numImages tensor for storing activations */
  /*  outputDim x outputDim x numFilters x numImages tensor for storing */
  /*  subsampled activations */
  cnnConvolve(images, Wc, bc, dv0);
  cnnPool(dv0, activationsPooled);

  /*  Reshape activations into 2-d matrix, hiddenSize x numImages, */
  /*  for Softmax layer */
  memcpy(&b_activationsPooled[0], &activationsPooled[0], 38720U * sizeof(double));
  repmat(probs, dv1);
  for (ixstart = 0; ixstart < 5; ixstart++) {
    mtmp = 0.0;
    for (itmp = 0; itmp < 38720; itmp++) {
      mtmp += Wd[ixstart + 5 * itmp] * b_activationsPooled[itmp];
    }

    temp_probs[ixstart] = mtmp + dv1[ixstart];
  }

  b_exp(temp_probs);
  bsxfun(temp_probs, sum(temp_probs), probs);
  ixstart = 1;
  mtmp = probs[0];
  itmp = 1;
  if (rtIsNaN(probs[0])) {
    ix = 2;
    exitg1 = false;
    while ((!exitg1) && (ix < 6)) {
      ixstart = ix;
      if (!rtIsNaN(probs[ix - 1])) {
        mtmp = probs[ix - 1];
        itmp = ix;
        exitg1 = true;
      } else {
        ix++;
      }
    }
  }

  if (ixstart < 5) {
    while (ixstart + 1 < 6) {
      if (probs[ixstart] > mtmp) {
        mtmp = probs[ixstart];
        itmp = ixstart + 1;
      }

      ixstart++;
    }
  }

  labels = itmp;

  /* fprintf('CNN Predicted class is %d\n',labels); */
  return labels;
}

/*
 * File trailer for cnnPredict.c
 *
 * [EOF]
 */
