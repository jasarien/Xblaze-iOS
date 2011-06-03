
#import <Cocoa/Cocoa.h>

@interface NSData (XfireAdditions)
- (NSData *)zlibCompressedData;
- (NSData *)zlibDecompressedData;

// These are complementary methods
+ (NSData *)archivedDataWithFiles:(NSArray *)paths;
- (NSArray *)unarchivedFiles;
@end

