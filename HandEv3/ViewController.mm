//
//  ViewController.m
//  HandEv3
//
//  Created by FloodSurge on 14/12/16.
//  Copyright (c) 2014年 FloodSurge. All rights reserved.
//

#import "ViewController.h"
#import <ExternalAccessory/ExternalAccessory.h>
#import "EADSessionController.h"
#import "EV3DirectCommander.h"

#import <opencv2/opencv.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <string>
#include <vector>
#include <cmath>

#import <opencv2/imgproc/types_c.h>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/videoio/cap_ios.h>

#import "CNNPredictor.h"


using namespace cv;
using namespace std;

@interface ViewController ()<CvVideoCameraDelegate>
{
    BOOL isConnected;
    BOOL isDetect;
    vector<int> fingerTipsData;
    vector<cv::Rect> palmLocationData;
    BOOL isForward;
    float angle;
    float power;
    int fingerTipsNum;
    int fingerType;
    vector<cv::Point> fingerTips;
    double twoFingerDistance;
    int motorA;
    int timeCounter;
    CGImageRef tempImage;
    CGImageRef tempRawImage;
    CGImageRef tempAdaptiveColorImage;
    CGImageRef tempSkinImage;
    CGImageRef tempBinaryImage;
    CGImageRef tempContourImage;
    CGImageRef tempFingerImage;
    CGImageRef tempFinalImage;
    CGImageRef tempTwoFingerImage;
    CGImageRef tempSeparationImage;
    CGImageRef tempUImage;
    
    CGRect tempRect;
    cv::RotatedRect rotatedRect;
    
    // CNN theta
    double theta[195245];
    
    double HParam;
    double LParam;
    double SParam;
    
    Mat tempMat;

    
  // EV3 Arm
    BOOL hasGrab;
    BOOL hasDrop;
    
}
@property (nonatomic,strong) EADSessionController *sessionController;
@property (nonatomic,strong) EAAccessory *ev3Device;
@property (nonatomic,strong) NSTimer *timer;

@property (nonatomic,strong) CvVideoCamera *videoCamera;

@property (weak, nonatomic) IBOutlet UILabel *fingerLabel;
@property (weak, nonatomic) IBOutlet UILabel *HLSLabel;

@property (weak, nonatomic) IBOutlet UILabel *HLSAveLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self openCamera];
    isDetect = YES;
    timeCounter = 0;
    fingerTipsNum = 0;
    
    HParam = 0.68;
    LParam = 1.1554;
    SParam = 0.8772;
    
    hasGrab = NO;
    hasDrop = YES;
    
    [self loadCNNTheta];
    
    [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(recognizeFingers) userInfo:nil repeats:YES];
}

- (IBAction)calibrate:(id)sender
{
    // Calibrate HLS Params
    int imageRow = tempMat.rows;
    int imageCol = tempMat.cols;
    int width = 15;
    
    double avg_H = 0;
    double avg_L = 0;
    double avg_S = 0;
    int pixelCounter = 0;
    
    for (int row = imageRow/2 - width; row < imageRow/2 + width; row++) {
        for (int col = imageCol/2 - width; col < imageCol/2 + width; col++) {
            uchar H = tempMat.at<cv::Vec3b>(row,col)[0];
            uchar L = tempMat.at<cv::Vec3b>(row,col)[1];
            uchar S = tempMat.at<cv::Vec3b>(row,col)[2];
            
            avg_H += (double)H;
            avg_L += (double)L;
            avg_S += (double)S;
            pixelCounter++;
        }
    }
    
    avg_H = avg_H/pixelCounter;
    avg_S = avg_S/pixelCounter;
    avg_L = avg_L/pixelCounter;
    
    NSLog(@"H:%f,L:%f,S:%f",avg_H,avg_L,avg_S);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.HLSLabel.text = [NSString stringWithFormat:@"H:%4.1f,L:%4.1f,S:%4.1f",avg_H,avg_L,avg_S];
    });
    
    HParam = 10/avg_H;
    LParam = 200/avg_L;
    SParam = 100/avg_S;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)openCamera
{
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:self.cameraView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    self.videoCamera.defaultFPS = 30;
    //[self.videoCamera unlockBalance];
    //[self.videoCamera unlockFocus];
    
    [self.videoCamera start];
    // 直接在storyboard更改view的大小
    /*
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {
        [device lockForConfiguration:nil];
        [device setTorchMode: AVCaptureTorchModeOn];
        [device unlockForConfiguration];
    }
     */
}

#pragma mark - EV3 Connection and Controller


- (IBAction)connectEV3:(UISwitch *)sender
{
    if (sender.isOn && !isConnected) {
        NSLog(@"connect EV3");
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accessoryDidConnect:) name:EAAccessoryDidConnectNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accessoryDidDisconnect:) name:EAAccessoryDidDisconnectNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionDataReceived:) name:EADSessionDataReceivedNotification object:nil];
        [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];
        self.sessionController = [EADSessionController sharedController];
       NSMutableArray *accessoryList = [[NSMutableArray alloc] initWithArray:[[EAAccessoryManager sharedAccessoryManager] connectedAccessories]];
        NSLog(@"accessory list:%@",accessoryList);
        if(accessoryList != nil){
            [self.sessionController setupControllerForAccessory:[accessoryList firstObject]
                                             withProtocolString:@"COM.LEGO.MINDSTORMS.EV3"];
            isConnected = [self.sessionController openSession];
            if (isConnected) {
                NSLog(@"ev3 on");
                self.timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(controlEV3) userInfo:nil repeats:YES];
                isForward = NO;
            }
        }

    } else {
        [self.sessionController closeSession];
        isConnected = NO;
        self.navigationController.navigationItem.title = @"EV3 Off";
        NSLog(@"ev3 off");
        [self.timer invalidate];
        
    
    }
}

