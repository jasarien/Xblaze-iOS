/*******************************************************************
	FILE:		XfirePacket.m
	
	COPYRIGHT:
		Copyright 2007-2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Represents an individual packet.  Also includes implementation
		of mutable packets, which are used by the sending logic
		elsewhere in the library.
	
	HISTORY:
		2008 05 17  Added helper method to stuff values into an array
		            even if the packet has only a single value.
		2008 04 06  Changed copyright to BSD license.
		2008 03 01  Added user search packet.
		2008 01 12  Added game status packet and copyright notice.
		2007 10 13  Created.
*******************************************************************/

#import "XfirePacket.h"

#import "NSData_XfireAdditions.h"
#import "NSMutableData_XfireAdditions.h"

#import "XfirePacketScanner.h"
#import "XfirePacketGenerator.h"
#import "XfirePacketAttributeValue.h"
#import "XfirePacketAttributeMap.h"
#import "XfireChatRoom.h"
#import "XfireFriend.h"

@interface XfirePacket (Private)
- (id)initWithID:(XfirePacketID)pktID attributeMap:(XfirePacketAttributeMap *)attrs raw:(NSData *)raw;
@end

NSString* kXfireAttributeChecksumKey		= @"checksum";
NSString* kXfireAttributeChunksKey			= @"chunks";
NSString* kXfireAttributeEmailKey           = @"email";
NSString* kXfireAttributeFirstNameKey       = @"fname";
NSString* kXfireAttributeFlagsKey			= @"flags";
NSString* kXfireAttributeFriendsKey         = @"friends";
NSString* kXfireAttributeFriendSIDKey       = @"fnsid";
NSString* kXfireAttributeGameIDKey          = @"gameid";
NSString* kXfireAttributeGameIPKey          = @"gip";
NSString* kXfireAttributeGamePortKey        = @"gport";
NSString* kXfireAttributeIMKey				= @"im";
NSString* kXfireAttributeIMIndexKey         = @"imindex";
NSString* kXfireAttributeTypingKey			= @"typing";
NSString* kXfireAttributeLanguageKey        = @"lang";
NSString* kXfireAttributeLastNameKey        = @"lname";
NSString* kXfireAttributeMessageKey         = @"msg";
NSString* kXfireAttributeMsgTypeKey         = @"msgtype";
NSString* kXfireAttributeNameKey            = @"name";
NSString* kXfireAttributeNicknameKey        = @"nick";
NSString* kXfireAttributePartnerKey			= @"partner";
NSString* kXfireAttributePasswordKey        = @"password";
NSString* kXfireAttributePeerMessageKey     = @"peermsg";
NSString* kXfireAttributeReasonKey          = @"reason";
NSString* kXfireAttributeSaltKey            = @"salt";
NSString* kXfireAttributeSessionIDKey       = @"sid";
NSString* kXfireAttributeSkinKey            = @"skin";
NSString* kXfireAttributeStatisticsKey		= @"stats";
NSString* kXfireAttributeStatusKey          = @"status";
NSString* kXfireAttributeThemeKey           = @"theme";
NSString* kXfireAttributeUserIDKey          = @"userid";
NSString* kXfireAttributeValueKey			= @"value";
NSString* kXfireAttributeVersionKey         = @"version";
NSString *kXfireAttributeAvatarTypeKey		= @"avatartype";
NSString *kXfireAttributeAvatarNumberKey	= @"avatarnumber";

NSString* kXfireAttributeCommandKey         = @"command";
NSString* kXfireAttributeDownloadSetKey     = @"dlset";
NSString* kXfireAttributeFileKey            = @"file";
NSString* kXfireAttributeFileIDKey          = @"fileid";
NSString* kXfireAttributePrefsKey           = @"prefs";
NSString* kXfireAttributeResultKey          = @"result";
NSString* kXfireAttributeStatusTextKey      = @"t";
NSString* kXfireAttributeTypeKey            = @"type";

/*
checksum chunks clientip climsg clntset conn ctry
did dlset
fileid fileids flags friends
gameid gcd gip gport
ip
lang localip localport
max maxrect minrect msg
name nat naterr nick n1 n2 n3
origin
partner password pip port p2pset
salt sec skin sid status
theme
upnpinfo userid version
withheld
*/





