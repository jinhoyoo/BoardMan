//
//  AloImageProcessing.h
//  AloImageProcessing
//
//  Created by 기대 여 on 10. 8. 17..
//  Copyright 2010 Gidae Yeo. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AloImageProcessing : NSObject {
	uint32_t* pixels;
	CGContextRef context;
	
	int width;
	int height;
}

-(id)initWithImage:(UIImage*)anImage;
-(id)setImage:(UIImage*)anImage;
-(UIImage*)image;

-(id)greyscale;




@end
