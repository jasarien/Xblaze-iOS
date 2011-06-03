/*******************************************************************
	FILE:		XfireFriendGroupController.h
	
	COPYRIGHT:
		Copyright 2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Manages XfireFriendGroup memberships for XfireFriend objects
		associated with a given Xfire session.  The friend groups
		are maintained on the Xfire server, so this must be part of
		the Xfire service.
	
	HISTORY:
		2008 09 30  Created.
*******************************************************************/

#import <Foundation/Foundation.h>
#import "XfireFriendGroup.h"

@class XfireFriend;
@class XfireSession;

@interface XfireFriendGroupController : NSObject
{
	NSMutableArray		*_groups;
	XfireSession		*_session;
	SEL					_groupSortSelector;
}

- (id)initWithSession:(XfireSession *)session;

// Group management
- (NSArray*)groups;
- (NSArray*)groupsExcludingClans;
- (XfireFriendGroup *)groupForMember:(XfireFriend *)member;
- (NSArray*)clans;
- (void)addClanWithID:(int)clanID name:(NSString *)name shortName:(NSString *)shortName;
- (void)addCustomGroupNamed:(NSString *)aName withID:(int)groupID;
- (void)setGroupList:(NSArray *)setGroups; // array of NSNumber containing group IDs
- (void)sortGroups;
- (void)renameGroup:(XfireFriendGroup *)group toName:(NSString *)aName;
- (void)removeGroup:(XfireFriendGroup *)group;
- (void)ensureStandardGroup:(XfireFriendGroupType)groupType;

// may return nil
- (XfireFriendGroup *)standardGroupOfType:(XfireFriendGroupType)groupType;

// called on XfireFriendGroup:
// Not currently configurable
// Signature should be: -(NSComparisonResult)compare:(XfireFriendGroup*)grp;
//- (void)setGroupSortSelector:(SEL)aSelector;

// Friend management
- (void)addFriend:(XfireFriend *)fr toGroupWithID:(int)groupID;
- (void)addPendingMemberID:(unsigned int)userID groupID:(int)gid;
- (void)addFriend:(XfireFriend *)fr;
- (void)removeFriend:(XfireFriend *)fr;
- (void)removeFriend:(XfireFriend *)fr fromGroup:(XfireFriendGroup *)group;
- (void)friendWentOffline:(XfireFriend *)fr;
- (void)friendCameOnline:(XfireFriend *)fr;

@end

@interface NSArray (XfireAdditions)
- (XfireFriendGroup *)groupForID:(int)groupID;
@end
