/*******************************************************************
	FILE:		XfireLoginConnection.m
	
	COPYRIGHT:
		Copyright 2007-2009, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Represents the log-in connection (the connection to the Xfire
		master server cs.xfire.com).  Handles sending/receiving
		packets.
	
	HISTORY:
		2008 10 01  Added friend group packet support.
		2008 05 17  Revised the packet handlers to use the new method in
		            XfirePacket as protection in case those packets later
		            have either arrays of values or single values.
		2008 04 06  Changed copyright to BSD license.
		2008 02 10  Eliminated secondary reader thread.
		2008 01 12  Revised to use new XfireConnection structure, and
		            added game status method.
		2007 11 18  Created.
*******************************************************************/

#import "XfireLoginConnection.h"
#import "XfireConnection_Private.h"
#import "XfireSession_Private.h"
#import "NSData_XfireAdditions.h"
#import "NSMutableData_XfireAdditions.h"
#import "XfirePacket.h"
#import "XfirePacketLogger.h"
#import "XfireFriend.h"
#import "AsyncSocket.h"
#import "XfireSkin.h"
#import "XfireChat_Private.h"
#import "XfireFriendGroupController.h"
#import "XfireFriendGroup.h"
#import "XfireFriendGroup_Private.h"
#import "XfirePacketAttributeMap.h"
#import "XfirePacketAttributeValue.h"
#import "XfireScreenshot.h"
#import "XfireChatRoom.h"

extern NSString* MFStringFromIPAddress(unsigned int addr);
static void _XfireCopyPreference( NSString *pktKey, NSString *dictKey, XfirePacketAttributeMap *map, NSMutableDictionary *dictionary );

#define GALLERY_AVATAR_URL @"http://media.xfire.com/xfire/xf/images/avatars/gallery/default/%.3d.gif"
#define DEFAULT_AVATAR_URL @"http://media.xfire.com/xfire/xf/images/avatars/gallery/default/xfire100.jpg"
#define CUSTOM_AVATAR_URL  @"http://screenshot.xfire.com/avatar/100/%@.jpg?%d"

@implementation XfireLoginConnection

- (id)initWithHost:(NSString *)host port:(unsigned short)portNumber
{
	self = [super initWithHost:host port:portNumber];
	if( self )
	{
		_availableData = [[NSMutableData data] retain];
		_keepAliveResponseTimer = nil;
	}
	return self;
}

- (void)dealloc
{
	[_availableData release];
	_availableData = nil;
	
	if( _keepAliveResponseTimer )
	{
		[_keepAliveResponseTimer invalidate];
		_keepAliveResponseTimer = nil;
	}
	
	[super dealloc];
}

- (void)disconnect
{
	if( _keepAliveResponseTimer )
	{
		[_keepAliveResponseTimer invalidate];
		_keepAliveResponseTimer = nil;
	}
	
	if( [self status] != kXfireConnectionConnected )
		return;
	
	[[self session] setStatus:kXfireSessionStatusLoggingOff];
	[super disconnect];
	_session = nil;
}

- (void)keepAlive
{
	if( [self status] != kXfireConnectionConnected )
		return;
	
	XfirePacket *pkt = [XfireMutablePacket keepAlivePacketWithValue:0 stats:[NSArray array]];
	[self sendPacket:pkt];
	
	// wait 10 secs for the response before hanging up
	_keepAliveResponseTimer = [NSTimer scheduledTimerWithTimeInterval:30.0
		target:self
		selector:@selector(keepAliveResponseTimeout:)
		userInfo:nil
		repeats:NO];
}

- (void)keepAliveResponseTimeout:(NSTimer *)aTimer
{
	_keepAliveResponseTimer = nil;
	[[self session] delegate_sessionWillDisconnect:kXfireServerStoppedRespondingReason];
	[[self session] disconnect];
}

// This is called once the socket connection is established (at least, the XfireSocket is created
// and "connected").
// send key UA01
// send client version packet
// Don't set session status to kXfireSessionStatusOnline here - wait until we get a login success packet
- (void)connectionDidConnect
{
	// send the key first
	[self sendData:[[NSString stringWithString:@"UA01"] dataUsingEncoding:NSUTF8StringEncoding]];
	
	// send client version packet
	[self sendPacketSafe:[XfireMutablePacket clientVersionPacket:[[self session] posingClientVersion]]];
}

// Xfire does not have a "disconnect" packet, as far as I can tell
// But we can be hung up on
- (void)connectionWillDisconnect
{
	if( _keepAliveResponseTimer )
	{
		[_keepAliveResponseTimer invalidate];
		_keepAliveResponseTimer = nil;
	}
	
	[[self session] setStatus:kXfireSessionStatusOffline];
	_session = nil;
	[_availableData release];
	_availableData = nil;
}

