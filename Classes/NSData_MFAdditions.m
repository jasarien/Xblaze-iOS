/*******************************************************************
	FILE:		NSData_MFAdditions.m
	
	COPYRIGHT:
		Copyright 2007-2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Useful methods for the NSData class.
	
	HISTORY:
		2008 04 06  Changed copyright to BSD license.
		2007 12 02  Added copyright notice.
		2007 10 14  Created.
*******************************************************************/

#import "NSData_MFAdditions.h"
#import "MFDataEmitter.h"
#import "MFDataScanner.h"
#include <zlib.h>


@interface ArchiveFile : NSObject
{
	NSString *_path;
	NSData *_data;
}
+ (id)fileWithPath:(NSString *)path data:(NSData *)data;
- (id)initWithPath:(NSString *)aName data:(NSData *)aData;
- (NSString *)path;
- (NSData *)data;
@end



@implementation NSData (MFAdditions)

- (NSData *)compressedZlibData
{
	z_stream compressionState;
	NSMutableData *compressedData = [NSMutableData dataWithCapacity:[self length]];
	int ok;
	unsigned char *outputBuffer;
	unsigned int outputBufferSize;
	
	memset(&compressionState, 0, sizeof(compressionState));
	ok = deflateInit(&compressionState,Z_DEFAULT_COMPRESSION);
	if( ok != Z_OK )
	{
		DebugLog(@"defateInit failed (%d)",ok);
		return nil;
	}
	
	compressionState.next_in = (unsigned char*)[self bytes];
	compressionState.avail_in = [self length];
	
	//outputBufferSize = [self length]*2;
	outputBufferSize = 12+(unsigned)(1.2*(double)[self length]);
	//outputBufferSize = (1024*1024);
	outputBuffer = malloc(outputBufferSize);
	while(1)
	{
		compressionState.next_out = outputBuffer;
		compressionState.avail_out = outputBufferSize;
		ok = deflate(&compressionState, Z_FINISH);
		if( compressionState.next_out > outputBuffer )
			[compressedData appendBytes:outputBuffer length:(compressionState.next_out - outputBuffer)];
		if( ok == Z_STREAM_END )
			break;
		else if( ok != Z_OK )
		{
			DebugLog(@"Error compressing data (%d)", ok);
			deflateEnd(&compressionState);
			free(outputBuffer);
			return nil;
		}
	}
	
	ok = deflateEnd(&compressionState);
	free(outputBuffer);
	if( ok != Z_OK )
	{
		DebugLog(@"Error compressing data (%d)", ok);
		return nil;
	}
	
	return compressedData;
}

- (NSData *)decompressedZlibData
{
	z_stream compressionState;
	NSMutableData *decompressedData = [NSMutableData dataWithCapacity:(10*1024*1024)];
	int ok;
	unsigned char *outputBuffer;
	unsigned int outputBufferSize;
	
	memset(&compressionState, 0, sizeof(compressionState));
	ok = inflateInit(&compressionState);
	if( ok != Z_OK )
	{
		DebugLog(@"inflateInit failed (%d)",ok);
		return nil;
	}
	
	compressionState.next_in = (unsigned char*)[self bytes];
	compressionState.avail_in = [self length];
	outputBufferSize = (1024*1024);
	outputBuffer = malloc(outputBufferSize);
	while(1)
	{
		compressionState.next_out = outputBuffer;
		compressionState.avail_out = outputBufferSize;
		ok = inflate(&compressionState, Z_SYNC_FLUSH);
		if( compressionState.next_out > outputBuffer )
			[decompressedData appendBytes:outputBuffer length:(compressionState.next_out - outputBuffer)];
		if( ok == Z_STREAM_END )
			break;
		else if( ok != Z_OK )
		{
			DebugLog(@"Error decompressing data (%d)", ok);
			inflateEnd(&compressionState);
			free(outputBuffer);
			return nil;
		}
	}
	
	ok = inflateEnd(&compressionState);
	free(outputBuffer);
	if( ok != Z_OK )
	{
		DebugLog(@"Error decompressing data (%d)", ok);
		return nil;
	}
	
	return decompressedData;
}