@implementation XfirePacket

// decode the raw data and build a new packet
+ (XfirePacket *)decodedPacketByScanningBuffer:(NSData *)data
{
	if( data && ([data length] >= 5) )
	{
		XfirePacketScanner *scanner = [XfirePacketScanner scannerWithData:data];
		XfirePacketAttributeMap *attrs;
		unsigned int packetID;
		
		@try
		{
			if( [scanner scan:&packetID attributes:&attrs] )
			{
				return [[[XfirePacket alloc] initWithID:packetID attributeMap:attrs raw:data] autorelease];
			}
		}
		@catch( NSException *e )
		{
			DebugLog(@"Error decoding packet data (%@)",e);
			return nil;
		}
	}
	
	return nil;
}

- (id)initWithID:(XfirePacketID)pktID attributeMap:(XfirePacketAttributeMap *)attrs raw:(NSData *)raw
{
	self = [super init];
	if( self )
	{
		_packetID = pktID;
		_attributes = [attrs retain];
		_raw = [raw copy];
	}
	return self;
}

- (void)dealloc
{
	if( _attributes ) [_attributes release];
	if( _raw ) [_raw release];
	_attributes = nil;
	_raw = nil;
	
	[super dealloc];
}

- (XfirePacketID)packetID
{
	return _packetID;
}

- (NSData*)raw;
{
	return _raw;
}

- (int)attributeCount
{
	return [[self attributes] count];
}

- (NSString *)description
{
	NSMutableString *str = [NSMutableString string];
	NSData *content = [self raw];
	
	[str appendFormat:@"packet:  ID %d, %d attrs", [self packetID], [self attributeCount]];
	
	[str appendFormat:@"\n%@\n", [[self attributes] description]];
	
	if( content )
	{
		[str appendString:[content enhancedDescription]];
	}
	
	return str;
}

- (XfirePacketAttributeMap *)attributes
{
	return _attributes;
}

- (XfirePacketAttributeValue *)attributeForKey:(id)key
{
	return [[self attributes] objectForKey:key];
}

// Compound accessor utility to get all values into an array, regardless of
// whether the packet has a single item or multiple items
- (NSArray *)attributeValuesForKey:(id)key
{
	XfirePacketAttributeValue *mainAttrVal = [self attributeForKey:key];
	
	if( mainAttrVal == nil )
		return nil;
	
	if( [mainAttrVal typeID] == kXfirePacketAttributeArrayType )
	{
		NSArray *mainAttrValArray = [mainAttrVal attributeValue];
		NSMutableArray *attrValues = [NSMutableArray array];
		
		int i, cnt;
		cnt = [mainAttrValArray count];
		for( i = 0; i < cnt; i++ )
		{
			[attrValues addObject: [(XfirePacketAttributeValue *)[mainAttrValArray objectAtIndex:i] attributeValue]];
		}
		
		return attrValues;
	}
	else
	{
		// single value
		return [NSArray arrayWithObject:[mainAttrVal attributeValue]];
	}
}

@end




@implementation XfireMutablePacket

+ (id)packet
{
	return [[[XfireMutablePacket alloc] init] autorelease];
}

// username/password packet (ID 1)
+ (id)loginPacketWithUsername:(NSString *)name password:(NSString *)pass flags:(unsigned int)flg
{
	XfireMutablePacket *pkt = [self packet];
	
	if( [pass length] != 40 )
	{
		@throw [NSException exceptionWithName:@"XfireMutablePacket" reason:@"Attempt to create packet with invalid password hash" userInfo:nil];
	}
	
	[pkt setPacketID: 0x01];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithString:name]
		forKey:kXfireAttributeNameKey];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithString:pass]
		forKey:kXfireAttributePasswordKey];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:flg]
		forKey:kXfireAttributeFlagsKey];
	
	[pkt generate];
	return pkt;
}

// chat messages (ID 2)

	// acknowledge receipt of a chat message