-(void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{	
	NSString *reason = nil;
	
	switch ([err code]) {
		case AsyncSocketCFSocketError:
			reason = kXfireServerHungUpReason;
			break;
		case AsyncSocketConnectTimeoutError:
			reason = kXfireServerConnectionTimedOutReason;
			break;
		case AsyncSocketReadTimeoutError:
			reason = kXfireReadTimeOutReason;
			break;
		case AsyncSocketWriteTimeoutError:
			reason = kXfireWriteTimeOutReason;
			break;
		default:
			reason = kXfireUnknownNetworkErrorReason;
			break;
	}
	
	[[self session] delegate_sessionWillDisconnect:reason];
	
	[super performSelector:@selector(onSocket:willDisconnectWithError:) withObject:sock withObject:err];
}

// Stuff you can only do on the log-in connection (to the Xfire master server)
- (void)setGameStatus:(unsigned)gameID gameIP:(unsigned)gip gamePort:(unsigned)gp
{
	if( [self status] != kXfireConnectionConnected )
		return;
	
	XfirePacket *pkt = [XfireMutablePacket gameStatusChangePacketWithGameID:gameID gameIP:gip gamePort:gp];
	if( pkt )
		[self sendPacket:pkt];
}

- (void)setStatusText:(NSString *)text
{
	if( [self status] != kXfireConnectionConnected )
		return;
	
	XfirePacket *pkt = [XfireMutablePacket statusTextChangePacket:text];
	if( pkt )
		[self sendPacket:pkt];
}

- (void)changeNickname:(NSString *)text
{
	if( [self status] != kXfireConnectionConnected )
		return;
	
	XfirePacket *pkt = [XfireMutablePacket changeNicknamePacketWithName:text];
	if( pkt )
		[self sendPacket:pkt];
}

- (void)beginUserSearch:(NSString *)searchString
{
	if( [self status] != kXfireConnectionConnected )
		return;
	
	XfirePacket *pkt = [XfireMutablePacket userSearchPacketWithName:searchString
		fname:nil
		lname:nil
		email:nil];
	if( pkt )
		[self sendPacket:pkt];
}

// Send a friend-add request
- (void)sendFriendInvitation:(NSString *)username message:(NSString *)msg
{
	if( [self status] != kXfireConnectionConnected )
		return;
	
	XfirePacket *pkt = [XfireMutablePacket addFriendRequestPacketWithUserName:username message:msg];
	if( pkt )
		[self sendPacket:pkt];
}

- (void)sendRemoveFriend:(XfireFriend *)fr
{
	if( [self status] != kXfireConnectionConnected )
		return;
	
	XfirePacket *pkt = [XfireMutablePacket removeFriendRequestWithUserID:[fr userID]];
	if( pkt )
		[self sendPacket:pkt];
}

- (void)acceptFriendRequest:(XfireFriend *)fr
{
	if( [self status] != kXfireConnectionConnected )
		return;
	
	XfirePacket *pkt = [XfireMutablePacket acceptFriendRequestPacketWithUserName:[fr userName]];
	if( pkt )
		[self sendPacket:pkt];
}

- (void)declineFriendRequest:(XfireFriend *)fr
{
	if( [self status] != kXfireConnectionConnected )
		return;
	
	XfirePacket *pkt = [XfireMutablePacket declineFriendRequestPacketWithUserName:[fr userName]];
	if( pkt )
		[self sendPacket:pkt];
}

- (void)addCustomFriendGroup:(NSString *)groupName
{
	if( [self status] != kXfireConnectionConnected )
		return;
	
	XfirePacket *pkt = [XfireMutablePacket addCustomFriendGroupPacketWithName:groupName];
	if( pkt )
		[self sendPacket:pkt];
}

- (void)renameCustomFriendGroup:(unsigned)groupID newName:(NSString *)groupName
{
	if( [self status] != kXfireConnectionConnected )
		return;
	
	XfirePacket *pkt = [XfireMutablePacket renameCustomFriendGroupPacket:groupID newName:groupName];
	if( pkt )
		[self sendPacket:pkt];
}

- (void)removeCustomFriendGroup:(unsigned)groupID
{
	if( [self status] != kXfireConnectionConnected )
		return;
	
	XfirePacket *pkt = [XfireMutablePacket removeCustomFriendGroupPacket:groupID];
	if( pkt )
		[self sendPacket:pkt];
}

- (void)addFriend:(XfireFriend *)fr toGroup:(XfireFriendGroup *)group
{
	if( [self status] != kXfireConnectionConnected )
		return;
	
	XfirePacket *pkt = [XfireMutablePacket addFriendPacket:[fr userID] toCustomGroup:[group groupID]];
	if( pkt )
	{
		[self sendPacket:pkt];
		
		// TODO: this is roundabout
		XfireFriendGroupController *ctl = [[self session] friendGroupController];
		[ctl addPendingMemberID:[fr userID] groupID:[group groupID]];
		[ctl addFriend:fr];
	}
}

- (void)removeFriend:(XfireFriend *)fr fromGroup:(XfireFriendGroup *)group
{
	if( [self status] != kXfireConnectionConnected )
		return;
	
	XfirePacket *pkt = [XfireMutablePacket removeFriendPacket:[fr userID] fromCustomGroup:[group groupID]];
	if( pkt )
	{
		[self sendPacket:pkt];
		
		// TODO: this is roundabout
		XfireFriendGroupController *ctl = [[self session] friendGroupController];
		[ctl removeFriend:fr fromGroup:group];
	}
}

- (void)setUserOptions:(NSDictionary *)options
{
	if( [self status] != kXfireConnectionConnected )
		return;
	
	XfirePacket *pkt = [XfireMutablePacket changeOptionsPacketWithOptions:options];
	if( pkt )
		[self sendPacket:pkt];
}

- (void)requestInfoViewDetailsForFriend:(XfireFriend *)friend
{	
	if ([self status] != kXfireConnectionConnected)
		return;
	
	XfirePacket *pkt = [XfireMutablePacket infoViewRequestPacket:[friend userID]];
	if (pkt)
	{
		[self sendPacket:pkt];
	}
	
}

- (void)raiseFriendNotification:(XfireFriend *)aFriend attribute:(XfireFriendChangeAttribute)attr
{
	[[self session] delegate_friendDidChange:aFriend attribute:attr];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XfireFriendDidChangeNotification
		object:aFriend
		userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:attr]
			forKey:kXfireFriendChangeAttribute]];
}

#pragma mark -
#pragma mark Chat Rooms

- (void)createChatRoomWithName:(NSString *)chatRoomName
{
	[self createChatRoomWithName:chatRoomName password:nil];
}

- (void)createChatRoomWithName:(NSString *)chatRoomName password:(NSString *)password
{
	if ([self status] != kXfireConnectionConnected)
		return;
	
	XfirePacket *pkt = [XfireMutablePacket makeNewChatRoomPacket:chatRoomName password:password];
	if (pkt)
	{
		[self sendPacket:pkt];
	}
}

- (void)requestExtendedInforForChatRoom:(XfireChatRoom *)chatRoom
{
	if ([self status] != kXfireConnectionConnected)
		return;
	
	XfirePacket *pkt = [XfireMutablePacket chatRoomInfoPacketForChatRoom:chatRoom];
	if (pkt)
	{
		[self sendPacket:pkt];
	}
}

- (void)leaveChatRoom:(XfireChatRoom *)chatRoom
{
	if ([self status] != kXfireConnectionConnected)
		return;
	
	XfirePacket *pkt = [XfireMutablePacket leaveChatRoomPacketForChatRoom:chatRoom];
	if (pkt)
		[self sendPacket:pkt];
}

- (void)inviteUsers:(NSArray *)users toChatRoom:(XfireChatRoom *)chatRoom
{
	if ([self status] != kXfireConnectionConnected)
		return;
	
	XfirePacket *pkt = [XfireMutablePacket chatRoomInvitePacketForUsers:users chatRoom:chatRoom];
	if (pkt)
		[self sendPacket:pkt];
}

- (void)declineChatRoomInviteForChatRoom:(XfireChatRoom *)chatRoom
{
	if ([self status] != kXfireConnectionConnected)
		return;
	
	XfirePacket *pkt = [XfireMutablePacket declineChatRoomInvitePacketForChatRoom:chatRoom];
	if (pkt)
		[self sendPacket:pkt];
}

- (void)joinChatRoom:(XfireChatRoom *)chatRoom password:(NSString *)password
{
	if ([self status] != kXfireConnectionConnected)
		return;
	
	XfirePacket *pkt = [XfireMutablePacket joinChatRoomPacketForChatRoom:chatRoom password:password];
	if (pkt)
		[self sendPacket:pkt];	
}

- (void)sendMessage:(NSString *)message toChatRoom:(XfireChatRoom *)chatRoom
{
	if ([self status] != kXfireConnectionConnected)
		return;
	
	XfirePacket *pkt = [XfireMutablePacket messagePacketWithMessage:message forChatRoom:chatRoom];
	if (pkt)
		[self sendPacket:pkt];
}

- (void)kickUser:(XfireFriend *)user fromChatRoom:(XfireChatRoom *)chatRoom
{
	if ([self status] != kXfireConnectionConnected)
		return;
	
	XfirePacket *pkt = [XfireMutablePacket kickUserPacketWithUser:user forChatRoom:chatRoom];
	if (pkt)
		[self sendPacket:pkt];
}

#pragma mark -
#pragma mark Packet Parsing

// Append new data to available data
// Attempt to decode into a real packet, then call -receiverProcessPacket:
- (void)receiverProcessData:(NSData *)data
{
	BOOL shouldContinue = YES;
	
	[_availableData appendData:data];
	while( shouldContinue && ([_availableData length] >= 5) )
	{
		const unsigned char *bytes = [_availableData bytes];
		unsigned short pktlen = (
			(((unsigned short)(bytes[1])) << 8) |
			((unsigned short)(bytes[0]))
			);
		if( [_availableData length] >= pktlen )
		{
			NSData *pktdata = [_availableData subdataWithRange:NSMakeRange(0,pktlen)];
			[_availableData removeBytesInRange:NSMakeRange(0,pktlen)];
			
			XfirePacket *pkt = nil;
			
			@try
			{
				pkt = [XfirePacket decodedPacketByScanningBuffer:pktdata];
			}
			@catch( NSException *e )
			{
				DebugLog(@"Caught exception while trying to decode packet: %@", e);
				// TBD: ignore? quit?
			}
			
			if( pkt != nil )
			{
				@try
				{
					shouldContinue = [self receiverProcessPacket:pkt];
				}
				@catch( NSException *e )
				{
					DebugLog(@"Caught exception while processing packet: %@", e);
					// TBD: ignore? quit?
				}
			}
			else
			{
				[_packetLogger logRawData:pktdata];
			}
		}
		else if( [_availableData length] >= 5 )
		{
			// We need to wait for more data before we can process this packet as we don't have
			// enough available data to handle it.
			break;
		}
	}
}