- (void)accessoryDidConnect:(NSNotification *)notification {
    NSLog(@"accessory Did Connect");
    
}

- (void)accessoryDidDisconnect:(NSNotification *)notification {
    NSLog(@"accessory Did Disconnect");
    self.ev3ConnectButton.on = NO;
    [self.timer invalidate];
}

- (void)sessionDataReceived:(NSNotification *)notification
{
  
    NSData *data = [self.sessionController readData:self.sessionController.readBytesAvailable];
    Byte * bytes = (Byte *)data.bytes;
    motorA = (int)(bytes[5] | (bytes[6] << 8));
    NSLog(@"data:%@,motorA:%d",data,motorA);
}

- (void)controlEV3
{
    [self controlEV3Arm];
    /*
    timeCounter++;
    timeCounter = timeCounter%4;
    NSData *data = [EV3DirectCommander readSensorDataAtPort:EV3InputPortA mode:0];
    [[EADSessionController sharedController] writeData:data];

    
    if (fingerTipsData.size() == 10) {
        if (fingerTipsData[9] == 4 && fingerTipsData[8] ==4 ) {
            int leftPower = int(power * 40 + (angle - 90)*0.4);
            int rightPower = int(power * 40 - (angle - 90)*0.4);
            
            leftPower = leftPower > 100? 100:leftPower;
            rightPower = rightPower > 100? 100:rightPower;
            leftPower = leftPower < -100? -100:leftPower;
            rightPower = rightPower < -100? -100:rightPower;
            
            
            NSData *data = [EV3DirectCommander turnMotorsAtPort:EV3OutputPortB power:leftPower port:EV3OutputPortD power:rightPower];
            [[EADSessionController sharedController] writeData:data];
            
        } else if (fingerTipsData[9] == 0 && fingerTipsData[8] == 0 ){
            NSData *data = [EV3DirectCommander turnMotorAtPort:EV3OutputPortBD power:0];
            [[EADSessionController sharedController] writeData:data];
        } else if (fingerTipsData[9] == 1 && fingerTipsData[8] == 1) {
            int leftPower = int(power * 40 + (angle - 90)*0.4);
            int rightPower = int(power * 40 - (angle - 90)*0.4);
            
            leftPower = leftPower > 100? 100:leftPower;
            rightPower = rightPower > 100? 100:rightPower;
            leftPower = leftPower < -100? -100:leftPower;
            rightPower = rightPower < -100? -100:rightPower;
            
            
            NSData *data = [EV3DirectCommander turnMotorsAtPort:EV3OutputPortB power:-leftPower port:EV3OutputPortD power:-rightPower];
            [[EADSessionController sharedController] writeData:data];

        } else if (fingerTipsData[9] == 5 && fingerTipsData[8] == 5 && timeCounter == 0) {
            NSData *data = [EV3DirectCommander turnMotorAtPort:EV3OutputPortBD power:0];
            [[EADSessionController sharedController] writeData:data];
            
            int degree = (int)(power*150 - 180);
            degree = degree > 90?90:degree;
            degree = degree < 10?10:degree;
            
            int offset = degree - motorA;
            NSLog(@"degree:%d",degree);
            
            if (offset > 0) {
                    data = [EV3DirectCommander turnMotorAtPort:EV3OutputPortA power:30 degrees:offset];
                } else {
                    data = [EV3DirectCommander turnMotorAtPort:EV3OutputPortA power:-30 degrees:abs(offset)];
                }
                    
            [[EADSessionController sharedController] writeData:data];
            
        }
    }
    */
    
    /*
    if (fingerTipsNum >= 3) {
        int leftPower = int(power * 40 + (angle - 90)*0.4);
        int rightPower = int(power * 40 - (angle - 90)*0.4);
        
        leftPower = leftPower > 100? 100:leftPower;
        rightPower = rightPower > 100? 100:rightPower;
        leftPower = leftPower < -100? -100:leftPower;
        rightPower = rightPower < -100? -100:rightPower;
        
        
        NSData *data = [EV3DirectCommander turnMotorsAtPort:EV3OutputPortB power:leftPower port:EV3OutputPortD power:rightPower];
        [[EADSessionController sharedController] writeData:data];
        
    } else if (fingerTipsNum == 2)
    {
        
        int leftPower = int(power * 40 + (angle - 90)*0.4);
        int rightPower = int(power * 40 - (angle - 90)*0.4);
        
        leftPower = leftPower > 100? 100:leftPower;
        rightPower = rightPower > 100? 100:rightPower;
        leftPower = leftPower < -100? -100:leftPower;
        rightPower = rightPower < -100? -100:rightPower;
        
        
        NSData *data = [EV3DirectCommander turnMotorsAtPort:EV3OutputPortB power:-leftPower port:EV3OutputPortD power:-rightPower];
        [[EADSessionController sharedController] writeData:data];
     

    } else if (fingerTipsNum <= 1)
    {
        NSData *data = [EV3DirectCommander turnMotorAtPort:EV3OutputPortBD power:0];
        [[EADSessionController sharedController] writeData:data];
    }
    */

}

