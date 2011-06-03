/*******************************************************************
	FILE:		XfirePacketScanner.m
	
	COPYRIGHT:
		Copyright 2007-2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Scans Xfire packets and creates an XfirePacketAttributeMap
		that contains the contents, if no errors occur.
	
	HISTORY:
		2008 04 06  Changed copyright to BSD license.
		2008 01 12  Added copyright notice.
		2007 10 28  Created.
*******************************************************************/

#import "XfirePacketScanner.h"
#import "XfirePacket.h"
#import "XfirePacketAttributeValue.h"
#import "XfirePacketAttributeMap.h"

#define CHECK_LENGTH_EX(_need,_what)				\
	if( (_idx + (_need)) > _len ) {		\
		[self raiseException:[NSString stringWithFormat:@"Not enough bytes (%d,%d) to scan %@",(_len - (_idx)), (_need),(_what)]];	\
	}

// use to debug the scanner
#define SCANNER_VERBOSE_LOG 0
#define ATTRIBUTE_LOG 0


typedef enum  {
	kXfireAttributeKeyStringDomain  = 1,
	kXfireAttributeKeyIntegerDomain
} XfireAttributeKeyDomain;


@interface XfirePacketScanner (Private)

- (void)raiseException:(NSString *)desc;

// Scan a collection of attributes (key/value pairs)

- (XfirePacketAttributeMap *)scanAttributeMapInDomain:(XfireAttributeKeyDomain)domain;
- (XfireAttributeKeyDomain)keyDomainForPacketType:(unsigned short)type;

// Scan an individual attribute

- (void)scanAttribute:(NSString **)keyOut keyDomain:(XfireAttributeKeyDomain)domain value:(id *)valueOut;

- (XfirePacketAttributeMap *)scanAttributes:(unsigned int)count binaryDeyDomain:(BOOL)binaryKeyDomain;
- (id)scanAttributeValue; // scans just value
- (NSArray *)scanArray;

// Primitive Scanners

- (unsigned char)scanUInt8;
- (unsigned short)scanUInt16;
- (unsigned int)scanUInt32;
- (unsigned long long)scanUInt64;
- (NSData *)scanUUID; // well, a 16 byte/128 bit value, anyway
- (NSString *)scanAttrKeyString;
- (NSString *)scanString;

- (NSData *)scanDataOfLength:(unsigned int)len;

// same as scanUInt8, but doesn't remove from the buffer
// used to peek ahead a little to make a decision, but leave the data to be consumed later
// it assumes we expect a byte to be available
- (unsigned char)peekUInt8;

// Other

- (BOOL)isAtEnd;

@end


@implementation XfirePacketScanner

+ (id)scannerWithData:(NSData *)data
{
	return [[[XfirePacketScanner alloc] initWithData:data] autorelease];
}

- (id)initWithData:(NSData *)dat
{
	self = [super init];
	if( self )
	{
		_dat = dat;
		_idx = 0;
		_len = [_dat length];
		_bytes = [_dat bytes];
	}
	return self;
}

- (BOOL)isAtEnd
{
	return (_idx == _len);
}

//------------------------------------------------------------------------------------------------
// Scanners of Primitive Values
// all the other scanning methods are built on these primitives
//------------------------------------------------------------------------------------------------

// scan a 1 byte integer
- (unsigned char)scanUInt8
{
	CHECK_LENGTH_EX(1,@"uint8");
	
	unsigned char v = _bytes[_idx];
	
#if SCANNER_VERBOSE_LOG
	DebugLog(@"XfirePacketScanner: scanned uint8 0x%02x",v);
#endif
	
	_idx += 1;
	return v;
}

// scan a 2 byte integer, assuming little endian order
- (unsigned short)scanUInt16
{
	CHECK_LENGTH_EX(2,@"uint16");
	
	unsigned short v = (
		((unsigned short)_bytes[_idx]) |
		(((unsigned short)_bytes[_idx+1]) << 8)
		);
	
#if SCANNER_VERBOSE_LOG
	DebugLog(@"XfirePacketScanner: scanned uint16 0x%04x",v);
#endif
	
	_idx += 2;
	return v;
}