+ (id)chatAcknowledgementPacketWithSID:(NSData *)sid imIndex:(unsigned int)imidx
{
	XfireMutablePacket *pkt = [self packet];
	XfirePacketAttributeMap *peermsg = [XfirePacketAttributeMap map];
	
	[pkt setPacketID: 0x02];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithUUID:sid]
		forKey:kXfireAttributeSessionIDKey];
	
	[peermsg setObject:[XfirePacketAttributeValue attributeValueWithInt:1]
		forKey:kXfireAttributeMsgTypeKey];
	[peermsg setObject:[XfirePacketAttributeValue attributeValueWithInt:imidx]
		forKey:kXfireAttributeIMIndexKey];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithAttributeMap:peermsg]
		forKey:kXfireAttributePeerMessageKey];
	
	[pkt generate];
	return pkt;
}

	// send an instant message
+ (id)chatInstantMessagePacketWithSID:(NSData *)sid imIndex:(unsigned int)imidx message:(NSString *)msg
{
	XfireMutablePacket *pkt = [self packet];
	XfirePacketAttributeMap *peermsg = [XfirePacketAttributeMap map];
	
	[pkt setPacketID: 0x02];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithUUID:sid]
		forKey:kXfireAttributeSessionIDKey];
	
	[peermsg setObject:[XfirePacketAttributeValue attributeValueWithInt:0]
		forKey:kXfireAttributeMsgTypeKey];
	[peermsg setObject:[XfirePacketAttributeValue attributeValueWithInt:imidx]
		forKey:kXfireAttributeIMIndexKey];
	[peermsg setObject:[XfirePacketAttributeValue attributeValueWithString:msg]
		forKey:kXfireAttributeIMKey];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithAttributeMap:peermsg]
		forKey:kXfireAttributePeerMessageKey];
	
	[pkt generate];
	return pkt;
}

//Typing notification packet
+ (id)chatTypingNotificationPacketWithSID:(NSData *)sid imIndex:(unsigned int)imidx typing:(unsigned int)typing
{
	XfireMutablePacket *pkt = [self packet];
	XfirePacketAttributeMap *peermsg = [XfirePacketAttributeMap map];
	
	[pkt setPacketID:0x02];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithUUID:sid]
			   forKey:kXfireAttributeSessionIDKey];
	
	[peermsg setObject:[XfirePacketAttributeValue attributeValueWithInt:3]
				forKey:kXfireAttributeMsgTypeKey];
	[peermsg setObject:[XfirePacketAttributeValue attributeValueWithInt:imidx]
				forKey:kXfireAttributeIMIndexKey];
	[peermsg setObject:[XfirePacketAttributeValue attributeValueWithInt:YES]
				forKey:kXfireAttributeTypingKey];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithAttributeMap:peermsg]
			   forKey:kXfireAttributePeerMessageKey];
	
	[pkt generate];
	return pkt;
}

// peer to peer info packet
+ (id)chatPeerToPeerInfoResponseWithSalt:(NSString *)salt sid:(NSData *)sid
{
	XfireMutablePacket *pkt = [self packet];
	XfirePacketAttributeMap *peermsg = [XfirePacketAttributeMap map];
	
	[pkt setPacketID:0x02];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithUUID:sid] forKey:kXfireAttributeSessionIDKey];
	
	[peermsg setObject:[XfirePacketAttributeValue attributeValueWithInt:2]
				forKey:kXfireAttributeMsgTypeKey];
	[peermsg setObject:[XfirePacketAttributeValue attributeValueWithInt:0]
				forKey:@"ip"];
	[peermsg setObject:[XfirePacketAttributeValue attributeValueWithInt:0]
				forKey:@"port"];
	[peermsg setObject:[XfirePacketAttributeValue attributeValueWithInt:0]
				forKey:@"localip"];
	[peermsg setObject:[XfirePacketAttributeValue attributeValueWithInt:0]
				forKey:@"localport"];
	[peermsg setObject:[XfirePacketAttributeValue attributeValueWithInt:0]
				forKey:@"status"];
	[peermsg setObject:[XfirePacketAttributeValue attributeValueWithString:salt]
				forKey:kXfireAttributeSaltKey];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithAttributeMap:peermsg]
			   forKey:kXfireAttributePeerMessageKey];
	
	[pkt generate];
	
	return pkt;
}

