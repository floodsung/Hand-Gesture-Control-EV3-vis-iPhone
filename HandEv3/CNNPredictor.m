//
//  CNNPredictor.m
//  HandEv3
//
//  Created by FloodSurge on 15/7/16.
//  Copyright (c) 2015年 FloodSurge. All rights reserved.
//

#import "CNNPredictor.h"
#import "CNNPredictor.h"
#import "cnnPredict.h"

@implementation CNNPredictor

+ (double)recognizeImage:(CGImageRef)imageRef withRect:(CGRect)tempRect withTheta:(double *)theta
{
    /*
    CGImageRef subImageRef = CGImageCreateWithImageInRect(imageRef, tempRect);
    
    CGSize saveSize = CGSizeMake(96, 96);
    
    
    UIGraphicsBeginImageContext(saveSize);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();

    
    CGRect saveRect = CGRectMake(0, 0, 96, 96);
    
    CGContextDrawImage(context, saveRect, subImageRef);
    
    CGImageRef smallImage = CGBitmapContextCreateImage(context);
    */
    CGDataProviderRef provider = CGImageGetDataProvider(imageRef);
    //UIGraphicsEndImageContext();

    NSData *data = (id)CFBridgingRelease(CGDataProviderCopyData(provider));
    NSLog(@"image:%lu",(unsigned long)data.length);
    
    
    const uint8_t *bytes = data.bytes;
    double newBytes[9216];
    /*
     for (int i = 0; i<9216; i++) {
     newBytes[i] = (double)bytes[i];
     }
     */
    for (int y = 0; y < 96 ; y++) {
        for (int x = 0; x < 96; x++) {
            newBytes[x*96 + y] = bytes[y*96 + x];
        }
    }
    
    return cnnPredict(newBytes, theta);

}

+ (double)recognizeImage:(CGImageRef)imageRef withTheta:(double *)theta
{
    CGDataProviderRef provider = CGImageGetDataProvider(imageRef);
    //UIGraphicsEndImageContext();
    
    NSData *data = (id)CFBridgingRelease(CGDataProviderCopyData(provider));
    //NSLog(@"image:%lu",(unsigned long)data.length);
    
    
    const uint8_t *bytes = data.bytes;
    double newBytes[9216];
    /*
     for (int i = 0; i<9216; i++) {
     newBytes[i] = (double)bytes[i];
     }
     */
    for (int y = 0; y < 96 ; y++) {
        for (int x = 0; x < 96; x++) {
            newBytes[x*96 + y] = bytes[y*96 + x];
        }
    }
    
    return cnnPredict(newBytes, theta);

}


@end
