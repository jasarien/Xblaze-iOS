/*******************************************************************
	FILE:		XfireSession.m
	
	COPYRIGHT:
		Copyright 2007-2009, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Represents one log-in session.  It tracks the associated
		connections, chats, friends, etc. while the user is online.
	
	HISTORY:
		2008 10 02  Added support for custom friend groups.
		2008 04 06  Changed copyright to BSD license.
		2008 02 10  Eliminated secondary reader thread.
		2008 01 12  Began integration into final phase of MacFire
		            project.  Added copyright notice.
		2007 10 13  Created.
*******************************************************************/

#import "XfireSession.h"
#import "XfireSession_Private.h"
#import "XfireConnection.h"
#import "XfireLoginConnection.h"
#import "XfireFriendGroupController.h"
#import "XfireChatRoom.h"

@interface XfireSession (Private2)
- (id)initWithHost:(NSString *)xfireHost port:(unsigned short)portNumber;
- (id)initWithIP:(NSString *)ip port:(unsigned short)portNumber;
@end

NSString *kXfireVersionTooOldReason = @"Version too old";
NSString *kXfireInvalidPasswordReason = @"The password you typed was incorrect";
NSString *kXfireNetworkErrorReason = @"A network error occurred.";

NSString *kXfireOtherSessionReason = @"Logged in at another location";
NSString *kXfireServerHungUpReason = @"The Xfire server closed the connection";
NSString *kXfireUnknownNetworkErrorReason = @"An unknown network error occured. Your connection to the internet may have dropped momentarily. Please try reconnecting…";
NSString *kXfireServerStoppedRespondingReason = @"The Xfire server has stopped responding";
NSString *kXfireServerConnectionTimedOutReason = @"The connection to the Xfire server timed out";
NSString *kXfireReadTimeOutReason = @"The connection timed out";
NSString *kXfireWriteTimeOutReason = @"The connection timed out";
NSString *kXfireNormalDisconnectReason = @"Normal disconnect";

NSString *kXfireShowMyFriendsOption = @"XfireShowMyFriendsOption";
NSString *kXfireShowMyGameServerDataOption = @"XfireShowMyGameServerDataOption";
NSString *kXfireShowOnMyProfileOption = @"XfireShowOnMyProfileOption";
NSString *kXfireShowChatTimeStampsOption = @"XfireShowChatTimeStampsOption";
NSString *kXfireShowFriendsOfFriendsOption = @"XfireShowFriendsOfFriendsOption";
NSString *kXfireShowMyOfflineFriendsOption = @"XfireShowMyOfflineFriendsOption";
NSString *kXfireShowNicknamesOption = @"kXfireShowNicknamesOption";
NSString *kXfireShowVoiceChatServerOption = @"kXfireShowVoiceChatServerOption";
NSString *kXfireShowWhenITypeOption = @"XfireShowWhenITypeOption";
NSString *kXfireUserOptionsDidChangeNotification = @"kXfireUserOptionsDidChangeNotification";

NSString *XfireFriendDidChangeNotification = @"XfireFriendDidChangeNotification";
NSString *kXfireFriendChangeAttribute = @"kXfireFriendChangeAttribute";
//NSString *kXfireFriendChangeFriend @"kXfireFriendChangeFriend";

static inline void _SetDeltaOption( NSDictionary *defaults, NSDictionary *current, NSMutableDictionary *deltas, NSString *defaultsKey, NSString *deltasKey );


@implementation XfireSession

/***********************************************************************************************************************/
#pragma mark Public interfaces
/***********************************************************************************************************************/

// get session status
- (XfireSessionStatus)status
{
	return _status;
}

// get active connections for this session
- (NSArray *)connections
{
	return [_connections copy];
}

- (void)setDelegate:(id)aDelegate
{
	if( [self status] == kXfireSessionStatusOffline )
	{
		_delegate = aDelegate;
	}
}

- (id)delegate
{
	return _delegate;
}


/***********************************************************************************************************************/
#pragma mark Connect/Disconnect
/***********************************************************************************************************************/

// Start the session by logging in
// The delegate must be set first or this will throw an exception

- (NSString *)xfireHost
{
	return _xfireHost;
}


- (NSString *)xfireIP
{
	return _xfireIP;
}

