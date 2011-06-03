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