/*
	Format is as follows:
	Header:
		Tag: 4 bytes (value 0x64686400)
		# files: 4 bytes
	For each file:
		File name: UTF8 string encoded with preceeding 2 byte count
		File length: 4 bytes
		File data: arbitrary bytes
*/
+ (NSData *)archivedDataWithFiles:(NSArray *)paths
{
	MFDataEmitter *emitter = [MFDataEmitter emitter];
	NSEnumerator *e = [paths objectEnumerator];
	NSString *pat;
	NSData *fileDat;
	
	// first step, archive each file's data to a data object
	// consists of a file count followed by alternating path/data pairs
	
	[emitter emitUInt32:0x64686400];
	[emitter emitUInt32:[paths count]];
	
	while( (pat = [e nextObject]) != nil )
	{
		fileDat = [NSData dataWithContentsOfFile:pat];
		if( fileDat == nil )
		{
			DebugLog(@"Cannot read file %@, aborting", pat);
			return nil;
		}
		
		[emitter emitString:pat];
		[emitter emitData:fileDat];
	}
	
	// second step compresses the data block
	NSData *compressedData = [[emitter data] compressedZlibData];
	if( compressedData == nil )
		return nil;
	
	// third step creates the final file
	emitter = [MFDataEmitter emitter];
	[emitter emitUInt32:0x64686400]; // magic
	[emitter emitUInt16:1]; // file format version
	[emitter emitUInt16:0]; // flags
	[emitter emitUInt8:22]; // another magic number, maybe will mean something someday
	[emitter emitData:compressedData];
	
	return [emitter data];
}

- (NSArray *)unarchivedFiles
{
	MFDataScanner *scanner = [MFDataScanner scannerWithData:self];
	
	// first step is to scan the file header
	
	if( [scanner scanUInt32] != 0x64686400 )
	{
		DebugLog(@"Magic didn't match");
		return nil;
	}
	if( [scanner scanUInt16] != 1 )
	{
		DebugLog(@"Unrecognized file format version");
		return nil;
	}
	[scanner scanUInt16]; // ignore flags
	if( [scanner scanUInt8] != 22 )
	{
		DebugLog(@"Magic number 22 didn't match");
		return nil;
	}
	NSData *compressedData = [scanner scanData];
	
	// second step decompresses the data block
	NSData *coreData = [compressedData decompressedZlibData];
	if( coreData == nil )
		return nil;
	
	// third step scans each file in the decompressed block
	scanner = [MFDataScanner scannerWithData:coreData];
	NSMutableArray *files = [NSMutableArray array];
	unsigned int i, cnt;
	
	if( [scanner scanUInt32] != 0x64686400 )
	{
		DebugLog(@"Magic didn't match");
		return nil;
	}
	cnt = [scanner scanUInt32];
	for( i = 0; i < cnt; i++ )
	{
		NSString *pat = [scanner scanString];
		NSData *dat = [scanner scanData];
		[files addObject:[ArchiveFile fileWithPath:pat data:dat]];
	}
	
	return files;
}

@end


@implementation ArchiveFile

+ (id)fileWithPath:(NSString *)path data:(NSData *)d
{
	return [[[ArchiveFile alloc] initWithPath:path data:d] autorelease];
}

- (id)initWithPath:(NSString *)aPath data:(NSData *)aData
{
	self = [super init];
	if( self )
	{
		_path = [aPath retain];
		_data = [aData retain];
	}
	return self;
}

- (void)dealloc
{
	[_path release];
	[_data release];
	[super dealloc];
}

- (NSString *)path { return _path; }

- (NSData *)data { return _data; }

- (NSString *)description
{
	return [NSString stringWithFormat:@"ArchiveFile{ path = %@, length = %u }", _path, [_data length]];
}

@end