- (void)connect
{
	if( [self status] != kXfireSessionStatusOffline )
	{
		@throw [NSException exceptionWithName:@"XfireSessionException"
			reason:@"Attempt to connect a connected session"
			userInfo:nil];
	}
	
	id tmpDel = [self delegate];
	if( (tmpDel == nil) || (![tmpDel respondsToSelector:@selector(xfireGetSession:userName:password:)]) )
	{
		@throw [NSException exceptionWithName:@"XfireSessionException"
			reason:@"Invalid delegate for Xfire session"
			userInfo:nil];
	}
	
	// Create the login connection
	[self setStatus:kXfireSessionStatusLoggingOn];
	_loginConnection = (XfireLoginConnection *)[XfireConnection newLoginConnectionToHost:_xfireHost port:_xfirePort];
	[_loginConnection setSession:self];
	_connections = [[NSMutableArray alloc] init];
	_friendGroupController = [[XfireFriendGroupController alloc] initWithSession:self];
	[_connections addObject:[_loginConnection autorelease]]; // so we don't have too many references to the connection
	
	_userOptions = [[NSMutableDictionary alloc] initWithDictionary:[XfireSession defaultUserOptions]];
	
	_keepAliveTimer = [NSTimer scheduledTimerWithTimeInterval:60.0
		target:self
		selector:@selector(keepAliveTimerExpired:)
		userInfo:nil
		repeats:YES];
	
	[_loginConnection connect];
}

- (void)disconnect
{	
	if ([self status] == kXfireSessionStatusOffline)
		return;
	
	[self delegate_sessionWillDisconnect:kXfireNormalDisconnectReason];
	
	[_keepAliveTimer invalidate];
	_keepAliveTimer = nil;
	
	[_loginConnection disconnect];
	[_loginConnection setSession:nil];
	_loginConnection = nil;
	
	// this ensures the login connection object isn't released right away
	// this may have been called from a delegate method so we don't want to invoke
	// something on an object that's just been deallocated.
	[_connections makeObjectsPerformSelector:@selector(retain)];
	[_connections makeObjectsPerformSelector:@selector(autorelease)];
	[_connections autorelease];
	_connections = nil;
	
	[_friendGroupController autorelease];
	_friendGroupController = nil;
		
	[_userOptions autorelease];
	_userOptions = nil;
	
	[_friends release];
	_friends = nil;
	
	[_pendingFriends release];
	_pendingFriends = nil;
	
	[_chats release];
	_chats = nil;
	
	[_loginIdent release];
	_loginIdent = nil;
	
	[self setStatus:kXfireSessionStatusOffline];
}

- (void)keepAliveTimerExpired:(NSTimer *)aTimer
{
	[_loginConnection keepAlive];
}

/***********************************************************************************************************************/
#pragma mark Friends
/***********************************************************************************************************************/

- (XfireFriend *)loginIdentity
{
	return _loginIdent;
}

- (NSArray *)friends
{
	return [[_friends copy] autorelease];
}

- (NSArray *)clanMembers
{
	return [[_clanMembers copy] autorelease];
}

- (NSArray *)clanMembersOnline
{
	NSMutableArray *tmp = [NSMutableArray array];
	XfireFriend *f;
	int i, len;
	
	len = [_clanMembers count];
	for( i = 0; i < len; i++ )
	{
		f = [_friends objectAtIndex:i];
		if( [f isOnline] )
		{
			[tmp addObject:f];
		}
	}
	
	return [tmp copy];
}

- (NSArray *)friendsOnline
{
	NSMutableArray *tmp = [NSMutableArray array];
	XfireFriend *f;
	int i, len;
	
	len = [_friends count];
	for( i = 0; i < len; i++ )
	{
		f = [_friends objectAtIndex:i];
		if( [f isOnline] )
		{
			[tmp addObject:f];
		}
	}
	
	return [tmp copy];
}

- (XfireFriend *)friendForUserID:(unsigned int)anID
{
	XfireFriend *f;
	int i, len;
	
	if( anID == 0 )
		return nil;
	
	// check friends first
	len = [_friends count];
	for( i = 0; i < len; i++ )
	{
		f = [_friends objectAtIndex:i];
		if( [f userID] == anID )
		{
			return f;
		}
	}
	
	// check clan members if not found in friends
	len = [_clanMembers count];
	for( i = 0; i < len; i++ )
	{
		f = [_clanMembers objectAtIndex:i];
		if( [f userID] == anID )
		{
			return f;
		}
	}
	
	return nil;
}

- (XfireFriend *)friendForUserName:(NSString *)name
{
	XfireFriend *f;
	int i, len;
	
	//check friends first
	len = [_friends count];
	for( i = 0; i < len; i++ )
	{
		f = [_friends objectAtIndex:i];
		if( [[f userName] isEqualToString:name] )
		{
			return f;
		}
	}
	
	// if not found in friends, check clan members
	len = [_clanMembers count];
	for( i = 0; i < len; i++ )
	{
		f = [_clanMembers objectAtIndex:i];
		if( [[f userName] isEqualToString:name] )
		{
			return f;
		}
	}
	
	return nil;
}

