//
//  BoardManImageProc.m
//  BoardMan
//
//  Created by 유진호 on 11. 1. 16..
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BoardManImageProc.h"

#ifdef __OBJC__
	#import <Foundation/Foundation.h>
	#import <UIKit/UIKit.h>
	#import <opencv/cv.h>
	#import <opencv/cxcore.h>

#endif



@implementation BoardManImageProc



#pragma mark -
#pragma mark OpenCV Support Methods

// NOTE you SHOULD cvReleaseImage() for the return value when end of the code.
- (IplImage *)CreateIplImageFromUIImage:(UIImage *)image {
	CGImageRef imageRef = image.CGImage;
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	IplImage *iplimage = cvCreateImage(cvSize(image.size.width, image.size.height), IPL_DEPTH_8U, 4);
	CGContextRef contextRef = CGBitmapContextCreate(iplimage->imageData, iplimage->width, iplimage->height,
													iplimage->depth, iplimage->widthStep,
													colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault);
	CGContextDrawImage(contextRef, CGRectMake(0, 0, image.size.width, image.size.height), imageRef);
	CGContextRelease(contextRef);
	CGColorSpaceRelease(colorSpace);
	
	IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
	cvCvtColor(iplimage, ret, CV_RGBA2BGR);
	cvReleaseImage(&iplimage);
	
	return ret;
}

#pragma mark -
#pragma mark OpenCV Support Methods
// NOTE You should convert color mode as RGB before passing to this function
- (UIImage *)UIImageFromIplImage:(IplImage *)image {
	NSLog(@"IplImage (%d, %d) %d bits by %d channels, %d bytes/row %s", image->width, image->height, image->depth, image->nChannels, image->widthStep, image->channelSeq);
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	NSData *data = [NSData dataWithBytes:image->imageData length:image->imageSize];
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
	CGImageRef imageRef = CGImageCreate(image->width, image->height,
										image->depth, image->depth * image->nChannels, image->widthStep,
										colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
										provider, NULL, false, kCGRenderingIntentDefault);
	UIImage *ret = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);
	return ret;
}

-(void) invertImage: (UIImage*) inputImg: (UIImage*) outputImg
{
	
	IplImage* pSrc = [self CreateIplImageFromUIImage:inputImg ];

	IplImage* pTrg = cvCloneImage(pSrc);
	
	cvSet( pTrg, cvScalar( 255.0, 255.0, 255.0, 255.0 ), NULL );
	
	cvSub(pTrg, pSrc, pTrg, NULL );
	
	outputImg = [self UIImageFromIplImage:pTrg ];	
	
}

@end
