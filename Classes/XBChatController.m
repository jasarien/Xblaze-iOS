//
//  XBChatController.m
//  Xblaze-iPhone
//
//  Created by James on 23/11/2009.
//  Copyright 2009 JamSoft. All rights reserved.
//

#import "XBChatController.h"
#import "Xblaze_iPhoneAppDelegate.h"

@implementation XBChatController
@synthesize chat, chatMessages, unreadCount, typing;

- (id)initWithXfireSession:(XfireSession *)session chat:(XfireChat *)_chat
{
	if ((self = [super init]))
	{
		unreadCount = 0;
		self.typing = NO;
		
		xfSession = session;
		self.chat = _chat;
		[self.chat setDelegate:self];
		
		self.chatMessages = [NSMutableArray array];
	}
	
	return self;
}

- (void)dealloc
{
	[self.chat setDelegate:nil];
	self.chat = nil;
	self.chatMessages = nil;
	[super dealloc];
}

- (void)xfireSession:(XfireSession *)session chat:(XfireChat *)aChat didReceiveMessage:(NSString *)msg
{	
	Xblaze_iPhoneAppDelegate *app = (Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate];
	[app playChatMessageSound];
	
	self.typing = NO;
	unreadCount++;
	NSDate *date = [NSDate date];
	
	NSDictionary *chatDict = [NSDictionary dictionaryWithObjectsAndKeys:[aChat remoteFriend], kChatIdentityKey, msg, kChatMessageKey, date, kChatDateKey, nil];
	[self.chatMessages addObject:chatDict];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kMessageReceivedNotification object:self];
}

- (void)sendMessage:(NSString *)message
{
	XfireFriend *loginIdentity = [xfSession loginIdentity];
	NSDate *date = [NSDate date];
	
	NSDictionary *chatDict = [NSDictionary dictionaryWithObjectsAndKeys:loginIdentity, kChatIdentityKey, message, kChatMessageKey, date, kChatDateKey, nil];
	[self.chatMessages addObject:chatDict];
	
	[self.chat sendMessage:message];
}

- (void)xfireSession:(XfireSession *)session chat:(XfireChat *)aChat didReceiveTypingNotification:(BOOL)isTyping
{
	self.typing = isTyping;
	NSDictionary *typingDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:isTyping], @"typing", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kTypingNotificationRecieved object:aChat userInfo:typingDict];
}

@end
