/*
 *  Constants.h
 *  Xblaze-iPhone
 *
 *  Created by James Addyman on 16/11/2009.
 *  Copyright 2009 JamSoft. All rights reserved.
 *
 */

#pragma mark Debug Settings

#ifdef DEBUG
	#define DebugLog(s, ...) NSLog( @"<%@:(%d)> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
	#define DebugLog(x...)
#endif

#pragma mark -
#pragma mark Xfire Server Details

#define XfireHostName @"cs.xfire.com"
#define XfirePortNumber 25999
#define XfirePoseClientVersion 9999
#define XfireConnectionTimeout 20.0

#pragma mark -
#pragma mark NSNotification Names

#define kShowKeyboardNotification @"kShowKeyboardNotification"
#define kHidePopoverNotification @"kHidePopoverNotification"

#define kSetupLogoutButtonNotification @"kSetupLogoutButtonNotification"
#define kRemoveLogoutButtonNotification @"kRemoveLogoutButtonNotification"

#define kXfireFriendDidChangeNotification @"kXfireFriendDidChangeNotification"

#define kMessageReceivedNotification @"kMessageReceivedNotification"
#define kResetUnreadCountNotification @"kResetUnreadCountNotification"

#define kSearchCompleteNotification @"kSearchCompleteNotification"

#define kTypingNotificationRecieved @"kTypingNotificationRecieved"

#define kXfireFriendGroupDidChangeNotification @"kXfireFriendGroupDidChangeNotification"
#define kXfireFriendGroupWasAddedNotification @"kXfireFriendGroupWasAddedNotification"
#define kXfireFriendGroupWillBeRemovedNotification @"kXfireFriendGroupWillBeRemovedNotification"

#define kXfireDidBeginChatNotification @"kXfireDidBeginChatNotification"
#define kXfireDidEndChatNotification @"kXfireDidEndChatNotification"

#define kXfireJoinChatRoomInvalidPasswordNotification @"kXfireJoinChatRoomInvalidPasswordNotification"
#define kXfireJoinChatRoomPasswordRequiredNotification @"kXfireJoinChatRoomPasswordRequiredNotification"
#define kXfireDidJoinChatRoomNotification @"kXfireDidJoinChatRoomNotification"
#define kXfireUpdatedChatRoomInfoNotification @"kXfireUpdatedChatRoomInfoNotification"
#define kXfireFriendDidJoinChatRoomNotification @"kXfireFriendDidJoinChatRoomNotification"
#define kXfireUserDidLeaveChatRoomNotification @"kXfireUserDidLeaveChatRoomNotification"
#define kXfireUserKickedFromChatRoomNotification @"kXfireUserKickedFromChatRoomNotification"

#define kAllowVibrateAlerts @"kAllowVibrateAlerts"
#define kAllowAudioAlerts @"kAllowAudioAlerts"