// Need to return whether processing should continue in the loop above
// This flag is necessary to avoid problems where the object gets deallocated
// (e.g. a disconnection) while processing data.  You can end up with weird results otherwise (crashes).
- (BOOL)receiverProcessPacket:(XfirePacket *)pkt
{	
	BOOL shouldContinue = YES;
	
	[_packetLogger logInbound:pkt];
	
	switch([pkt packetID])
	{			
		case 128: // login request
			[self processLoginPacket:pkt];
			break;
		
		case 129: // login failure
			// Nothing useful in login failure packet (just a 'reason' which is always zero as far as I see).
			[[self session] loginFailed:kXfireInvalidPasswordReason];
			shouldContinue = NO;
			break;
		
		case 130: // Login success
			[self processLoginSuccessPacket:pkt];
			break;
		
		case 131: // Friends list
			[self processFriendsListPacket:pkt];
			break;
		
		case 132: // Session ID change
			[self processSessionIDPacket:pkt];
			break;
		
		case 133: // Chat (instant) message
			[self processChatMessagePacket:pkt];
			break;
		
		case 134: // new version available
			[self processVersionTooOldPacket:pkt];
			shouldContinue = NO;
			break;
		
		case 135: // game status change
			[self processGameStatusPacket:pkt];
			break;
		
		case 136: // friend of friend info
			[self processFriendOfFriendPacket:pkt];
			break;
		
		case 138: // friend add request
			[self processFriendRequestPacket:pkt];
			break;
		
		case 139: // remove friend
			[self processRemoveFriendPacket:pkt];
			break;
		
		case 141: // user options
			[self processUserOptionsPacket:pkt];
			break;
		
		case 143: // user search results
			[self processSearchResultsPacket:pkt];
			break;
		
		case 144: // keepalive response
			[self processKeepAliveResponse:pkt];
			break;
		
		case 145: // Session Disconnect packet
			[self processDisconnectPacket:pkt];
			shouldContinue = NO;
			break;
		
		case 151: // Friend group name
			[self processFriendGroupNamePacket:pkt];
			break;
		
		case 152: // Friend group member
			[self processFriendGroupMemberPacket:pkt];
			break;
		
		case 153: // New friend group ID
			[self processFriendGroupNamePacket:pkt];
			break;
		
		case 154: // Friend status message changed
			[self processFriendStatusPacket:pkt];
			break;
		
		case 158: // Clans list
			[self processClanListPacket:pkt];
			break;
			
		case 159: //Clan member list
			[self processClanMembersPacket:pkt];
			break;
			
		case 160: // clan member left clan
			[self processClanMemberLeftClanPacket:pkt];
			break;
		
		case 161: // Nickname changed
			[self processNicknameChangePacket:pkt];
			break;
		
		case 162: //clan member nickname changed
			[self processClanMemberChangedNicknamePacket:pkt];
			break;
			
		case 163: // Friend group list
			[self processFriendGroupListPacket:pkt];
			break;
			
		case 165: //clan invite
			break;

		case 170: //clan events
			break;
			
		case 171: //clan event deleted
			break;
		case 172: // screenshots info
			[self processScreenshotsInfo:pkt];
			break;
		case 173: // advanced info changed
			[self processFriendInfoChanged:pkt];
			break;			
		case 174: //Friend's avatar changed
			[self processFriendAvatarPacket:pkt];
			break;
			
		case 177: //news posted on clan site
			break;
			
		case 351: // chat room info on join
			[self processChatRoomJoinPacket:pkt];
			break;
		case 353:
			[self processChatRoomUserJoinedPacket:pkt];
			break;
		case 354:
			[self processChatRoomUserLeftPacket:pkt];
			break;
		case 355:
			[self processChatRoomReceivedMessagePacket:pkt];
			break;
		case 356:
			[self processChatRoomInvitePacket:pkt];
			break;
		case 359:
			[self processChatRoomUserKickedPacket:pkt];
			break;
		case 368: //chat room extended info
			[self processChatRoomInfoPacket:pkt];
			break;
			
		default:
			DebugLog(@"Unhandled packet: %@", pkt);
			break;
	}
	
	return shouldContinue;
}

- (void)processLoginPacket:(XfirePacket *)pkt
{
	NSString *salt;
	NSData *hash;
	NSMutableString *cur;
	NSString *username;
	NSString *password;
	NSString *hashedPassword;
	
	[[self session] delegate_getUserName:&username password:&password];
	if( (username == nil) || (password == nil) )
	{
		// TODO: abort
		DebugLog(@"Either username or password not provided!!!");
		return;
	}
	
	// copy so we have a full identification on us
	[[[self session] loginIdentity] setUserName:username];
	
	salt = [[pkt attributeForKey:kXfireAttributeSaltKey] attributeValue];
	
	// Compute hashed password
	cur = [NSMutableString string];
	[cur appendFormat:@"%@%@UltimateArena",username,password];
	hash = [[cur dataUsingEncoding:NSUTF8StringEncoding] sha1Hash];
	NSLog(@"Password Hash Before Salt: %@", [hash stringRepresentation]);
	cur = [NSMutableString string];
	[cur appendFormat:@"%@%@", [hash stringRepresentation], salt];
	hash = [[cur dataUsingEncoding:NSUTF8StringEncoding] sha1Hash];
	hashedPassword = [hash stringRepresentation];
	
	XfirePacket *loginPkt = [XfireMutablePacket loginPacketWithUsername:username
		password:hashedPassword
		flags:0];
	
	[username release];
	[password release];
	[self sendPacketSafe:loginPkt];
}

/*
Extract information from the login success packet
Set status to connected
Send client info packet (skin, lang)
Send network info packet

SCR 37 - Don't set status to Online here, wait until we get the friends list (we've logged in more)
*/
- (void)processLoginSuccessPacket:(XfirePacket *)pkt
{
	// Extract information from the login success packet
	// Contains useful information:
	//    int   user ID (userid)
	//    str   nickname (nick)
	//    uuid  session id (sid)
	//    int   public IP (pip)
	// Ignore: status, dlset, p2pset, clntset, minrect, maxrect, ctry, n1, n2, n3
	XfireFriend *fr = [[self session] loginIdentity];
	
	NSNumber *nbr = (NSNumber *)[[pkt attributeForKey:kXfireAttributeUserIDKey] attributeValue];
	[fr setUserID:[nbr unsignedIntValue]];
	[fr setNickName:[[pkt attributeForKey:kXfireAttributeNicknameKey] attributeValue]];
	[fr setSessionID:(NSData *)[[pkt attributeForKey:kXfireAttributeSessionIDKey] attributeValue]];
	
	// send skin packet
	XfireSkin *skin = [[self session] delegate_skin];
	XfirePacket *newPkt;
	
	// TODO: fix the language attribute
	newPkt = [XfireMutablePacket clientInfoPacketWithLanguage:@"us"
		skin:[skin name]
		theme:[skin theme]
		partner:@""];
	[self sendPacketSafe:newPkt];
	
	// send network info packet
	// TODO: figure out something better for this
	newPkt = [XfireMutablePacket networkInfoPacketWithConn:2
		nat:0
		sec:0
		ip:[_socket localAddressAsInt]
		naterr:0
		uPnPInfo:@""];
	[self sendPacketSafe:newPkt];
}

