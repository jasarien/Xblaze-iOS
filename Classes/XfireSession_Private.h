/*******************************************************************
	FILE:		XfireSession_Private.h
	
	COPYRIGHT:
		Copyright 2007-2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Interfaces to XfireSession that are private to the Xfire
		protocol library.  These are used in various places of the
		library support classes.
	
	HISTORY:
		2008 04 06  Changed copyright to BSD license.
		2008 01 12  Began integration into final phase of MacFire
		            project.  Added copyright notice.
		2007 11 20  Created.
*******************************************************************/

#import "XfireSession.h"

@class XfireFriendGroupController;

@interface XfireSession (Private)

// Set session status
- (void)setStatus:(XfireSessionStatus)aStatus;

// Change friends list
- (void)addFriend:(XfireFriend *)fr;
- (void)removeFriend:(XfireFriend *)fr;
- (void)addClanMember:(XfireFriend *)fr;
- (void)removeClanMember:(XfireFriend *)fr;
- (void)addPendingFriend:(XfireFriend *)fr;
- (void)removePendingFriend:(XfireFriend *)fr;
- (XfireFriend *)pendingFriendForSessionID:(NSData *)anSid;

- (void)setLatestClientVersion:(unsigned int)ver;

- (XfireFriendGroupController *)friendGroupController;
- (void)addFriend:(XfireFriend *)fr toGroup:(XfireFriendGroup *)grp;
- (void)removeFriend:(XfireFriend *)fr fromGroup:(XfireFriendGroup *)grp;

// sets the dictionary without causing events to be triggered
- (void)_privateSetUserOptions:(NSDictionary *)options;

// For XfireLoginConnection to notify of login failure for clean abort
- (void)loginFailed:(NSString *)reason;

//- (void)connectionDidTerminate:(XfireConnection *)conn;

// Session delegation helpers

// For - (void)xfireGetSession:(XfireSession *)session userName:(NSString **)aName password:(NSString **)password;
- (void)delegate_getUserName:(NSString **)uname password:(NSString **)pword;
// For - (void)xfireSessionWillDisconnect:(XfireSession *)session reason:(NSString *)reason;
- (void)delegate_sessionWillDisconnect:(NSString *)reason;
// For - (XfireSkin *)xfireSessionSkin:(XfireSession *)session;
- (XfireSkin *)delegate_skin;
// For - (NSString *)xfireSessionLogPath:(XfireSession *)session;
- (NSString *)delegate_sessionLogPath;
// For - (void)xfireSession:(XfireSession *)session nicknameDidChange:(NSString *)newNick;
- (void)delegate_nicknameDidChange:(NSString *)newNick;
// For - (void)xfireSession:(XfireSession *)session searchResults:(NSArray *)friends;
- (void)delegate_searchResults:(NSArray *)friends;
// For - (void)xfireSession:(XfireSession *)session didReceiveFriendshipRequests:(NSArray *)requestors;
- (void)delegate_didReceiveFriendshipRequests:(NSArray *)requestors;
// For - (void)xfireSession:(XfireSession *)session friendDidChange:(XfireFriend *)fr attribute:(XfireFriendChangeAttribute)attr;
- (void)delegate_friendDidChange:(XfireFriend *)fr attribute:(XfireFriendChangeAttribute)attr;
// For - (void)xfireSession:(XfireSession *)session friendGroupDidChange:(XfireFriendGroup *)grp;
- (void)delegate_friendGroupDidChange:(XfireFriendGroup *)grp;
// For - (void)xfireSession:(XfireSession *)session friendGroupWasAdded:(XfireFriendGroup *)grp;
- (void)delegate_friendGroupWasAdded:(XfireFriendGroup *)grp;
// For - (void)xfireSession:(XfireSession *)session friendGroupWillBeRemoved:(XfireFriendGroup *)grp;
- (void)delegate_friendGroupWillBeRemoved:(XfireFriendGroup *)grp;
// For - (void)xfireSession:(XfireSession *)session didBeginChat:(XfireChat *)chat;
- (void)delegate_didBeginChat:(XfireChat *)chat;
// For - (void)xfireSession:(XfireSession *)session chatDidEnd:(XfireChat *)aChat;
- (void)delegate_chatDidEnd:(XfireChat *)chat;

- (void)delegate_joinChatRoomInvalidPassword;
- (void)delegate_joinChatRoomPasswordRequired;
- (void)delegate_didJoinChatRoom:(XfireChatRoom *)chatRoom;
- (void)delegate_updatedInfoForChatRoom:(XfireChatRoom *)chatRoom;
- (void)delegate_user:(XfireFriend *)user didJoinChatRoom:(XfireChatRoom *)chatRoom;
- (void)delegate_userDidLeaveChatRoom:(XfireChatRoom *)chatRoom;
- (void)delegate_receivedChatRoomInviteFrom:(XfireFriend *)friend forChatRoom:(XfireChatRoom *)chatRoom;
- (void)delegate_user:(XfireFriend *)user kickedFromChatRoom:(XfireChatRoom *)chatRoom;

@end
