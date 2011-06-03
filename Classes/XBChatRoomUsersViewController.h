//
//  XBChatRoomUsersViewController.h
//  Xblaze-iPhone
//
//  Created by James on 29/08/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XfireChatRoom;

@interface XBChatRoomUsersViewController : UITableViewController <UIActionSheetDelegate> {
	
	XfireChatRoom *_chatRoom;
	
	NSMutableArray *_users;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil chatRoom:(XfireChatRoom *)chatRoom;

@end