// client version packet (ID 3)
+ (id)clientVersionPacket:(unsigned int)vers
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID: 0x03];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:vers]
		forKey:kXfireAttributeVersionKey];
	
	[pkt generate];
	return pkt;
}

// game status change packet (ID 4)
+ (id)gameStatusChangePacketWithGameID:(unsigned)gid gameIP:(unsigned)gip gamePort:(unsigned)port
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID: 0x04];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:gid]
		forKey:kXfireAttributeGameIDKey];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:gip]
		forKey:kXfireAttributeGameIPKey];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:port]
		forKey:kXfireAttributeGamePortKey];
	
	[pkt generate];
	return pkt;
}

// Friend of Friend info request (ID 5)
+ (id)friendOfFriendRequestPacketWithSIDs:(NSArray *)sessionIDs
{
	NSMutableArray *sidArray = [NSMutableArray array];
	NSData *sid;
	int i, cnt;
	
	cnt = [sessionIDs count];
	if( cnt == 0 )
		@throw [NSException exceptionWithName:@"XfireMutablePacket" reason:@"Attempt to create friend of friend request without any session IDs" userInfo:nil];
	
	for( i = 0; i < cnt; i++ )
	{
		sid = [sessionIDs objectAtIndex:i];
		if( ! [sid isKindOfClass:[NSData class]] )
			@throw [NSException exceptionWithName:@"XfireMutablePacket" reason:@"Attempt to create friend of friend request with invalid session ID" userInfo:nil];
		if( [sid length] != 16 )
			@throw [NSException exceptionWithName:@"XfireMutablePacket" reason:@"Attempt to create friend of friend request with invalid session ID" userInfo:nil];
		
		[sidArray addObject:[XfirePacketAttributeValue attributeValueWithUUID:sid]];
	}
	
	XfireMutablePacket *pkt = [self packet];
	[pkt setPacketID: 5];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithArray:sidArray emptyElementType:3]
		forKey:kXfireAttributeSessionIDKey];
	
	[pkt generate];
	return pkt;
}

// Add-friend request (ID 6)
+ (id)addFriendRequestPacketWithUserName:(NSString *)un message:(NSString *)msg
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID: 6];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithString:un]
		forKey:kXfireAttributeNameKey];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithString:msg]
		forKey:kXfireAttributeMessageKey];
	
	[pkt generate];
	return pkt;
}

// Accept incoming add-friend request (ID 7)
+ (id)acceptFriendRequestPacketWithUserName:(NSString *)un
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID: 7];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithString:un]
		forKey:kXfireAttributeNameKey];
	
	[pkt generate];
	return pkt;
}

// Decline incoming add-friend request (ID 8)
+ (id)declineFriendRequestPacketWithUserName:(NSString *)un
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID: 8];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithString:un]
		forKey:kXfireAttributeNameKey];
	
	[pkt generate];
	return pkt;
}

// Add-friend request (ID 9)
+ (id)removeFriendRequestWithUserID:(unsigned int)uid
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID: 9];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:uid]
		forKey:kXfireAttributeUserIDKey];
	
	[pkt generate];
	return pkt;
}

// Change user options packet (ID 10)
// Pass options with keys equal to the packet attribute map keys and values as NSNumber.bool
+ (id)changeOptionsPacketWithOptions:(NSDictionary *)options
{
	XfireMutablePacket *pkt = [self packet];
	XfirePacketAttributeMap *map = [XfirePacketAttributeMap map];
	
	[pkt setPacketID: 10];
	
	NSArray *allKeys = [[options allKeys] sortedArrayUsingSelector:@selector(compare:)];
	int i, cnt;
	cnt = [allKeys count];
	NSString *key;
	NSNumber *valN;
	NSString *valS;
	for( i = 0; i < cnt; i++ )
	{
		key = [allKeys objectAtIndex:i];
		valN = [options objectForKey:key];
		if( valN && [valN boolValue] )
			valS = @"1";
		else
			valS = @"0";
		
		[map setObject:[XfirePacketAttributeValue attributeValueWithString:valS] forKey:key];
	}
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithAttributeMap:map]
		forKey:kXfireAttributePrefsKey];
	
	[pkt generate];
	return pkt;
}