// scan a 4 byte integer, assuming little endian order
- (unsigned int)scanUInt32
{
	CHECK_LENGTH_EX(4,@"uint32");
	
	unsigned int v = (
		((unsigned int)_bytes[_idx]) |
		(((unsigned int)_bytes[_idx+1]) << 8) |
		(((unsigned int)_bytes[_idx+2]) << 16) |
		(((unsigned int)_bytes[_idx+3]) << 24)
		);
	
#if SCANNER_VERBOSE_LOG
	DebugLog(@"XfirePacketScanner: scanned uint32 0x%08x",v);
#endif
	
	_idx += 4;
	return v;
}

// scan an 8 byte integer, assuming little endian order
- (unsigned long long)scanUInt64
{
	CHECK_LENGTH_EX(8,@"uint64");
	
	unsigned long long v = (
		((unsigned long long)_bytes[_idx]) |
		(((unsigned long long)_bytes[_idx+1]) << 8) |
		(((unsigned long long)_bytes[_idx+2]) << 16) |
		(((unsigned long long)_bytes[_idx+3]) << 24) |
		(((unsigned long long)_bytes[_idx+4]) << 32) |
		(((unsigned long long)_bytes[_idx+5]) << 40) |
		(((unsigned long long)_bytes[_idx+6]) << 48) |
		(((unsigned long long)_bytes[_idx+7]) << 56)
		);
	
#if SCANNER_VERBOSE_LOG
	DebugLog(@"XfirePacketScanner: scanned uint64 0x%016llx",v);
#endif
	
	_idx += 8;
	return v;
}

// scan a 16 byte integer value, in order
// I figure this is probably a UUID, given how it's used
- (NSData *)scanUUID
{
	CHECK_LENGTH_EX(16,@"uuid");
	
	NSData *v = [NSData dataWithBytes:(&_bytes[_idx]) length:16];
	
#if SCANNER_VERBOSE_LOG
	DebugLog(@"XfirePacketScanner: scanned uuid %@",v);
#endif
	
	_idx += 16;
	return v;
}

// scan an attribute key string
// this is a UTF8 string with a leading 1 byte length
- (NSString *)scanAttrKeyString
{
	unsigned int len = [self scanUInt8];
	
	CHECK_LENGTH_EX(len,@"key string");
	
	NSString *s = [[[NSString alloc] initWithBytes:&_bytes[_idx]
		length:len
		encoding:NSUTF8StringEncoding] autorelease];
	
#if SCANNER_VERBOSE_LOG
	DebugLog(@"XfirePacketScanner: scanned attr key string \"%@\"",s);
#endif
	
	_idx += len;
	return s;
}

// scan a string
// this is a UTF8 string with a leading 2 byte length
- (NSString *)scanString
{
	unsigned int len = [self scanUInt16];
	NSString *s = nil;
	
	CHECK_LENGTH_EX(len,@"string");
	
	if( len > 0 )
	{
		s = [[[NSString alloc] initWithBytes:&_bytes[_idx]
			length:len
			encoding:NSUTF8StringEncoding] autorelease];
		
#if SCANNER_VERBOSE_LOG
		DebugLog(@"XfirePacketScanner: scanned string \"%@\"",s);
#endif
		
		_idx += len;
	}
	else
	{
		s = [NSString string];
	}
	
	if (![s length])
	{
		s = [NSString string];
	}
	
	return s;
}

// scan arbitrary length data
- (NSData *)scanDataOfLength:(unsigned int)len
{
	CHECK_LENGTH_EX(len,@"did");
	
	NSData *v = [NSData dataWithBytes:(&_bytes[_idx]) length:len];
	
	_idx += len;
	return v;
}

// Peek ahead one byte
- (unsigned char)peekUInt8
{
	CHECK_LENGTH_EX(1,@"uint8");
	return _bytes[_idx];
}

//------------------------------------------------------------------------------------------------
// Top level
//------------------------------------------------------------------------------------------------

