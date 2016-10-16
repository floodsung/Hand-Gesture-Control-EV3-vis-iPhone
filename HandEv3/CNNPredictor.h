//
//  CNNPredictor.h
//  HandEv3
//
//  Created by FloodSurge on 15/7/16.
//  Copyright (c) 2015年 FloodSurge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CNNPredictor : NSObject

+ (double)recognizeImage:(CGImageRef)images withRect:(CGRect)tempRect withTheta:(double *)theta;

+ (double)recognizeImage:(CGImageRef)images withTheta:(double *)theta;
@end