- (void)controlEV3Arm
{
    // Grab
    if (twoFingerDistance < 0.4 && hasDrop) {
        hasDrop = NO;
        hasGrab = YES;
        NSData *data = [EV3DirectCommander turnMotorAtPort:EV3OutputPortB power:30 degrees:60];
        [[EADSessionController sharedController] writeData:data];
    } else if (twoFingerDistance > 0.8 && hasGrab){
        hasDrop = YES;
        hasGrab = NO;
        NSData *data = [EV3DirectCommander turnMotorAtPort:EV3OutputPortB power:-30 degrees:60];
        [[EADSessionController sharedController] writeData:data];
    }
    
    // Turn
    if (fingerTipsNum == 5) {
        int velocity = int(angle-90);
        NSData *data = [EV3DirectCommander turnMotorAtPort:EV3OutputPortA power:velocity];
        [[EADSessionController sharedController] writeData:data];
    } else {
        NSData *data = [EV3DirectCommander turnMotorAtPort:EV3OutputPortA power:0];
        [[EADSessionController sharedController] writeData:data];

    }
    // Up and Down
    if (fingerTipsNum == 1) {
        NSLog(@"ratio:%f",power);
        if(power > 2.3){
            // Up
            NSData *data = [EV3DirectCommander turnMotorAtPort:EV3OutputPortC power:-30];
            [[EADSessionController sharedController] writeData:data];
        } else if(power < 2){
            NSData *data = [EV3DirectCommander turnMotorAtPort:EV3OutputPortC power:30];
            [[EADSessionController sharedController] writeData:data];
        } else {
            NSData *data = [EV3DirectCommander turnMotorAtPort:EV3OutputPortC power:0];
            [[EADSessionController sharedController] writeData:data];
        }
    }
    
    
}

- (IBAction)testEV3:(id)sender
{
    if (isForward) {
        NSData *data = [EV3DirectCommander turnMotorAtPort:EV3OutputPortBD power:0];
        [[EADSessionController sharedController] writeData:data];
        isForward = NO;
    } else {
        NSData *data = [EV3DirectCommander turnMotorAtPort:EV3OutputPortBD power:50];
        [[EADSessionController sharedController] writeData:data];
        isForward = YES;
    }
}

#pragma mark - Hand Detection

- (void)loadCNNTheta
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"opttheta" ofType:@"txt"];
    NSString *testString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSMutableArray *thetaString = (NSMutableArray *)[testString componentsSeparatedByString:@"\n"];
    [thetaString removeLastObject];
    NSLog(@"Theta1 count:%lu",(unsigned long)thetaString.count);
    for (int i = 0; i < thetaString.count; i++) {
        NSString *data = [thetaString objectAtIndex:i];
        theta[i] = [data doubleValue];
    }

}

-(CGImageRef)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        //NSLog(@"gray");
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        //NSLog(@"rgb");
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    //UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    //CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return imageRef;
}

- (IBAction)save:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if (tempFinalImage) {
            [self saveImage:tempFinalImage];
        }
        if (tempBinaryImage) {
            [self saveImage:tempBinaryImage];
        }
        if (tempSeparationImage) {
            [self saveImage:tempSeparationImage];
        }
        if (tempUImage) {
            [self saveImage:tempUImage];
        }
        if (tempRawImage)
        {
            [self saveImage:tempRawImage];
        }
        
    });
    /*
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if (tempRawImage) {
            [self saveImage:tempRawImage];
        }
        if (tempAdaptiveColorImage) {
            [self saveImage:tempAdaptiveColorImage];
        }
        if (tempSkinImage) {
            [self saveImage:tempSkinImage];
        }
        if (tempBinaryImage) {
            [self saveImage:tempBinaryImage];
        }
    });

dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        if (tempContourImage) {
            NSLog(@"save contour");
            [self saveImage:tempContourImage];
        }
        if (tempFingerImage) {
            NSLog(@"save finger");
            [self saveImage:tempFingerImage];
        }
        if (tempFinalImage) {
            NSLog(@"save final");
            [self saveImage:tempFinalImage];
        }
        if(tempImage){
            [self saveImage:tempImage];
        }
});
   */
}

- (void)saveImage:(CGImageRef)imageRef
{
    
        UIImage* image = [UIImage imageWithCGImage:imageRef];  //剪切后的图片
        
        UIImageWriteToSavedPhotosAlbum(image,nil,nil,nil);
   
    

}

- (void)recognizeFingers
{
    if (tempImage) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            fingerType = (int)[CNNPredictor recognizeImage:tempImage withTheta:theta];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.fingerLabel.text = [NSString stringWithFormat:@"%d",fingerType];
                
            });
        });
        
        
        
    }
}

- (void)processImage:(cv::Mat &)image
{
    [self handDetectionWithImage:image];
}