// user search packet (ID 12)
+ (id)userSearchPacketWithName:(NSString *)name fname:(NSString *)fn lname:(NSString *)ln email:(NSString *)em
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID: 12];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithString:name]
		forKey:kXfireAttributeNameKey];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithString:(fn?fn:@"")]
		forKey:kXfireAttributeFirstNameKey];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithString:(ln?ln:@"")]
		forKey:kXfireAttributeLastNameKey];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithString:(em?em:@"")]
		forKey:kXfireAttributeEmailKey];
	
	[pkt generate];
	return pkt;
}

// connection keepalive packet (ID 13)
+ (id)keepAlivePacketWithValue:(unsigned)val stats:(NSArray *)stats
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID: 13];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:val]
		forKey:kXfireAttributeValueKey];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithArray:stats emptyElementType:2]
		forKey:kXfireAttributeStatisticsKey];
	
	[pkt generate];
	return pkt;
}

// Change nickname (ID 14)
+ (id)changeNicknamePacketWithName:(NSString *)nick
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID: 14];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithString:(nick?nick:@"")]
		forKey:kXfireAttributeNicknameKey];
	
	[pkt generate];
	return pkt;
}

// client information packet (ID 16)
+ (id)clientInfoPacketWithLanguage:(NSString *)lng skin:(NSString *)skn theme:(NSString *)thm partner:(NSString *)prt
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID: 16];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithString:lng]
		forKey:kXfireAttributeLanguageKey];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithString:skn]
		forKey:kXfireAttributeSkinKey];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithString:thm]
		forKey:kXfireAttributeThemeKey];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithString:prt]
		forKey:kXfireAttributePartnerKey];
	
	[pkt generate];
	return pkt;
}

// client network info packet (ID 17)
+ (id)networkInfoPacketWithConn:(unsigned)conn nat:(BOOL)isNat sec:(unsigned)sec ip:(unsigned)ip naterr:(BOOL)nErr uPnPInfo:(NSString *)info
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID: 17];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:conn]    forKey:@"conn"];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:isNat]   forKey:@"nat"];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:sec]     forKey:@"sec"];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:ip]      forKey:@"clientip"];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:nErr]    forKey:@"naterr"];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithString:info] forKey:@"upnpinfo"];
	
	[pkt generate];
	return pkt;
}

// add custom friend group packet (ID 26)
+ (id)addCustomFriendGroupPacketWithName:(NSString *)groupName
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID: 26];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithString:groupName]
		forKey:[NSNumber numberWithInt:0x1a]];
	
	[pkt generate];
	return pkt;
}

// remove custom friend group packet (ID 27)
+ (id)removeCustomFriendGroupPacket:(unsigned)groupID
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID: 27];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:groupID]
		forKey:[NSNumber numberWithInt:0x19]];
	
	[pkt generate];
	return pkt;
}

// rename custom friend group packet (ID 28)
+ (id)renameCustomFriendGroupPacket:(unsigned)groupID newName:(NSString *)groupName
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID: 28];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:groupID]
		forKey:[NSNumber numberWithInt:0x19]];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithString:groupName]
		forKey:[NSNumber numberWithInt:0x1a]];
	
	[pkt generate];
	return pkt;
}

// add friend to custom friend group (ID 29)
+ (id)addFriendPacket:(unsigned)friendID toCustomGroup:(unsigned)groupID
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID: 29];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:friendID]
		forKey:[NSNumber numberWithInt:0x01]];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:groupID]
		forKey:[NSNumber numberWithInt:0x19]];
	
	[pkt generate];
	return pkt;
}

// remove friend from custom friend group (ID 30)
+ (id)removeFriendPacket:(unsigned)friendID fromCustomGroup:(unsigned)groupID
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID: 30];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:friendID]
		forKey:[NSNumber numberWithInt:0x01]];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:groupID]
		forKey:[NSNumber numberWithInt:0x19]];
	
	[pkt generate];
	return pkt;
}

