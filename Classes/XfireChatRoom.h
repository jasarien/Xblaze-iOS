//
//  XfireChatRoom.h
//  Xblaze-iPhone
//
//  Created by James on 17/08/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XfireFriend.h"

extern NSString *kXfireChatRoomDidReceiveMessageNotification;



@class XfireSession, XfirePacket, XfireChatRoom;

typedef enum {
	XFGroupChatAccessUnknown,
	XFGroupChatAccessPublic,
	XFGroupChatAccessFriends
} XFGroupChatAccess;

typedef enum {
	XFGroupChatJoinSuccess,
	XFGroupChatRequiresPassword = 4,
	XFGroupChatIncorrectPassword = 5
} XFGroupChatJoinResponse;

typedef enum {
	
	XFGroupChatPermissionLevelUnknown,
	XFGroupChatPermissionLevelMuted,
	XFGroupChatPermissionLevelNormal,
	XFGroupChatPermissionLevelPowerUser,
	XFGroupChatPermissionLevelModerator,
	XFGroupChatPermissionLevelAdmin
	
} XFGroupChatPermissionLevel;

@protocol XfireChatRoomDelegate <NSObject>

- (void)session:(XfireSession *)session chatRoom:(XfireChatRoom *)chatRoom didReceiveMessage:(NSDictionary *)message;
- (void)session:(XfireSession *)session chatRoom:(XfireChatRoom *)chatRoom didReceiveSystemMessage:(NSDictionary *)message;

@end


@interface XfireChatRoom : NSObject {

	NSData *_groupChatSID;
	NSString *_name;
	NSString *_messageOfTheDay;
	XFGroupChatPermissionLevel _defaultPermissionLevel;
	NSNumber *_timestamp;
	XFGroupChatAccess _chatRoomAccess;
	XFGroupChatJoinResponse _joinResponse;
	
	NSMutableSet *_users;
	
	NSMutableArray *_messages;
	
	NSInteger _unreadCount;
	
	XfireSession *_session;
	
	id <XfireChatRoomDelegate> _delegate;
	
	NSMutableDictionary *_permissions;
}

@property (nonatomic, retain) NSData *groupChatSID;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *messageOfTheDay;
@property (nonatomic, assign) XFGroupChatPermissionLevel defaultPermissionLevel;
@property (nonatomic, retain) NSNumber *timestamp;
@property (nonatomic, assign) XFGroupChatAccess chatRoomAccess;

@property (nonatomic, retain) NSMutableSet *users;
@property (nonatomic, retain) NSMutableArray *messages;

@property (nonatomic, retain) NSMutableDictionary *permissions;

@property (nonatomic, assign) NSInteger unreadCount;

@property (nonatomic, assign) XfireSession *session;
@property (nonatomic, assign) id <XfireChatRoomDelegate> delegate;

- (XfireFriend *)userForUserID:(NSUInteger)userID;

- (void)processChatRoomUserJoinedPacket:(XfirePacket *)pkt;
- (void)processChatRoomUserLeftPacket:(XfirePacket *)pkt;
- (void)processChatRoomReceivedMessagePacket:(XfirePacket *)pkt;
- (NSString *)stringForPermissionLevel:(XFGroupChatPermissionLevel)permissionLevel;
- (XFGroupChatPermissionLevel)permissionForUser:(XfireFriend *)user;
- (void)sendMessage:(NSString *)message;
- (void)kickUser:(XfireFriend *)user;
@end
