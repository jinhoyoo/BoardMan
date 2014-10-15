//
//  BoardManViewController.m
//  BoardMan
//
//  Created by 유진호 on 11. 01. 08.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//

#import "BoardManViewController.h"
#import "BoardManImageProc.h"


const int kScrollView = 100;  //Tag for ScrollView

const int kCameraActionSheet = 0; //Tag for action sheet
const int kTrashActionSheet  = 1; 
const int kExportActionSheet = 2;


@implementation BoardManViewController


@synthesize activityIndicator;
@synthesize trashButton;
@synthesize exportButton;
@synthesize backgroundImageView;

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
- (UIImage *)UIImageFromIplImage:(IplImage *)image  {
	NSLog(@"IplImage (%d, %d) %d bits by %d channels, %d bytes/row %s", image->width, image->height, image->depth, image->nChannels, image->widthStep, image->channelSeq);
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	NSData *data = [NSData dataWithBytes:image->imageData length:image->imageSize];
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
	CGImageRef imageRef = CGImageCreate(image->width, image->height,
										image->depth, image->depth * image->nChannels, image->widthStep,
										colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
										provider, NULL, false, kCGRenderingIntentDefault);
	UIImage *ret = [UIImage imageWithCGImage:imageRef ];
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);
	return ret;
}


- (UIImage *)scaleAndRotateImage:(UIImage *)image {
	
	static int kMaxResolution = 1024;
	
	CGImageRef imgRef = image.CGImage; 
	CGFloat width = CGImageGetWidth(imgRef); 
	CGFloat height = CGImageGetHeight(imgRef);
	
	CGAffineTransform transform = CGAffineTransformIdentity; 
	
	CGRect bounds = CGRectMake(0, 0, width, height); 
	if (width > kMaxResolution || height > kMaxResolution) { 
		CGFloat ratio = width/height;
		
		if(ratio>1){ 
			bounds.size.width = kMaxResolution; 
			bounds.size.height = bounds.size.width / ratio;
		}else
		{ 
			bounds.size.height = kMaxResolution; 
			bounds.size.width = bounds.size.height * ratio; 
		} 
	}
	
	CGFloat scaleRatio = bounds.size.width / width; 
	
	CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef)); 
	
	CGFloat boundHeight;
	
	UIImageOrientation orient = image.imageOrientation; 
	
	switch(orient) { 
		
		case UIImageOrientationUp: 
			transform = CGAffineTransformIdentity;
			break; 
		
		case UIImageOrientationUpMirrored: 
			transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0); 
			transform = CGAffineTransformScale(transform, -1.0, 1.0); 
			break; 
		
		case UIImageOrientationDown: 
			transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height); 
			transform = CGAffineTransformRotate(transform, M_PI); 
			break; 
		
		case UIImageOrientationDownMirrored: 
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.height); 
			transform = CGAffineTransformScale(transform, 1.0, -1.0); 
			break; 
		
		case UIImageOrientationLeftMirrored: 
			boundHeight = bounds.size.height; 
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight; 
			transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width); 
			transform = CGAffineTransformScale(transform, -1.0, 1.0); 
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break; 
		
		case UIImageOrientationLeft: 
			boundHeight = bounds.size.height; 
			bounds.size.height = bounds.size.width; 
			bounds.size.width = boundHeight; 
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.width); 
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0); 
			break; 
		
		case UIImageOrientationRightMirrored: 
			boundHeight = bounds.size.height; 
			bounds.size.height = bounds.size.width; 
			bounds.size.width = boundHeight; 
			transform = CGAffineTransformMakeScale(-1.0, 1.0); 
			transform = CGAffineTransformRotate(transform, M_PI / 2.0); 
			break; 
		
		case UIImageOrientationRight: 
			boundHeight = bounds.size.height; 
			bounds.size.height = bounds.size.width; 
			bounds.size.width = boundHeight; 
			transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0); 
			transform = CGAffineTransformRotate(transform, M_PI / 2.0); 
			break; 
		
		default: 
			[NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
	}
	
	UIGraphicsBeginImageContext(bounds.size); CGContextRef context = UIGraphicsGetCurrentContext(); 
	
	if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) { 
			CGContextScaleCTM(context, -scaleRatio, scaleRatio); 
			CGContextTranslateCTM(context, -height, 0); 
	}else{ 
		CGContextScaleCTM(context, scaleRatio, -scaleRatio); 
		CGContextTranslateCTM(context, 0, -height); 
	} 
	
	CGContextConcatCTM(context, transform); 
	CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
	UIImage *returnImage = UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext();
	return returnImage; 
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
	
		
	
	//Camera가 있을 때 혹은 아닐때의 행동을 정의한다. 
	if( [UIImagePickerController isSourceTypeAvailable: 
	     UIImagePickerControllerSourceTypeCamera ] )
		m_bHasCamera = true;	
	else
		m_bHasCamera = false;
	
	m_bGotImage = false;
	
	
	//UI: disable buttons.
	[trashButton setEnabled:NO];
	[exportButton setEnabled:NO];
	[backgroundImageView setHidden:NO];

	
	
	
	[super viewDidLoad];
	
	//iAd
	[self createBannerView ];

	
}