// status text change packet (ID 32)
+ (id)statusTextChangePacket:(NSString *)newText
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID: 32];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithString:(newText?newText:@"")]
		forKey:[NSNumber numberWithInt:0x2e]];
	
	[pkt generate];
	return pkt;
}

+ (id)infoViewRequestPacket:(unsigned)friendID
{
	XfireMutablePacket *pkt = [self packet];
	[pkt setPacketID:37];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:friendID]
			   forKey:[NSNumber numberWithInt:0x01]];
	[pkt generate];
	return pkt;
}

+ (id)joinChatRoomPacketWithSID:(NSData *)sid name:(NSString *)name password:(NSString *)password
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID:0x19];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:0x4cf4] forKey:@"climsg"];
	
	XfirePacketAttributeMap *map = [XfirePacketAttributeMap map];
	
	[map setObject:[XfirePacketAttributeValue attributeValueWithDid:(sid) ? sid : [NSMutableData dataWithLength:21]]
			forKey:[NSNumber numberWithInt:0x04]];
	[map setObject:[XfirePacketAttributeValue attributeValueWithInt:0x01]
			forKey:[NSNumber numberWithInt:0x0b]];
	[map setObject:[XfirePacketAttributeValue attributeValueWithInt:0x01]
			forKey:[NSNumber numberWithInt:0xaa]];
	[map setObject:[XfirePacketAttributeValue attributeValueWithString:(name) ? name : @""]
			forKey:[NSNumber numberWithInt:0x05]];
	[map setObject:[XfirePacketAttributeValue attributeValueWithString:(password) ? password : @""]
			forKey:[NSNumber numberWithInt:0x5f]];
	[map setObject:[XfirePacketAttributeValue attributeValueWithByte:0x00]
			forKey:[NSNumber numberWithInt:0xa7]];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithAttributeMap:map]
			   forKey:kXfireAttributeMessageKey];
	
	[pkt generate];
	
	return pkt;
}

+ (id)makeNewChatRoomPacket:(NSString *)name
{
	return [self makeNewChatRoomPacket:name password:nil];
}

+ (id)makeNewChatRoomPacket:(NSString *)name password:(NSString *)password
{
	return [self joinChatRoomPacketWithSID:nil name:name password:password];
}

+ (id)joinChatRoomPacketForChatRoom:(XfireChatRoom *)chatRoom
{
	return [self joinChatRoomPacketWithSID:[chatRoom groupChatSID] name:[chatRoom name] password:nil];
}

+ (id)joinChatRoomPacketForChatRoom:(XfireChatRoom *)chatRoom password:(NSString *)password
{
	return [self joinChatRoomPacketWithSID:[chatRoom groupChatSID] name:[chatRoom name] password:password];
}

+ (id)chatRoomInfoPacketForChatRoom:(XfireChatRoom *)chatRoom
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID:0x19];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:0x4d06] forKey:@"climsg"];
	
	XfirePacketAttributeMap *map = [XfirePacketAttributeMap map];
	
	[map setObject:[XfirePacketAttributeValue attributeValueWithDid:[chatRoom groupChatSID]] forKey:[NSNumber numberWithInt:0x04]];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithAttributeMap:map] 
			   forKey:kXfireAttributeMessageKey];
	
	[pkt generate];
	
	return pkt;
}

+ (id)leaveChatRoomPacketForChatRoom:(XfireChatRoom *)chatRoom
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID:0x19];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:0x4cf5] forKey:@"climsg"];
	
	XfirePacketAttributeMap *map = [XfirePacketAttributeMap map];
	
	[map setObject:[XfirePacketAttributeValue attributeValueWithDid:[chatRoom groupChatSID]] forKey:[NSNumber numberWithInt:0x04]];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithAttributeMap:map] 
			   forKey:kXfireAttributeMessageKey];
	
	[pkt generate];
	
	return pkt;
}