- (XfireFriend *)friendForSessionID:(NSData *)anID
{
	XfireFriend *f;
	int i, len;
	
	len = [_friends count];
	for( i = 0; i < len; i++ )
	{
		f = [_friends objectAtIndex:i];
		if( [[f sessionID] isEqual:anID] )
		{
			return f;
		}
	}
	
	return nil;
}

- (void)addFriend:(XfireFriend *)fr
{
	if( fr )
	{
		[fr setSession:self];
		if (![_friends containsObject:fr])
			[_friends addObject:fr];
		[_friendGroupController addFriend:fr];
	}
}

- (void)removeFriend:(XfireFriend *)fr
{
	if( fr )
	{
		[_friendGroupController removeFriend:fr];
		if (![fr isClanMember])
			[_friends removeObject:fr];
	}
}

- (void)addClanMember:(XfireFriend *)fr
{
	if (fr)
	{
		[fr setSession:self];
		[_clanMembers addObject:fr];
	}
}

- (void)removeClanMember:(XfireFriend *)fr
{
	if (fr)
	{
		[_clanMembers removeObject:fr];
	}
}

- (void)addPendingFriend:(XfireFriend *)fr
{
	[_pendingFriends addObject:fr];
}

- (void)removePendingFriend:(XfireFriend *)fr
{
	[_pendingFriends removeObject:fr];
}

- (XfireFriend *)pendingFriendForSessionID:(NSData *)anID
{
	XfireFriend *f;
	int i, len;
	
	len = [_pendingFriends count];
	for( i = 0; i < len; i++ )
	{
		f = [_pendingFriends objectAtIndex:i];
		if( [[f sessionID] isEqual:anID] )
		{
			return f;
		}
	}
	
	return nil;
}

// Send a friend-add request
- (void)sendFriendInvitation:(NSString *)username message:(NSString *)msg
{
	if( [self status] == kXfireSessionStatusOnline )
	{
		[_loginConnection sendFriendInvitation:username message:msg];
	}
}

// Remove a friend
- (void)sendRemoveFriend:(XfireFriend *)fr
{
	if( [self status] == kXfireSessionStatusOnline )
	{
		[_loginConnection sendRemoveFriend:fr];
	}
}

// Accept incoming friendship requests
- (void)acceptFriendRequest:(XfireFriend *)fr
{
	if( [self status] == kXfireSessionStatusOnline )
	{
		[_loginConnection acceptFriendRequest:fr];
	}
}

// Decline incoming friendship requests
- (void)declineFriendRequest:(XfireFriend *)fr
{
	if( [self status] == kXfireSessionStatusOnline )
	{
		[_loginConnection declineFriendRequest:fr];
	}
}

/***********************************************************************************************************************/
#pragma mark Friend Groups
/***********************************************************************************************************************/

- (XfireFriendGroupController *)friendGroupController
{
	return _friendGroupController;
}

- (NSArray *)friendGroups
{
	return [[self friendGroupController] groups];
}

- (void)requestNewFriendGroup:(NSString *)groupName
{
	if( [groupName length] > 0 )
	{
		[_loginConnection addCustomFriendGroup:groupName];
	}
}

- (void)renameFriendGroup:(XfireFriendGroup *)group newName:(NSString *)name
{
	if( ([name length] > 0) && ([group groupID] > 2) )
	{
		[_loginConnection renameCustomFriendGroup:[group groupID] newName:name];
		[[self friendGroupController] renameGroup:group toName:name];
	}
}

- (void)removeFriendGroup:(XfireFriendGroup *)group
{
	if( [group groupID] > 2 )
	{
		[_loginConnection removeCustomFriendGroup:[group groupID]];
		[[self friendGroupController] removeGroup:group];
	}
}

- (void)addFriend:(XfireFriend *)fr toGroup:(XfireFriendGroup *)grp
{
	if( [grp groupID] > 2 )
	{
		[_loginConnection addFriend:fr toGroup:grp];
	}
}

- (void)removeFriend:(XfireFriend *)fr fromGroup:(XfireFriendGroup *)grp
{
	if( [grp groupID] > 2 )
	{
		[_loginConnection removeFriend:fr fromGroup:grp];
	}
}