- (void)handDetectionWithImage:(cv::Mat &)image
{
    
    // Step 1: 通过HLS颜色获取可能是手的区域并处理
    
    Mat HLSimage;
    Mat blurImage;
    // Step 1.1:模糊处理
    //medianBlur(image, blurImage, 5);
    Mat rawImage;
    cvtColor(image, rawImage, CV_BGR2RGB);
    //tempRawImage = [self UIImageFromCVMat:rawImage];
    // Step 1.2:转换为HLS颜色
    cvtColor(image, HLSimage, CV_BGR2HLS);
    // Step 1.3:根据皮肤颜色范围获取皮肤区域：
    HLSimage.copyTo(tempMat);
    int imageRow = HLSimage.rows;
    int imageCol = HLSimage.cols;
    
    
    
    
    double avg_H = 0;
    double avg_L = 0;
    double avg_S = 0;
    int pixelCount = 0;
    
    for (int row = 0; row < imageRow; row++) {
        for (int col = 0; col < imageCol; col++) {
            uchar H = HLSimage.at<cv::Vec3b>(row,col)[0];
            uchar L = HLSimage.at<cv::Vec3b>(row,col)[1];
            uchar S = HLSimage.at<cv::Vec3b>(row,col)[2];
            double LS_ratio = ((double) L) / ((double) S);
            bool skin_pixel = (S >= 50) && (LS_ratio > 0.5) && (LS_ratio < 3.0) && ((H <= 14) || (H >= 165));
            if (skin_pixel) {
                avg_H += (double)H;
                avg_L += (double)L;
                avg_S += (double)S;
                pixelCount++;
            }

        }
    }

    
    if (pixelCount > 0) {
        avg_H = avg_H/pixelCount;
        avg_L = avg_L/pixelCount;
        avg_S = avg_S/pixelCount;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.HLSLabel.text = [NSString stringWithFormat:@"H:%4.1f,L:%4.1f,S:%4.1f",avg_H,avg_L,avg_S];
    });
    
    HParam = 10/avg_H;
    LParam = 190/avg_L;
    SParam = 120/avg_S;
    
    double L_change_rate = LParam;
    double S_change_rate = SParam;
    double H_change_rate = HParam;
    
    
    for (int row = 0; row < imageRow; row++) {
        for (int col = 0; col < imageCol; col++) {
            uchar H = HLSimage.at<cv::Vec3b>(row,col)[0];
            uchar L = HLSimage.at<cv::Vec3b>(row,col)[1];
            uchar S = HLSimage.at<cv::Vec3b>(row,col)[2];
            double LS_ratio = ((double) L) / ((double) S);
            bool skin_pixel = (S >= 50) && (LS_ratio > 0.5) && (LS_ratio < 3.0) && ((H <= 14) || (H >= 165));
            if (!skin_pixel) {

            HLSimage.at<cv::Vec3b>(row,col)[2] = HLSimage.at<cv::Vec3b>(row,col)[2] * S_change_rate;
            HLSimage.at<cv::Vec3b>(row,col)[0] = HLSimage.at<cv::Vec3b>(row,col)[0] * H_change_rate;
            HLSimage.at<cv::Vec3b>(row,col)[1] = HLSimage.at<cv::Vec3b>(row,col)[1] * L_change_rate;
            if (HLSimage.at<cv::Vec3b>(row,col)[0] > 179) {
                HLSimage.at<cv::Vec3b>(row,col)[0] = 179;
            }
            if (HLSimage.at<cv::Vec3b>(row,col)[1] > 255) {
                HLSimage.at<cv::Vec3b>(row,col)[1] = 255;
            }
            if (HLSimage.at<cv::Vec3b>(row,col)[2] > 255) {
                HLSimage.at<cv::Vec3b>(row,col)[2] = 255;
            }
            }
        }
    }
    
    Mat adaptiveImage;
    
    cvtColor(HLSimage, adaptiveImage, CV_HLS2RGB);
    
    //tempAdaptiveColorImage = [self UIImageFromCVMat:adaptiveImage];
    
    //Mat temp;
    //temp.copyTo(image);
    //temp.convertTo(temp, -1, L_change_rate, 0);
    
    //cvtColor(temp, HLSimage, CV_RGB2HLS);
    /*
     avg_H = 0;
     avg_L = 0;
     avg_S = 0;
     pixelCount = 0;
    */
    for (int row = 0; row < imageRow; row++) {
        for (int col = 0; col < imageCol; col++) {
            uchar H = HLSimage.at<cv::Vec3b>(row,col)[0];
            uchar L = HLSimage.at<cv::Vec3b>(row,col)[1];
            uchar S = HLSimage.at<cv::Vec3b>(row,col)[2];
            double LS_ratio = ((double) L) / ((double) S);
            bool skin_pixel = (S >= 50) && (LS_ratio > 0.5) && (LS_ratio < 3.0) && ((H <= 14) || (H >= 165));
            if (!skin_pixel) {
                HLSimage.at<cv::Vec3b>(row,col)[0] = 0;
                HLSimage.at<cv::Vec3b>(row,col)[1] = 0;
                HLSimage.at<cv::Vec3b>(row,col)[2] = 0;
                
            } else {
                //avg_H += (double)H;
                //avg_L += (double)L;
                //avg_S += (double)S;
                //pixelCount++;
            }
            
        }
    }
    
    /*
    if (pixelCount > 0) {
        avg_H = avg_H/pixelCount;
        avg_L = avg_L/pixelCount;
        avg_S = avg_S/pixelCount;
    }
    */
    
    
    
    // Step 1.4: 转换为RGB
    Mat skinImage;
    cvtColor(HLSimage, skinImage, CV_HLS2RGB);
    
    //tempSkinImage = [self UIImageFromCVMat:skinImage];
    
    // Step 1.5: 对皮肤区域进行二值及平滑处理
    Mat gray;
    cvtColor(skinImage, gray, CV_RGB2GRAY);
    Mat binary;
    threshold(gray, binary, 50, 255, THRESH_BINARY);
    
    
    //[self handDetection2WithImage:image];
    
    // Step 2.1:转换为YUV
    Mat yuvImage;
    cvtColor(image, yuvImage, CV_BGR2YUV);
    // Step 2.2:取出U分量
    vector<Mat> yuvImages;
    split(yuvImage, yuvImages);
    
    Mat& uImage = yuvImages[1];
    
    // Step 2.3: 形态学梯度操作
    Mat structure_element(5, 5, CV_8U, Scalar(1));
    morphologyEx(uImage, uImage, MORPH_GRADIENT, structure_element);
    threshold(uImage, uImage, 10, 255, THRESH_BINARY_INV|THRESH_OTSU);
    medianBlur(binary, binary, 5);
    //morphologyEx( binary, binary, MORPH_CLOSE,Mat());
    //morphologyEx( binary, binary, MORPH_OPEN,Mat());
    
    //tempUImage = [self UIImageFromCVMat:uImage];
    //tempBinaryImage = [self UIImageFromCVMat:binary];
    
    for (int row = 0; row < imageRow; row++) {
        for (int col = 0; col < imageCol; col++) {
            binary.at<uchar>(row,col) = uImage.at<uchar>(row,col) & binary.at<uchar>(row,col);
        }
    }
    
    //tempSeparationImage = [self UIImageFromCVMat:binary];
    // Step 3: 获取可能是手的轮廓区域并进行处理获得多边形角点
    // Step 3.1：寻找轮廓
    vector<vector<cv::Point>> contours;
    vector<Vec4i> hierarchy;
    Mat processImage;
    binary.copyTo(processImage);
    findContours( processImage, contours, hierarchy,
                 CV_RETR_TREE, CV_CHAIN_APPROX_NONE );
    
    // Step 3.2：找到最大轮廓
    int indexOfBiggestContour = -1;
    int sizeOfBiggestContour = 0;
    for (int i = 0; i < contours.size(); i++){
        if(contours[i].size() > sizeOfBiggestContour){
            sizeOfBiggestContour = int(contours[i].size());
            indexOfBiggestContour = i;
        }
    }
    //tempBinaryImage = [self UIImageFromCVMat:binary];
    // Step 2.3：检查轮廓，获取手的信息
    if(indexOfBiggestContour > -1 && sizeOfBiggestContour > 400)
    {
        // 获取轮廓多边形
        approxPolyDP(Mat(contours[indexOfBiggestContour]), contours[indexOfBiggestContour], 1.5, true);
        // 获取轮廓矩形框
        cv::Rect rect = boundingRect(Mat(contours[indexOfBiggestContour]));
        
        rotatedRect = fitEllipse(Mat(contours[indexOfBiggestContour]));
        
        
        
        angle = rotatedRect.angle;
        power = rotatedRect.size.height/rotatedRect.size.width;
        //NSLog(@"power:%f angle:%f\n",power,angle);
        
        //ellipse(image, rotatedRect, Scalar(0,0,200));
        Point2f rect_points[4];
        rotatedRect.points( rect_points );
        
        
        
        cv::Rect saveRect;
        
        if (rect.width > rect.height) {
            saveRect = cv::Rect(rect.x,rect.y -(rect.width/2 - rect.height/2),rect.width,rect.width);
        } else {
            saveRect = cv::Rect(rect.x - (rect.height/2 - rect.width/2),rect.y,rect.height,rect.height);
        }
        
        //tempRect = CGRectMake(saveRect.x, saveRect.y, saveRect.width, saveRect.height);
        
        
        
        if (saveRect.x >= 0 && saveRect.y >= 0 && saveRect.x+saveRect.width <= binary.cols && saveRect.y+saveRect.height <= binary.rows) {
            
            Mat ROIImage;
            ROIImage = binary(saveRect);
            CvSize size(96,96);
            resize(ROIImage, ROIImage, size);
            
            tempImage = [self UIImageFromCVMat:ROIImage];
            
            //rectangle(image, saveRect.tl(), saveRect.br(), Scalar(0,0,200));
            /*
            double bytes[9216];
            
            for (int row = 0; row < 96; row++) {
                for (int col = 0; col < 96; col++) {
                    bytes[row*96 + col] = (double)ROIImage.at<uchar>(row,col);
                }
            }
            
            
            double result = [CNNPredictor recognizeImage:bytes withTheta:theta];
             */
            //double result = cnnPredict(bytes, theta);
            //NSLog(@"recognize:%1f",result);
        }
    
        
        
        
        // 在image中画出轮廓
        drawContours(image, contours, indexOfBiggestContour, Scalar(200,255,255),2);
        //Mat contourImage;
        //cvtColor(image, contourImage, CV_BGR2RGB);
        //tempContourImage = [self UIImageFromCVMat:contourImage];
        
        // 检测手指
        
        
        fingerTips = detectUcurveWithContour(contours[indexOfBiggestContour]);
        for (int i = 0; i < fingerTips.size(); i++) {
            circle(image,fingerTips[i], 3, Scalar(0,0,255), 2);
        }
        
        fingerTipsNum = (int)fingerTips.size();
        
        //Mat fingerImage;
        //cvtColor(image, fingerImage, CV_BGR2RGB);
        
        //tempFingerImage = [self UIImageFromCVMat:fingerImage];
        
        for( int j = 0; j < 4; j++ ){
            //line( image, rect_points[j], rect_points[(j+1)%4], Scalar(0,255,255), 2, 8 );
        }
        [self constructCommandWith:image];
        Mat finalImage;
        cvtColor(image, finalImage, CV_BGR2RGB);
        
        
        //tempFinalImage = [self UIImageFromCVMat:finalImage];
        
        
        
    /*
        fingerTipsData.push_back(int(uPoints.size()));
        
        if (fingerTipsData.size() > 10) {
            fingerTipsData.erase(fingerTipsData.begin());
        }
        //NSLog(@"data size:%d",fingerTipsData.size());
*/
        
    } else {
        fingerTipsNum = 0;
        
        /*
        fingerTipsData.push_back(0);
        
       
        
        if (fingerTipsData.size() > 10) {
            fingerTipsData.erase(fingerTipsData.begin());
        }
       */
       
    }

}

