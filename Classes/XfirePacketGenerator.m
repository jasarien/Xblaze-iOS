/*******************************************************************
	FILE:		XfirePacketGenerator.m
	
	COPYRIGHT:
		Copyright 2007-2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Helps generating packets.  It flattens the XfirePacketAttributeMap
		into the stream of bytes required by the protocol.
	
	HISTORY:
		2008 04 06  Changed copyright to BSD license.
		2008 01 12  Added copyright notice.
		2007 11 03  Created.
*******************************************************************/

#import "XfirePacketGenerator.h"
#import "NSMutableData_XfireAdditions.h"

#import "XfirePacketAttributeValue.h"
#import "XfirePacketAttributeMap.h"

// the length 65531 is 65536 - 5
// the header is 5 bytes long
// the CHECK_LENGTH is used when generating the non-header part of the packet
#define CHECK_LENGTH(_need)								\
	if( ([_data length] + (_need)) > 65530 ) {			\
		[self raiseException:@"Packet is too long"];	\
	}

// use to debug the generator
#define GENERATOR_VEBOSE_LOG 0


@interface XfirePacketGenerator (Private)
- (id)initWithID:(XfirePacketID)anID attributes:(XfirePacketAttributeMap *)attrs;

- (void)raiseException:(NSString *)desc;

- (void)generateUInt8:(unsigned char)value;
- (void)generateUInt16:(unsigned short)value;
- (void)generateUInt32:(unsigned int)value;
- (void)generateUUID:(NSData *)uuid; // 16 byte value
- (void)generateString:(NSString *)str;
- (void)generateAttrKeyString:(NSString *)str;
- (void)generateDID:(NSData *)data; // 21 byte value

- (void)generateAttributeMap:(XfirePacketAttributeMap *)attrs;
- (void)generateAttribute:(id)key value:(XfirePacketAttributeValue *)val;
- (void)generateArray:(XfirePacketAttributeValue *)arr;

- (BOOL)keyStringIsNumber:(NSString *)key;
- (int)intForKeyString:(NSString *)key;

@end



@implementation XfirePacketGenerator

+ (id)generatorWithID:(XfirePacketID)anID attributes:(XfirePacketAttributeMap *)attrs
{
	return [[[XfirePacketGenerator alloc] initWithID:anID attributes:attrs] autorelease];
}

- (id)initWithID:(XfirePacketID)anID attributes:(XfirePacketAttributeMap *)attrs
{
	self = [super init];
	if( self )
	{
		_data = [[NSMutableData dataWithCapacity:65536] retain];
		_pktID = anID;
		_attributes = [attrs retain];
	}
	return self;
}

- (void)dealloc
{
	[_data release];
	[_attributes release];
	
	_data = nil;
	_attributes = nil;
	
	[super dealloc];
}

//------------------------------------------------------------------------------------------------
// Generators of Primitive Values
//------------------------------------------------------------------------------------------------

// generate a 1 byte integer
- (void)generateUInt8:(unsigned char)value
{
	CHECK_LENGTH(1);
	
#if GENERATOR_VEBOSE_LOG
	DebugLog(@"XfirePacketGenerator: generating uint8 0x%02x",value);
#endif
	
	[_data appendByte:value];
}

// generate a 2 byte integer, assuming little endian order
- (void)generateUInt16:(unsigned short)value
{
	CHECK_LENGTH(2);
	
#if GENERATOR_VEBOSE_LOG
	DebugLog(@"XfirePacketGenerator: generating uint16 0x%04x",value);
#endif
	
	unsigned char bfr[2];
	
	bfr[0] = (value & 0xFF);
	bfr[1] = ((value >> 8) & 0xFF);
	
	[_data appendBytes:bfr length:2];
}

// generate a 4 byte integer, assuming little endian order
- (void)generateUInt32:(unsigned int)value
{
	CHECK_LENGTH(4);
	
#if GENERATOR_VEBOSE_LOG
	DebugLog(@"XfirePacketGenerator: generating uint16 0x%08x",value);
#endif
	
	unsigned char bfr[4];
	
	bfr[0] = (value & 0xFF);
	bfr[1] = ((value >> 8) & 0xFF);
	bfr[2] = ((value >> 16) & 0xFF);
	bfr[3] = ((value >> 24) & 0xFF);
	
	[_data appendBytes:bfr length:4];
}