/***********************************************************************************************************************/
#pragma mark User Options
/***********************************************************************************************************************/

+ (NSDictionary *)defaultUserOptions
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithBool:YES],  kXfireShowMyFriendsOption,
		[NSNumber numberWithBool:YES],  kXfireShowMyGameServerDataOption,
		[NSNumber numberWithBool:YES],  kXfireShowOnMyProfileOption,
		[NSNumber numberWithBool:YES],  kXfireShowChatTimeStampsOption,
		[NSNumber numberWithBool:YES],  kXfireShowFriendsOfFriendsOption,
		[NSNumber numberWithBool:YES],  kXfireShowMyOfflineFriendsOption,
		[NSNumber numberWithBool:YES],  kXfireShowNicknamesOption,
		[NSNumber numberWithBool:YES],  kXfireShowVoiceChatServerOption,
		[NSNumber numberWithBool:YES],  kXfireShowWhenITypeOption,
		nil];
}

- (NSDictionary *)userOptions
{
	return [NSDictionary dictionaryWithDictionary:_userOptions];
}

- (void)setUserOptions:(NSDictionary *)options
{
	NSEnumerator *srcKeyEnum = [options keyEnumerator];
	NSString *key;
	NSNumber *val;
	BOOL newVal;
	
	BOOL optionChanged = NO;
	
	while( (key = [srcKeyEnum nextObject]) != nil )
	{
		val = [_userOptions objectForKey:key];
		if( val )
		{
			newVal = [[options objectForKey:key] boolValue];
			if( [val boolValue] != newVal )
			{
				optionChanged = YES;
				[_userOptions setObject:[options objectForKey:key] forKey:key];
				
				// Check for specific items we care about
				if( [key isEqualToString:kXfireShowFriendsOfFriendsOption] )
				{
					XfireFriendGroup *grp = [_friendGroupController standardGroupOfType:kXfireFriendGroupFriendOfFriends];
					if( newVal )
					{
						if( !grp )
						{
							[_friendGroupController ensureStandardGroup:kXfireFriendGroupFriendOfFriends];
						}
					}
					else
					{
						if( grp )
						{
							[_friendGroupController removeGroup:grp];
						}
					}
				}
				else if( [key isEqualToString:kXfireShowMyOfflineFriendsOption] )
				{
					XfireFriendGroup *grp = [_friendGroupController standardGroupOfType:kXfireFriendGroupOffline];
					if( newVal )
					{
						if( !grp )
						{
							[_friendGroupController ensureStandardGroup:kXfireFriendGroupOffline];
						}
					}
					else
					{
						if( grp )
						{
							[_friendGroupController removeGroup:grp];
						}
					}
				}
			}
		}
	}
	
	if( optionChanged )
	{
		// compute the delta dictionary from default options in a format understandable by XfirePacket
		
		NSMutableDictionary *deltaOptions = [NSMutableDictionary dictionary];
		NSDictionary *defaultOptions = [XfireSession defaultUserOptions];
		
		_SetDeltaOption( defaultOptions, _userOptions, deltaOptions, kXfireShowMyFriendsOption,        @"0x01" );
		_SetDeltaOption( defaultOptions, _userOptions, deltaOptions, kXfireShowMyGameServerDataOption, @"0x02" );
		_SetDeltaOption( defaultOptions, _userOptions, deltaOptions, kXfireShowOnMyProfileOption,      @"0x03" );
		_SetDeltaOption( defaultOptions, _userOptions, deltaOptions, kXfireShowChatTimeStampsOption,   @"0x06" );
		_SetDeltaOption( defaultOptions, _userOptions, deltaOptions, kXfireShowFriendsOfFriendsOption, @"0x08" );
		_SetDeltaOption( defaultOptions, _userOptions, deltaOptions, kXfireShowMyOfflineFriendsOption, @"0x09" );
		_SetDeltaOption( defaultOptions, _userOptions, deltaOptions, kXfireShowNicknamesOption,        @"0x0a" );
		_SetDeltaOption( defaultOptions, _userOptions, deltaOptions, kXfireShowVoiceChatServerOption,  @"0x0b" );
		_SetDeltaOption( defaultOptions, _userOptions, deltaOptions, kXfireShowWhenITypeOption,        @"0x0c" );
		
		[_loginConnection setUserOptions:deltaOptions];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:kXfireUserOptionsDidChangeNotification object:[self userOptions]];
	}
}

