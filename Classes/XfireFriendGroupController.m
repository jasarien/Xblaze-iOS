/*******************************************************************
	FILE:		XfireFriendGroupController.m
	
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

#import "XfireFriendGroupController.h"
#import "XfireFriendGroup_Private.h"
#import "XfireFriend.h"
#import "XfireSession_Private.h"

@interface XfireFriendGroupController (Private)
- (void)addFriend:(XfireFriend *)fr toGroup:(XfireFriendGroup *)group;
- (XfireFriendGroup *)newStandardGroupOfType:(XfireFriendGroupType)type;
@end

@implementation XfireFriendGroupController

- (id)initWithSession:(XfireSession *)session
{
	self = [super init];
	if( self )
	{
		_groups = [[NSMutableArray alloc] init];
		_session = session;
		_groupSortSelector = @selector(compareGroups:);
	}
	return self;
}

- (void)dealloc
{
	[_groups release];
	_groups = nil;
	_session = nil;
	
	[super dealloc];
}

- (NSArray*)groups
{
	return _groups;
}


- (NSArray*)groupsExcludingClans
{
	NSMutableArray *groupsExcludingClans = [NSMutableArray array];
	
	for (XfireFriendGroup *group in _groups)
	{
		if ([group groupType] != kXfireFriendGroupClan)
		{
			[groupsExcludingClans addObject:group];
		}
	}
	
	return [[groupsExcludingClans copy] autorelease];
}

- (XfireFriendGroup *)groupForMember:(XfireFriend *)member
{
	XfireFriendGroup *group = nil;
	NSArray *groups;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		groups = [self groups];
	else
		groups = [self groupsExcludingClans];
	
	for (XfireFriendGroup *g in groups)
	{
		if ([g indexOfMember:member] != NSNotFound)
		{
			group = g;
			break;
		}
	}
	
	return group;
}

- (NSArray*)clans
{
	NSMutableArray *clans = [NSMutableArray array];
	
	for (XfireFriendGroup *clan in _groups)
	{
		if ([clan groupType] == kXfireFriendGroupClan)
		{
			[clans addObject:clan];
		}
	}
	
	return [[clans copy] autorelease];
}

- (void)addClanWithID:(int)clanID name:(NSString *)name shortName:(NSString *)shortName
{
	XfireFriendGroup *clan = nil;
	clan = [_groups groupForID:clanID];
	
	if (clan)
	{
		DebugLog(@"Clan already exists!");
		return;
	}
	
	clan = [[XfireFriendGroup alloc] initWithClanID:clanID name:name shortName:shortName session:_session];
	[_groups addObject:clan];
	[clan release];
	[self sortGroups];
	
	[_session delegate_friendGroupWasAdded:clan];
}

- (void)addCustomGroupNamed:(NSString *)aName withID:(int)groupID
{
	XfireFriendGroup *grp;
	
	grp = [_groups groupForID:groupID];
	if( grp != nil )
	{
		DebugLog(@"Group already exists! (\"%@\", ID %d)", aName, groupID);
		return;
	}
	
	grp = [[XfireFriendGroup alloc] initCustomWithID:groupID name:aName session:_session];
	[_groups addObject:grp];
	[grp release];
	[self sortGroups];
	
	[_session delegate_friendGroupWasAdded:grp];
}

// Public interface
- (void)ensureStandardGroup:(XfireFriendGroupType)groupType
{
	XfireFriendGroup *grp;
	
	if( groupType == kXfireFriendGroupOnline )
	{
		grp = [_groups groupForID:kXfireFriendGroupOnlineID];
		if( !grp )
		{
			grp = [self newStandardGroupOfType:kXfireFriendGroupOnline];
			[_groups addObject:grp];
			[grp release];
			
			[_session delegate_friendGroupWasAdded:grp];
			[grp sortMembers];
		}
	}
	else if( groupType == kXfireFriendGroupOffline )
	{
		grp = [_groups groupForID:kXfireFriendGroupOfflineID];
		if( !grp )
		{
			grp = [self newStandardGroupOfType:kXfireFriendGroupOffline];
			[_groups addObject:grp];
			[grp release];
			
			[_session delegate_friendGroupWasAdded:grp];
			[grp sortMembers];
		}
	}
	else if( groupType == kXfireFriendGroupFriendOfFriends )
	{
		grp = [_groups groupForID:kXfireFriendGroupFriendOfFriendsID];
		if( !grp )
		{
			grp = [self newStandardGroupOfType:kXfireFriendGroupFriendOfFriends];
			[_groups addObject:grp];
			[grp release];
			
			[_session delegate_friendGroupWasAdded:grp];
			[grp sortMembers];
		}
	}
	
	[self sortGroups];
}

- (XfireFriendGroup *)newStandardGroupOfType:(XfireFriendGroupType)type
{
	XfireFriendGroup *grp;
	
	grp = [[XfireFriendGroup alloc] initDynamicType:type session:_session];
	
	// This can be called while we're online (e.g. if preference changes) and not just at startup
	// So we need to populate the group with any friends we already have
	NSArray *friends = [_session friends];
	XfireFriend *fr;
	int i, cnt;
	cnt = [friends count];
	for( i = 0; i < cnt; i++ )
	{
		fr = [friends objectAtIndex:i];
		if( [grp friendShouldBeMember:fr] && ![grp friendIsMember:fr] )
		{
			[grp addMember:fr];
		}
	}
	
	return grp;
}

// This packet doesn't contain every group, but it does appear to identify whether
// a standard group is listed.  So, we look for the standard group IDs and add them
// to the list if they are present.
- (void)setGroupList:(NSArray *)setGroups
{
	int i, cnt;
	int newID;
	XfireFriendGroup *grp;
	
	cnt = [setGroups count];
	for( i = 0; i < cnt; i++ )
	{
		newID = [[setGroups objectAtIndex:i] intValue];
		grp = [_groups groupForID:newID];
		if( grp == nil )
		{
			if( newID == kXfireFriendGroupOnlineID )
			{
				grp = [self newStandardGroupOfType:kXfireFriendGroupOnline];
				[_groups addObject:grp];
				[grp release];
				
				[_session delegate_friendGroupWasAdded:grp];
			}
			else if( newID == kXfireFriendGroupOfflineID )
			{
				if( [_session shouldShowOfflineFriends] )
				{
					grp = [self newStandardGroupOfType:kXfireFriendGroupOffline];
					[_groups addObject:grp];
					[grp release];
					
					[_session delegate_friendGroupWasAdded:grp];
				}
			}
			else if( newID == kXfireFriendGroupFriendOfFriendsID )
			{
				if( [_session shouldShowFriendsOfFriends] )
				{
					grp = [self newStandardGroupOfType:kXfireFriendGroupFriendOfFriends];
					[_groups addObject:grp];
					[grp release];
					
					[_session delegate_friendGroupWasAdded:grp];
				}
			}
		}
	}
	
	[self sortGroups];
}

- (void)sortGroups
{
	if( _groupSortSelector )
		[_groups sortUsingSelector:_groupSortSelector];
}

- (void)renameGroup:(XfireFriendGroup *)group toName:(NSString *)aName
{
	[group setGroupName:aName];
	[self sortGroups];
	[_session delegate_friendGroupDidChange:group];
}

- (void)removeGroup:(XfireFriendGroup *)group
{
	[_session delegate_friendGroupWillBeRemoved:group];
	[_groups removeObject:group];
	[_session delegate_friendGroupDidChange:group];
}

- (XfireFriendGroup *)standardGroupOfType:(XfireFriendGroupType)groupType
{
	int i, cnt;
	cnt = [_groups count];
	for( i = 0; i < cnt; i++ )
	{
		XfireFriendGroup *grp;
		grp = [_groups objectAtIndex:i];
		
		if( (groupType == kXfireFriendGroupOnline) && ([grp groupID] == kXfireFriendGroupOnlineID) )
		{
			return grp;
		}
		else if( (groupType == kXfireFriendGroupOffline) && ([grp groupID] == kXfireFriendGroupOfflineID) )
		{
			return grp;
		}
		else if( (groupType == kXfireFriendGroupFriendOfFriends) && ([grp groupID] == kXfireFriendGroupFriendOfFriendsID) )
		{
			return grp;
		}
	}
	
	return nil;
}

#if 0
- (void)setGroupList:(NSArray *)setGroups
{
	NSMutableArray *newGroups = [[NSMutableArray alloc] init];
	NSMutableArray *curGroups;
	int i, cnt;
	int newID;
	XfireFriendGroup *grp;
	
	// Find or create all groups in the new list
	curGroups = [NSMutableArray arrayWithArray:_groups];
	cnt = [setGroups count];
	for( i = 0; i < cnt; i++ )
	{
		newID = [[setGroups objectAtIndex:i] intValue];
		grp = [curGroups groupForID:newID];
		if( grp != nil )
		{
			// check current groups first
			[newGroups addObject:grp];
			[curGroups removeObject:grp];
			[_session delegate_friendGroupWasAdded:grp];
		}
		else if( newID == kXfireFriendGroupOnlineID )
		{
			// not a current group, but now we are adding one of the standard groups
			grp = [self createStandardGroupOfType:kXfireFriendGroupOnline];
			[newGroups addObject:grp];
			[_session delegate_friendGroupWasAdded:grp];
			[grp release];
		}
		else if( newID == kXfireFriendGroupOfflineID )
		{
			// not a current group, but now we are adding one of the standard groups
			grp = [self createStandardGroupOfType:kXfireFriendGroupOffline];
			[newGroups addObject:grp];
			[_session delegate_friendGroupWasAdded:grp];
			[grp release];
		}
		else if( newID == kXfireFriendGroupFriendOfFriendsID )
		{
			// not a current group, but now we are adding one of the standard groups
			grp = [self createStandardGroupOfType:kXfireFriendGroupFriendOfFriends];
			[newGroups addObject:grp];
			[grp release];
			
			[_session delegate_friendGroupWasAdded:grp];
		}
		else // better be a pending group
		{
			
			grp = [_pendingGroups groupForID:newID];
			if( grp )
			{
				[newGroups addObject:grp];
				[_pendingGroups removeObject:grp];
				[_session delegate_friendGroupWasAdded:grp];
			}
		}
	}
	
	// Any leftover current groups get deleted (not in the new list)
	cnt = [curGroups count];
	for( i = 0; i < cnt; i++ )
	{
		[_session delegate_friendGroupWillBeRemoved:[curGroups objectAtIndex:0]];
		[curGroups removeObjectAtIndex:0];
	}
	
	// assign the new group list and re-sort
	[_groups release];
	_groups = newGroups;
	if( _groupSortSelector )
		[_groups sortUsingSelector:_groupSortSelector];
}
#endif

- (void)addFriend:(XfireFriend *)fr toGroupWithID:(int)groupID
{
	XfireFriendGroup *group = [_groups groupForID:groupID];
	[self addFriend:fr toGroup:group];
}

- (void)addFriend:(XfireFriend *)fr toGroup:(XfireFriendGroup *)group
{
	if( [group friendShouldBeMember:fr] && ![group friendIsMember:fr] )
	{
		[group addMember:fr];
		[_session delegate_friendGroupDidChange:group];
	}
}

- (void)removeFriend:(XfireFriend *)fr fromGroup:(XfireFriendGroup *)group
{
	if( [group friendIsMember:fr] )
	{
		[group removeMember:fr];
		[_session delegate_friendGroupDidChange:group];
	}
}

- (void)addFriend:(XfireFriend *)fr
{
	int i, cnt;
	cnt = [_groups count];
	for( i = 0; i < cnt; i++ )
	{
		[self addFriend:fr toGroup:[_groups objectAtIndex:i]];
	}
}

- (void)removeFriend:(XfireFriend *)fr
{
	int i, cnt;
	cnt = [_groups count];
	for( i = 0; i < cnt; i++ )
	{
		if ([[_groups objectAtIndex:i] groupType] != kXfireFriendGroupClan)
			[self removeFriend:fr fromGroup:[_groups objectAtIndex:i]];
	}
}

- (void)friendWentOffline:(XfireFriend *)fr
{
	// remove from Online group
	// add to Offline group
	
	[self removeFriend:fr fromGroup:[_groups groupForID:kXfireFriendGroupOnlineID]];
	[self addFriend:fr      toGroup:[_groups groupForID:kXfireFriendGroupOfflineID]];
}

- (void)friendCameOnline:(XfireFriend *)fr
{
	// remove from Offline group
	// add to Online group
	
	[self removeFriend:fr fromGroup:[_groups groupForID:kXfireFriendGroupOfflineID]];
	[self addFriend:fr      toGroup:[_groups groupForID:kXfireFriendGroupOnlineID]];
}

- (void)addPendingMemberID:(unsigned int)userID groupID:(int)gid
{
	XfireFriendGroup *grp = [_groups groupForID:gid];
	if( grp )
	{
		[grp addPendingMemberID:userID];
	}
}

@end


@implementation NSArray (XfireAdditions)

- (XfireFriendGroup *)groupForID:(int)groupID
{
	int i, cnt;
	XfireFriendGroup *grp;
	
	cnt = [self count];
	for( i = 0; i < cnt; i++ )
	{
		grp = [self objectAtIndex:i];
		if( [grp groupID] == groupID )
		{
			return grp;
		}
	}
	
	return nil;
}

@end
