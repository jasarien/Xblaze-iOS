/*******************************************************************
	FILE:		XfireFriendGroup.h
	
	COPYRIGHT:
		Copyright 2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Reflects friend groups, including the standard dynamic and the
		custom groups.  These are stored on the Xfire chat server and
		require network support.
	
	HISTORY:
		2008 09 28  Created.
*******************************************************************/

#import <Foundation/Foundation.h>

@class XfireFriend;
@class XfireSession;

typedef enum {
	kXfireFriendGroupOnline = 1,
	kXfireFriendGroupOffline,
	kXfireFriendGroupFriendOfFriends,
	kXfireFriendGroupCustom,
	kXfireFriendGroupClan
} XfireFriendGroupType;

@interface XfireFriendGroup : NSObject
{
	int						_groupID; //also used for clan IDs if the group is a clan
	NSString				*_name;
	NSString				*_shortName; // only used if the group is a clans
	NSMutableArray			*_members;
	NSMutableArray			*_pendingMembers;
	XfireFriendGroupType	_groupType;
	XfireSession			*_session;
	SEL						_friendSortSelector;
}

- (XfireFriendGroupType)groupType;
- (void)setGroupName:(NSString *)aName;
- (NSString *)groupName;
- (void)setShortName:(NSString *)shortName;
- (NSString *)shortName;
- (int)groupID;

- (unsigned)numberOfMembers;
- (XfireFriend *)memberAtIndex:(unsigned)idx;
- (NSUInteger)indexOfMember:(XfireFriend *)friend;
- (BOOL)friendIsMember:(XfireFriend *)fr;
- (void)addFriend:(XfireFriend *)fr;
- (void)removeFriend:(XfireFriend *)fr;
- (void)removeMember:(XfireFriend *)fr;

- (NSArray *)offlineMembers;
- (NSArray *)onlineMembers;

// This selector is sent to the XfireFriend, so you should define your own
// category with associated selector in order to use this.  This is called by an
// NSMutableArray -sortUsingSelector: so the selector passed here should
// follow that convention.  The default behavior is to sort by username.
- (void)setFriendSortSelector:(SEL)aSelector;

@end