// sets the dictionary without causing events to be triggered
- (void)_privateSetUserOptions:(NSDictionary *)options
{
	NSEnumerator *srcKeyEnum = [options keyEnumerator];
	NSString *key;
	NSNumber *val;
	
	while( (key = [srcKeyEnum nextObject]) != nil )
	{
		val = [_userOptions objectForKey:key];
		if( val )
		{
			if( [val boolValue] != [[options objectForKey:key] boolValue] )
			{
				[_userOptions setObject:[options objectForKey:key] forKey:key];
			}
		}
	}
}

- (BOOL)shouldShowFriendsOfFriends
{
	NSNumber *show = [_userOptions objectForKey:kXfireShowFriendsOfFriendsOption];
	if( show && [show boolValue] )
	{
		return YES;
	}
	return NO;
}

- (BOOL)shouldShowOfflineFriends
{
	NSNumber *show = [_userOptions objectForKey:kXfireShowMyOfflineFriendsOption];
	if( show && [show boolValue] )
	{
		return YES;
	}
	return NO;
}

/***********************************************************************************************************************/
#pragma mark Chatting
/***********************************************************************************************************************/

- (XfireChat *)beginChatWithFriend:(XfireFriend *)fr
{
	XfireChat *chat = [[XfireChat alloc] initWithRemoteFriend:fr connection:_loginConnection];
	[_chats addObject:[chat autorelease]];
	[self delegate_didBeginChat:chat];
	return chat;
}

- (XfireChat *)chatForSessionID:(NSData *)anID
{
	XfireChat *ch;
	int i, len;
	
	len = [_chats count];
	for( i = 0; i < len; i++ )
	{
		ch = [_chats objectAtIndex:i];
		if( [[ch sessionID] isEqual:anID] )
		{
			return ch;
		}
	}
	
	return nil;
}

- (void)closeChat:(XfireChat*)aChat
{
	[[aChat retain] autorelease]; // make sure the chat object doesn't go away quite yet
	[_chats removeObject:aChat];
	
	[self delegate_chatDidEnd:aChat];
}

/***********************************************************************************************************************/
#pragma mark Group Chatting
/***********************************************************************************************************************/

- (NSArray *)chatRooms
{
	return [[_chatRooms copy] autorelease];
}

- (XfireChatRoom *)chatRoomForSessionID:(NSData *)sessionID
{
	for (XfireChatRoom *chatRoom in _chatRooms)
	{
		if ([[chatRoom groupChatSID] isEqual:sessionID])
			return chatRoom;
	}
	
	return nil;
}

- (void)createChatRoomWithName:(NSString *)name
{
	[self createChatRoomWithName:name password:nil];
}

- (void)createChatRoomWithName:(NSString *)name password:(NSString *)password
{
	[_loginConnection createChatRoomWithName:name password:password];
}

- (void)leaveChatRoom:(XfireChatRoom *)chatRoom
{
	[_loginConnection leaveChatRoom:chatRoom];
	[_chatRooms removeObject:chatRoom];
}

- (void)inviteUsers:(NSArray *)users toChatRoom:(XfireChatRoom *)chatRoom
{
	[_loginConnection inviteUsers:users toChatRoom:chatRoom];
}

- (void)declineChatRoomInviteForChatRoom:(XfireChatRoom *)chatRoom
{
	[_loginConnection declineChatRoomInviteForChatRoom:chatRoom];
}

- (void)joinChatRoom:(XfireChatRoom *)chatRoom
{
	[self joinChatRoom:chatRoom password:nil];
}

- (void)joinChatRoom:(XfireChatRoom *)chatRoom password:(NSString *)password
{
	[_loginConnection joinChatRoom:chatRoom password:password];
}

- (void)sendMessage:(NSString *)message toChatRoom:(XfireChatRoom *)chatRoom
{
	[_loginConnection sendMessage:message toChatRoom:chatRoom];
}

- (void)kickUser:(XfireFriend *)user fromChatRoom:(XfireChatRoom *)chatRoom
{
	[_loginConnection kickUser:user fromChatRoom:chatRoom];
}

/***********************************************************************************************************************/
#pragma mark Private Interfaces (Session and/or Library)
/***********************************************************************************************************************/

// TBD, eventually may expose this as a public interface
+ (XfireSession *)newSessionWithHost:(NSString *)host port:(unsigned short)portNumber
{
	return [[XfireSession alloc] initWithHost:host port:portNumber];
}

+ (XfireSession *)newSessionWithIP:(NSString *)ip port:(unsigned short)portNumber
{
	return [[XfireSession alloc] initWithIP:ip port:portNumber];
}

