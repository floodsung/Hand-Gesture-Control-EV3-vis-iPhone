/*
 * File: cnnConvolve.c
 *
 * MATLAB Coder version            : 2.7
 * C/C++ source code generated on  : 16-Jul-2015 16:22:01
 */

/* Include Files */
#include "rt_nonfinite.h"
#include "cnnPredict.h"
#include "cnnConvolve.h"
#include "sigmoid.h"
#include "conv2.h"
#include "rot90.h"
#include "squeeze.h"

/* Function Definitions */

/*
 * cnnConvolve Returns the convolution of the features given by W and b with
 * the given images
 *
 *  Parameters:
 *   filterDim - filter (feature) dimension
 *   numFilters - number of feature maps
 *   images - large images to convolve with, matrix in the form
 *            images(r, c, image number)
 *   W, b - W, b for features from the sparse autoencoder
 *          W is of shape (filterDim,filterDim,numFilters)
 *          b is of shape (numFilters,1)
 *
 *  Returns:
 *   convolvedFeatures - matrix of convolved features in the form
 *                       convolvedFeatures(imageRow, imageCol, featureNum, imageNum)
 * Arguments    : const double images[9216]
 *                const double W[1620]
 *                const double b[20]
 *                double convolvedFeatures[154880]
 * Return Type  : void
 */
void cnnConvolve(const double images[9216], const double W[1620], const double
                 b[20], double convolvedFeatures[154880])
{
  int filterNum;
  double dv2[81];
  static double dv3[9216];
  double dv4[81];
  double convolvedImage[7744];
  double b_convolvedImage[7744];
  int i0;

  /*  Instructions: */
  /*    Convolve every filter with every image here to produce the  */
  /*    (imageDim - filterDim + 1) x (imageDim - filterDim + 1) x numFilters x numImages */
  /*    matrix convolvedFeatures, such that  */
  /*    convolvedFeatures(imageRow, imageCol, featureNum, imageNum) is the */
  /*    value of the convolved featureNum feature for the imageNum image over */
  /*    the region (imageRow, imageCol) to (imageRow + filterDim - 1, imageCol + filterDim - 1) */
  /*  */
  /*  Expected running times:  */
  /*    Convolving with 100 images should take less than 30 seconds  */
  /*    Convolving with 5000 images should take around 2 minutes */
  /*    (So to save time when testing, you should convolve with less images, as */
  /*    described earlier) */
  for (filterNum = 0; filterNum < 20; filterNum++) {
    /*  convolution of image with feature matrix */
    /*  Obtain the feature (filterDim x filterDim) needed during the convolution */
    /* %% YOUR CODE HERE %%% */
    /*  Flip the feature matrix because of the definition of convolution, as explained later */
    squeeze(*(double (*)[81])&W[81 * filterNum], dv2);

    /*  Obtain the image */
    /*  Convolve "filter" with "im", adding the result to convolvedImage */
    /*  be sure to do a 'valid' convolution */
    /* %% YOUR CODE HERE %%% */
    b_squeeze(images, dv3);
    rot90(dv2, dv4);
    conv2(dv3, dv4, convolvedImage);

    /*  Add the bias unit */
    /*  Then, apply the sigmoid function to get the hidden activation */
    /* %% YOUR CODE HERE %%% */
    for (i0 = 0; i0 < 7744; i0++) {
      b_convolvedImage[i0] = convolvedImage[i0] + b[filterNum];
    }

    sigmoid(b_convolvedImage, convolvedImage);
    for (i0 = 0; i0 < 88; i0++) {
      memcpy(&convolvedFeatures[88 * i0 + 7744 * filterNum], &convolvedImage[88 *
             i0], 88U * sizeof(double));
    }
  }
}

/*
 * File trailer for cnnConvolve.c
 *
 * [EOF]
 */
