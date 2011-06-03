
#import <Cocoa/Cocoa.h>

@interface MFDataEmitter : NSObject
{
	NSMutableData *_data;
}
+ (id)emitter;
+ (id)emitterWithCapacity:(unsigned long)cap;
- (id)init;
- (id)initWithCapacity:(unsigned long)cap;

- (NSData *)data; // get the result

- (void)emitUInt8:(UInt8)value;
- (void)emitUInt16:(UInt16)value;
- (void)emitUInt32:(UInt32)value;
- (void)emitString:(NSString *)str;
- (void)emitData:(NSData *)data;
@end
