//
//  XBSettingsViewController.h
//  Xblaze-iPhone
//
//  Created by James on 16/01/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IFGenericTableViewController.h"
#import "XfireSession.h"
#import <MessageUI/MessageUI.h>

@interface XBSettingsViewController : IFGenericTableViewController <MFMailComposeViewControllerDelegate> {

	XfireSession *xfSession;
	
}

@end