// Get newest version
// We can't download the file
// Contains information:
//   int[]    Version numbers   (version)
//   str[]    File URLs         (file)
//   int[]    Command           (command) always 1?
//   int[]    File ID           (fileid)
//   int      Login flags       (flags)  always 0?
- (void)processVersionTooOldPacket:(XfirePacket *)pkt
{
	NSArray  *versions = (NSArray *)[[pkt attributeForKey:kXfireAttributeVersionKey] attributeValue];
	if( [versions isKindOfClass:[NSArray class]] && ([versions count] > 0) )
	{
		// For now, just get the first number
		NSNumber *ver = (NSNumber *)[(XfirePacketAttributeValue *)[versions objectAtIndex:0] attributeValue];
		[[self session] setLatestClientVersion:[ver unsignedIntValue]];
	}
	[[self session] loginFailed:kXfireVersionTooOldReason];
}

// Read the list of friends and add it
// Contains information:
//   str[]    User Names   (friends)
//   str[]    Nick names   (nick)
//   int[]    User IDs     (userid)
- (void)processFriendsListPacket:(XfirePacket *)pkt
{	
	NSArray *usernames;
	NSArray *nicknames;
	NSArray *userids;
	XfireFriend *fr;
	
	int i, cnt;
	
	if ([[self session] status] != kXfireSessionStatusOnline)
		[[self session] setStatus:kXfireSessionStatusGettingFriends];
	
	usernames = [pkt attributeValuesForKey:kXfireAttributeFriendsKey];
	nicknames = [pkt attributeValuesForKey:kXfireAttributeNicknameKey];
	userids   = [pkt attributeValuesForKey:kXfireAttributeUserIDKey];
	
	// SCR 37 - This prevents the main app from sending packets before we have a friends list
	// Careful because this will not wait for status change, but friend list changes will wait
	// I think it all gets queued through the NSRunLoop of the main thread, so we should be okay
	if ([[self session] status] != kXfireSessionStatusOnline)
		[[self session] setStatus:kXfireSessionStatusOnline];
	
	cnt = [usernames count];
	for( i = 0; i < cnt; i++ )
	{
		fr = [[self session] friendForUserName:[usernames objectAtIndex:i]];
		if( fr == nil )
		{
			fr = [[XfireFriend alloc] init];
			[fr setUserName:[usernames objectAtIndex:i]];
			[fr setNickName:[nicknames objectAtIndex:i]];
			[fr setUserID:  [[userids objectAtIndex:i] unsignedIntValue]];
			[fr setIsDirectFriend:YES]; // why else would they be in the friends list packet?
			[[self session] addFriend:fr]; // retained by _friends in session
			[fr release];
			
			[[self session] delegate_friendDidChange:fr attribute:kXfireFriendWasAdded];
		}
		else if( [fr isFriendOfFriend] )
		{
			// We can get this on a friend we already know about if they accept a friendship invitation (or we do)
			// This should have the effect of moving groups from FoF to Online or Offline friend group.
			[fr retain];
			[[self session] removeFriend:fr];
			[fr setIsFriendOfFriend:NO];
			[[self session] addFriend:fr];
			[fr release];
			
			[[self session] delegate_friendDidChange:fr attribute:kXfireFriendWasAdded];
		}
		else if ([fr isClanMember])
		{ // friend is a friend AND a clan member
			[fr setIsDirectFriend:YES]; // why else would they be in the friends list packet?
			[fr setNickName:[nicknames objectAtIndex:i]];
			[[self session] addFriend:fr];
			[[self session] delegate_friendDidChange:fr attribute:kXfireFriendWasAdded];
		}
	}
}

// Contains a list of userids and session IDs
// Tells us who is online and offline
// Contains information:
//   int[]   User IDs  (userid)
//   uuid[]  Session IDs (sid)
- (void)processSessionIDPacket:(XfirePacket *)pkt
{	
	NSArray *userids;
	NSArray *sessionids;
	XfireFriend *fr;
	NSData *sid;
	NSNumber *uid;
	BOOL isCurrentlyOnline;
	XfireFriendGroupController *groupCtl = [[self session] friendGroupController];
	
	int i, cnt;
	
	userids    = [pkt attributeValuesForKey:@"0x01"];
	sessionids = [pkt attributeValuesForKey:@"0x03"];
	
	cnt = [userids count];
	for( i = 0; i < cnt; i++ )
	{
		uid = [userids objectAtIndex:i];
		sid = [sessionids objectAtIndex:i];
		
		fr = [[self session] friendForUserID:[uid unsignedIntValue]];
		if( fr )
		{
			isCurrentlyOnline = [fr isOnline];
			
			[fr setSessionID:sid];
			if( [sid isClear] )
			{
				if( isCurrentlyOnline )
				{
					[self raiseFriendNotification:fr attribute:kXfireFriendOnlineStatusWillChange];
				}
				
				[fr setIsOnline:NO];
				
				// clear out the XfireFriend status and game info
				[fr setPublicIP:0];
				[fr setPublicPort:0];
				[fr setStatusString:nil];
				[fr setGameID:0];
				[fr setGameIPAddress:0];
				[fr setGamePort:0];
				
				if( isCurrentlyOnline )
				{
					[groupCtl friendWentOffline:fr];
					[self raiseFriendNotification:fr attribute:kXfireFriendOnlineStatusDidChange];
				}
			}
			else
			{
				if( !isCurrentlyOnline )
				{
					[self raiseFriendNotification:fr attribute:kXfireFriendOnlineStatusWillChange];
					[fr setIsOnline:YES];
					[groupCtl friendCameOnline:fr];
					[self raiseFriendNotification:fr attribute:kXfireFriendOnlineStatusDidChange];
				}
			}
		}
	}
}

// Contains a list of status strings for a given user's session
// Contains information:
//   uuid[]  Session IDs (sid)
//   str[]   Message String (msg)
- (void)processFriendStatusPacket:(XfirePacket *)pkt
{
	NSArray *sessionids;
	NSArray *msgs;
	XfireFriend *fr;
	NSData *sid;
	NSString *msg;
	
	int i, cnt;
	
	sessionids  = [pkt attributeValuesForKey:kXfireAttributeSessionIDKey];
	msgs        = [pkt attributeValuesForKey:kXfireAttributeMessageKey];
	
	cnt = [sessionids count];
	for( i = 0; i < cnt; i++ )
	{
		sid = [sessionids objectAtIndex:i];
		msg = [msgs objectAtIndex:i];
		
		fr = [[self session] friendForSessionID:sid];
		if( fr )
		{
			[fr setStatusString:msg];
			[self raiseFriendNotification:fr attribute:kXfireFriendStatusStringDidChange];
		}
	}
}

