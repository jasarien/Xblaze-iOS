//
//  XBChatViewController.h
//  Xblaze-iPhone
//
//  Created by James on 24/11/2009.
//  Copyright 2009 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XBFriendSummaryViewController.h"
#import "XBChatController.h"
#import "XfireSession.h"
#import "XBChatMessageCell.h"

@interface XBChatViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, XBFriendSummaryViewDelegate, UIActionSheetDelegate, XBChatMessageCellDelegate> {
	
	IBOutlet UIToolbar *toolbar;
	IBOutlet UITableView *tableView;
	IBOutlet UITextField *messageField;
	IBOutlet UIImageView *typingIcon;
	
	UIBarButtonItem *_optionsButton;
	
	XBFriendSummaryViewController *friendSummary;
	
	XBChatController *chatController;
	
	NSMutableData *profileImageData;
	
	XfireSession *xfSession;
	
	BOOL shouldUpdateUnreadCount;
	
	NSArray *_tempLinks;
	
	UIPopoverController *popoverController;
	
	UIActionSheet *_optionsSheet;
	
	BOOL _screenShotsLoaded;
	BOOL _isTyping;
}

@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, assign) BOOL openedFromClanList;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil chatController:(XBChatController *)controller;

- (void)updateFriendSummary:(NSNotification *)note;
- (void)updateAvatar:(NSNotification *)note;

- (void)screenshotsLoaded:(NSNotification *)note;

- (void)scrollTableToBottomAnimated:(BOOL)animated;

- (IBAction)hideKeyboard;

- (void)animateBarUp:(NSNotification *)note;
- (void)animateBarDown:(NSNotification *)note;

- (void)messageReceived:(NSNotification *)note;
- (void)typingNotificationReceieved:(NSNotification *)note;

- (void)setChatController:(XBChatController *)aChatController;
- (XBChatController *)chatController;

- (void)handleHidePopoverNotification:(NSNotification *)note;

- (void)options:(id)sender;
- (void)clearChatHistory;

- (void)handleWillEnterBackgroundNotification:(NSNotification *)note;
@end