- (BOOL)scan:(unsigned int *)packetID attributes:(XfirePacketAttributeMap **)attrsOut
{
	unsigned short len;
	XfirePacketAttributeMap *attributes;
	
	len = [self scanUInt16];
	if( len != _len )
	{
		[self raiseException:@"Length doesn't match"];
		return NO; // just to be sure
	}
	
	unsigned int pktID   = (unsigned int)[self scanUInt16];
	
	// scan the primary attribute map
	attributes = [self scanAttributeMapInDomain:[self keyDomainForPacketType:pktID]];
	
#if ATTRIBUTE_LOG	
	DebugLog(@"Packet %u has attributes:\n%@ attributes", pktID, attributes);
#endif
	
	// TODO: determine whether to throw an exception or if this is okay
	if( ![self isAtEnd] )
	{
		DebugLog(@"XfirePacketScanner: Stopped scanning but more data remains");
	}
	
	// return results
	if( packetID ) *packetID = pktID;
	if( attrsOut ) *attrsOut = attributes;
	return YES;
}

- (XfireAttributeKeyDomain)keyDomainForPacketType:(unsigned short)type
{
//	// TODO: determine which packet types have integer key domains
//	// TODO: figure out a better way to handle this
//	if(
//	   (type == 26) ||
//	   (type == 27) ||
//	   (type == 28) ||
//	   (type == 29) ||
//	   (type == 30) ||
//	   (type == 32) ||
//	   (type == 36) ||
//	   (type == 37) ||
//	   (type == 141) ||
//	   (type == 151) ||
//	   (type == 152) ||
//	   (type == 153) ||
//	   (type == 155) ||
//	   (type == 157) ||
//	   (type == 158) ||
//	   (type == 159) ||
//	   (type == 160) ||
//	   (type == 161) ||
//	   (type == 162) ||
//	   (type == 163) ||
//	   (type == 165) ||
//	   (type == 170) ||
//	   (type == 171) ||
//	   (type == 172) ||
//	   (type == 173) ||
//	   (type == 174) ||
//	   (type == 176) ||
//	   (type == 177) ||
//	   (type == 179) ||
//	   (type == 182) ||
//	   (type == 351) ||
//	   (type == 368) ||
//	   (type == 450) ||
//	   (type == 451) ||
//	   (type == 452) )
//	{
//		return kXfireAttributeKeyIntegerDomain;
//	}
//	
//	return kXfireAttributeKeyStringDomain; // default domain
	
	if (type == 1  ||
		type == 2  ||
		type == 3  ||
		type == 5  ||
		type == 6  ||
		type == 7  ||
		type == 8  ||
		type == 9  ||
		type == 10 ||
		type == 12 ||
		type == 13 ||
		type == 14 ||
		type == 16 ||
		type == 17 ||
		
		type == 128 ||
		type == 129 ||
		type == 130 ||
		type == 131 ||
		type == 133 ||
		type == 134 ||
		type == 135 ||
		type == 136 ||
		type == 137 ||
		type == 138 ||
		type == 139 ||
		type == 143 ||
		type == 144 ||
		type == 145 ||
		type == 147 ||
		type == 148 ||
		type == 154 ||
		type == 156 ||
		
		type == 400)
	{
		return kXfireAttributeKeyStringDomain;
	}
	
	return kXfireAttributeKeyIntegerDomain;
}

- (XfirePacketAttributeMap *)scanAttributeMapInDomain:(XfireAttributeKeyDomain)domain
{
	unsigned int attrCnt;
	unsigned int i;
	XfirePacketAttributeMap *attributes = [XfirePacketAttributeMap map];
	
#if SCANNER_VERBOSE_LOG
	if( domain == kXfireAttributeKeyIntegerDomain )
		DebugLog(@"XfirePacketScanner: scanning attr map in integer domain");
	else
		DebugLog(@"XfirePacketScanner: scanning attr map in string domain");
#endif
	
	NSString *attrKey;
	id       attrValue;
	
	attrCnt = (unsigned int)[self scanUInt8];
	
	for( i = 0; i < attrCnt; i++ )
	{
		[self scanAttribute:&attrKey keyDomain:domain value:&attrValue ];
		[attributes setObject:attrValue forKey:attrKey];
	}
	
	return attributes;
}