- (id)initWithHost:(NSString *)host port:(unsigned short)portNumber
{
	self = [super init];
	if( self )
	{
		_status = kXfireSessionStatusOffline;
		_xfireHost = [host retain];
		_xfireIP = nil;
		_xfirePort = portNumber;
		_delegate = nil;
		_loginConnection = nil;
		_keepAliveTimer = nil;
		_friends = [[NSMutableArray alloc] init];
		_clanMembers = [[NSMutableArray alloc] init];
		_pendingFriends = [[NSMutableArray alloc] init];
		_loginIdent = [[XfireFriend alloc] init];
		[_loginIdent setSession:self];
		
		_latestClientVersion = [self compiledClientVersion];
		_posingVersion = _latestClientVersion;
		_chats = [[NSMutableArray alloc] init];
		_chatRooms = [[NSMutableArray alloc] init];
		
	}
	return self;
}

- (id)initWithIP:(NSString *)ip port:(unsigned short)portNumber
{
	self = [super init];
	if( self )
	{
		_status = kXfireSessionStatusOffline;
		_xfireHost = nil;
		_xfireIP = ip;
		_xfirePort = portNumber;
		_delegate = nil;
		_loginConnection = nil;
		_keepAliveTimer = nil;
		_friends = [[NSMutableArray alloc] init];
		_clanMembers = [[NSMutableArray alloc] init];
		_pendingFriends = [[NSMutableArray alloc] init];
		_loginIdent = [[XfireFriend alloc] init];
		[_loginIdent setSession:self];
		
		_latestClientVersion = [self compiledClientVersion];
		_posingVersion = _latestClientVersion;
		_chats = [[NSMutableArray alloc] init];
		_chatRooms = [[NSMutableArray alloc] init];
		
	}
	return self;
}

- (void)dealloc
{
	[_connections release];
	_connections = nil;
	_loginConnection = nil;
	
	[_xfireHost release];
	_xfireHost = nil;
	
	[_friends release];
	_friends = nil;
	
	[_clanMembers release];
	_clanMembers = nil;
	
	[_pendingFriends release];
	_pendingFriends = nil;
	
	[_loginIdent release];
	_loginIdent = nil;
	
	[_chats release];
	_chats = nil;
	
	[_chatRooms release];
	_chatRooms = nil;
	
	[super dealloc];
}

- (void)workspaceWillPowerOff:(NSNotification *)aNote
{
	if( _status != kXfireSessionStatusOffline )
	{
		[self disconnect];
	}
}
- (void)workspaceWillSleep:(NSNotification *)aNote
{
	if( _status != kXfireSessionStatusOffline )
	{
		[self disconnect];
	}
}

/***********************************************************************************************************************/
#pragma mark Session status change
/***********************************************************************************************************************/

- (void)setStatus:(XfireSessionStatus)aStatus
{
	_status = aStatus;
	
	if( [[self delegate] respondsToSelector:@selector(xfireSession:didChangeStatus:)] )
	{
		[[self delegate] xfireSession:self didChangeStatus:aStatus];
	}
}

// For XfireLoginConnection to notify of login failure for clean abort
- (void)loginFailed:(NSString *)reason
{
	[self disconnect];
	
	if( [[self delegate] respondsToSelector:@selector(xfireSessionLoginFailed:reason:)] )
	{
		[[self delegate] xfireSessionLoginFailed:self reason:reason];
	}
}

/***********************************************************************************************************************/
#pragma mark Delegate operations
/***********************************************************************************************************************/

// For - (void)xfireGetSession:(XfireSession *)session userName:(NSString **)aName password:(NSString **)password;
- (void)delegate_getUserName:(NSString **)uname password:(NSString **)pword
{
	[[self delegate] xfireGetSession:self userName:uname password:pword];
}

// For - (void)xfireSessionWillDisconnect:(XfireSession *)session reason:(NSString *)reason;
- (void)delegate_sessionWillDisconnect:(NSString *)reason
{
	if( [[self delegate] respondsToSelector:@selector(xfireSessionWillDisconnect:reason:)] )
	{
		[[self delegate] xfireSessionWillDisconnect:self reason:reason];
	}
}

// For - (XfireSkin *)xfireSessionSkin:(XfireSession *)session;
- (XfireSkin *)delegate_skin
{
	return [[self delegate] xfireSessionSkin:self];
}

// For - (NSString *)xfireSessionLogPath:(XfireSession *)session;
- (NSString *)delegate_sessionLogPath
{
	if( [[self delegate] respondsToSelector:@selector(xfireSessionLogPath:)] )
	{
		return [[self delegate] xfireSessionLogPath:self];
	}
	return nil;
}

