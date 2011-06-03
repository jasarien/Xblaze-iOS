
#import "NSData_XfireAdditions.h"
#import "MFDataEmitter.h"
#import "MFDataScanner.h"
#include <zlib.h>

#ifndef FILE_FORMAT_VERSION
#define FILE_FORMAT_VERSION 1
#endif

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

@implementation NSData (XfireAdditions)
- (NSData *)zlibCompressedData
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
		NSLog(@"defateInit failed (%d)",ok);
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
			NSLog(@"Error compressing data (%d)", ok);
			deflateEnd(&compressionState);
			free(outputBuffer);
			return nil;
		}
	}
	
	ok = deflateEnd(&compressionState);
	free(outputBuffer);
	if( ok != Z_OK )
	{
		NSLog(@"Error compressing data (%d)", ok);
		return nil;
	}
	
	return compressedData;
}
- (NSData *)zlibDecompressedData
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
		NSLog(@"inflateInit failed (%d)",ok);
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
			NSLog(@"Error decompressing data (%d)", ok);
			inflateEnd(&compressionState);
			free(outputBuffer);
			return nil;
		}
	}
	
	ok = inflateEnd(&compressionState);
	free(outputBuffer);
	if( ok != Z_OK )
	{
		NSLog(@"Error decompressing data (%d)", ok);
		return nil;
	}
	
	return decompressedData;
}
/*
Format version 1 is as follows:
	Header:
		Tag: 4 bytes (value 0x64686400)
		# files: 4 bytes
	For each file:
		File name: UTF8 string encoded with preceeding 2 byte count
		File length: 4 bytes
		File data: arbitrary bytes
Format version 2 puts all the strings first and the data second. This allows scanning the file manifest
without reading all the data.
	Header:
		Tag: 4 bytes (value 0x64686400)
		# files: 4 bytes
	For each file:
		File name: UTF8 string encoded with preceeding 2 byte count
	For each file:
		File length: 4 bytes
		File data: arbitrary bytes
*/
+ (NSData *)archivedDataWithFiles:(NSArray *)paths
{
	MFDataEmitter *emitter = [MFDataEmitter emitter];
	NSEnumerator *e;
	NSString *pat;
	NSData *fileDat;
#if (FILE_FORMAT_VERSION >= 2)
	NSMutableArray *datas = [NSMutableArray array];
#endif
	
	// first step, archive each file's data to a data object
	// consists of a file count followed by alternating path/data pairs
	
	[emitter emitUInt32:0x64686400];
	[emitter emitUInt32:[paths count]];
	
	e = [paths objectEnumerator];
	while( (pat = [e nextObject]) != nil )
	{
		fileDat = [NSData dataWithContentsOfFile:pat];
		if( fileDat == nil )
		{
			NSLog(@"Cannot read file %@, aborting", pat);
			return nil;
		}
		
		[emitter emitString:pat];
#if (FILE_FORMAT_VERSION == 1)
		[emitter emitData:fileDat];
#else
		[datas addObject:fileDat];
#endif
	}
	
#if (FILE_FORMAT_VERSION == 2)
	e = [datas objectEnumerator];
	while( (fileDat = [e nextObject]) != nil )
	{
		[emitter emitData:fileDat];
	}
#endif
	
	// second step compresses the data block
	NSData *compressedData = [[emitter data] zlibCompressedData];
	if( compressedData == nil )
		return nil;
	
	// third step creates the final file
	emitter = [MFDataEmitter emitter];
	[emitter emitUInt32:0x64686400]; // magic
#if (FILE_FORMAT_VERSION == 1)
	[emitter emitUInt16:1]; // file format version
#elif (FILE_FORMAT_VERSION == 2)
	[emitter emitUInt16:2]; // file format version
#else
	#error Unrecognized file format version
#endif
	
	[emitter emitUInt16:0]; // flags
	[emitter emitUInt8:22]; // another magic number, maybe will mean something someday
	[emitter emitData:compressedData];
	
	return [emitter data];
}

- (NSArray *)unarchivedFiles
{
	MFDataScanner *scanner = [MFDataScanner scannerWithData:self];
	unsigned short version;
	
	// first step is to scan the file header
	
	if( [scanner scanUInt32] != 0x64686400 )
	{
		NSLog(@"Magic didn't match");
		return nil;
	}
	version = [scanner scanUInt16];
	if( ! ( (version == 1) || (version == 2) ) )
	{
		NSLog(@"Unrecognized file format version");
		return nil;
	}
	[scanner scanUInt16]; // ignore flags
	if( [scanner scanUInt8] != 22 )
	{
		NSLog(@"Magic number 22 didn't match");
		return nil;
	}
	NSData *compressedData = [scanner scanData];
	
	// second step decompresses the data block
	NSData *coreData = [compressedData zlibDecompressedData];
	if( coreData == nil )
		return nil;
	
	// third step scans each file in the decompressed block
	scanner = [MFDataScanner scannerWithData:coreData];
	NSMutableArray *files = [NSMutableArray array];
	unsigned int i, cnt;
	
	if( [scanner scanUInt32] != 0x64686400 )
	{
		NSLog(@"Magic didn't match");
		return nil;
	}
	cnt = [scanner scanUInt32];
	if( version == 1 )
	{
		for( i = 0; i < cnt; i++ )
		{
			NSString *pat = [scanner scanString];
			NSData *dat = [scanner scanData];
			[files addObject:[ArchiveFile fileWithPath:pat data:dat]];
		}
	}
	else if( version == 2 )
	{
		NSMutableArray *paths = [NSMutableArray arrayWithCapacity:cnt];
		for( i = 0; i < cnt; i++ )
		{
			[paths addObject:[scanner scanString]];
		}
		for( i = 0; i < cnt; i++ )
		{
			NSData *dat = [scanner scanData];
			[files addObject:[ArchiveFile fileWithPath:[paths objectAtIndex:i]
				data:dat]];
		}
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
- (NSString *)path { return _path; }
- (NSData *)data { return _data; }
- (NSString *)description
{
	return [NSString stringWithFormat:@"ArchiveFile{ path = %@, length = %u }", _path, [_data length]];
}
@end