// Contains game ID, IP, and port information for a given user
// This represents status-changed message
// Contains information:
//   uuid[]  Session IDs  (sid)
//   int[]   Game ID      (gameid)
//   int[]   Game IP addr (gip)
//   int[]   Game Port    (gport)
// Anyone that is not on our friends list, we will request FoF information if allowed
- (void)processGameStatusPacket:(XfirePacket *)pkt
{
	NSArray *sessionIDs;
	NSArray *gameIDs;
	NSArray *gameIPAddrs;
	NSArray *gamePorts;
	XfireFriend *fr;
	
	NSMutableArray *unknownSids = [NSMutableArray array];
	
	NSData      *sid;
	NSNumber    *gid;
	NSNumber    *gip;
	NSNumber    *gport;
	
	int i, cnt;
	
	sessionIDs  = [pkt attributeValuesForKey:kXfireAttributeSessionIDKey];
	gameIDs     = [pkt attributeValuesForKey:kXfireAttributeGameIDKey];
	gameIPAddrs = [pkt attributeValuesForKey:kXfireAttributeGameIPKey];
	gamePorts   = [pkt attributeValuesForKey:kXfireAttributeGamePortKey];
	
	cnt = [sessionIDs count];
	for( i = 0; i < cnt; i++ )
	{
		sid = [sessionIDs objectAtIndex:i];
		gid = [gameIDs objectAtIndex:i];
		gip = [gameIPAddrs objectAtIndex:i];
		gport = [gamePorts objectAtIndex:i];
		
		fr = [[self session] friendForSessionID:sid];
		if( fr )
		{
			// Did a FoF leave a game?  If so, remove from our FoF list
			if( ([gid unsignedIntValue] == 0) && [fr isFriendOfFriend] )
			{
				[[fr retain] autorelease];
				[fr setIsOnline:NO];
				[[self session] removeFriend:fr];
				
				[self raiseFriendNotification:fr attribute:kXfireFriendWasRemoved];
			}
			else
			{
				[fr setGameID:[gid unsignedIntValue]];
				[fr setGameIPAddress:[gip unsignedIntValue]];
				[fr setGamePort:([gport unsignedIntValue] & 0x0000FFFF)]; // this seems to be a packed value; not sure what the upper half is yet
				
				[self raiseFriendNotification:fr attribute:kXfireFriendGameInfoDidChange];
			}
		}
		else
		{
			// We can get additional notifications on a given FoF before we know who they are
			// (before we've gotten the info for FoF).  If so, update the info, otherwise we end up
			// with 2 or more instances of a given FoF in the list.  We won't send a FoF request for this
			// person again since we've already sent one.  This may result in canceling a pending
			// friend, if the person comes online and goes offline quickly.  Let's kill the pending FoF.
			fr = [[self session] pendingFriendForSessionID:sid];
			if( fr )
			{
				if( [gid unsignedIntValue] != 0 )
				{
					// change info.
					[fr setGameID:[gid unsignedIntValue]];
					[fr setGameIPAddress:[gip unsignedIntValue]];
					[fr setGamePort:([gport unsignedIntValue] & 0x0000FFFF)];
				}
				else
				{
					[[self session] removePendingFriend:fr];
				}
			}
			else
			{
				// Add a pending friend (FoF)
				[unknownSids addObject:sid];
				
				fr = [[XfireFriend alloc] init];
				[fr setSessionID:sid];
				[fr setGameID:[gid unsignedIntValue]];
				[fr setGameIPAddress:[gip unsignedIntValue]];
				[fr setGamePort:([gport unsignedIntValue] & 0x0000FFFF)]; // this seems to be a packed value; not sure what the upper half is yet
				[[self session] addPendingFriend:fr];
				[fr release];
				fr = nil;
			}
		}
	}
	
	// Some Session IDs were unknown.  These correspond to Friends of Friends
	// Request that information if the user requests it
	if( ([unknownSids count] > 0) && [[self session] shouldShowFriendsOfFriends] )
	{
		XfirePacket *sendPkt = [XfireMutablePacket friendOfFriendRequestPacketWithSIDs:unknownSids];
		[self sendPacketSafe:sendPkt];
	}
}

// Contains information about our friends-of-friends
// Contains information:
//   uuid[]  Session IDs    (fnsid)
//   int[]   User IDs       (userid)
//   str[]   User Names     (name)
//   str[]   Nick names     (nick)
//   int[][] Mutual Friends (friends)
// Ignore mutual friends for now
- (void)processFriendOfFriendPacket:(XfirePacket *)pkt
{
	NSArray *sessionIDs;
	NSArray *userIDs;
	NSArray *userNames;
	NSArray *nickNames;
	NSArray *commonFriends;
	
	int i, j, cnt;
	
	NSData   *sid;
	NSNumber *userID;
	NSString *username;
	NSString *nickname;
	NSArray  *common;
	
	XfireFriend *fr;
	
	sessionIDs = [pkt attributeValuesForKey:kXfireAttributeFriendSIDKey];
	userIDs = [pkt attributeValuesForKey:kXfireAttributeUserIDKey];
	userNames = [pkt attributeValuesForKey:kXfireAttributeNameKey];
	nickNames = [pkt attributeValuesForKey:kXfireAttributeNicknameKey];
	commonFriends = [pkt attributeValuesForKey:kXfireAttributeFriendsKey];
	
	cnt = [sessionIDs count];
	for( i = 0; i < cnt; i++ )
	{
		sid = [sessionIDs objectAtIndex:i];
		userID = [userIDs objectAtIndex:i];
		username = [userNames objectAtIndex:i];
		nickname = [nickNames objectAtIndex:i];
		common = [commonFriends objectAtIndex:i]; // it's an array of XfirePacketAttributeValue objects containing NSNumbers
		
		// Can be 0 if this person went offline, I think
		if( [username length] > 0 )
		{
			fr = [[self session] pendingFriendForSessionID:sid];
			if( fr )
			{
				[fr setUserID:[userID unsignedIntValue]];
				[fr setUserName:username];
				[fr setNickName:nickname];
				[fr setIsOnline:YES];
				[fr setIsFriendOfFriend:YES];
				
				for( j = 0; j < [common count]; j++ )
				{
					[fr addCommonFriendID:(NSNumber *)[(XfirePacketAttributeValue *)[common objectAtIndex:j] attributeValue]];
				}
				
				// move from pending to actual
				[[self session] addFriend:fr];
				[[self session] removePendingFriend:fr];
				[[self session] delegate_friendDidChange:fr attribute:kXfireFriendWasAdded];
			}
			// else no such friend with this SID ... not sure what happened ... ignore it
			else
			{
				DebugLog(@"Friend of friend packet with unknown SID (username = %@)",username);
			}
		}
		// else the username is invalid ... the person probably just left a game ... ignore it
	}
}

- (void)processNicknameChangePacket:(XfirePacket *)pkt
{
	NSArray *userIDs;
	NSArray *nickNames;
	
	int i, cnt;
	
	NSNumber *userID;
	NSString *nickname;
	
	userIDs   = [pkt attributeValuesForKey:@"0x01"];
	nickNames = [pkt attributeValuesForKey:@"0x0d"];
	
	cnt = [userIDs count];
	for( i = 0; i < cnt; i++ )
	{
		unsigned int uid;
		XfireFriend *fr;
		
		userID = [userIDs objectAtIndex:i];
		nickname = [nickNames objectAtIndex:i];
		uid = [userID unsignedIntValue];
		
		// check if it's a friend
		fr = [[self session] friendForUserID:uid];
		if( fr )
		{
			[fr setNickName:nickname];
			[self raiseFriendNotification:fr attribute:kXfireFriendNicknameDidChange];
		}
		
		// check if it's us, too
		fr = [[self session] loginIdentity];
		if( [fr userID] == uid )
		{
			[fr setNickName:nickname];
			[[self session] delegate_nicknameDidChange:nickname];
		}
	}
}

- (void)processSearchResultsPacket:(XfirePacket *)pkt
{
	NSArray *userNames;
	NSArray *firstNames;
	NSArray *lastNames;
	
	int i, cnt;
	
	NSMutableArray *friends = [NSMutableArray array];
	XfireFriend *fr;
	
	userNames = [pkt attributeValuesForKey:kXfireAttributeNameKey];
	firstNames = [pkt attributeValuesForKey:kXfireAttributeFirstNameKey];
	lastNames = [pkt attributeValuesForKey:kXfireAttributeLastNameKey];
	
	cnt = [userNames count];
	for( i = 0; i < cnt; i++ )
	{
		fr = [[XfireFriend alloc] init];
		
		[fr setUserName:[userNames objectAtIndex:i]];
		[fr setFirstName:[firstNames objectAtIndex:i]];
		[fr setLastName:[lastNames objectAtIndex:i]];
		
		[friends addObject:fr];
		[fr release];
	}
	
	[[self session] delegate_searchResults:friends];
}