// For - (void)xfireSession:(XfireSession *)session nicknameDidChange:(NSString *)newNick;
- (void)delegate_nicknameDidChange:(NSString *)newNick
{
	if( [[self delegate] respondsToSelector:@selector(xfireSession:nicknameDidChange:)] )
	{
		[[self delegate] xfireSession:self nicknameDidChange:newNick];
	}
}

// For - (void)xfireSession:(XfireSession *)session searchResults:(NSArray *)friends;
- (void)delegate_searchResults:(NSArray *)friends
{
	if( [[self delegate] respondsToSelector:@selector(xfireSession:searchResults:)] )
	{
		[[self delegate] xfireSession:self searchResults:friends];
	}
}

// For - (void)xfireSession:(XfireSession *)session didReceiveFriendshipRequests:(NSArray *)requestors;
- (void)delegate_didReceiveFriendshipRequests:(NSArray *)requestors
{
	if( [[self delegate] respondsToSelector:@selector(xfireSession:didReceiveFriendshipRequests:)] )
	{
		[[self delegate] xfireSession:self didReceiveFriendshipRequests:requestors];
	}
}

// For - (void)xfireSession:(XfireSession *)session friendDidChange:(XfireFriend *)fr attribute:(XfireFriendChangeAttribute)attr;
- (void)delegate_friendDidChange:(XfireFriend *)fr attribute:(XfireFriendChangeAttribute)attr
{
	if( [[self delegate] respondsToSelector:@selector(xfireSession:friendDidChange:attribute:)] )
	{
		[[self delegate] xfireSession:self friendDidChange:fr attribute:attr];
	}
}

// For - (void)xfireSession:(XfireSession *)session friendGroupDidChange:(XfireFriendGroup *)grp;
- (void)delegate_friendGroupDidChange:(XfireFriendGroup *)grp
{
	if( [[self delegate] respondsToSelector:@selector(xfireSession:friendGroupDidChange:)] )
	{
		[[self delegate] xfireSession:self friendGroupDidChange:grp];
	}
}

// For - (void)xfireSession:(XfireSession *)session didBeginChat:(XfireChat *)chat;
- (void)delegate_didBeginChat:(XfireChat *)chat
{
	if( [[self delegate] respondsToSelector:@selector(xfireSession:didBeginChat:)] )
	{
		[[self delegate] xfireSession:self didBeginChat:chat];
	}
}

// For - (void)xfireSession:(XfireSession *)session chatDidEnd:(XfireChat *)aChat;
- (void)delegate_chatDidEnd:(XfireChat *)chat
{
	if( [[self delegate] respondsToSelector:@selector(xfireSession:chatDidEnd:)] )
	{
		[[self delegate] xfireSession:self chatDidEnd:chat];
	}
}

// For - (void)xfireSession:(XfireSession *)session friendGroupWasAdded:(XfireFriendGroup *)grp;
- (void)delegate_friendGroupWasAdded:(XfireFriendGroup *)grp
{
	if( [[self delegate] respondsToSelector:@selector(xfireSession:friendGroupWasAdded:)] )
	{
		[[self delegate] xfireSession:self friendGroupWasAdded:grp];
	}
}

// For - (void)xfireSession:(XfireSession *)session friendGroupWillBeRemoved:(XfireFriendGroup *)grp;
- (void)delegate_friendGroupWillBeRemoved:(XfireFriendGroup *)grp
{
	if( [[self delegate] respondsToSelector:@selector(xfireSession:friendGroupWillBeRemoved:)] )
	{
		[[self delegate] xfireSession:self friendGroupWillBeRemoved:grp];
	}
}

- (void)delegate_joinChatRoomInvalidPassword
{
	if ([[self delegate] respondsToSelector:@selector(xfireSessionJoinChatRoomInvalidPassword:)])
	{
		[[self delegate] xfireSessionJoinChatRoomInvalidPassword:self];
	}
}

- (void)delegate_joinChatRoomPasswordRequired
{
	if ([[self delegate] respondsToSelector:@selector(xfireSessionJoinChatRoomPasswordRequired:)])
	{
		[[self delegate] xfireSessionJoinChatRoomPasswordRequired:self];
	}
}

- (void)delegate_didJoinChatRoom:(XfireChatRoom *)chatRoom
{
	[_chatRooms addObject:chatRoom];
	
	if ([[self delegate] respondsToSelector:@selector(xfireSession:didJoinChatRoom:)])
	{
		[[self delegate] xfireSession:self didJoinChatRoom:chatRoom];
	}
}

