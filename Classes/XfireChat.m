/*******************************************************************
	FILE:		XfireChat.m
	
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

#import "XfireChat.h"
#import "XfirePacket.h"
#import "XfireChat_Private.h"
#import "XfireSession.h"
#import "XfireSession_Private.h"
#import "XfireFriend.h"
#import "XfireConnection.h"
#import "XfirePacketAttributeValue.h"

const NSTimeInterval typingDuration = 10.0;

@implementation XfireChat

- (id)initWithRemoteFriend:(XfireFriend *)aFriend connection:(XfireConnection *)aConn
{
	self = [super init];
	if( self )
	{
		remoteFriend = [aFriend retain];
		conn = aConn;
		sendSeqNo = 1;
		_friendIsTyping = NO;
	}
	return self;
}

- (void)dealloc
{
	if ([selfTypingNotificationTimer isValid])
	{
		[selfTypingNotificationTimer invalidate];
		selfTypingNotificationTimer = nil;
	}
	
	if ([typingNotificationTimer isValid])
	{
		[typingNotificationTimer invalidate];
		typingNotificationTimer = nil;
	}
	
	remoteFriend = nil;
	_delegate = nil;
	[super dealloc];
}


- (XfireFriend *)remoteFriend
{
	return remoteFriend;
}

- (void)sendMessage:(NSString *)msg
{
	[selfTypingNotificationTimer invalidate];
	selfTypingNotificationTimer = nil;
	
	XfirePacket *sendPkt = [XfireMutablePacket chatInstantMessagePacketWithSID:[[self remoteFriend] sessionID]
																	   imIndex:sendSeqNo
																	   message:msg];
	sendSeqNo++;
	[conn sendPacket:sendPkt];
}

- (void)sendTypingNotification
{
	if (!selfTypingNotificationTimer)
	{
		XfirePacket *sendPkt = [XfireMutablePacket chatTypingNotificationPacketWithSID:[[self remoteFriend] sessionID]
																			   imIndex:sendSeqNo
																				typing:1];
		sendSeqNo++;
		[conn sendPacket:sendPkt];
		
		selfTypingNotificationTimer = [NSTimer scheduledTimerWithTimeInterval:10.0
																		target:self 
																	  selector:@selector(selfTypingTimedOut:)
																	  userInfo:nil
																	   repeats:NO];
	}
}

- (XfireSession *)session
{
	return [remoteFriend session];
}

- (NSData *)sessionID
{
	return [remoteFriend sessionID];
}

- (void)setDelegate:(id)aDelegate
{
	_delegate = aDelegate;
}

- (id)delegate
{
	return _delegate;
}

- (void)closeChat
{
	[[remoteFriend session] closeChat:self];
}

- (void)receivePacket:(XfirePacket *)recvPkt
{
	XfirePacketAttributeMap *peermsg = (XfirePacketAttributeMap *)[[recvPkt attributeForKey:kXfireAttributePeerMessageKey] attributeValue];
	NSNumber *msgtypeNbr = (NSNumber *)[(XfirePacketAttributeValue *)[peermsg objectForKey:kXfireAttributeMsgTypeKey] attributeValue];
	unsigned int msgtype = [msgtypeNbr unsignedIntValue];
	
	switch( msgtype )
	{
		case 0: // chat message
		{
			// we use the receive sequence number only to acknowledge the message
			// otherwise we ignore it
			NSString *msgText = [(XfirePacketAttributeValue *)[peermsg objectForKey:kXfireAttributeIMKey] attributeValue];
			unsigned int recvNo = [(NSNumber *)[(XfirePacketAttributeValue *)[peermsg objectForKey:kXfireAttributeIMIndexKey] attributeValue] unsignedIntValue];
			[[self delegate] xfireSession:[remoteFriend session] chat:self didReceiveMessage:msgText];
			
			XfirePacket *sendPkt = (XfirePacket *)[XfireMutablePacket chatAcknowledgementPacketWithSID:(NSData *)[[recvPkt attributeForKey:kXfireAttributeSessionIDKey] attributeValue]
																							   imIndex:recvNo];
			[conn sendPacket:sendPkt];
			
			if ([typingNotificationTimer isValid])
			{
				[typingNotificationTimer invalidate];
				typingNotificationTimer = nil;
			}
		}
			break;
			
		case 1: // acknowledgement
			break;
			
		case 2: // client info message
		{
			NSString *salt = [(XfirePacketAttributeValue *)[peermsg objectForKey:@"salt"] attributeValue];
			
			if (!salt)
				return;
			
			XfirePacket *response = (XfirePacket *)[XfireMutablePacket chatPeerToPeerInfoResponseWithSalt:salt sid:[remoteFriend sessionID]];
			if (response)
			{
				[conn sendPacket:response];
			}
		}
			break;
		case 3: // typing notification
		{
			_friendIsTyping = YES;
			
			if ([typingNotificationTimer isValid])
			{
				[typingNotificationTimer invalidate];
				typingNotificationTimer = nil;
			}
			
			typingNotificationTimer = [[NSTimer scheduledTimerWithTimeInterval:typingDuration target:self selector:@selector(friendStoppedTyping:) userInfo:nil repeats:NO] retain];
			[[self delegate] xfireSession:[remoteFriend session] chat:self didReceiveTypingNotification:_friendIsTyping];
		}
			break;
	}
}

- (void)friendStoppedTyping:(NSTimer *)timer
{
	[typingNotificationTimer invalidate];
	typingNotificationTimer = nil;
	_friendIsTyping = NO;
	if ([[self delegate] respondsToSelector:@selector(xfireSession:chat:didReceiveTypingNotification:)])
		 [[self delegate] xfireSession:[remoteFriend session] chat:self didReceiveTypingNotification:_friendIsTyping];	
}

- (void)selfTypingTimedOut:(NSTimer *)timer
{
	[selfTypingNotificationTimer invalidate];
	selfTypingNotificationTimer = nil;
}

@end
