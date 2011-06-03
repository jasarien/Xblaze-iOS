/*******************************************************************
	FILE:		XfirePacket.h
	
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

#import <Foundation/Foundation.h>

typedef unsigned int XfirePacketID;

@class XfirePacketAttributeMap;
@class XfireChatRoom, XfireFriend;

@interface XfirePacket : NSObject
{
	XfirePacketID _packetID;
	XfirePacketAttributeMap *_attributes;
	NSData        *_raw;
}

//------------------------------------------------------------------
// Decode a serialized packet
// Used when receiving a packet
+ (XfirePacket *)decodedPacketByScanningBuffer:(NSData *)data;

//------------------------------------------------------------------
// Accessors

- (XfirePacketID)packetID;
- (XfirePacketAttributeMap *)attributes;

- (id)attributeForKey:(id)key;

// Compound accessor utility to get all values into an array, regardless of
// whether the packet has a single item or multiple items
- (NSArray *)attributeValuesForKey:(id)key;


//------------------------------------------------------------------
// Get the raw byte stream (serialized packet)
// WARNING: if the target is an XfireMutablePacket, the result is only valid
//          after a call to -generate.  The return value reflects the status
//          of the packet after the last invocation of -generate.
- (NSData*)raw;

@end




@interface XfireMutablePacket : XfirePacket
{
}

//------------------------------------------------------------------
// Empty packet
+ (id)packet;

//------------------------------------------------------------------
// Generators for Common Packets

// username/password packet (ID 1)
+ (id)loginPacketWithUsername:(NSString *)name password:(NSString *)pass flags:(unsigned int)f;
	// name is username
	// pass is hashed password (generate elsewhere)
	// I don't know what flags might be, so pass 0 for now

// chat messages (ID 2)
	// acknowledge receipt of a chat message
+ (id)chatAcknowledgementPacketWithSID:(NSData *)sid imIndex:(unsigned int)idx;
	// send an instant message
+ (id)chatInstantMessagePacketWithSID:(NSData *)sid imIndex:(unsigned int)idx message:(NSString *)msg;
	// send a typing notification
+ (id)chatTypingNotificationPacketWithSID:(NSData *)sid imIndex:(unsigned int)imidx typing:(unsigned int)typing;
	// peer to peer info packet
+ (id)chatPeerToPeerInfoResponseWithSalt:(NSString *)salt sid:(NSData *)sid;

// client version packet (ID 3)
+ (id)clientVersionPacket:(unsigned int)vers;
	// Not sure what a valid version value is; 82 came from a recent Xfire client

// game status change packet (ID 4)
+ (id)gameStatusChangePacketWithGameID:(unsigned)gid gameIP:(unsigned)gip gamePort:(unsigned)port;

// Friend of Friend info request (ID 5)
+ (id)friendOfFriendRequestPacketWithSIDs:(NSArray *)sessionIDs;
	// pass an array of Session IDs (NSData<16>)
	// do not pass an empty array!

// Add-friend request (ID 6)
+ (id)addFriendRequestPacketWithUserName:(NSString *)un message:(NSString *)msg;

// Accept incoming add-friend request (ID 7)
+ (id)acceptFriendRequestPacketWithUserName:(NSString *)un;

// Decline incoming add-friend request (ID 8)
+ (id)declineFriendRequestPacketWithUserName:(NSString *)un;

// Remove-friend request (ID 9)
+ (id)removeFriendRequestWithUserID:(unsigned int)uid;

// Change user options packet (ID 10)
// Pass options with keys equal to the packet attribute map keys and values as NSNumber.bool
+ (id)changeOptionsPacketWithOptions:(NSDictionary *)options;

// user search packet (ID 12)
+ (id)userSearchPacketWithName:(NSString *)name fname:(NSString *)fn lname:(NSString *)ln email:(NSString *)em;
	// pass nil or @"" for fn, ln, and em

// connection keepalive packet (ID 13)
+ (id)keepAlivePacketWithValue:(unsigned)val stats:(NSArray *)stats;
	// pass 0 for val
	// pass [NSArray array] for stats

// Change nickname (ID 14)
+ (id)changeNicknamePacketWithName:(NSString *)nick;

// client information packet (ID 16)
+ (id)clientInfoPacketWithLanguage:(NSString *)lng skin:(NSString *)skn theme:(NSString *)thm partner:(NSString *)prt;
	// pass "us" for language
	// pass "Shadow" for skin
	// pass "default" for theme
	// pass "" for partner

// client network info packet (ID 17)
+ (id)networkInfoPacketWithConn:(unsigned)conn nat:(BOOL)isNat sec:(unsigned)sec ip:(unsigned)ip naterr:(BOOL)nErr uPnPInfo:(NSString *)info;
	// pass 2 for conn (no idea what it means)
	// pass 1 for isNat (assume it's a boolean: are we behind a NAT)
	// pass 5 for sec (no idea what it means)
	// pass local IP address for ip (so, whatever you see)
	// pass 1 for nErr (assume it's a boolean: did we have NAT errors)
	// pass "" for UPnP info (assume it's a configuration string)

// add custom friend group packet (ID 26)
+ (id)addCustomFriendGroupPacketWithName:(NSString *)groupName;

// remove custom friend group packet (ID 27)
+ (id)removeCustomFriendGroupPacket:(unsigned)groupID;

// rename custom friend group packet (ID 28)
+ (id)renameCustomFriendGroupPacket:(unsigned)groupID newName:(NSString *)groupName;

// add friend to custom friend group (ID 29)
+ (id)addFriendPacket:(unsigned)friendID toCustomGroup:(unsigned)groupID;

// remove friend from custom friend group (ID 30)
+ (id)removeFriendPacket:(unsigned)friendID fromCustomGroup:(unsigned)groupID;

// status text change packet (ID 32)
+ (id)statusTextChangePacket:(NSString *)newText;
	// pass @"" or nil to remove status text

// request detailed info view info (ID 37)
+ (id)infoViewRequestPacket:(unsigned)friendID;

// join a chat room
+ (id)joinChatRoomPacketWithSID:(NSData *)sid name:(NSString *)name password:(NSString *)password;
+ (id)joinChatRoomPacketForChatRoom:(XfireChatRoom *)chatRoom password:(NSString *)password;
+ (id)joinChatRoomPacketForChatRoom:(XfireChatRoom *)chatRoom;

// Create a chat room
+ (id)makeNewChatRoomPacket:(NSString *)name;
+ (id)makeNewChatRoomPacket:(NSString *)name password:(NSString *)password;

// get info for a chat room
+ (id)chatRoomInfoPacketForChatRoom:(XfireChatRoom *)chatRoom;

// leave a chat room
+ (id)leaveChatRoomPacketForChatRoom:(XfireChatRoom *)chatRoom;

// invites users to chat room
+ (id)chatRoomInvitePacketForUsers:(NSArray *)users chatRoom:(XfireChatRoom *)chatRoom;

// invite management
+ (id)declineChatRoomInvitePacketForChatRoom:(XfireChatRoom *)chatRoom;

// send a message to a chat room
+ (id)messagePacketWithMessage:(NSString *)message forChatRoom:(XfireChatRoom *)chatRoom;

// kick a user from a chat room
+ (id)kickUserPacketWithUser:(XfireFriend *)user forChatRoom:(XfireChatRoom *)chatRoom;

//------------------------------------------------------------------
// Accessors

- (void)setPacketID:(XfirePacketID)anID;
- (void)setAttribute:(id)value forKey:(id)aKey; // key may be only NSString or NSNumber(int)
//- (void)removeAttributeForKey:(NSString *)aKey;

//------------------------------------------------------------------
// Generate the raw byte stream, that you can then get using -raw
- (BOOL)generate;

@end



// ---------------------------------------
// Packet attribute keys
// ---------------------------------------

// NOTES:
// 1. As a general rule, most attributes can be either the type specified or
//    an NSArray of the specified type.  Exceptions are noted.
// 2. When an NSDictionary is specified, that dictionary must consist of the
//    same kinds of data (the keys below with associated values).
// 3. All strings must be convertible to UTF-8.

// Key											Valid Value Type(s)
// -----------------------------------------	--------------------------
extern NSString* kXfireAttributeChecksumKey;	// NSString
extern NSString* kXfireAttributeChunksKey;		// NSNumber<uint32>
extern NSString* kXfireAttributeEmailKey;		// NSString
extern NSString* kXfireAttributeFirstNameKey;	// NSString
extern NSString* kXfireAttributeFlagsKey;		// NSNumber<uint32>
extern NSString* kXfireAttributeFriendsKey;		// NSString
extern NSString* kXfireAttributeFriendSIDKey;	// NSData<16>
extern NSString* kXfireAttributeGameIDKey;		// NSNumber<uint32>
extern NSString* kXfireAttributeGameIPKey;		// NSNumber<uint32> (IP address)
extern NSString* kXfireAttributeGamePortKey;	// NSNumber<uint32>
extern NSString* kXfireAttributeIMKey;			// NSString
extern NSString* kXfireAttributeIMIndexKey;		// NSNumber<uint32>
extern NSString* kXfireAttributeTypingKey;		// NSNumber<uint32>
extern NSString* kXfireAttributeLanguageKey;	// NSString
extern NSString* kXfireAttributeLastNameKey;	// NSString
extern NSString* kXfireAttributeMessageKey;		// NSString
extern NSString* kXfireAttributeMsgTypeKey;		// NSNumber<uint32>
extern NSString* kXfireAttributeNameKey;		// NSString    (username)
extern NSString* kXfireAttributeNicknameKey;	// NSString
extern NSString* kXfireAttributePartnerKey;		// NSString
extern NSString* kXfireAttributePasswordKey;	// NSString    (of hashed password, not an array)
extern NSString* kXfireAttributePeerMessageKey;	// NSDictionary
	// value is an NSDictionary of the following keys:
	//   kXfireAttributeMsgTypeKey
	//   kXfireAttributeIMIndexKey
	//   kXfireAttributeInstantMessageKey
extern NSString* kXfireAttributeReasonKey;		// NSNumber<uint32>
extern NSString* kXfireAttributeSaltKey;		// NSString/NSData  (no arrays)
extern NSString* kXfireAttributeSessionIDKey;	// NSData      (16 bytes, a UUID?)
extern NSString* kXfireAttributeSkinKey;		// NSString
extern NSString* kXfireAttributeStatisticsKey;	// NSNumber<uint32>
extern NSString* kXfireAttributeStatusKey;		// NSNumber<uint32>, NSDictionary
	// TBD valid keys when it's an NSDictionary
	//   kXfireAttributeStatusTextKey ?
extern NSString* kXfireAttributeThemeKey;		// NSString
extern NSString* kXfireAttributeUserIDKey;		// NSNumber<uint32>
extern NSString* kXfireAttributeValueKey;		// NSNumber<uint32>
extern NSString* kXfireAttributeVersionKey;		// NSNumber<uint32>

extern NSString *kXfireAttributeAvatarTypeKey;		//
extern NSString *kXfireAttributeAvatarNumberKey;	//


//extern NSString* kXfireAttributeCommandKey;		// NSNumber<uint32>
//extern NSString* kXfireAttributeDownloadSetKey;	// NSString
//extern NSString* kXfireAttributeFileKey;		// NSString
//extern NSString* kXfireAttributeFileIDKey;		// NSNumber<uint32>
//extern NSString* kXfireAttributePrefsKey;		// NSDictionary
//extern NSString* kXfireAttributeResultKey;		// NSNumber<uint32>
//extern NSString* kXfireAttributeStatusTextKey;	// NSString
//extern NSString* kXfireAttributeTypeKey;		// NSNumber<uint32>