// Override to allow orientations other than the default portrait orientation.

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	return NO;
}



- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	
	self. activityIndicator = nil;
	
	[super viewDidUnload];
	
	
		
		
}

- (void) takePhoto {
	
	NSLog( @"Get image from camera of exisiting pictures.\n");
	
	
	//Camera가 있으면 Camera에서 찍을지 아니면 있는 사진을 고를지 선택하게 한다. 
	if( m_bHasCamera )
	{   
		
		UIActionSheet * actionSheet = [  [UIActionSheet alloc] 
									   initWithTitle:@"What would you like to capture?"
									   delegate:self
									   cancelButtonTitle:@"Cancel"
									   destructiveButtonTitle:nil
									   otherButtonTitles:@"Take new photo", @"Existing photo", nil 								   
									   ];
		
		actionSheet.tag = kCameraActionSheet;
		
		[actionSheet showInView:self.view];
		[actionSheet release];
		
	}else 
	{ 
		//Camera가 없으면 CameraRoll에서 선택하게 한다. 		
		
		UIImagePickerController* picker = 
		[ [UIImagePickerController alloc] init ];
		
		
		picker.delegate = self;
		
		
		picker.sourceType = 
		UIImagePickerControllerSourceTypePhotoLibrary;
		[self presentModalViewController:picker animated:YES]; 
		
		[picker release];
	}
	
	
	
}

-(IBAction) getImageFromCameraOrExistingPictures:(id)sender;
{
	
	[self takePhoto ];	
	
}


//View를 Touch한 다음에 사진을 찍을 수 있게 함. 
-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{ 
	
	[self takePhoto ];	

}


- (void)dealloc {
	
	[activityIndicator release];
	

	
    [super dealloc];
	
}


- (void) createBannerView{
	Class cls = NSClassFromString(@"ADBannerView");
	if(cls != nil) {
		ADBannerView *adView = [[cls alloc] initWithFrame:CGRectZero];
		adView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
		adView.delegate = self;                
		
		adView.frame = CGRectMake(0, 370, 320,50 ); //위치값을 변경할 수 있음
		[self.view addSubview:adView];
	}

}



#pragma mark mark - 
#pragma mark Convenience Functions for Image Picking

-(void) imagePickerController:(UIImagePickerController*) picker
		didFinishPickingImage:(UIImage*)image
		editingInfo:(NSDictionary* )editingInfo
{
	//Picker에서 돌아가기 
	[picker dismissModalViewControllerAnimated: YES]; 
	
	
	image = [self scaleAndRotateImage:image ];
	
	
	//imageView.image = image;
	
	//Activity indicator start~
	//==================================================
	activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
	[activityIndicator setCenter:self.view.center];
	[activityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];	
	[self.view addSubview:activityIndicator];	
	[activityIndicator startAnimating];
	//==================================================
	
	[NSThread detachNewThreadSelector:@selector(theProcess: ) toTarget:self withObject:image];

		
	m_bGotImage = true; 
	

		
	
	
}


- (void)theProcess:(UIImage*) image 
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		
	
	IplImage* pSrc = [self CreateIplImageFromUIImage:image ];

	
	
	//Processing..... 
	//==================================================
	IplImage* pTrg = cvCloneImage(pSrc);
	
	
	
	NSLog(@"Start to enhance image. ( %d, %d)\n", pSrc->width, pSrc->height );
	
	
	EnhanceBoardImage(pSrc, pTrg, 15, 15, 0.70 );
	
	
	UIImage* resImage = [self UIImageFromIplImage:pTrg  ];			

	
	NSLog(@"Finish enhancing image. ( %d, %d)\n", pSrc->width, pSrc->height );

	
	//버퍼 정리 
	cvReleaseImage( &pSrc);	
	cvReleaseImage( &pTrg);
	//==================================================
	
	
	
	
	[self performSelectorOnMainThread:@selector(processDone:) withObject:resImage waitUntilDone:NO ];
	[pool release];
		
		
}

