/*******************************************************************
	FILE:		NSData_XfireAdditions.m
	
	COPYRIGHT:
		Copyright 2007-2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Adds items to NSData that are useful for implementing the
		Xfire protocol.
	
	HISTORY:
		2008 04 06  Changed copyright to BSD license.
		2008 01 12  Added copyright notice.
		2007 10 14  Created.
*******************************************************************/

#import "NSData_XfireAdditions.h"
#include <CommonCrypto/CommonDigest.h>

@implementation NSData (XfireAdditions)

//- (NSData*)sha1Hash
//{
//	SHA_CTX			ctx;
//	unsigned char	hash[SHA_DIGEST_LENGTH];
//	
//	SHA1_Init(&ctx);
//	SHA1_Update(&ctx,[self bytes],[self length]);
//	SHA1_Final(hash,&ctx);
//	
//	return [NSData dataWithBytes:hash length:SHA_DIGEST_LENGTH];
//}

- (NSData *)sha1Hash
{
	unsigned char hash[CC_SHA1_DIGEST_LENGTH];
	(void) CC_SHA1( [self bytes], (CC_LONG)[self length], hash );
	return ( [NSData dataWithBytes: hash length: CC_SHA1_DIGEST_LENGTH] );
}

// prints all bytes as consecutive strings
- (NSString*)stringRepresentation
{
	const char *rawBytes;
	unsigned int len;
	unsigned int i;
	
	len = [self length];
	rawBytes = [self bytes];
	
	NSMutableString *str = [NSMutableString stringWithCapacity:(len*2)];
	
	for( i = 0; i < len; i++ )
	{
		[str appendFormat:@"%02x", (unsigned char)rawBytes[i]];
	}
	
	return str;
}

// prints raw hex + ascii
- (NSString *)enhancedDescription
{
	NSMutableString *str   = [NSMutableString string]; // full string result
	NSMutableString *hrStr = [NSMutableString string]; // "human readable" string
	
	int i, len;
	const unsigned char *b;
	len = [self length];
	b = [self bytes];
	
	if( len == 0 )
	{
		return @"<empty>";
	}
	
	[str appendString:@"\n   "];
	
	int linelen = 16;
	for( i = 0; i < len; i++ )
	{
		[str appendFormat:@" %02x", b[i]];
		if( isprint(b[i]) )
		{
			[hrStr appendFormat:@"%c", b[i]];
		}
		else
		{
			[hrStr appendString:@"."];
		}
		
		if( (i % linelen) == (linelen-1) ) // new line every linelen bytes
		{
			[str appendFormat:@"    %@\n", hrStr];
			hrStr = [NSMutableString string];
			
			if( i < (len-1) )
			{
				[str appendString:@"   "];
			}
		}
	}
	
	// make sure to print out the remaining hrStr part, aligned of course
	if( (len % linelen) != 0 )
	{
		int bytesRemain = linelen-(len%linelen); // un-printed bytes
		for( i = 0; i < bytesRemain; i++ )
		{
			[str appendString:@"   "];
		}
		[str appendFormat:@"    %@\n", hrStr];
	}
	
	return str;
}

- (unsigned char)byteAtIndex:(unsigned int)index
{
	const unsigned char *b = [self bytes];
	return b[index];
}

// tests for all zeros
- (BOOL)isClear
{
	int i, cnt;
	const unsigned char *b;
	cnt = [self length];
	b = [self bytes];
	for( i = 0; i < cnt; i++ )
	{
		if( b[i] != 0 )
			return NO;
	}
	return YES;
}

+ (NSData *)newUUID
{
	CFUUIDRef uuid;
	NSData    *dat = nil;
	
	uuid = CFUUIDCreate(nil);
	if( uuid != nil )
	{
		CFUUIDBytes bytes;
		
		bytes = CFUUIDGetUUIDBytes(uuid);
		dat = [NSData dataWithBytes:&bytes length:16];
		
		CFRelease(uuid);
	}
	return dat;
}

#if 0
+ (id)stringWithNewUUID
{
	CFUUIDRef		uuid;
	CFStringRef		cfstr;
	NSString		*nstr;
	
	uuid = CFUUIDCreate(nil);
	cfstr = CFUUIDCreateString(nil, uuid);
	nstr = (NSString *)cfstr;
	CFRelease(uuid);
	
	return nstr;
}
#endif

@end