- (void)processRemoveFriendPacket:(XfirePacket *)pkt
{
	NSArray *userIDs;
	XfireFriend *fr;
	XfireSession *sess;
	
	int i, cnt;
	
	NSNumber *userID;
	
	userIDs = [pkt attributeValuesForKey:kXfireAttributeUserIDKey];
	sess = [self session];
	
	cnt = [userIDs count];
	for( i = 0; i < cnt; i++ )
	{
		userID = [userIDs objectAtIndex:i];
		fr = [sess friendForUserID:[userID unsignedIntValue]];
		if( fr )
		{
			[[fr retain] autorelease]; // make sure it stays around for a little while longer
			
			[sess removeFriend:fr];
			[fr setIsDirectFriend:NO];
			[self raiseFriendNotification:fr attribute:kXfireFriendWasRemoved];
		}
	}
}

- (void)processFriendRequestPacket:(XfirePacket *)pkt
{
	NSArray *userNames;
	NSArray *nickNames;
	NSArray *messages;
	
	int i, cnt;
	
	NSMutableArray *friends = [NSMutableArray array];
	XfireFriend *fr;
	
	userNames = [pkt attributeValuesForKey:kXfireAttributeNameKey];
	nickNames = [pkt attributeValuesForKey:kXfireAttributeNicknameKey];
	messages  = [pkt attributeValuesForKey:kXfireAttributeMessageKey];
	
	cnt = [userNames count];
	for( i = 0; i < cnt; i++ )
	{
		fr = [[XfireFriend alloc] init];
		
		[fr setUserName:[userNames objectAtIndex:i]];
		[fr setNickName:[nickNames objectAtIndex:i]];
		[fr setStatusString:[messages objectAtIndex:i]];
		
		[friends addObject:fr];
		[fr release];
	}
	
	[[self session] delegate_didReceiveFriendshipRequests:friends];
}

- (void)processFriendGroupNamePacket:(XfirePacket *)pkt
{
	NSArray *groupIDs;
	NSArray *groupNames;
	XfireFriendGroupController *ctl = [[self session] friendGroupController];
	
	int i, cnt;
	
	NSNumber *groupID;
	NSString *groupName;
	
	groupIDs   = [pkt attributeValuesForKey:@"0x19"];
	groupNames = [pkt attributeValuesForKey:@"0x1a"];
	
	cnt = [groupIDs count];
	for( i = 0; i < cnt; i++ )
	{
		groupID   = [groupIDs objectAtIndex:i];
		groupName = [groupNames objectAtIndex:i];
		
		[ctl addCustomGroupNamed:groupName withID:[groupID intValue]];
	}
}

- (void)processFriendGroupMemberPacket:(XfirePacket *)pkt
{
	NSArray *userIDs;
	NSArray *groupIDs;
	XfireFriendGroupController *ctl = [[self session] friendGroupController];
	
	int i, cnt;
	
	NSNumber *groupID;
	NSNumber *userID;
	
	userIDs    = [pkt attributeValuesForKey:@"0x01"];
	groupIDs   = [pkt attributeValuesForKey:@"0x19"];
	
	cnt = [userIDs count];
	for( i = 0; i < cnt; i++ )
	{
		groupID  = [groupIDs objectAtIndex:i];
		userID   = [userIDs objectAtIndex:i];
		
		[ctl addPendingMemberID:[userID unsignedIntValue] groupID:[groupID unsignedIntValue]];
	}
}

/*
	This packet (ID 163) contains 3 keys with integer array values.
	Key 0x19 is the group ID.
	Key 0x34 appears to be a type (best guess).  0 = custom, 2 = dynamic
	Key 0x12 is unknown.
	
	Keys 0x34 and 0x12 are ignored for now.
	
	It is not known what the purpose of the values are in this packet, as it can be empty.
*/
- (void)processFriendGroupListPacket:(XfirePacket *)pkt
{
#if 0
	NSArray *groupIDs;
	XfireFriendGroupController *ctl = [[self session] friendGroupController];
	
	groupIDs   = [pkt attributeValuesForKey:@"0x19"];
	
	[ctl setGroupList:groupIDs];
#endif
}

- (void)processUserOptionsPacket:(XfirePacket *)pkt
{
	NSArray *maps = [pkt attributeValuesForKey:@"0x4c"];
	if( [maps count] != 1 )
		return;
	
	XfirePacketAttributeMap *map = [maps objectAtIndex:0];
	if( !map || ![map isKindOfClass:[XfirePacketAttributeMap class]])
	{
		DebugLog(@"Got something unexpected: %@",map);
		return;
	}
	
	NSMutableDictionary *options = [[[XfireSession defaultUserOptions] mutableCopy] autorelease];
	
	_XfireCopyPreference( @"0x01", kXfireShowMyFriendsOption, map, options );
	_XfireCopyPreference( @"0x02", kXfireShowMyGameServerDataOption, map, options );
	_XfireCopyPreference( @"0x03", kXfireShowOnMyProfileOption, map, options );
	_XfireCopyPreference( @"0x06", kXfireShowChatTimeStampsOption, map, options );
	_XfireCopyPreference( @"0x08", kXfireShowFriendsOfFriendsOption, map, options );
	_XfireCopyPreference( @"0x09", kXfireShowMyOfflineFriendsOption, map, options );
	_XfireCopyPreference( @"0x0a", kXfireShowNicknamesOption, map, options );
	_XfireCopyPreference( @"0x0b", kXfireShowVoiceChatServerOption, map, options );
	_XfireCopyPreference( @"0x0c", kXfireShowWhenITypeOption, map, options );
	
	// As far as I know, we only get this at login and possibly when explicitly setting
	// options, so not triggering notifications should be ok in all cases.
	[[self session] _privateSetUserOptions:options];
	
	// Now that we know the user's preferences, enable the customizable groups
	[[[self session] friendGroupController] ensureStandardGroup:kXfireFriendGroupOnline];
	if( [[self session] shouldShowFriendsOfFriends] )
		[[[self session] friendGroupController] ensureStandardGroup:kXfireFriendGroupFriendOfFriends];
	if( [[self session] shouldShowOfflineFriends] )
		[[[self session] friendGroupController] ensureStandardGroup:kXfireFriendGroupOffline];
}

- (void)processChatMessagePacket:(XfirePacket *)pkt
{
	NSData *sid = (NSData *)[[pkt attributeForKey:kXfireAttributeSessionIDKey] attributeValue];
	XfireChat *chat = [[self session] chatForSessionID:sid];
	
	// no open chat yet, create one
	if( chat == nil )
	{
		XfireFriend *fr;
		
		fr = [[self session] friendForSessionID:sid];
		if( !fr )
		{
			// ?? can we get chat messages from someone we don't know their SID ??
			return;
		}
		
		// get a new chat object
		// this asks the session delegate for an appropriate chat delegate
		chat = [[self session] beginChatWithFriend:fr];
	}
	
	// chat object handles the message and acknowledgements
	// the chat has its own delegate
	[chat receivePacket:pkt];
}

- (void)processDisconnectPacket:(XfirePacket *)pkt
{
	NSNumber * reason = (NSNumber *)[[pkt attributeForKey:kXfireAttributeReasonKey] attributeValue];
	if( [reason intValue] == 1 )
	{
		[[self session] delegate_sessionWillDisconnect:kXfireOtherSessionReason];
	}
	else
	{
		[[self session] delegate_sessionWillDisconnect:kXfireServerHungUpReason];
	}
	
	[[self session] disconnect];
}

- (void)processKeepAliveResponse:(XfirePacket *)pkt
{
	[_keepAliveResponseTimer invalidate];
	_keepAliveResponseTimer = nil;
}

