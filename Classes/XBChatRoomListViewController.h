//
//  XBChatRoomListViewController.h
//  Xblaze-iPhone
//
//  Created by James on 16/08/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XBPasswordInputSheet.h"

@class XfireSession, XfireChatRoom, SoundEffect;

@interface XBChatRoomListViewController : UITableViewController <XBInputSheetDelegate> {

	NSMutableArray *_chatRooms;
	NSMutableArray *_pendingPasswordedChatRoomInvites;
	
	XfireSession *_session;
	
	SoundEffect *_soundEffect;
	
	UITextField *_chatNameTextField; // weak reference, check for nil before using
}

@property (nonatomic, readonly) NSMutableArray *chatRooms;
@property (nonatomic, assign) XfireSession *session;

- (void)getPasswordAndJoinChatRoom:(XfireChatRoom *)chatRoom;

@end
