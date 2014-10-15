//
//  AloImageProcessing.m
//  AloImageProcessing
//
//  Created by 기대 여 on 10. 8. 17..
//  Copyright 2010 Gidae Yeo. All rights reserved.
//

#import "AloImageProcessing.h"

typedef enum {
    ALPHA = 0,
    BLUE = 1,
    GREEN = 2,
    RED = 3
} PIXELS;


@interface AloImageProcessing (Interanl) 

-(void)reset;

@end


@implementation AloImageProcessing

-(id)initWithImage:(UIImage*)anImage {
	
	if( (self = [super init] ) ) {
		[self setImage:anImage];
	}
	
	return self;
}

-(void)dealloc {
	
	if( context ) {
		CGContextRelease(context);
	}
	if( pixels ) {
		free(pixels);
	}
	
	[super dealloc];
}

-(id)setImage:(UIImage*)anImage {
	[self reset];
	if( anImage == nil ) {
		return nil;
	}
	
	CGSize size = anImage.size;
    width = size.width;
    height = size.height;
	
    // the pixels will be painted to this array
    pixels = (uint32_t *) malloc(width * height * sizeof(uint32_t));
	
    // clear the pixels so any transparency is preserved
    memset(pixels, 0, width * height * sizeof(uint32_t));
	
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
    // create a context with RGBA pixels
    context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(uint32_t), colorSpace, 
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
	
    // paint the bitmap to our context which will fill in the pixels array
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), anImage.CGImage);
	
	
	CGColorSpaceRelease( colorSpace ); 
	
	return self;
}

-(UIImage*)image {
	if( context == nil ) {
		return nil;
	}
	
	CGImageRef image = CGBitmapContextCreateImage(context);

	// make a new UIImage to return
    UIImage *resultUIImage = [UIImage imageWithCGImage:image];
	
    // we're done with image now too
    CGImageRelease(image);
	
    return resultUIImage;	
}


#pragma mark -
#pragma mark Image Processing
-(id)greyscale {
	for(int y = 0; y < height; y++) {
        for(int x = 0; x < width; x++) {
            uint8_t *rgbaPixel = (uint8_t *) &pixels[y * width + x];
			
            // convert to grayscale using recommended method: http://en.wikipedia.org/wiki/Grayscale#Converting_color_to_grayscale
            uint32_t gray = 0.3 * rgbaPixel[RED] + 0.59 * rgbaPixel[GREEN] + 0.11 * rgbaPixel[BLUE];
			
            // set the pixels to gray
            rgbaPixel[RED] = gray;
            rgbaPixel[GREEN] = gray;
            rgbaPixel[BLUE] = gray;
        }
    }
	
	return self;
}

#pragma mark -
#pragma mark internal
-(void)reset {
	if( pixels ) {
		free(pixels);
		pixels = nil;
	}
	
	if( context ) {
		CGContextRelease(context);
		context = nil;
	}
}
@end