// generate a 16 byte integer value, in order
// I figure this is probably a UUID, given how it's used
- (void)generateUUID:(NSData *)uuid
{
	if( [uuid length] != 16 )
		[self raiseException:@"Expected 16 bytes for UUID"];
	
#if GENERATOR_VEBOSE_LOG
	DebugLog(@"XfirePacketGenerator: generating uuid %@",uuid);
#endif
	
	CHECK_LENGTH(16);
	
	[_data appendData:uuid];
}

// scan an attribute key string
// this is a UTF8 string with a leading 1 byte length
- (void)generateAttrKeyString:(NSString *)str
{
	NSData *utf8str = [str dataUsingEncoding:NSUTF8StringEncoding];
	unsigned int strLen = [utf8str length];
	
	CHECK_LENGTH( strLen + 1 );
	
	if( strLen >= 256 )
		[self raiseException:@"Attribute key string is too long for 1 byte length"];
	
	[self generateUInt8:(unsigned char)strLen];
	
#if GENERATOR_VEBOSE_LOG
	DebugLog(@"XfirePacketGenerator: generating attr key string \"%@\"",str);
#endif
	
	[_data appendData:utf8str];
}

// generate a string
// this is a UTF8 string with a leading 2 byte length
- (void)generateString:(NSString *)str
{
	NSData *utf8str = [str dataUsingEncoding:NSUTF8StringEncoding];
	unsigned int strLen = [utf8str length];
	
	CHECK_LENGTH( strLen + 2 );
	
	if( strLen >= 65536 )
		[self raiseException:@"String is too long for 2 byte length"];
	
	[self generateUInt16:(unsigned short)strLen];
	
#if GENERATOR_VEBOSE_LOG
	DebugLog(@"XfirePacketGenerator: generating string \"%@\"",str);
#endif
	
	[_data appendData:utf8str];
}

// 21 byte value
- (void)generateDID:(NSData *)data
{
	if( [data length] != 21 )
		[self raiseException:@"Expected 21 bytes for DID"];
	
	CHECK_LENGTH(21);
	
	[_data appendData:data];
}

//------------------------------------------------------------------------------------------------
// Generators of the Attribute Type Stream
//------------------------------------------------------------------------------------------------

// TODO: sanity check the packet content
// TODO: generate attributes in specific order
- (NSData *)generate
{
	if( [_attributes count] > 255 )
		[self raiseException:@"Too many attributes"];
	
	[self generateAttributeMap:_attributes];
	
	// then prepend the header and return
	unsigned int finalLen = [_data length] + 4;
	
	NSMutableData *tmp = _data;
	
	_data = [[NSMutableData data] retain];
	[self generateUInt16:finalLen];
	[self generateUInt16:_pktID];
	[_data appendData:tmp];
	
	[tmp release];
	
	return _data;
}

- (void)generateAttributeMap:(XfirePacketAttributeMap *)attrs
{
	// first the count byte
	[self generateUInt8:[attrs count]];
	
	// first generate the content, so we can get the length
	NSEnumerator *attrKeyEnumer = [attrs keyEnumerator];
	id theKey;
	while( (theKey = [attrKeyEnumer nextObject]) != nil )
	{
		[self generateAttribute:theKey value:[attrs objectForKey:theKey]];
	}
}

- (void)generateAttribute:(id)key value:(XfirePacketAttributeValue *)val
{
	// generate the key
	// check if the key should be a number or a string
	if( [key isKindOfClass:[NSString class]] )
	{
		if( [[((NSString*)key) substringWithRange:NSMakeRange(0,2)] isEqualToString:@"0x"] )
		{
			int kv = [self intForKeyString:key];
			[self generateUInt8:(unsigned char)kv];
		}
		else
		{
			[self generateAttrKeyString:key];
		}
	}
	else if( [key isKindOfClass:[NSNumber class]] )
	{
		[self generateUInt8:[((NSNumber*)key) unsignedCharValue]];
	}
	else
	{
		[self raiseException:@"Invalid packet attribute key"];
	}
	
	// now generate the value
	switch( [val typeID] )
	{
		case kXfirePacketAttributeStringType:
			[self generateUInt8:0x01];
			[self generateString:((NSString*)[val value])];
			break;
		
		case kXfirePacketAttributeUInt32Type:
			[self generateUInt8:0x02];
			[self generateUInt32:[((NSNumber*)[val value]) unsignedIntValue]];
			break;
		
		case kXfirePacketAttributeUUIDType:
			[self generateUInt8:0x03];
			[self generateUUID:((NSData *)[val value])];
			break;
		
		case kXfirePacketAttributeDIDType:
			[self generateUInt8:0x06];
			[self generateDID:((NSData *)[val value])];
			break;
		
		case kXfirePacketAttributeArrayType:
			[self generateUInt8:0x04];
			[self generateArray:val];
			break;
		
		case kXfirePacketAttributeStringAttrMapType:
			[self generateUInt8:0x05];
			[self generateAttributeMap:((XfirePacketAttributeMap *)[val value])];
			break;
		
		case kXfirePacketAttributeIntAttrMapType:
			[self generateUInt8:0x09];
			[self generateAttributeMap:((XfirePacketAttributeMap *)[val value])];
			break;
		
		case kXfirePacketAttributeUInt8Type:
			[self generateUInt8:0x08];
			[self generateUInt8:[((NSNumber*)[val value]) unsignedCharValue]];
			break;
			
		default:
			[self raiseException:@"Unrecognized attribute value type"];
			break;
	}
}