- (void)constructCommandWith:(cv::Mat &)image
{
    if (fingerType == 2 ) {
        if (fingerTipsNum == 2) {
            line(image, fingerTips[0], fingerTips[1], Scalar(0,0,255));
            twoFingerDistance = sqrt((fingerTips[0].x - fingerTips[1].x)*(fingerTips[0].x - fingerTips[1].x) + (fingerTips[0].y - fingerTips[1].y)*(fingerTips[0].y - fingerTips[1].y))/rotatedRect.size.width;
            NSLog(@"distance:%f",twoFingerDistance);
            
        }
    }
}

- (void)handDetection2WithImage:(cv::Mat &)image
{
    int rows = image.rows;
    int cols = image.cols;
    // Step 1: 通过HLS颜色获取可能是手的区域并处理
    
    Mat HLSimage;
    Mat blurImage;
    // Step 1.1:模糊处理
    medianBlur(image, blurImage, 5);
    // Step 1.2:转换为HLS颜色
    cvtColor(blurImage, HLSimage, CV_BGR2HLS);
    // Step 1.3:根据皮肤颜色范围获取皮肤区域：
    int imageRow = HLSimage.rows;
    int imageCol = HLSimage.cols;
    for (int row = 0; row < imageRow; row++) {
        for (int col = 0; col < imageCol; col++) {
            uchar H = HLSimage.at<cv::Vec3b>(row,col)[0];
            uchar L = HLSimage.at<cv::Vec3b>(row,col)[1];
            uchar S = HLSimage.at<cv::Vec3b>(row,col)[2];
            double LS_ratio = ((double) L) / ((double) S);
            bool skin_pixel = (S >= 50) && (LS_ratio > 0.5) && (LS_ratio < 3.0) && ((H <= 14) || (H >= 165));
            if (!skin_pixel) {
                HLSimage.at<cv::Vec3b>(row,col)[0] = 0;
                HLSimage.at<cv::Vec3b>(row,col)[1] = 0;
                HLSimage.at<cv::Vec3b>(row,col)[2] = 0;
                
            }
        }
    }
    
    
    
    // Step 1.4: 转换为RGB
    Mat skinImage;
    cvtColor(HLSimage, skinImage, CV_HLS2RGB);
    
    // Step 1.5: 对皮肤区域进行二值及平滑处理
    Mat gray;
    cvtColor(skinImage, gray, CV_RGB2GRAY);
    Mat binary;
    threshold(gray, binary, 50, 255, THRESH_BINARY);
    
    
    
    //[self handDetection2WithImage:image];
    // Step 3:转换为YUV
    Mat yuvImage;
    cvtColor(image, yuvImage, CV_BGR2YUV);
    // Step 4:取出U分量
    vector<Mat> yuvImages;
    split(yuvImage, yuvImages);
    
    Mat& uImage = yuvImages[1];
    
    // Step 5: 形态学梯度操作
    Mat structure_element(5, 5, CV_8U, Scalar(1));
    morphologyEx(uImage, uImage, MORPH_GRADIENT, structure_element);
    threshold(uImage, uImage, 10, 255, THRESH_BINARY_INV|THRESH_OTSU);
    
    //Mat dilateB(rows,cols,CV_8U,Scalar(1));
    //Mat structuring_element(10, 10, CV_8U, Scalar(1) );
    //dilate(binary, dilateB, structuring_element);
    
    /*
    Mat edge(rows,cols,CV_8U,Scalar(1));
    
    
    for (int row = 0; row < imageRow; row++) {
        for (int col = 0; col < imageCol; col++) {
            edge.at<uchar>(row,col) = uImage.at<uchar>(row,col) & binary.at<uchar>(row,col);
        }
    }
    
    */
    
    Mat five_by_five_element(5, 5, CV_8U, Scalar(1));
    //morphologyEx( binary, binary, MORPH_OPEN,five_by_five_element );
    morphologyEx( binary, binary, MORPH_CLOSE,five_by_five_element );
    dilate(binary, binary, five_by_five_element);
    medianBlur(binary, binary, 3);
    
    for (int row = 0; row < imageRow; row++) {
        for (int col = 0; col < imageCol; col++) {
            binary.at<uchar>(row,col) = uImage.at<uchar>(row,col) & binary.at<uchar>(row,col);
        }
    }
    
    // Step 2: 获取可能是手的轮廓区域并进行处理获得多边形角点
    // Step 2.1：寻找轮廓
    vector<vector<cv::Point>> contours;
    vector<Vec4i> hierarchy;
    findContours( binary, contours, hierarchy,
                 CV_RETR_TREE, CV_CHAIN_APPROX_NONE );
    
    // Step 2.2：找到最大轮廓
    int indexOfBiggestContour = -1;
    int sizeOfBiggestContour = 0;
    for (int i = 0; i < contours.size(); i++){
        if(contours[i].size() > sizeOfBiggestContour){
            sizeOfBiggestContour = int(contours[i].size());
            indexOfBiggestContour = i;
        }
    }
    
    // Step 2.3：检查轮廓，获取手的信息
    if(indexOfBiggestContour > -1 && sizeOfBiggestContour > 600)
    {
        // 获取轮廓多边形
        approxPolyDP(Mat(contours[indexOfBiggestContour]), contours[indexOfBiggestContour], 1.5, true);
        // 获取轮廓矩形框
        cv::Rect rect = boundingRect(Mat(contours[indexOfBiggestContour]));
        cv::RotatedRect rotatedRect = fitEllipse(Mat(contours[indexOfBiggestContour]));
        
        angle = rotatedRect.angle;
        power = rotatedRect.size.height/rotatedRect.size.width;
        //NSLog(@"power:%f angle:%f\n",power,angle);
        
        ellipse(image, rotatedRect, Scalar(0,0,200));
        Point2f rect_points[4];
        rotatedRect.points( rect_points );
        for( int j = 0; j < 4; j++ )
            line( image, rect_points[j], rect_points[(j+1)%4], Scalar(0,0,200), 1, 8 );
        
        // 在image中画出矩形框
        //rectangle(image, rect.tl(), rect.br(), Scalar(0,0,200));
        
        // 在image中画出轮廓
        drawContours(image, contours, indexOfBiggestContour, Scalar(100,100,255));
    
        
        // 检测手指
        
        vector<cv::Point> uPoints;
        uPoints = detectUcurveWithContour(contours[indexOfBiggestContour]);
        for (int i = 0; i < uPoints.size(); i++) {
            circle(image,uPoints[i], 3, Scalar(100,255,255), 2);
        }
        
        vector<vector<cv::Point>> hullP(contours.size());
        vector<vector<int>> hullI(contours.size());
        vector<vector<Vec4i>> defects(contours.size());
        convexHull(Mat(contours[indexOfBiggestContour]), hullP[indexOfBiggestContour]);
        approxPolyDP(Mat(hullP[indexOfBiggestContour]), hullP[indexOfBiggestContour], 11, true );
        convexHull(contours[indexOfBiggestContour], hullI[indexOfBiggestContour]);
        convexityDefects(contours[indexOfBiggestContour], hullI[indexOfBiggestContour], defects[indexOfBiggestContour]);
        
        
        // eliminate bad defects
        float toleranceMin =  rect.height/4;
        float toleranceMax =  rect.height*0.8;
        float angleTolMax=90;
        float angleTolMin = 5;
        vector<Vec4i> newDefects;
        int startidx, endidx, faridx;
        
        vector<cv::Point> fingerTips;
        float tipTolerance = rect.width/10;
        
        for(int i = 0;i < defects[indexOfBiggestContour].size();i++)
        {
            Vec4i v = defects[indexOfBiggestContour][i];
            startidx=v[0];
            cv::Point ptStart(contours[indexOfBiggestContour][startidx] );
            endidx=v[1];
            cv::Point ptEnd(contours[indexOfBiggestContour][endidx]);
            faridx=v[2];
            cv::Point ptFar(contours[indexOfBiggestContour][faridx]);
            float angleValue = getAngle(ptStart, ptFar, ptEnd);
            float distance1 = distanceP2P(ptStart, ptFar);
            float distance2 = distanceP2P(ptEnd, ptFar);
            if(distance1 > toleranceMin && distance2 > toleranceMin && distance1 < toleranceMax && distance2 < toleranceMax &&  angleValue< angleTolMax && angleValue > angleTolMin && startidx > 5){
                
                if (fingerTips.size() == 0) {
                    fingerTips.push_back(ptStart);
                    fingerTips.push_back(ptEnd);
                    
                    //printf("index :%d\n",startidx);
                    
                    
                } else {
                    float newStartDistance = 500;
                    float newEndDistance = 500;
                    for(int i = 0;i < fingerTips.size();i++)
                    {
                        float startDistance = distanceP2P(ptStart, fingerTips[i]);
                        float endDistance = distanceP2P(ptEnd, fingerTips[i]);
                        newStartDistance = startDistance <newStartDistance ? startDistance:newStartDistance;
                        newEndDistance = endDistance < newEndDistance? endDistance:newEndDistance;
                    }
                    
                    //printf("distance:%f %f\n",newStartDistance,newEndDistance);
                    
                    if (newStartDistance > tipTolerance) {
                        fingerTips.push_back(ptStart);
                        //printf("index :%d\n",startidx);
                        
                        
                    }
                    if (newEndDistance > tipTolerance) {
                        fingerTips.push_back(ptEnd);
                        
                    }
                }
                
                
                
                newDefects.push_back(v);
                
            }
            
        }
        
        //nrOfDefects = newDefects.size();
        defects[indexOfBiggestContour].swap(newDefects);
        
        
        //printf("finger tips:%d\n",fingerTips.size());
        
        fingerTipsNum = fingerTips.size();
        //printf("fingers:%d\n",numberOfFingers);
        for (int i = 0; i < fingerTips.size(); i++) {
            //circle(image,fingerTips[i], 3, Scalar(100,255,100), 2);
        }
        
        for(int i = 0;i < defects[indexOfBiggestContour].size();i++)
        {
            Vec4i point = defects[indexOfBiggestContour][i];
            
            //circle(image, contours[indexOfBiggestContour][point[2]], 3, Scalar(0,255,100),2);
            
            
        }

    }
    
    
    
    
}

