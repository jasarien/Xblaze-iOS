
#import <Cocoa/Cocoa.h>

@interface MFDataScanner : NSObject
{
	NSData *_data;
	const unsigned char *_start, *_cur, *_end;
}
+ (id)scannerWithData:(NSData *)data;
- (id)initWithData:(NSData *)data;

- (UInt8)scanUInt8;
- (UInt16)scanUInt16;
- (UInt32)scanUInt32;
- (NSString *)scanString;
- (NSData *)scanData;

- (NSData *)scanDataOfLength:(unsigned long)len;
- (void)seek:(unsigned long)loc;
- (unsigned long)tell;
- (NSString *)scanUTF16String;

@end


