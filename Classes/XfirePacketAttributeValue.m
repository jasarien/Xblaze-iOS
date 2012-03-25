/*******************************************************************
	FILE:		XfirePacketAttributeValue.m
	
	COPYRIGHT:
		Copyright 2007-2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Represents a value in an XfirePacketAttributeMap.  The only
		reason this class exists is to ensure that array types are
		correct when sent packets have empty arrays.  It's a CYA in
		case the Xfire master server requires correct types keys for
		attribute values.  Otherwise it is just a wrapper around
		the various Cocoa types that represent values in Xfire packets.
	
	HISTORY:
		2008 04 06  Changed copyright to BSD license.
		2008 01 12  Added copyright notice.
		2007 11 13  Created.
*******************************************************************/

#import "XfirePacketAttributeValue.h"
#import "XfirePacketAttributeMap.h"

#define ATTRIBUTE_VALUE_LOG 0

@interface XfirePacketAttributeValue (Private)
- (id)initWithValue:(id)aVal typeID:(int)tid arrayType:(int)atid;
+ (int)typeIDForObject:(id)obj;
+ (BOOL)keyIsNumber:(id)key;
@end


@implementation XfirePacketAttributeValue

+ (id)attributeValueWithString:(NSString *)str
{
	return [[[XfirePacketAttributeValue alloc]
		initWithValue:str
		typeID:kXfirePacketAttributeStringType
		arrayType:kXfirePacketAttributeInvalidType
		] autorelease];
}

+ (id)attributeValueWithInt:(unsigned int)val
{
	return [[[XfirePacketAttributeValue alloc]
		initWithValue:[NSNumber numberWithUnsignedInt:val]
		typeID:kXfirePacketAttributeUInt32Type
		arrayType:kXfirePacketAttributeInvalidType
		] autorelease];
}

+ (id)attributeValueWithInt64:(unsigned long long)val
{
	return [[[XfirePacketAttributeValue alloc]
		initWithValue:[NSNumber numberWithUnsignedLongLong:val]
		typeID:kXfirePacketAttributeUInt64Type
		arrayType:kXfirePacketAttributeInvalidType
		] autorelease];
}

+ (id)attributeValueWithByte:(unsigned char)val
{
	return [[[XfirePacketAttributeValue alloc]
		initWithValue:[NSNumber numberWithUnsignedChar:val]
		typeID:kXfirePacketAttributeUInt8Type
		arrayType:kXfirePacketAttributeInvalidType
		] autorelease];
}

+ (id)attributeValueWithNumber:(NSNumber *)nbr
{
	const char *octype = [nbr objCType];
	if( octype )
	{
		if( strcasecmp(octype,"i") == 0 )
		{
			return [[[XfirePacketAttributeValue alloc]
				initWithValue:nbr
				typeID:kXfirePacketAttributeUInt32Type
				arrayType:kXfirePacketAttributeInvalidType
				] autorelease];
		}
	}
	return nil;
}

+ (id)attributeValueWithUUID:(NSData *)uuid
{
	if( [uuid length] == 16 )
	{
		return [[[XfirePacketAttributeValue alloc]
			initWithValue:uuid
			typeID:kXfirePacketAttributeUUIDType
			arrayType:kXfirePacketAttributeInvalidType
			] autorelease];
	}
	return nil;
}

+ (id)attributeValueWithDid:(NSData *)did
{
	if( [did length] == 21 )
	{
		return [[[XfirePacketAttributeValue alloc]
			initWithValue:did
			typeID:kXfirePacketAttributeDIDType
			arrayType:kXfirePacketAttributeInvalidType
			] autorelease];
	}
	return nil;
}

+ (id)attributeValueWithArray:(NSArray *)arr
{
	return [self attributeValueWithArray:arr emptyElementType:kXfirePacketAttributeStringType]; // default type for 0-element array
}

+ (id)attributeValueWithArray:(NSArray *)arr emptyElementType:(int)et
{
	// get the type of the first element, then check other elements
	unsigned int cnt;
#if ATTRIBUTE_VALUE_LOG
	DebugLog(@"attributeValueWithArray:%@ eET:%d",arr,et);
#endif	
	cnt = [arr count];
	if( cnt == 0 )
	{
		return [[[XfirePacketAttributeValue alloc]
			initWithValue:arr
			typeID:kXfirePacketAttributeArrayType
			arrayType:et
			] autorelease];
	}
	
	// Max array size supported by Xfire protocol is technically 65535, though in practice you would
	// blow the size off the entire packet if you did that.  We let the XfirePacketGenerator deal with that since
	// we can't safely pick a size that won't have other problems.
	else if( cnt < 65536 )
	{
		int objType;
		unsigned int i;
		id arrObj;
		
		arrObj = [arr objectAtIndex:0];
		objType = [XfirePacketAttributeValue typeIDForObject:arrObj];
		if( ! [arrObj isKindOfClass:[XfirePacketAttributeValue class]] )
		{
#if ATTRIBUTE_VALUE_LOG
			DebugLog(@"XfirePacketAttributeValue: array element is not a valid class");
#endif
			return nil;
		}
		for( i = 1; i < cnt; i++ )
		{
			arrObj = [arr objectAtIndex:i];
			if( ! [arrObj isKindOfClass:[XfirePacketAttributeValue class]] )
			{
#if ATTRIBUTE_VALUE_LOG
				DebugLog(@"XfirePacketAttributeValue: array element is not a valid class");
#endif
				return nil;
			}
			if( objType != [XfirePacketAttributeValue typeIDForObject:arrObj] )
			{
				// types don't match, abort
#if ATTRIBUTE_VALUE_LOG
				DebugLog(@"XfirePacketAttributeValue: incompatible types while scanning array");
#endif
				return nil;
			}
		}
		
#if ATTRIBUTE_VALUE_LOG
		DebugLog(@"objType %d, et = %d",objType,et);
#endif
		
		return [[[XfirePacketAttributeValue alloc]
			initWithValue:arr
			typeID:kXfirePacketAttributeArrayType
			arrayType:objType
			] autorelease];
	}
	// else don't try
	
	return nil;
}