vector<cv::Point> detectUcurveWithContour(vector<cv::Point> contour)
{
    cv::Rect rect = boundingRect(contour);
    float toleranceMin = rect.height/5;
    //float toleranceMax =  rect.height*0.8;
    

    // Step 0: 平滑一下曲线
    for (int i = 1; i < contour.size() - 1; i++) {
        contour[i].x = (contour[i-1].x + contour[i].x + contour[i+1].x)/3;
        contour[i].y = (contour[i-1].y + contour[i].y + contour[i+1].y)/3;
    }
   
    vector<cv::Point> uPoints;
    
    // Step 1：计算每个点与相邻点形成的夹角
    vector<float> angles;
    
    
    int size = int(contour.size());
    
    int step = 5;
    
    for (int i = 0; i < size; i++) {
        int index1 = i - step;
        int index2 = i;
        int index3 = i + step;
        
        index1 = index1 < 0 ? index1 + size : index1;
        index3 = index3 >= size ? index3 - size : index3;
        
        angles.push_back(getAngleWithDirection(contour[index1], contour[index2], contour[index3]));
    }
    
    // Step 2: 计算先变小后变大的点，并记录
    float thresholdAngleMax = 50;
    //float thresholdAngleMin = 0;
    
    for (int i = 0; i < size; i++) {
        int index1 = i - 1;
        int index2 = i;
        int index3 = i+1;
        int index4 = i+step;
        int index5 = i-step;
        index1 = index1 < 0 ? index1+size:index1;
        index3 = index3 >= size? index3-size:index3;
        index5 = index5 < 0 ? index5+size:index5;
        index4 = index4 >= size? index4-size:index4;
        if (angles[index2] < angles[index1] && angles[index2] < angles[index3] && angles[i] > 0 && angles[i] < thresholdAngleMax) {
            
            float dis1 = distanceP2P(contour[i], contour[index4]);
            float dis2 = distanceP2P(contour[index5], contour[i]);
            //NSLog(@"dis:%f,tor:%f",dis,toleranceMin);
            if (dis1 > toleranceMin || dis2 > toleranceMin) {
                uPoints.push_back(contour[i]);
                //NSLog(@"angel:%f",angles[i]);

            }
            
        }
    }
     
    return uPoints;

}

