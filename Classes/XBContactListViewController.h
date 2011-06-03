//
//  XBContactListViewController.h
//  Xblaze-iPhone
//
//  Created by James Addyman on 18/11/2009.
//  Copyright 2009 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XfireSession.h"
#import "XfireSession_Private.h"
#import "XBInputSheet.h"

extern NSString *kContactListControllerDidAppear;

@class XBChatController;
@class XBTextFieldPopoverViewController;
@class Xblaze_iPhoneAppDelegate;

@protocol XBContactListDelegate <NSObject>

- (void)updateChatViewControllerWithChatController:(XBChatController *)chatController;
- (XBChatController *)activeChatController;

@end


@interface XBContactListViewController : UITableViewController <UIActionSheetDelegate, XBInputSheetDelegate> {
	
	Xblaze_iPhoneAppDelegate *_appDelegate;
	
	UISearchBar *searchBar;
	
	XfireSession *xfSession;
		
	XBInputSheet *nicknameSheet;
	XBInputSheet *statusSheet;
	
	UIActionSheet *anActionSheet;
	
	UIBarButtonItem *statusNicknameButton;
	
	NSArray *_searchResults;
	
	id <XBContactListDelegate> _delegate;
}

@property (nonatomic, assign) IBOutlet id <XBContactListDelegate> delegate;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;

@property (nonatomic, assign) XfireSession *xfSession;

- (void)pushViewControllerWithAnimation:(UIViewController *)viewController;

- (NSString *)statusStringForFriend:(XfireFriend *)friend;
- (UIButton *)unreadButtonWithLabel:(int)count;

- (void)xfireFriendDidChange:(NSNotification *)note;
- (void)messageReceived:(NSNotification *)note;
- (void)resetUnreadCount:(NSNotification *)note;
- (void)updateCellForTypingNote:(NSNotification *)note;
- (void)friendGroupDidChange:(NSNotification *)note;
- (void)friendGroupWasAdded:(NSNotification *)note;
- (void)friendGroupWillBeRemoved:(NSNotification *)note;

- (void)chooseNicknameOrStatus:(id)sender;
- (void)addFriend:(id)sender;
- (void)changeStatus;
- (void)changeNickname;
- (void)showInvites;

- (void)chatDidBegin:(NSNotification *)note;
- (void)chatDidEnd:(NSNotification *)note;

@end
