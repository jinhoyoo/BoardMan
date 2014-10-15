//
//  BoardManViewController.m
//  BoardMan
//
//  Created by 유진호 on 11. 01. 08.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//

#import "BoardManViewController.h"
#import <opencv/cv.h>


@implementation BoardManViewController
@synthesize imageView;



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


/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	
	//@Camera가 있을 때 혹은 아닐때의 행동을 정의한다. 
	if( [UIImagePickerController isSourceTypeAvailable: 
	     UIImagePickerControllerSourceTypeCamera ] )
		m_bHasCamera = true;	
	else
		m_bHasCamera = false;
	
	m_bGotImage = false;
	
    [super viewDidLoad];
}




// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
	
	return YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

-(IBAction) getImageFromCameraOrExistingPictures:(id)sender;
{
	
	//TODO: 카메라나 카메라롤에서 사진을 가져온다. 
	NSLog( @"Get image from camera of exisiting pictures.\n");
	
	if( m_bGotImage )
	{
		NSLog( @" We've got image. \n");
		return;
	}
	
	
	if( m_bHasCamera )
	{ //Camera가 있으면 Camera에서 찍게 한다. 
	 
		UIImagePickerController* picker = 
			[ [UIImagePickerController alloc] init ];
		
		picker.delegate = self;
		picker.sourceType = 
			UIImagePickerControllerSourceTypeCamera;
		
		[self presentModalViewController:picker animated:YES]; 
		[picker release];
	}
	else
	{ //Camera가 없으면 CameraRoll에서 선택하게 한다. 
		UIImagePickerController* picker = 
		[ [UIImagePickerController alloc]  init ];
		
		picker.delegate = self;
		picker.sourceType = 
			UIImagePickerControllerSourceTypePhotoLibrary;
		[self presentModalViewController:picker animated:YES]; 
		[picker release];
		
	}
	
}


- (void)dealloc {
	[imageView release];
    [super dealloc];
	
}


#pragma mark mark - 
-(void) imagePickerController:(UIImagePickerController*) picker
		didFinishPickingImage:(UIImage*)image
		editingInfo:(NSDictionary* )editingInfo
{
	[imageView setContentMode: UIViewContentModeScaleAspectFit ];
	
	
	//m_pBoard = [ [BoardManImageProc alloc] init];
	
	
	//======================================================
	UIImage* imageResult = [ [UIImage alloc]  init ];
	
	IplImage* pSrc = [self CreateIplImageFromUIImage:image ];
	
	IplImage* pTrg = cvCloneImage(pSrc);
	
	cvSet( pTrg, cvScalar( 255.0, 255.0, 255.0, 255.0 ), NULL );
	
	cvSub( pTrg, pSrc, pTrg, NULL );
	
	imageResult = [self UIImageFromIplImage:pTrg ];	
	
	imageView.image = imageResult;
	//======================================================
	
	[picker dismissModalViewControllerAnimated:YES];
	
	m_bGotImage = true; 
	
	[imageView release];
}

-(void) imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
	[picker dismissModalViewControllerAnimated:YES];
	
}
							  


@end