- (void)scanAttribute:(NSString **)keyOut keyDomain:(XfireAttributeKeyDomain)domain value:(id *)valueOut
{
	NSString *key = nil;
	id value = nil;
	
	// first scan the attribute key, converting to string as necessary
	
	if( domain == kXfireAttributeKeyIntegerDomain )
	{
		unsigned int keyInt = (unsigned int)[self scanUInt8];
		key = [NSString stringWithFormat:@"0x%02x",keyInt];
	}
	else if( domain == kXfireAttributeKeyStringDomain )
	{
		key = [self scanAttrKeyString];
	}
	else
	{
		[self raiseException:@"Internal scan error - unrecognized key domain"];
	}
#if SCANNER_VERBOSE_LOG
	DebugLog(@"XfirePacketScanner: attr key = %@", key);
#endif
	
	// second scan the attribute value
	
	value = [self scanAttributeValue];
	
	// lastly return the results
	
	if( keyOut ) *keyOut = key;
	if( valueOut ) *valueOut = value;
}


//------------------------------------------------------------------------------------------------
// Scanners of the Attribute Type Stream
//------------------------------------------------------------------------------------------------

- (id)scanAttributeValue
{
	id value = nil;
	unsigned char type;
	
	type = [self scanUInt8];
	switch( type )
	{
		case 0x01: value = [XfirePacketAttributeValue attributeValueWithString:[self scanString]]; break;
		case 0x02: value = [XfirePacketAttributeValue attributeValueWithInt:[self scanUInt32]]; break;
		case 0x03: value = [XfirePacketAttributeValue attributeValueWithUUID:[self scanUUID]]; break;
		case 0x04:
			{
				// need to peek before scanning the array
				int emptyElementType = (int)[self peekUInt8];
				value = [XfirePacketAttributeValue attributeValueWithArray:[self scanArray] emptyElementType:emptyElementType];
			}
			break;
		case 0x05: value = [XfirePacketAttributeValue attributeValueWithAttributeMap:[self scanAttributeMapInDomain:kXfireAttributeKeyStringDomain]]; break;
		case 0x06: value = [XfirePacketAttributeValue attributeValueWithDid:[self scanDataOfLength:21]]; break;
		case 0x07: value = [XfirePacketAttributeValue attributeValueWithInt64:[self scanUInt64]]; break;
		case 0x08: value = [XfirePacketAttributeValue attributeValueWithByte:[self scanUInt8]]; break;
		case 0x09: value = [XfirePacketAttributeValue attributeValueWithAttributeMap:[self scanAttributeMapInDomain:kXfireAttributeKeyIntegerDomain]]; break;
		
		default:
			[self raiseException:[NSString stringWithFormat:@"Unexpected type ID (%02x)", type]];
			break;
	}
	
	return value;
}

// Very similar to -scanAttributeValue, but scans a sequence of values instead of just one
- (NSArray *)scanArray
{
	unsigned int i, cnt;
	unsigned char elementType;
	NSMutableArray *arr = [NSMutableArray array];
	
	// first byte of array is type of each element, assume it can be anything
	// second byte is the # of entries
	elementType = [self scanUInt8];
	cnt = [self scanUInt16];
	
	switch( elementType )
	{
		case 0x01:
			for( i = 0; i < cnt; i++ )
				[arr addObject:[XfirePacketAttributeValue attributeValueWithString:[self scanString]]];
			break;
		
		case 0x02:
			for( i = 0; i < cnt; i++ )
				[arr addObject:[XfirePacketAttributeValue attributeValueWithInt:[self scanUInt32]]];
			break;
		
		case 0x03:
			for( i = 0; i < cnt; i++ )
				[arr addObject:[XfirePacketAttributeValue attributeValueWithUUID:[self scanUUID]]];
			break;
		
		case 0x04:
			for( i = 0; i < cnt; i++ )
			{
				int emptyElementType = (int)[self peekUInt8];
				[arr addObject:[XfirePacketAttributeValue attributeValueWithArray:[self scanArray] emptyElementType:emptyElementType]];
			}
			break;
		
		case 0x05:
			for( i = 0; i < cnt; i++ )
				[arr addObject:[XfirePacketAttributeValue attributeValueWithAttributeMap:[self scanAttributeMapInDomain:kXfireAttributeKeyStringDomain]]];
			break;
		
		case 0x06:
			for( i = 0; i < cnt; i++ )
				[arr addObject:[XfirePacketAttributeValue attributeValueWithDid:[self scanDataOfLength:21]]];
			break;
		
		case 0x07:
			for( i = 0; i < cnt; i++ )
				[arr addObject:[XfirePacketAttributeValue attributeValueWithInt64:[self scanUInt64]]];
			break;
		
		case 0x08:
			for( i = 0; i < cnt; i++ )
				[arr addObject:[XfirePacketAttributeValue attributeValueWithByte:[self scanUInt8]]];
			break;
		
		case 0x09:
			for( i = 0; i < cnt; i++ )
				[arr addObject:[XfirePacketAttributeValue attributeValueWithAttributeMap:[self scanAttributeMapInDomain:kXfireAttributeKeyIntegerDomain]]];
			break;
		
		default:
			[self raiseException:[NSString stringWithFormat:@"Unexpected type while scanning array (%02x)", elementType]];
			break;
	}
	
	return arr;
}

