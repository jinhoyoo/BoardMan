//
//  BoardManViewController.h
//  BoardMan
//
//  Created by 유진호 on 11. 01. 08.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <iAd/iAd.h>


@interface BoardManViewController : UIViewController
<UIImagePickerControllerDelegate, UINavigationControllerDelegate, 
 UIActionSheetDelegate, UIScrollViewDelegate, 
 MFMailComposeViewControllerDelegate, ADBannerViewDelegate>
{
	
	bool m_bHasCamera; //Camera가 있는지
	bool m_bGotImage; //Image를 받아 왔는지 확인
	
	
	//UI IBOOutlet
	//-----------------------------
	IBOutlet UIActivityIndicatorView *activityIndicator;

	IBOutlet UIBarButtonItem *trashButton;
	IBOutlet UIBarButtonItem *exportButton;
	
	IBOutlet UIImageView *backgroundImageView;
	//-----------------------------
    

		
}

@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) UIBarButtonItem *trashButton;
@property (nonatomic, retain) UIBarButtonItem *exportButton;
@property (nonatomic, retain) UIImageView *backgroundImageView;

- (void) createBannerView; //iAD
- (IBAction) getImageFromCameraOrExistingPictures:(id)sender;
- (IBAction) trashOutBoadImage:(id)sender;
- (IBAction) exportImage:(id)sender;
- (IBAction) openAboutPage:(id)sender;


@end

