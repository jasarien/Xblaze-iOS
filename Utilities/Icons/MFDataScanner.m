
#import "MFDataScanner.h"

#define CHECK_LENGTH_EX( _need, _desc ) if( (_cur + (_need)) > _end ) [NSException raise:@"ScannerException" format:@"Not enough bytes to scan %@ (%u)", (_desc), (_end-_cur)]

@implementation MFDataScanner

+ (id)scannerWithData:(NSData *)data
{
	return [[[MFDataScanner alloc] initWithData:data] autorelease];
}

- (id)initWithData:(NSData *)data
{
	self = [super init];
	if( self )
	{
		_data = [data retain];
		_start = [_data bytes];
		_cur = _start;
		_end = _start + [_data length];
	}
	return self;
}

- (void)dealloc
{
	[_data release];
	[super dealloc];
}

- (UInt8)scanUInt8
{
	CHECK_LENGTH_EX( 1, @"int8" );
	
	UInt8 v = *_cur;
	
	_cur++;
	return v;
}

- (UInt16)scanUInt16
{
	CHECK_LENGTH_EX( 2, @"int16" );
	
	UInt16 v = (
		((UInt16)_cur[0]) |
		(((UInt16)_cur[1]) << 8)
		);
	
	_cur += 2;
	return v;
}

- (UInt32)scanUInt32
{
	CHECK_LENGTH_EX( 4, @"int32" );
	
	UInt32 v = (
		((UInt32)_cur[0]) |
		(((UInt32)_cur[1]) << 8) |
		(((UInt32)_cur[2]) << 16) |
		(((UInt32)_cur[3]) << 24)
		);
	
	_cur += 4;
	return v;
}

- (NSString *)scanString
{
	UInt16 len = [self scanUInt16];
	NSString *s;
	
	CHECK_LENGTH_EX( len, @"string" );
	
	if( len > 0 )
	{
		s = [[[NSString alloc] initWithBytes:_cur
			length:len
			encoding:NSUTF8StringEncoding] autorelease];
		_cur += len;
	}
	else
	{
		s = [NSString string];
	}
	
	return s;
}

- (NSData *)scanData
{
	UInt32 len = [self scanUInt32];
	NSData *d;
	
	CHECK_LENGTH_EX( len, @"data" );
	
	if( len >  0)
	{
		d = [NSData dataWithBytes:_cur length:len];
		_cur += len;
	}
	else
	{
		d = [NSData data];
	}
	
	return d;
}

- (NSString *)scanUTF16String
{
	UInt16 len = [self scanUInt16];
	NSString *s;
	
	CHECK_LENGTH_EX( len, @"string" );
	
	if( len > 0 )
	{
		s=(NSString*)CFStringCreateWithBytes(nil,
			_cur,
			(len*2),
			kCFStringEncodingUTF16LE,
			YES);
		_cur += len;
	}
	else
	{
		s = [NSString string];
	}
	
	return s;
}

- (NSData *)scanDataOfLength:(unsigned long)len
{
	NSData *d;
	
	CHECK_LENGTH_EX( len, @"data" );
	
	if( len >  0)
	{
		d = [NSData dataWithBytes:_cur length:len];
		_cur += len;
	}
	else
	{
		d = [NSData data];
	}
	
	return d;
}

- (void)seek:(unsigned long)loc
{
	if( (_start + loc) > _end )
	{
		[NSException raise:@"ScannerException" format:@"Attempt to scan past the end of the data"];
	}
	_cur = _start+loc;
}

- (unsigned long)tell
{
	return (_cur-_start);
}

@end