- (void)processScreenshotsInfo:(XfirePacket *)pkt
{
	NSNumber *userID = (NSNumber *)[[pkt attributeForKey:@"0x01"] attributeValue];
	XfireFriend *friend = [[self session] friendForUserID:[userID unsignedIntValue]];
	NSArray *screenshotIndexes = [pkt attributeValuesForKey:@"0x5c"];
	NSArray *gameIDs = [pkt attributeValuesForKey:@"0x21"];
	NSArray *descriptions = [pkt attributeValuesForKey:@"0x54"];
	
	NSMutableDictionary *screenshots = [[NSMutableDictionary alloc] init];

	for (NSNumber *gameID in gameIDs)
	{
		NSMutableArray *screenshotArray = [NSMutableArray array];
		[screenshots setObject:screenshotArray forKey:[NSString stringWithFormat:@"%d", [gameID intValue]]];
	}
	
	if ([[screenshots allKeys] count])
	{
		for (NSUInteger i = 0; i < [screenshotIndexes count]; i++)
		{
			NSNumber *screenshotIndex = [screenshotIndexes objectAtIndex:i];
			NSNumber *gameID = [gameIDs objectAtIndex:i];
			NSString *description = [descriptions objectAtIndex:i];
			
			XfireScreenshot *screenshot = [[XfireScreenshot alloc] initWithIndex:screenshotIndex
																		  gameID:gameID
																	 description:description];
			[[screenshots objectForKey:[NSString stringWithFormat:@"%d", [gameID intValue]]] addObject:screenshot];
			[screenshot release], screenshot = nil;
		}
		
		[friend setScreenshots:screenshots];
	}
	
	[screenshots release];
}

- (void)processFriendInfoChanged:(XfirePacket *)pkt
{
	NSNumber *userID = (NSNumber *)[[pkt attributeForKey:@"0x01"] attributeValue];
	XfireFriend *friend = [[self session] friendForUserID:[userID unsignedIntValue]];
	[[self session] requestInfoViewInfoForFriend:friend];
}

- (void)processFriendAvatarPacket:(XfirePacket *)pkt
{
	NSNumber *userID = (NSNumber *)[[pkt attributeForKey:@"0x01"] attributeValue];
	
	XfireFriend *friend = [[self session] friendForUserID:[userID unsignedIntValue]];
	
	const int avatarType = [(NSNumber *)[[pkt attributeForKey:@"0x34"] attributeValue] intValue];
	const int avatarNumber = [(NSNumber *)[[pkt attributeForKey:@"0x1f"] attributeValue] intValue];
	
	NSURL *avatarURL = nil;
	
	switch (avatarType)
	{
		case 00:
			avatarURL = [NSURL URLWithString:[NSString stringWithFormat:DEFAULT_AVATAR_URL]];
			break;
		case 01:
			avatarURL = [NSURL URLWithString:[NSString stringWithFormat:GALLERY_AVATAR_URL, avatarNumber]];
			break;
		case 02:
			avatarURL = [NSURL URLWithString:[NSString stringWithFormat:CUSTOM_AVATAR_URL, [friend userName], avatarNumber]];
			break;
		case 03:
			avatarURL = [NSURL URLWithString:[NSString stringWithFormat:DEFAULT_AVATAR_URL]];
			break;
		default:
			avatarURL = [NSURL URLWithString:[NSString stringWithFormat:DEFAULT_AVATAR_URL]];
			break;
	}
	
	[friend setAvatarURL:avatarURL];
	[self raiseFriendNotification:friend attribute:kXfireFriendAvatarInfoPacketDidArrive];
}

- (void)processClanListPacket:(XfirePacket *)pkt
{	
	NSArray *clanIDs = [pkt attributeValuesForKey:@"0x6c"];
	NSArray *clanLongNames = [pkt attributeValuesForKey:@"0x02"];
	NSArray *clanShortNames = [pkt attributeValuesForKey:@"0x72"];
	
	for (NSUInteger i = 0; i < [clanIDs count]; i++)
	{
		NSNumber *clanID = [clanIDs objectAtIndex:i];
		NSString *clanLongName = [clanLongNames objectAtIndex:i];
		NSString *clanShortName = [clanShortNames objectAtIndex:i];
		
		XfireFriendGroup *clan = [[[_session friendGroupController] clans] groupForID:[clanID intValue]];
		
		if (clan)
		{
			[clan setGroupName:clanLongName];
			[clan setShortName:clanShortName];
			[_session delegate_friendGroupDidChange:clan];
		}
		else
		{
			[[_session friendGroupController] addClanWithID:[clanID intValue] name:clanLongName shortName:clanShortName];
		}
	}
}

- (void)processClanMembersPacket:(XfirePacket *)pkt
{
	NSNumber *clanID = (NSNumber *)[[pkt attributeForKey:@"0x6c"] attributeValue];
	NSArray *userIDs = [pkt attributeValuesForKey:@"0x01"];
	NSArray *userNames = [pkt attributeValuesForKey:@"0x02"];
	//NSArray *nickNames = [pkt attributeValuesForKey:@"0x0d"];
	NSArray *clanNicknames = [pkt attributeValuesForKey:@"0x6d"];
	
	for (NSUInteger i = 0; i < [userIDs count]; i++)
	{
		NSNumber *userID = [userIDs objectAtIndex:i];
		NSString *userName = [userNames objectAtIndex:i];
		NSString *clanNickname = [clanNicknames objectAtIndex:i];
		
		XfireFriend *clanMember = [_session friendForUserID:[userID unsignedIntValue]];
		if (!clanMember)
		{
			clanMember = [[[XfireFriend alloc] init] autorelease];
		}
		
		[clanMember setUserID:[userID unsignedIntValue]];
		[clanMember setIsClanMember:YES];
		[clanMember setClanID:[clanID intValue]];
		[clanMember setUserName:userName];
		[clanMember setClanNickname:clanNickname forKey:[[[[_session friendGroupController] groups] groupForID:[clanID intValue]] shortName]];
		
		[_session addFriend:clanMember];
		//[_session addClanMember:clanMember];
		[[_session friendGroupController] addFriend:clanMember toGroupWithID:[clanID intValue]];
	}
}

- (void)processClanMemberLeftClanPacket:(XfirePacket *)pkt
{
	NSNumber *clanID = (NSNumber *)[[pkt attributeForKey:@"0x6c"] attributeValue];
	NSNumber *userID = (NSNumber *)[[pkt attributeForKey:@"0x01"] attributeValue];
	
	XfireFriendGroupController *grpCtrl = [_session friendGroupController];
	XfireFriendGroup *clan = [[grpCtrl groups] groupForID:[clanID intValue]];
	XfireFriend *clanMember = [_session friendForUserID:[userID unsignedIntValue]];
	
	if ([userID intValue] == [[_session loginIdentity] userID])
	{	//current user left the clan
		[[_session friendGroupController] removeGroup:clan];
	}
	else
	{	//clan member left the clan
		[grpCtrl removeFriend:clanMember fromGroup:clan];
	}
}

- (void)processClanMemberChangedNicknamePacket:(XfirePacket *)pkt
{
	NSNumber *clanID = (NSNumber *)[[pkt attributeForKey:@"0x6c"] attributeValue];
	NSNumber *userID = (NSNumber *)[[pkt attributeForKey:@"0x01"] attributeValue];
	NSString *newClanNickname = [[pkt attributeForKey:@"0x0d"] attributeValue];
	
	XfireFriend *clanMember = [_session friendForUserID:[userID unsignedIntValue]];
	
	if (clanMember)
	{
		[clanMember setClanNickname:newClanNickname forKey:[[[[_session friendGroupController] groups] groupForID:[clanID intValue]] shortName]];
		[_session delegate_friendDidChange:clanMember attribute:kXfireFriendNicknameDidChange];
	}
}