+ (id)chatRoomInvitePacketForUsers:(NSArray *)users chatRoom:(XfireChatRoom *)chatRoom
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID:0x19];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:0x4cfc] forKey:@"climsg"];
	
	XfirePacketAttributeMap *map = [XfirePacketAttributeMap map];
	
	[map setObject:[XfirePacketAttributeValue attributeValueWithDid:[chatRoom groupChatSID]] forKey:[NSNumber numberWithInt:0x04]];
	
	NSMutableArray *userIDs = [NSMutableArray array];
	for (XfireFriend *friend in users)
	{
		[userIDs addObject:[XfirePacketAttributeValue attributeValueWithInt:[friend userID]]];
	}
	
	[map setObject:[XfirePacketAttributeValue attributeValueWithArray:userIDs] forKey:[NSNumber numberWithInt:0x18]];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithAttributeMap:map] 
			   forKey:kXfireAttributeMessageKey];
	
	[pkt generate];
	
	return pkt;
}

+ (id)declineChatRoomInvitePacketForChatRoom:(XfireChatRoom *)chatRoom
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID:0x19];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:0x4cff] forKey:@"climsg"];
	
	XfirePacketAttributeMap *map = [XfirePacketAttributeMap map];
	
	[map setObject:[XfirePacketAttributeValue attributeValueWithDid:[chatRoom groupChatSID]] forKey:[NSNumber numberWithInt:0x04]];
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithAttributeMap:map] 
			   forKey:kXfireAttributeMessageKey];
	
	[pkt generate];
	
	return pkt;	
}

+ (id)messagePacketWithMessage:(NSString *)message forChatRoom:(XfireChatRoom *)chatRoom
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID:0x019];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:0x4cf6] forKey:@"climsg"];
	
	XfirePacketAttributeMap *map = [XfirePacketAttributeMap map];
	[map setObject:[XfirePacketAttributeValue attributeValueWithDid:[chatRoom groupChatSID]] forKey:[NSNumber numberWithInt:0x04]];
	[map setObject:[XfirePacketAttributeValue attributeValueWithString:message] forKey:[NSNumber numberWithInt:0x2e]];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithAttributeMap:map] forKey:kXfireAttributeMessageKey];
	
	[pkt generate];
	
	return pkt;
}

+ (id)kickUserPacketWithUser:(XfireFriend *)user forChatRoom:(XfireChatRoom *)chatRoom
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID:0x019];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithInt:0x4cfb] forKey:@"climsg"];
	
	XfirePacketAttributeMap *map = [XfirePacketAttributeMap map];
	[map setObject:[XfirePacketAttributeValue attributeValueWithDid:[chatRoom groupChatSID]] forKey:[NSNumber numberWithInt:0x04]];
	[map setObject:[XfirePacketAttributeValue attributeValueWithInt:[user userID]] forKey:[NSNumber numberWithInt:0x18]];
	
	[pkt setAttribute:[XfirePacketAttributeValue attributeValueWithAttributeMap:map] forKey:kXfireAttributeMessageKey];
	
	[pkt generate];
	
	return pkt;
}

#if 0
+ (id)template
{
	XfireMutablePacket *pkt = [self packet];
	
	[pkt setPacketID: 0x00];
	
	[pkt generate];
	return pkt;
}
#endif

- (id)init
{
	self = [super init];
	if( self )
	{
		_packetID = 0;
		_attributes = [[XfirePacketAttributeMap map] retain];
		_raw = nil;
	}
	return self;
}

- (void)setAttribute:(id)value forKey:(id)aKey
{
	// TODO: check key
	// TODO: check value
	
	[[self attributes] setObject:value forKey:aKey];
}

#if 0
- (void)removeAttributeForKey:(NSString *)aKey
{
	[[self attributes] removeObjectForKey:aKey];
}
#endif

- (void)setPacketID:(XfirePacketID)anID
{
	// TODO: check ID
	
	_packetID = anID;
}

- (BOOL)generate
{
	// TODO: perform a sanity check before using XfirePacketGenerator
	
	if( [[self attributes] count] > 0 )
	{
		XfirePacketGenerator *generator = [XfirePacketGenerator generatorWithID:[self packetID] attributes:[self attributes]];
		
		@try
		{
			NSData *dat = [generator generate];
			if( dat )
			{
				[_raw release];
				_raw = [dat retain];
				return YES;
			}
		}
		@catch( NSException *e )
		{
			DebugLog(@"Error generating packet data (%@)",e);
			return NO;
		}
	}
	
	return NO;
}

@end