+ (id)attributeValueWithAttributeMap:(XfirePacketAttributeMap *)map
{
	return [[[XfirePacketAttributeValue alloc]
		initWithValue:map
		typeID:[self typeIDForObject:map]
		arrayType:kXfirePacketAttributeInvalidType
		] autorelease];
}

+ (int)typeIDForObject:(id)obj
{
	if( [obj isKindOfClass:[NSString class]] )
	{
		return kXfirePacketAttributeStringType;
	}
	else if( [obj isKindOfClass:[NSNumber class]] )
	{
		const char *octype = [((NSNumber*)obj) objCType];
		if( octype )
		{
			if( strcasecmp(octype,"i") == 0 )
			{
				return kXfirePacketAttributeUInt32Type;
			}
		}
	}
	else if( [obj isKindOfClass:[NSData class]] )
	{
		unsigned len = [((NSData*)obj) length];
		if( len == 16 )
		{
			return kXfirePacketAttributeUUIDType;
		}
		else if( len == 21 )
		{
			return kXfirePacketAttributeDIDType;
		}
	}
	else if( [obj isKindOfClass:[NSArray class]] )
	{
		return kXfirePacketAttributeArrayType;
	}
	else if( [obj isKindOfClass:[XfirePacketAttributeMap class]] )
	{
		// check key domain
		XfirePacketAttributeMap *map = obj;
		id subkey;
		NSEnumerator *keynumer = [map keyEnumerator];
		BOOL keysAreStrings = NO;
		while( (subkey = [keynumer nextObject]) != nil )
		{
			if( ! [self keyIsNumber:subkey] )
			{
				keysAreStrings = YES;
			}
		}
		
		if( keysAreStrings )
			return kXfirePacketAttributeStringAttrMapType;
		else
			return kXfirePacketAttributeIntAttrMapType;
	}
	else if( [obj isKindOfClass:[XfirePacketAttributeValue class]] )
	{
		XfirePacketAttributeValue *pav = obj;
		return [pav typeID];
	}
	
	// if we fall through to here, return invalid type
	return kXfirePacketAttributeInvalidType;
}

+ (BOOL)keyIsNumber:(id)key
{
#if ATTRIBUTE_VALUE_LOG
	DebugLog(@"keyIsNumber:%@",key);
#endif
	if( [key isKindOfClass:[NSString class]] )
	{
		if( [[key substringWithRange:NSMakeRange(0,2)] isEqualToString:@"0x"] )
		{
			return YES;
		}
	}
	else if( [key isKindOfClass:[NSNumber class]] )
	{
		// TODO: Check objCType ?
		return YES;
	}
	return NO;
}

// This is intended to be used locally only (by the above class methods).
// It assumes the arguments have been vetted and should be consistent
- (id)initWithValue:(id)aVal typeID:(int)tid arrayType:(int)atid
{
	self = [super init];
	if( self )
	{
		_typeID = tid;
		_arrayElementType = atid;
		_value = [aVal retain];

#if ATTRIBUTE_VALUE_LOG
		DebugLog(@"XfirePacketAttributeValue -initWithValue:%@ typeID:%d arrayType:%d",aVal,tid,atid);
#endif
	}
	return self;
}

- (void)dealloc
{
	[_value release];
	[super dealloc];
}

- (int)typeID
{
	return _typeID;
}

- (id)attributeValue
{
	return _value;
}

- (int)arrayElementType
{
	return _arrayElementType;
}

- (NSString *)description
{
	if( [self typeID] == kXfirePacketAttributeStringType )
	{
		return [NSString stringWithFormat: @"[[ Packet Attribute, type = %d, arrType = %d, value = \"%@\" ]]",
			_typeID, _arrayElementType, _value];
	}
	else
	{
		return [NSString stringWithFormat: @"[[ Packet Attribute, type = %d, arrType = %d, value = %@ ]]",
			_typeID, _arrayElementType, _value];
	}
}

@end