vector<cv::Point> fingerTipsDetectionWithContour(vector<cv::Point> contour,Mat &image)
{
    for (int i = 1; i < contour.size() - 1; i++) {
        contour[i].x = (contour[i-1].x + contour[i].x + contour[i+1].x)/3;
        contour[i].y = (contour[i-1].y + contour[i].y + contour[i+1].y)/3;
    }
    
    vector<cv::Point> fingerTips;
    
    vector<cv::Point> hullP;
    vector<int> hullI;
    vector<Vec4i> defects;
    // Step 1:获取轮廓的多边形区域并平滑
    convexHull(Mat(contour), hullP);
    approxPolyDP(Mat(hullP), hullP, 15, true );
    
    for (int i = 0; i < hullP.size(); i++) {
        for (int j = 0; j< contour.size(); j++) {
            float distance = distanceP2P(hullP[i], contour[j]);
            
        }
    }
    
     for (int i = 0; i < hullP.size(); i++) {
         circle(image,hullP[i],   5, Scalar(100,255,100), 4 );
     }
    
    
    return fingerTips;
}

#pragma mark - Edge Robot Detection Test

// 使用Edge Robot来从任意一个点出发，检测所在闭区域的轮廓
// 假设：Edge Robot所在的区域为一个范围的闭区域，比如手，保证能够获得一个闭合的曲线
vector<cv::Point> edgeRobotDetection(Mat &image,cv::Point point)
{
    // 初始化
    vector<cv::Point> edges;
    
    cv::Point location;
    cv::Point direction;

    location = point;
    
    Mat HLS;
    cvtColor(image, HLS, CV_BGR2HLS);
    
    // Step 1: 探索周边区域，寻找到一个边界点
    
    // Approach :向某个特定的方向搜搜，直到碰到梯度下降非常大的点。
    
    // 比如朝右边检查
    // 为了避免那种灰度很接近，但实际颜色相差很多的情况，我们使用HLS来进行多维度的梯度检测
    // OK,先分析一下人类是如何在假想的二维图像世界中行走的。
    
    
    float multiGradient = 0;
    float gradientThreshold = 5;
    
    
    
    
    
    return edges;
}