- (void)processDone : (UIImage*) image
{
	
	// stop the activityIndicator
	[activityIndicator stopAnimating]; 	


	//Core animation : Start
	//--------------------------------------------
	[UIView beginAnimations:@"View Flip" context:nil];
	[UIView setAnimationDuration:1.00];
	[UIView setAnimationTransition: UIViewAnimationTransitionCurlUp 
			forView:self.view cache:YES ];
	//--------------------------------------------

	
	
	//ScrollView에 그리기 
	//--------------------------------------------
	//--------------------------------------------


	//앞서 사용한 scroll view가 있으면 기존의 scroll view를 삭제한다. 	
	for(UIView *subview in [self.view subviews]) 
	{
		
		if( subview.tag == kScrollView )
			[subview removeFromSuperview];
	}
	

    
	UIScrollView *myScrollView
		= [ [UIScrollView alloc] initWithFrame: backgroundImageView.frame ];
	
	
	
	myScrollView.tag = kScrollView;
	
	myScrollView.delegate = self;
	
	
	myScrollView.bouncesZoom = YES;
	myScrollView.maximumZoomScale = 2.5;
	myScrollView.minimumZoomScale = 0.5;
	myScrollView.contentSize = image.size;
	myScrollView.autoresizesSubviews = YES;
	myScrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	
	
	UIImageView* imageView = [  [UIImageView alloc] initWithImage: image ];
	[myScrollView  addSubview: imageView];
		
	
	[self.view addSubview:myScrollView ];
	//------------------------
	
	//zoom초기화 
	//------------------------
	CGSize imageSize = image.size;
	
	float zoomScale 
		= float( self.view.frame.size.width ) / float( imageSize.width );
	
	myScrollView.zoomScale = zoomScale;
	//------------------------
	
	[myScrollView release];
	[imageView release];
	
	//--------------------------------------------
	//--------------------------------------------
	
	
	//Core animation : End
	//--------------------------------------------
	[UIView commitAnimations];
	//--------------------------------------------
	
	
	
	//UI: enable buttons.
	[trashButton setEnabled:YES];
	[exportButton setEnabled: YES];
	[backgroundImageView setHidden:YES];


	
}

-(void)  exportImageToSaveCameraRoll
{
	

	for(UIView *subview in [self.view subviews]) 
	{
		
		if( subview.tag == kScrollView )
		{
			UIImageView* imageView = [ [subview subviews] objectAtIndex:0 ];
			
			//저장하기 
			UIImageWriteToSavedPhotosAlbum( imageView.image, self,nil , nil);			
		}
	}
	
	UIAlertView *alert = [  [UIAlertView alloc] 
						  initWithTitle:@"Expoted image." 
						  message:@"Image is in Camera roll." 
						  delegate:self 
						  cancelButtonTitle:@"OK" 
						  otherButtonTitles:nil];
	[alert show];
	[alert release];
	
	
}


-(void)  exportImageToMail
{
	
	
	for(UIView *subview in [self.view subviews]) 
	{
		
		if( subview.tag == kScrollView )
		{
			UIImageView* imageView = [ [subview subviews] objectAtIndex:0 ];
			
			
			if ( [MFMailComposeViewController canSendMail] ) 
			{
				MFMailComposeViewController *mailComposeController 
				=[ [  [MFMailComposeViewController alloc] init ] autorelease];
				
				mailComposeController.mailComposeDelegate = self;
				
				
				//Set subject.
			    [mailComposeController setSubject:@"Meeting minutes" ];

				
				//Set mail body. 
				NSString *bodyTemplate 
					= [ NSString stringWithFormat:@"<p>Dear All, </p> <p>I share the ideas that we'd discussed. </p>" ];
				
				[mailComposeController setMessageBody:bodyTemplate isHTML:YES ];
				
				
				//Attach image file. 
				UIImage* attachedImage = imageView.image;
				
				NSData *imageData = UIImagePNGRepresentation( attachedImage );
				
				[mailComposeController addAttachmentData:imageData mimeType:@"image/png" fileName:@"MeetingMinutes.png"];
				

				//Animation
				[self presentModalViewController:mailComposeController animated:YES];
				
				
				
				
			}else 
			{
				UIAlertView *alertView = [  [UIAlertView alloc] initWithTitle:@"Notice" 
																	  message:@"Cannot send e-mail. Please check network status. " 
																	 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil ];
				[alertView show];
				
			}
			
			
			
			
		}
	}
	
	
}



- (IBAction) exportImage:(id)sender
{
	UIActionSheet * actionSheet = [  [UIActionSheet alloc] 
								   initWithTitle:@"Export image to"
								   delegate:self
								   cancelButtonTitle:@"Cancel"
								   destructiveButtonTitle:nil
								   otherButtonTitles:@"Camera Roll", @"E-mail", nil
								   ];
	
	
	actionSheet.tag = kExportActionSheet;
	
	[actionSheet showInView:self.view];
	[actionSheet release];
	
	
}


