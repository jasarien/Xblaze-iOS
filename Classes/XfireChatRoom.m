//
//  XfireChatRoom.m
//  Xblaze-iPhone
//
//  Created by James on 17/08/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import "XfireChatRoom.h"
#import "XfirePacket.h"
#import "XfireSession.h"
#import "XfireSession_Private.h"
#import "XfireFriend.h"
#import "XfirePacketAttributeValue.h"

NSString *kXfireChatRoomDidReceiveMessageNotification = @"kXfireChatRoomDidReceiveMessageNotification";

@implementation XfireChatRoom

@synthesize groupChatSID = _groupChatSID;
@synthesize name = _name;
@synthesize messageOfTheDay = _messageOfTheDay;
@synthesize defaultPermissionLevel = _defaultPermissionLevel;
@synthesize timestamp = _timestamp;
@synthesize chatRoomAccess = _chatRoomAccess;

@synthesize users = _users;
@synthesize messages = _messages;

@synthesize permissions = _permissions;

@synthesize unreadCount = _unreadCount;

@synthesize session = _session;

@synthesize delegate = _delegate;

- (id)init
{
	if ((self = [super init]))
	{
		self.messages = [NSMutableArray array];
		self.permissions = [NSMutableDictionary dictionary];
	}
	
	return self;
}

- (void)dealloc
{
	self.groupChatSID = nil;
	self.name = nil;
	self.messageOfTheDay = nil;
	self.timestamp = nil;
	self.users = nil;
	self.messages = nil;
	self.permissions = nil;
	self.session = nil;
	self.delegate = nil;
	
	[super dealloc];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"XfireChatRoom: %@,\n users: %@", self.name, self.users];
}

- (XfireFriend *)userForUserID:(NSUInteger)userID
{
	for (XfireFriend *user in _users)
	{
		if ([user userID] == userID)
			return user;
	}
	
	return nil;
}

- (XFGroupChatPermissionLevel)permissionForUser:(XfireFriend *)user
{
	NSString *username = [user userName];
	return [[[self permissions] objectForKey:username] intValue];
}

- (NSString *)stringForPermissionLevel:(XFGroupChatPermissionLevel)permissionLevel
{	
	NSString *permission = nil;
	
	switch (permissionLevel)
	{
		case XFGroupChatPermissionLevelUnknown:
			permission = @"Unknown";
			break;
		case XFGroupChatPermissionLevelMuted:
			permission = @"muted";
			break;
		case XFGroupChatPermissionLevelNormal:
			permission = @"Normal";
			break;
		case XFGroupChatPermissionLevelPowerUser:
			permission = @"Power User";
			break;
		case XFGroupChatPermissionLevelModerator:
			permission = @"Moderator";
			break;
		case XFGroupChatPermissionLevelAdmin:
			permission = @"Admin";
			break;
		default:
			permission = @"Unknown";
			break;
	}
	
	return permission;
}

- (void)processChatRoomUserJoinedPacket:(XfirePacket *)pkt
{
	NSLog(@"Default permission level: %@", [self stringForPermissionLevel:self.defaultPermissionLevel]);
	
	NSNumber *userID = (NSNumber *)[[pkt attributeForKey:@"0x01"] attributeValue];
	NSData *userSID = (NSData *)[[pkt attributeForKey:@"0x11"] attributeValue];
	NSString *username = [[pkt attributeForKey:@"0x02"] attributeValue];
	NSString *nickname = [[pkt attributeForKey:@"0x0d"] attributeValue];
	XFGroupChatPermissionLevel permissionLevel = [(NSNumber *)[[pkt attributeForKey:@"0x12"] attributeValue] intValue];
	
	XfireFriend *user = [_session friendForUserID:[userID unsignedIntValue]];
	
	if (!user) // we don't know this user, create a representation for it
	{
		user = [[[XfireFriend alloc] init] autorelease];
		[user setUserID:[userID unsignedIntValue]];
		[user setSessionID:userSID];
		[user setUserName:username];
		[user setNickName:nickname];
		
		[_users addObject:user];
	}
	else
	{
		[_users addObject:user];
	}
	
	[_session delegate_user:user didJoinChatRoom:self];
	
	[self.permissions setObject:[NSNumber numberWithInteger:permissionLevel] forKey:username];
	
	NSString *text = [NSString stringWithFormat:@"%@ (%@) joined the chat room", [user displayName], [self stringForPermissionLevel:permissionLevel]];
	NSDictionary *message = [NSDictionary dictionaryWithObjectsAndKeys:@"system", @"system", text, @"message", nil];
	
	[_messages addObject:message];
	
	if ([[self delegate] respondsToSelector:@selector(session:chatRoom:didReceiveSystemMessage:)])
	{
		[[self delegate] session:_session chatRoom:self didReceiveSystemMessage:message];
	}
}

- (void)processChatRoomUserLeftPacket:(XfirePacket *)pkt
{
	NSUInteger userID = [(NSNumber *)[[pkt attributeForKey:@"0x01"] attributeValue] unsignedIntValue];
	
	XfireFriend *user = [self userForUserID:userID];
	
	NSString *text = [NSString stringWithFormat:@"%@ left the chat room", [user displayName]];
	NSDictionary *message = [NSDictionary dictionaryWithObjectsAndKeys:@"system", @"system", text, @"message", nil];
	
	[_messages addObject:message];
	
	if ([[self delegate] respondsToSelector:@selector(session:chatRoom:didReceiveSystemMessage:)])
	{
		[[self delegate] session:_session chatRoom:self didReceiveSystemMessage:message];
	}
	
	[_users removeObject:user];
	[_session delegate_userDidLeaveChatRoom:self];
}

- (void)processChatRoomReceivedMessagePacket:(XfirePacket *)pkt
{
	XfireFriend *user = [self userForUserID:[(NSNumber *)[[pkt attributeForKey:@"0x01"] attributeValue] unsignedIntValue]];
	NSString *message = [[pkt attributeValuesForKey:@"0x2e"] objectAtIndex:0];
	
	NSDate *date = [NSDate date];
	
	NSDictionary *chatRoomMessage = [NSDictionary dictionaryWithObjectsAndKeys:user, @"user", message, @"message", date, @"timestamp", nil];
	[_messages addObject:chatRoomMessage];
	NSLog(@"%@: %@", [user displayName], message);
	
	if ([[self delegate] respondsToSelector:@selector(session:chatRoom:didReceiveMessage:)])
	{
		[[self delegate] session:_session chatRoom:self didReceiveMessage:chatRoomMessage];
	}
	
	_unreadCount++;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kXfireChatRoomDidReceiveMessageNotification object:nil];
}

- (void)sendMessage:(NSString *)message
{
	[_session sendMessage:message toChatRoom:self];
}

- (void)kickUser:(XfireFriend *)user
{
	[_session kickUser:user fromChatRoom:self];
}

@end
