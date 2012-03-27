//
//  XBChatController.h
//  Xblaze-iPhone
//
//  Created by James on 23/11/2009.
//  Copyright 2009 JamSoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XfireSession.h"
#import "XfireChat.h"

#define kChatIdentityKey @"kChatIdentityKey"
#define kChatMessageKey @"kChatMessageKey"
#define kChatDateKey	@"kChatDateKey"

@interface XBChatController : NSObject {

	XfireSession *xfSession;
	XfireChat *chat;
	
	NSMutableArray *chatMessages;
	
	NSInteger unreadCount;
	
	BOOL typing;
}

@property (nonatomic, retain) XfireChat *chat;
@property (nonatomic, retain) NSMutableArray *chatMessages;
@property (nonatomic) NSInteger unreadCount;
@property (nonatomic, assign, getter=isTyping) BOOL typing;

- (id)initWithXfireSession:(XfireSession *)session chat:(XfireChat *)_chat;
- (void)sendMessage:(NSString *)message;
- (void)saveChatTranscript;
- (void)clearChatHistory;

@end