- (void)processClanEventsPacket:(XfirePacket *)pkt
{
	DebugLog(@"Clan Events Packet: %@", pkt);
}

- (void)processClanEventDeletedPacket:(XfirePacket *)pkt
{
	DebugLog(@"Clan Event Deleted Packet: %@", pkt);
}

- (void)processClanNewsPostedPacket:(XfirePacket *)pkt
{
	DebugLog(@"Clan News Posted Packet: %@", pkt);
}

- (void)processChatRoomJoinPacket:(XfirePacket *)pkt
{
	NSData *chatRoomSID = (NSData *)[[pkt attributeForKey:@"0x04"] attributeValue];
	XfireChatRoom *chatRoom = [_session chatRoomForSessionID:chatRoomSID];
	
	if (chatRoom)
		return; // already in that chat...
	
	XFGroupChatJoinResponse joinResponse = [(NSNumber *)[[pkt attributeForKey:@"0x0c"] attributeValue] intValue];
	
	if (joinResponse == XFGroupChatIncorrectPassword)
	{
		[_session delegate_joinChatRoomInvalidPassword];
		return;
	}
	else if (joinResponse == XFGroupChatRequiresPassword)
	{
		[_session delegate_joinChatRoomPasswordRequired];
		return;
	}
	
	chatRoom = [[[XfireChatRoom alloc] init] autorelease];
	
	//NSNumber *chatRoomResponse = (NSNumber *)[[pkt attributeForKey:@"0x0c"] value];
	
	[chatRoom setGroupChatSID:chatRoomSID];
	[chatRoom setName:[[pkt attributeForKey:@"0x05"] attributeValue]];
	[chatRoom setMessageOfTheDay:[[pkt attributeForKey:@"0x4d"] attributeValue]];
	[chatRoom setDefaultPermissionLevel:[(NSNumber *)[[pkt attributeForKey:@"0x12"] attributeValue] intValue]];
	[chatRoom setChatRoomAccess:[(NSNumber *)[[pkt attributeForKey:@"0x17"] attributeValue] intValue]];
	[chatRoom setSession:_session];
	
	[_session delegate_didJoinChatRoom:chatRoom];
}

- (void)processChatRoomInfoPacket:(XfirePacket *)pkt
{
	NSData *chatRoomSID = (NSData *)[[pkt attributeForKey:@"0x04"] attributeValue];
	
	XfireChatRoom *chatRoom = [_session chatRoomForSessionID:chatRoomSID];
	
	if (!chatRoom)
		return;
	
	NSArray *userIDs = [pkt attributeValuesForKey:@"0x33"];	
	//NSArray *chatPermissionLevels = [pkt attributeValuesForKey:@"0x44"];
	NSArray *usernames = [pkt attributeValuesForKey:@"0x42"];
	NSArray *nicknames = [pkt attributeValuesForKey:@"0x43"];
	
	NSMutableSet *chatUsers = [NSMutableSet set];
	
	for (NSUInteger i = 0; i < [userIDs count]; i++)
	{
		NSNumber *userID = [userIDs objectAtIndex:i];
		NSString *username = [usernames objectAtIndex:i];
		NSString *nickname = [nicknames objectAtIndex:i];
		//NSNumber *chatPermissionLevel = [chatPermissionLevels objectAtIndex:i];
		
		XfireFriend *friend = [_session friendForUserID:[userID intValue]];
		if (!friend)
		{
			friend = [[[XfireFriend alloc] init] autorelease];
			[friend setUserID:[userID unsignedIntValue]];
			[friend setUserName:username];
			[friend setNickName:nickname];
			//[friend setGroupChatPermissionLevel:[chatPermissionLevel intValue]];
		}
		
		[chatUsers addObject:friend];
	}
	
	if ([chatUsers count] > 0)
		[chatRoom setUsers:chatUsers];
	
	[_session delegate_updatedInfoForChatRoom:chatRoom];
}

- (void)processChatRoomUserJoinedPacket:(XfirePacket *)pkt
{
	XfireChatRoom *chatRoom = [_session chatRoomForSessionID:(NSData *)[[pkt attributeForKey:@"0x04"] attributeValue]];
	if (!chatRoom)
		return; // if we don't have a chat room for this SID, then we can't add a user to it, so ignore.
	
	[chatRoom processChatRoomUserJoinedPacket:pkt];
}

- (void)processChatRoomUserLeftPacket:(XfirePacket *)pkt
{
	XfireChatRoom *chatRoom = [_session chatRoomForSessionID:(NSData *)[[pkt attributeForKey:@"0x04"] attributeValue]];
	if (!chatRoom)
		return;
	
	[chatRoom processChatRoomUserLeftPacket:pkt];
}

- (void)processChatRoomReceivedMessagePacket:(XfirePacket *)pkt
{
	XfireChatRoom *chatRoom = [_session chatRoomForSessionID:(NSData *)[[pkt attributeForKey:@"0x04"] attributeValue]];
	if (!chatRoom)
		return;
	
	[chatRoom processChatRoomReceivedMessagePacket:pkt];
}

- (void)processChatRoomInvitePacket:(XfirePacket *)pkt
{
	NSData *groupChatSID = (NSData *)[[pkt attributeForKey:@"0x04"] attributeValue];
	
	XfireChatRoom *chatRoom = [_session chatRoomForSessionID:groupChatSID];
	
	if (chatRoom)
		return; // chat room already exists, so we must already be in it.
	
	// create it if its not found
	chatRoom = [[[XfireChatRoom alloc] init] autorelease];
	
	[chatRoom setGroupChatSID:groupChatSID];
	[chatRoom setName:[[pkt attributeForKey:@"0x05"] attributeValue]];
	[chatRoom setChatRoomAccess:[(NSNumber *)[[pkt attributeForKey:@"0x17"] attributeValue] intValue]];
	[chatRoom setSession:_session];
	
	NSNumber *userID = (NSNumber *)[[pkt attributeForKey:@"0x01"] attributeValue];
	
	XfireFriend *friend = [[_session friendForUserID:[userID unsignedIntValue]] retain];
	if (!friend)
	{
		friend = [[XfireFriend alloc] init];
		[friend setUserID:[userID unsignedIntValue]];
		[friend setUserName:[[pkt attributeForKey:@"0x02"] attributeValue]];
		[friend setNickName:[[pkt attributeForKey:@"0x0d"] attributeValue]];
	}
	
	[_session delegate_receivedChatRoomInviteFrom:friend forChatRoom:chatRoom];
	[friend release];
}

- (void)processChatRoomUserKickedPacket:(XfirePacket *)pkt
{
	XfireChatRoom *chatRoom = [_session chatRoomForSessionID:(NSData *)[[pkt attributeForKey:@"0x04"] attributeValue]];
	if (!chatRoom)
		return;
	
	XfireFriend *friend = [chatRoom userForUserID:[(NSNumber *)[[pkt attributeForKey:@"0x18"] attributeValue] unsignedIntValue]];
	
	[_session delegate_user:friend kickedFromChatRoom:chatRoom];
}

@end

void _XfireCopyPreference( NSString *pktKey, NSString *dictKey, XfirePacketAttributeMap *map, NSMutableDictionary *dictionary )
{
	NSString *pktStr = [[map objectForKey:pktKey] attributeValue];
	if( pktStr )
	{
		NSNumber *dctVal = [dictionary objectForKey:dictKey];
		if( dctVal )
		{
			BOOL     pktVal = ([pktStr intValue] != 0);
			BOOL     val = [dctVal boolValue];
			
			if( pktVal != val )
			{
				[dictionary setObject:[NSNumber numberWithBool:pktVal] forKey:dictKey];
			}
		}
	}
}
