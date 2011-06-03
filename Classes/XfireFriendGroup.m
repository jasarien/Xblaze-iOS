/*******************************************************************
	FILE:		XfireFriendGroup.m
	
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

#import "XfireFriendGroup.h"
#import "XfireFriendGroup_Private.h"
#import "XfireFriend.h"
#import "XfireSession_Private.h"

@implementation XfireFriendGroup

- (id)initCustomWithID:(int)groupID name:(NSString *)groupName session:(XfireSession *)session
{
	self = [super init];
	if( self )
	{
		_name = [groupName copy];
		_groupID = groupID;
		_members = [[NSMutableArray alloc] init];
		_pendingMembers = [[NSMutableArray alloc] init];
		_groupType = kXfireFriendGroupCustom;
		_friendSortSelector = @selector(compareFriendsByUserName:);
		_session = session;
	}
	return self;
}

- (id)initDynamicType:(XfireFriendGroupType)type session:(XfireSession *)session
{
	self = [super init];
	if( self )
	{
		_name = nil;
		_members = [[NSMutableArray alloc] init];
		_pendingMembers = nil; // Not applicable
		_session = session;
		_friendSortSelector = @selector(compareFriendsByUserName:);
		_groupType = type;
		_groupID = -1;
		if( type == kXfireFriendGroupOnline )
		{
			_groupID = kXfireFriendGroupOnlineID;
			_name = [@"Online Friends" copy];
		}
		else if( type == kXfireFriendGroupFriendOfFriends )
		{
			_groupID = kXfireFriendGroupFriendOfFriendsID;
			_name = [@"Friends of Friends Playing" copy];
		}
		else if( type == kXfireFriendGroupOffline )
		{
			_groupID = kXfireFriendGroupOfflineID;
			_name = [@"Offline Friends" copy];
		}
		else
		{
			[self release];
			return nil;
		}
	}
	return self;
}

- (id)initWithClanID:(int)clanID name:(NSString *)name shortName:(NSString *)shortName session:(XfireSession *)session
{
	if ((self = [super init]))
	{
		_groupID = clanID;
		_name = [name copy];
		_shortName = [shortName copy];
		_groupType = kXfireFriendGroupClan;
		_session = session;
		
		_members = [[NSMutableArray alloc] init];
		_pendingMembers = nil; // N/A
		_friendSortSelector = @selector(compareFriendsByUserName:);
	}
	
	return self;
}

- (void)dealloc
{
	[_name release];
	[_shortName release];
	[_members release];
	[_pendingMembers release];
	_name = nil;
	_shortName = nil;
	_members = nil;
	_pendingMembers = nil;
	[super dealloc];
}

- (XfireFriendGroupType)groupType
{
	return _groupType;
}

- (void)setGroupName:(NSString *)aName
{
	[aName retain];
	[_name release];
	_name = aName;
}

- (NSString *)groupName
{
	return _name;
}

- (void)setShortName:(NSString *)shortName
{
	[_shortName release];
	_shortName = [shortName retain];
}

- (NSString *)shortName
{
	return _shortName;
}

- (int)groupID
{
	return _groupID;
}

- (NSArray *)members
{
	return _members;
}

- (unsigned)numberOfMembers
{
	return [_members count];
}

- (XfireFriend *)memberAtIndex:(unsigned)idx
{
	XfireFriend *friend = nil;
	
	@try
	{
		friend = [_members objectAtIndex:idx];
	}
	@catch (NSException * e)
	{
		DebugLog(@"Error: index (%u) out of bounds (%u)", idx, [_members count] - 1);
	}
	
	return friend;
}

- (NSUInteger)indexOfMember:(XfireFriend *)friend
{
	return [_members indexOfObject:friend];
}

// external interface
- (void)addFriend:(XfireFriend *)fr
{
	if( _groupType == kXfireFriendGroupCustom )
	{
		if( ![self friendIsMember:fr] )
		{
			[_session addFriend:fr toGroup:self];
		}
	}
}

// internal interface
// TODO: consolidate addFriend: and addMember:
- (void)addMember:(XfireFriend *)fr
{
	int idx = [self indexOfPendingMember:[fr userID]];
	if( idx != -1 )
	{
		[_pendingMembers removeObjectAtIndex:idx];
	}
	[_members addObject:fr];
	[self sortMembers];
}

- (void)removeFriend:(XfireFriend *)fr
{
	if( _groupType == kXfireFriendGroupCustom )
	{
		if( [self friendIsMember:fr] )
		{
			[_session removeFriend:fr fromGroup:self];
		}
	}
}

- (void)removeMember:(XfireFriend *)fr
{
	[_members removeObject:fr];
}

- (BOOL)friendIsMember:(XfireFriend *)fr
{
	return [_members containsObject:fr];
}

- (void)addPendingMemberID:(unsigned int)userID
{
	[_pendingMembers addObject:[NSNumber numberWithUnsignedInt:userID]];
}

- (int)indexOfPendingMember:(unsigned int)userID
{
	int i, cnt;
	cnt = [_pendingMembers count];
	for( i = 0; i < cnt; i++ )
	{
		if( [[_pendingMembers objectAtIndex:i] unsignedIntValue] == userID )
		{
			return i;
		}
	}
	
	return -1;
}

- (BOOL)friendShouldBeMember:(XfireFriend *)fr
{
	XfireFriendGroupType type = [self groupType];
	
	if (type == kXfireFriendGroupClan)
	{
		if ([fr isClanMember] && ([fr clanID] == [self groupID]))
		{
			return YES;
		}
	}
	else if( type == kXfireFriendGroupCustom )
	{
		if( [self indexOfPendingMember:[fr userID]] != -1 )
			return YES;
	}
	else if( type == kXfireFriendGroupFriendOfFriends )
	{
		if( [fr isFriendOfFriend] )
			return YES;
	}
	else if( type == kXfireFriendGroupOnline )
	{
		if( [fr isOnline] && [fr isDirectFriend])
			return YES;
	}
	else if( type == kXfireFriendGroupOffline )
	{
		if( ![fr isOnline] && [fr isDirectFriend])
			return YES;
	}
	
	return NO;
}

- (void)setFriendSortSelector:(SEL)aSelector
{
	if( [XfireFriend instancesRespondToSelector:aSelector] )
	{
		_friendSortSelector = aSelector;
	}
}

- (void)sortMembers
{
	if( _friendSortSelector )
	{
		[_members sortUsingSelector:_friendSortSelector];
	}
}


// Ordering is
// 1. Custom groups ordered by display name
// 2. Online group
// 3. Friends of Friends group
// 4. Offline group
- (NSComparisonResult)compareGroups:(XfireFriendGroup *)aGroup
{
	XfireFriendGroupType ourType = [self groupType];
	XfireFriendGroupType otherType = [aGroup groupType];
	
	if( ourType == kXfireFriendGroupOffline )
	{
		return NSOrderedDescending;
	}
	else if( ourType == kXfireFriendGroupFriendOfFriends )
	{
		if( otherType == kXfireFriendGroupOffline )
			return NSOrderedAscending;
		else
			return NSOrderedDescending;
	}
	else if( ourType == kXfireFriendGroupOnline )
	{
		if( (otherType == kXfireFriendGroupOffline) ||
			(otherType == kXfireFriendGroupFriendOfFriends) )
		{
			return NSOrderedAscending;
		}
		if( otherType == kXfireFriendGroupCustom )
		{
			return NSOrderedDescending;
		}
	}
	else if( ourType == kXfireFriendGroupCustom )
	{
		if( otherType == kXfireFriendGroupCustom )
		{
			return [[self groupName] localizedCaseInsensitiveCompare:[aGroup groupName]];
		}
		return NSOrderedAscending;
	}
	
	// give up
	return NSOrderedSame;
}

- (NSString *)description
{
	NSMutableString *str = [NSMutableString string];
	XfireFriend *fr;
	int i, cnt;
	
	[str appendFormat:@"XfireFriendGroup name %@ {\n",[self groupName]];
	cnt = [_members count];
	for( i = 0; i < cnt; i++ )
	{
		fr = [_members objectAtIndex:i];
		[str appendFormat:@"   %@\n", [fr userName]];
	}
	[str appendFormat:@"}\n"];
	
	return str;
}

- (NSArray *)offlineMembers
{
	NSMutableArray *offline = [NSMutableArray array];
	
	for (XfireFriend *friend in _members)
	{
		if (![friend isOnline])
		{
			[offline addObject:friend];
		}
	}
	
	return [[offline copy] autorelease];
}

- (NSArray *)onlineMembers
{
	NSMutableArray *online = [NSMutableArray array];
	
	for (XfireFriend *friend in _members)
	{
		if ([friend isOnline])
		{
			[online addObject:friend];
		}
	}
	
	return [[online copy] autorelease];
}

@end
