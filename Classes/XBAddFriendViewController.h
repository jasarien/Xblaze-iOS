//
//  XBAddFriendViewController.h
//  Xblaze-iPhone
//
//  Created by James on 11/12/2009.
//  Copyright 2009 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Xblaze_iPhoneAppDelegate.h"
#import "XfireFriend.h"
#import "XfireSession.h"

@interface XBAddFriendViewController : UIViewController {

	UITextField *_messageField;
	UILabel *_inviteLabel;
	UILabel *_tipLabel;
	
	XfireFriend *_friend;
	
	Xblaze_iPhoneAppDelegate *app;
}

@property (nonatomic, retain) IBOutlet UITextField *messageField;
@property (nonatomic, retain) IBOutlet UILabel *inviteLabel;
@property (nonatomic, retain) IBOutlet UILabel *tipLabel;
@property (nonatomic, retain) XfireFriend *friend;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil xfireFriend:(XfireFriend *)friend;
- (void)dismiss;

@end
