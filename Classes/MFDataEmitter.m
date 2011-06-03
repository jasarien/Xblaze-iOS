/*******************************************************************
	FILE:		MFDataEmitter.m
	
	COPYRIGHT:
		Copyright 2007-2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		A class to emit specific kinds of data.  It uses some rules
		similar to Xfire encoding rules.  It generates an NSData result
		suitable for being scanned by MFDataScanner.  It is similar in
		concept to an NSArchiver, but more limited with more direct
		control over the results.
	
	HISTORY:
		2008 04 06  Changed copyright to BSD license.
		2007 12 02  Added copyright notice.
		2007 12 01  Created.
*******************************************************************/

#import "MFDataEmitter.h"

@implementation MFDataEmitter

+ (id)emitter
{
	return [[[MFDataEmitter alloc] init] autorelease];
}

+ (id)emitterWithCapacity:(unsigned long)cap
{
	return [[[MFDataEmitter alloc] initWithCapacity:cap] autorelease];
}

- (id)init
{
	self = [super init];
	if( self )
	{
		_data = [[NSMutableData alloc] init];
	}
	return self;
}

- (id)initWithCapacity:(unsigned long)cap
{
	self = [super init];
	if( self )
	{
		_data = [[NSMutableData alloc] initWithCapacity:cap];
	}
	return self;
}

- (void)dealloc
{
	[_data release];
	[super dealloc];
}

- (NSData *)data
{
	return _data;
}

- (void)emitUInt8:(UInt8)value
{
	unsigned char bfr = value;
	[_data appendBytes:&bfr length:1];
}

- (void)emitUInt16:(UInt16)value
{
	unsigned char bfr[2];
	
	bfr[0] = (value & 0xFF);
	bfr[1] = ((value >> 8) & 0xFF);
	
	[_data appendBytes:bfr length:2];
}

- (void)emitUInt32:(UInt32)value
{
	unsigned char bfr[4];
	
	bfr[0] = (value & 0xFF);
	bfr[1] = ((value >> 8) & 0xFF);
	bfr[2] = ((value >> 16) & 0xFF);
	bfr[3] = ((value >> 24) & 0xFF);
	
	[_data appendBytes:bfr length:4];
}

- (void)emitString:(NSString *)str
{
	NSData *utf8str = [str dataUsingEncoding:NSUTF8StringEncoding];
	unsigned int strLen = [utf8str length];
	if( strLen >= 65536 )
		[NSException raise:@"MFDataEmitterException" format:@"String too long to emit"];
	[self emitUInt16:strLen];
	[_data appendData:utf8str];
}

- (void)emitData:(NSData *)data
{
	[self emitUInt32:[data length]];
	[_data appendData:data];
}

@end
