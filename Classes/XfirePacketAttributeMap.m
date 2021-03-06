/*******************************************************************
	FILE:		XfirePacketAttributeMap.m
	
	COPYRIGHT:
		Copyright 2007-2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Represents a packet map in an XfirePacket.  It's basically a
		wrapper around NSMutableDictionary that includes an array
		to order the keys.  It guarantees that keys are traversed in
		the same order as they are inserted.  This is protection against
		certain other implementations that my not work right (and a
		CYA in case order of attributes does matter).
	
	HISTORY:
		2008 04 06  Changed copyright to BSD license.
		2008 01 12  Added copyright notice.
		2007 11 14  Created.
*******************************************************************/

#import "XfirePacketAttributeMap.h"

@implementation XfirePacketAttributeMap

+ (id)map
{
	return [[[XfirePacketAttributeMap alloc] init] autorelease];
}

- (id)init
{
	self = [super init];
	if( self )
	{
		_orderedKeys = [[NSMutableArray array] retain];
		_data = [[NSMutableDictionary dictionary] retain];
	}
	return self;
}

- (void)dealloc
{
	[_orderedKeys release];
	[_data release];
	_orderedKeys = nil;
	_data = nil;
	[super dealloc];
}

- (void)setObject:(XfirePacketAttributeValue *)value forKey:(id)aKey
{
	if( (aKey == nil) || (value == nil) )
	{
		@throw [NSException exceptionWithName:@"XfirePacketAttributeMap" reason:@"Attempt to insert nil key or value into attribute map" userInfo:nil];
	}
	if( ! ([aKey isKindOfClass:[NSString class]] || [aKey isKindOfClass:[NSNumber class]]) )
	{
		@throw [NSException exceptionWithName:@"XfirePacketAttributeMap" reason:@"Attempt to insert key not of type NSString or NSNumber" userInfo:nil];
	}
	
	[_orderedKeys addObject:aKey];
	[_data setObject:value forKey:aKey];
}

- (XfirePacketAttributeValue *)objectForKey:(id)aKey
{
	return [_data objectForKey:aKey];
}

- (NSEnumerator *)keyEnumerator
{
	return [_orderedKeys objectEnumerator];
}

- (unsigned)count
{
	return [_data count];
}

- (NSString *)description
{
	NSMutableString *s = [NSMutableString string];
	id k, v;
	int i, cnt;
	cnt = [self count];
	[s appendString:@"AttrMap {\n"];
	for( i = 0; i < cnt; i++ )
	{
		k = [_orderedKeys objectAtIndex:i];
		v = [_data objectForKey:k];
		if( [k isKindOfClass:[NSNumber class]] )
			k = [NSString stringWithFormat:@"0x%x",[k unsignedIntValue]];
		[s appendFormat:@"\t%@ = %@\n",k,v];
	}
	[s appendString:@"}\n"];
	return s;
}

@end