- (void)raiseException:(NSString *)desc
{
	@throw [NSException exceptionWithName:@"XfirePacketScannerException" reason:desc userInfo:nil];
}

@end

/*
Some attributes are followed by a cryptic sequence of bytes before we finally get to the value we care about.
My hypothesis is that these bytes are actually a typing system - a typed stream!

	Byte
	01			String
	02			UInt32
	03			UUID (UInt128)
	04			Means it's an array.  It's followed by another type byte (01, 02)
				e.g. in 'name', a 'name' 04 01 #LS #MS is an array of strings
				whereas in 'version', it's 'version'04 02 #LS #MS is an array of UInt32's
	05			A subpacket with key/value pairs; keys are in string domain
	06			A 21-byte value
	07			UInt64
	08			In several cases it appears to be a UInt8, usually in an array (04) representing arbitrary data block
	09			A subpacket with key/value pairs; keys are in binary domain
*/

/*
Attribute key formats:
  1. string key with 1-byte length prefix
  2. single byte numerical value

Attribute key "domains":
Sometimes even very small numbers appear to represent keys.  For example, the value 0x01
appears to be a key in certain circumstances, even though there is a known key "t", which
appears as a two-byte value with the first one being 0x01 (the length of string "t").  As
far as I can tell, there are certain (higher level) conditions under which the keys are
always single-byte numerical values.  To cover those cases, this code uses what I call
key "domains".

General rules:
  1. No known string keys are greater than X bytes long.
  2. In all cases, if the key byte is longer than Y, assume it's a single byte key.
  3. If the key search "domain" is binary, use only the first byte, otherwise read a string.
*/

/*
Best guess on integer key meanings:
	0x01		User ID
	0x02		? Name?  it's a string
	0x04		? array of 21byte
	0x12		? array of uint32
	0x19		? array of uint32
	0x1a		? array of string
	0x1f		? uint32
	0x21		? uin32 <or> array of uint32
	0x22		? array of uint32
	0x23		? array of uint32
	0x2e		msg? string
	0x34		? uint32 <or> array of uint32
	0x4c		? contains attrmap9 with 0x06, 0x08, 0x0b
	0x4f		? channel ID,  uint32 <or> array of uint32
	0x50		? timestamp?  uint32 <or> array of uint32   (it appears as a timestamp in channel1000.ini)
	0x54		? array of string
	0x55		? array of uint32
	0x5c		? array of uint32
	0x5d		? array of uint32
	0x5e		? array of string
	0x6c		? array of uint32
	0x91		? array of uint32
*/


/*
tcpdump commands:

To capture packets to a file 'dump':
sudo tcpdump -s 0 -w dump
sudo tcpdump -s 0 -w dump -C 1

To dump the packet file 'dump' to a text file 'dump.txt':
tcpdump -r dump -X > dump.txt
tcpdump -r dump -X dst host 206.220.42.147 or src host 206.220.42.147 > dump_a.txt
*/

