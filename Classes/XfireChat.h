/*******************************************************************
	FILE:		XfireChat.h
	
	COPYRIGHT:
		Copyright 2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Represents a chat conversation between two users.  Needs work...
	
	HISTORY:
		2008 04 06  Changed copyright to BSD license.
		2008 01 07  Created.
*******************************************************************/

#import <Foundation/Foundation.h>

@class XfireFriend;
@class XfireSession;
@class XfireConnection;

@interface XfireChat : NSObject
{
	XfireFriend			*remoteFriend; // not retained; it and us are owned by the controlling XfireSession
	XfireConnection		*conn; // not retained
	unsigned int		sendSeqNo;
	id					_delegate;
	BOOL				_friendIsTyping;
	
	NSTimer				*typingNotificationTimer;
	NSTimer				*selfTypingNotificationTimer;
}

// This is the friend you will chat with
- (id)initWithRemoteFriend:(XfireFriend *)aFriend connection:(XfireConnection *)aConn;

// The person on the other end of this chat conversation
- (XfireFriend *)remoteFriend;

// Sending messages
- (void)sendMessage:(NSString *)message;
- (void)sendTypingNotification;
- (void)friendStoppedTyping:(NSTimer *)timer;
- (void)selfTypingTimedOut:(NSTimer *)timer;

// Session using this
- (XfireSession *)session;

- (NSData *)sessionID;

// Chat delegation
- (void)setDelegate:(id)aDelegate;
- (id)delegate;

// This will cause the chat to be autoreleased
- (void)closeChat;

@end

@interface NSObject (XfireChatDelegate)
- (void)xfireSession:(XfireSession *)session chat:(XfireChat *)aChat didReceiveMessage:(NSString *)msg;
- (void)xfireSession:(XfireSession *)session chat:(XfireChat *)aChat didReceiveTypingNotification:(BOOL)isTyping;
@end