- (void)delegate_updatedInfoForChatRoom:(XfireChatRoom *)chatRoom
{
	if ([[self delegate] respondsToSelector:@selector(xfireSession:updatedInfoForChatRoom:)])
	{
		[[self delegate] xfireSession:self updatedInfoForChatRoom:chatRoom];
	}
}

- (void)delegate_user:(XfireFriend *)user didJoinChatRoom:(XfireChatRoom *)chatRoom
{
	if ([[self delegate] respondsToSelector:@selector(xfireSession:user:didJoinChatRoom:)])
	{
		[[self delegate] xfireSession:self user:user didJoinChatRoom:chatRoom];
	}
}

- (void)delegate_userDidLeaveChatRoom:(XfireChatRoom *)chatRoom
{
	if ([[self delegate] respondsToSelector:@selector(xfireSession:userDidLeaveChatRoom:)])
	{
		[[self delegate] xfireSession:self userDidLeaveChatRoom:chatRoom];
	}
}

- (void)delegate_receivedChatRoomInviteFrom:(XfireFriend *)friend forChatRoom:(XfireChatRoom *)chatRoom
{
	if ([[self delegate] respondsToSelector:@selector(xfireSession:receivedInviteFromFriend:forChatRoom:)])
	{
		[[self delegate] xfireSession:self receivedInviteFromFriend:friend forChatRoom:chatRoom];
	}
}

- (void)delegate_user:(XfireFriend *)user kickedFromChatRoom:(XfireChatRoom *)chatRoom
{
	if ([[self delegate] respondsToSelector:@selector(xfireSession:user:kickedFromChatRoom:)])
	{
		[[self delegate] xfireSession:self user:user kickedFromChatRoom:chatRoom];
	}
}

/***********************************************************************************************************************/
#pragma mark Xfire Protocol Version
/***********************************************************************************************************************/

- (unsigned int)compiledClientVersion
{
	return 101;
}

- (void)setLatestClientVersion:(unsigned int)ver
{
	_latestClientVersion = ver;
}

- (unsigned int)latestClientVersion
{
	return _latestClientVersion;
}

- (void)setPosingClientVersion:(unsigned int)posingVersion
{
	_posingVersion = posingVersion;
}

- (unsigned int)posingClientVersion
{
	return _posingVersion;
}

/***********************************************************************************************************************/
#pragma mark Changing Client Status
/***********************************************************************************************************************/

- (void)setStatusString:(NSString *)text
{
	if( [self status] == kXfireSessionStatusOnline )
	{
		XfireFriend *us = [self loginIdentity];
		if( ! [[us statusString] isEqualToString:text] )
		{
			[us setStatusString:text];
			[_loginConnection setStatusText:text];
		}
	}
}

- (void)setNickname:(NSString *)text
{
	if( [self status] == kXfireSessionStatusOnline )
	{
		XfireFriend *us = [self loginIdentity];
		if( ! [[us nickName] isEqualToString:text] )
		{
			[us setNickName:text];
			[_loginConnection changeNickname:text];
			[self delegate_nicknameDidChange:text];
		}
	}
}

- (void)changeGame:(int)gid
{
	XfireFriend *us = [self loginIdentity];
	if( [us gameID] != gid )
	{
		[us setGameID:gid];
		[_loginConnection setGameStatus:gid gameIP:0 gamePort:0];
	}
}

- (void)enterGame:(unsigned int)gid
{
	if( [self status] == kXfireSessionStatusOnline )
	{
		[self changeGame:gid];
	}
}

- (void)exitGame:(unsigned int)gid
{
	if( [self status] == kXfireSessionStatusOnline )
	{
		[self changeGame:0];
	}
}

- (void)beginUserSearch:(NSString *)searchString
{
	if( [self status] == kXfireSessionStatusOnline )
	{
		[_loginConnection beginUserSearch:searchString];
	}
}

- (void)requestInfoViewInfoForFriend:(XfireFriend *)friend
{
	if ([self status] == kXfireSessionStatusOnline)
	{
		[_loginConnection requestInfoViewDetailsForFriend:friend];
	}
}

@end

static inline void _SetDeltaOption( NSDictionary *defaults, NSDictionary *current, NSMutableDictionary *deltas, NSString *defaultsKey, NSString *deltasKey )
{
	NSNumber *nbr = [current objectForKey:defaultsKey];
	
	if( [nbr boolValue] != [[defaults objectForKey:defaultsKey] boolValue] )
	{
		[deltas setObject:nbr forKey:deltasKey];
	}
}