float distanceP2P(cv::Point a, cv::Point b){
    float d= sqrt(fabs( pow(a.x-b.x,2) + pow(a.y-b.y,2) )) ;
    return d;
}

float getAngleWithDirection(cv::Point s, cv::Point f, cv::Point e){
    float l1 = distanceP2P(f,s);
    float l2 = distanceP2P(f,e);
    float dot=(s.x-f.x)*(e.x-f.x) + (s.y-f.y)*(e.y-f.y);
    float angle = acos(dot/(l1*l2));
    angle=angle*180/M_PI;
    
    // 计算从s到f到e的旋转方向
    cv::Point f2s = cv::Point(s.x - f.x,s.y-f.y);
    cv::Point f2e = cv::Point(e.x - f.x,e.y - f.y);
    float direction = f2s.x*f2e.y - f2e.x*f2s.y;
    if (direction > 0 ) {
        return angle;
    } else {
        return -angle;
    }
    
}

float getAngle(cv::Point s, cv::Point f, cv::Point e){
    float l1 = distanceP2P(f,s);
    float l2 = distanceP2P(f,e);
    float dot=(s.x-f.x)*(e.x-f.x) + (s.y-f.y)*(e.y-f.y);
    float angle = acos(dot/(l1*l2));
    angle=angle*180/M_PI;
    
    return angle;
}


@end
