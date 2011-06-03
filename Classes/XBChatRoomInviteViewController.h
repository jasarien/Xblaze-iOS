//
//  XBChatRoomInviteViewController.h
//  Xblaze-iPhone
//
//  Created by James on 29/08/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XfireSession, XfireChatRoom;

@interface XBChatRoomInviteViewController : UITableViewController {
	
	NSMutableArray *_friends;
	
	NSMutableArray *_selectedFriends;
	
	XfireChatRoom *_chatRoom;
	XfireSession *_session;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil chatRoom:(XfireChatRoom *)chatRoom;

@end
