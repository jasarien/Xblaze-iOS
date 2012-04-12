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
		
		_ownUsername = [[[xfSession loginIdentity] userName] copy];
		
		[self loadChatTranscript];
	}
	
	return self;
}

- (void)dealloc
{
	[self saveChatTranscript];
	[_ownUsername release], _ownUsername = nil;
	[self.chat setDelegate:nil];
	self.chat = nil;
	self.chatMessages = nil;
	[super dealloc];
}

- (void)addMessage:(NSDictionary *)messageDict
{
	[self.chatMessages addObject:messageDict];
	[[NSNotificationCenter defaultCenter] postNotificationName:kMessageReceivedNotification object:self];
}

- (void)xfireSession:(XfireSession *)session chat:(XfireChat *)aChat didReceiveMessage:(NSString *)msg
{	
	Xblaze_iPhoneAppDelegate *app = (Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate];
	[app playChatMessageSound];
	
	self.typing = NO;
	unreadCount++;
	NSDate *date = [NSDate date];
	
	NSDictionary *chatDict = [NSDictionary dictionaryWithObjectsAndKeys:[[aChat remoteFriend] userName], kChatIdentityKey, msg, kChatMessageKey, date, kChatDateKey, nil];
	[self.chatMessages addObject:chatDict];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kMessageReceivedNotification object:self];
}

- (void)sendMessage:(NSString *)message
{
	XfireFriend *loginIdentity = [xfSession loginIdentity];
	NSDate *date = [NSDate date];
	
	NSDictionary *chatDict = [NSDictionary dictionaryWithObjectsAndKeys:[loginIdentity userName], kChatIdentityKey, message, kChatMessageKey, date, kChatDateKey, nil];
	[self.chatMessages addObject:chatDict];
	
	[self.chat sendMessage:message];
}

- (void)xfireSession:(XfireSession *)session chat:(XfireChat *)aChat didReceiveTypingNotification:(BOOL)isTyping
{
	self.typing = isTyping;
	NSDictionary *typingDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:isTyping], @"typing", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kTypingNotificationRecieved object:aChat userInfo:typingDict];
}

- (void)saveChatTranscript
{
	NSString *appDocsPath = nil;
	NSString *docsPath = nil;
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0)
	{
		appDocsPath = [paths objectAtIndex:0];
	}
	
	if (![appDocsPath length])
	{
		DebugLog(@"Unable to get path for documents directory...");
		return;
	}
	
	docsPath = [appDocsPath stringByAppendingPathComponent:@"ChatTranscripts"];
	docsPath = [docsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", _ownUsername]];
	if (![[NSFileManager defaultManager] fileExistsAtPath:docsPath])
	{ // create docs directory
		NSError *error = nil;
		[[NSFileManager defaultManager] createDirectoryAtPath:docsPath
								  withIntermediateDirectories:YES
												   attributes:nil
														error:&error];
		if (error)
		{
			DebugLog(@"Unable to create docs directory: %@", [error localizedDescription]);
			return;
		}
	}
	
	NSString *filename = [docsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", [[[self chat] remoteFriend] userName]]];
	
	if ([self.chatMessages count] <= 10)
	{
		[self.chatMessages writeToFile:filename atomically:YES];
	}
	else
	{
		NSArray *transcript = [self.chatMessages subarrayWithRange:NSMakeRange([self.chatMessages count] - 10, 10)];
		[transcript writeToFile:filename atomically:YES];
	}
}

- (void)loadChatTranscript
{
	NSString *appDocsPath = nil;
	NSString *docsPath = nil;
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0)
	{
		appDocsPath = [paths objectAtIndex:0];
	}
	
	if (![appDocsPath length])
	{
		DebugLog(@"Unable to get path for documents directory...");
		return;
	}
	
	docsPath = [appDocsPath stringByAppendingPathComponent:@"ChatTranscripts"];
	docsPath = [docsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", _ownUsername]];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:docsPath])
	{ // create docs directory
		NSError *error = nil;
		[[NSFileManager defaultManager] createDirectoryAtPath:docsPath
								  withIntermediateDirectories:YES
												   attributes:nil
														error:&error];
		if (error)
		{
			DebugLog(@"Unable to create docs directory: %@", [error localizedDescription]);
			return;
		}
	}
	
	NSString *filename = [docsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", [[[self chat] remoteFriend] userName]]];
	self.chatMessages = [NSMutableArray arrayWithContentsOfFile:filename];
	if (!self.chatMessages)
	{
		self.chatMessages = [NSMutableArray array];
	}
}

- (void)clearChatHistory
{
	self.chatMessages = [NSMutableArray array];
}

@end