- (void)generateArray:(XfirePacketAttributeValue *)arrayAttr
{
	unsigned int i, cnt;
	NSArray *arr = [arrayAttr value];
	XfirePacketAttributeValue *pav;
	
	// simple case = empty array
	cnt = [arr count];
	if( cnt == 0 )
	{
		[self generateUInt8:[arrayAttr arrayElementType]];
		[self generateUInt16:0]; // no items in the array
		
		return; // no more to do here
	}
	else if( cnt > 65535 )
	{
		[self raiseException:@"Too many elements in array"];
	}
	
	// generate each element of the array
	switch( [arrayAttr arrayElementType] )
	{
		case kXfirePacketAttributeStringType:
			[self generateUInt8:0x01];
			[self generateUInt16:cnt];
			
			for( i = 0; i < cnt; i++ )
			{
				pav = [arr objectAtIndex:i];
				[self generateString:[pav value]];
			}
			break;
		
		case kXfirePacketAttributeUInt32Type:
			[self generateUInt8:0x02];
			[self generateUInt16:cnt];
			
			for( i = 0; i < cnt; i++ )
			{
				pav = [arr objectAtIndex:i];
				[self generateUInt32:[((NSNumber*)[pav value]) unsignedIntValue]];
			}
			break;
		
		case kXfirePacketAttributeUUIDType:
			[self generateUInt8:0x03];
			[self generateUInt16:cnt];
			
			for( i = 0; i < cnt; i++ )
			{
				pav = [arr objectAtIndex:i];
				[self generateUUID:[pav value]];
			}
			break;
		
		case kXfirePacketAttributeDIDType:
			[self generateUInt8:0x06];
			[self generateUInt16:cnt];
			
			for( i = 0; i < cnt; i++ )
			{
				pav = [arr objectAtIndex:i];
				[self generateDID:[pav value]];
			}
			break;
		
		case kXfirePacketAttributeArrayType:
			[self generateUInt8:0x04];
			[self generateUInt16:cnt];
			
			for( i = 0; i < cnt; i++ )
			{
				pav = [arr objectAtIndex:i];
				[self generateArray:pav];
			}
			break;
		
		case kXfirePacketAttributeStringAttrMapType:
			[self generateUInt8:0x05];
			[self generateUInt16:cnt];
			
			for( i = 0; i < cnt; i++ )
			{
				pav = [arr objectAtIndex:i];
				[self generateAttributeMap:[pav value]];
			}
			break;
		
		case kXfirePacketAttributeIntAttrMapType:
			[self generateUInt8:0x09];
			[self generateUInt16:cnt];
			
			for( i = 0; i < cnt; i++ )
			{
				pav = [arr objectAtIndex:i];
				[self generateAttributeMap:[pav value]];
			}
			break;
		
		default:
			[self raiseException:[NSString stringWithFormat:@"Unrecognized element type while generating array (%d)",
				[arrayAttr arrayElementType]]];
			break;
	}
}

- (BOOL)keyStringIsNumber:(NSString *)key
{
	if( [[key substringWithRange:NSMakeRange(0,2)] isEqualToString:@"0x"] )
	{
		return YES;
	}
	return NO;
}

// scan the hex string format "0x##" and return the integer
- (int)intForKeyString:(NSString *)key
{
	NSString *str = [key substringWithRange:NSMakeRange(2,2)];
	int v;
	const char *utfs = [str UTF8String];
	if( sscanf(utfs,"%x",&v) != 1 )
		[self raiseException:@"Invalid attribute key"];
	return v;
}

- (void)raiseException:(NSString *)desc
{
	@throw [NSException exceptionWithName:@"XfirePacketGeneratorException" reason:desc userInfo:nil];
}

@end