- (void) trashOutBoadImageImpl
{
	
	//Core animation : Start
	//--------------------------------------------
	[UIView beginAnimations:@"View Flip" context:nil];
	[UIView setAnimationDuration:1.00];
	[UIView setAnimationTransition: UIViewAnimationTransitionCurlDown 
						   forView:self.view cache:YES ];
	//--------------------------------------------
	
	
	
	//앞서 사용한 scroll view가 있으면 기존의 scroll view를 삭제한다. 	
	for(UIView *subview in [self.view subviews]) 
	{
		
		if( subview.tag == kScrollView )
			[subview removeFromSuperview];
	}
	
	//UI: disable buttons.
	[trashButton setEnabled:NO];
	[exportButton setEnabled: NO];
	[backgroundImageView setHidden:NO];
	
	
	//Core animation : End
	//--------------------------------------------
	[UIView commitAnimations];
	//--------------------------------------------
}

- (IBAction) trashOutBoadImage:(id)sender
{
	
	
	UIActionSheet * actionSheet = [  [UIActionSheet alloc] 
								   initWithTitle:@"Delete this image?"
								   delegate:self
								   cancelButtonTitle:@"No"
								   destructiveButtonTitle:@"Yes"
								   otherButtonTitles:nil
								   ];
	
	actionSheet.tag = kTrashActionSheet;
	
	[actionSheet showInView:self.view];
	[actionSheet release];
	
	
	
		
}





-(void) actionSheet:(UIActionSheet*)actionSheet
didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	
	switch ( actionSheet.tag ) 
	{
			
		case kCameraActionSheet:
			if ( buttonIndex != [ actionSheet cancelButtonIndex ] )
			{
				UIImagePickerController* picker = 
				[ [UIImagePickerController alloc] init ];
				
				//카메라에서 촬영 
				if ( 0 == buttonIndex )
				{
					
					picker.delegate = self;
					picker.sourceType = 
					UIImagePickerControllerSourceTypeCamera;
					picker.allowsEditing = NO;
					
					
					[self presentModalViewController:picker animated:YES]; 
					
					
				//Camera Roll에서 가져온다. 
				}else if (1 == buttonIndex) 
				{
					picker.delegate = self;
					picker.allowsEditing = NO;
					
					picker.sourceType = 
					UIImagePickerControllerSourceTypePhotoLibrary;
					[self presentModalViewController:picker animated:YES]; 
				}
				
				
				[picker release];
				
			}
			
			break;
			
		case kTrashActionSheet:
			if ( buttonIndex != [ actionSheet cancelButtonIndex ] )
			{
				UIImagePickerController* picker = 
				[ [UIImagePickerController alloc] init ];
				
				//Delete image
				if ( 0 == buttonIndex )
				{
					[self trashOutBoadImageImpl];										
				}
				
				[picker release];
				
			}
			break;

		case kExportActionSheet:
			if ( buttonIndex != [ actionSheet cancelButtonIndex ] )
			{
				UIImagePickerController* picker = 
				[ [UIImagePickerController alloc] init ];
				
				//Write image on camera roll 
				if ( 0 == buttonIndex )
				{
					[self exportImageToSaveCameraRoll ];
				}else if ( 1 == buttonIndex ) 
				{
					[self exportImageToMail ];
				}

				
				[picker release];
				
			}
			break;

			
		default:
			break;
	}
	
	
	
	
	
	
}




-(void) imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
	[picker dismissModalViewControllerAnimated:YES];
	
}
							  
-(UIView*) viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	UIImageView* imageView = [ scrollView.subviews objectAtIndex:0 ];
	return imageView;
	
}




- (IBAction) openAboutPage:(id)sender
{
	
	NSURL *url = [[NSURL alloc] initWithString: @"http://ideabywindow.wordpress.com/boardman/"];
	
	[[UIApplication sharedApplication] openURL:url];
	
	
	[url release];
}


-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
		if ( result == MFMailComposeResultCancelled) 
		{
			NSLog(@"Cancel to send mail.");
			
		}else if ( result == MFMailComposeResultSaved) 
		{
			NSLog(@"Save draft mail.");
			
			UIAlertView *alertView = [  [UIAlertView alloc] initWithTitle:@"Notice" 
																  message:@"Your e-mail is saved." 
																 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil ];
			[alertView show];

		}else if ( result == MFMailComposeResultSent) 
		{
			NSLog(@"Succeed to send e-mail.");	
			UIAlertView *alertView = [  [UIAlertView alloc] initWithTitle:@"Notice" 
																  message:@"Succeed to send e-mail. " 
																 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil ];
			[alertView show];
			
		}else if ( result == MFMailComposeResultFailed) 
		{
			NSLog(@"Fail to send e-mail.");	
			UIAlertView *alertView = [  [UIAlertView alloc] initWithTitle:@"Notice" 
																  message:@"Fail to send e-mail. " 
																 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil ];
			[alertView show];
			
		}
	
	[self becomeFirstResponder];
	[self dismissModalViewControllerAnimated:YES];
	
	
	
}



@end
