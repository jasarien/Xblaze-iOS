//
//  XBDetailViewController.h
//  Xblaze-iPhone
//
//  Created by James on 16/05/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XBChatViewController;
@interface XBDetailViewController : UIViewController {

	UIPopoverController *popoverController;
	
	XBChatViewController *_chatViewController;
	
}

@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, retain) XBChatViewController *chatViewController;

@end
