//
//  XBClanListViewController.h
//  Xblaze-iPhone
//
//  Created by James on 25/01/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XfireSession.h"
#import "XfireSession_Private.h"

@interface XBClanListViewController : UITableViewController {

	XfireSession *_xfSession;
	
	int clanID;
	
	UINavigationController *navController;
}

@property (nonatomic) int clanID;
@property (nonatomic, assign) UINavigationController *navController;

- (UIButton *)unreadButtonWithLabel:(int)count;
- (NSString *)statusStringForFriend:(XfireFriend *)friend;
- (NSIndexPath *)indexPathForFriend:(XfireFriend *)friend;
- (UITableViewCell *)cellForFriend:(XfireFriend *)friend;

- (void)friendGroupDidChange:(NSNotification *)note;
- (void)xfireFriendDidChange:(NSNotification *)note;
- (void)messageReceived:(NSNotification *)note;
- (void)resetUnreadCount:(NSNotification *)note;
- (void)updateCellForTypingNote:(NSNotification *)note;

@end
