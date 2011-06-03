/*******************************************************************
	FILE:		XfireFriendGroup.h
	
	COPYRIGHT:
		Copyright 2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Interfaces to XfireFriendGroup that are not public outside
		the Xfire service.
	
	HISTORY:
		2008 09 30  Created.
*******************************************************************/

#import "XfireFriendGroup.h"

enum {
	kXfireFriendGroupOnlineID = 0,
	kXfireFriendGroupOfflineID = 2,
	kXfireFriendGroupFriendOfFriendsID = 1
};

@interface XfireFriendGroup (Private)

- (id)initCustomWithID:(int)groupID name:(NSString *)groupName session:(XfireSession *)session;
- (id)initDynamicType:(XfireFriendGroupType)type session:(XfireSession *)session;
// for creating new clan groups
- (id)initWithClanID:(int)groupID name:(NSString *)name shortName:(NSString *)shortName session:(XfireSession *)session;

// Pending members - apply only to Custom groups
- (void)addPendingMemberID:(unsigned int)userID;
- (int)indexOfPendingMember:(unsigned int)userID;

// These are used by the XfireFriendGroupController to manage groups
- (void)addMember:(XfireFriend *)fr;
- (BOOL)friendShouldBeMember:(XfireFriend *)fr;

- (NSComparisonResult)compareGroups:(XfireFriendGroup *)aGroup;

// force sort
- (void)sortMembers;

@end
