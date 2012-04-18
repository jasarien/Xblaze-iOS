//
//  XBMediaCache.h
//  Xblaze-iPhone
//
//  Created by James Addyman on 15/12/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const kXBMediaCachePath;

@interface XBMediaCache : NSObject {
    
}

+ (NSString *)cachePath;
+ (UIImage *)imageForKey:(NSString *)key;
+ (NSString *)filePathForKey:(NSString *)key;
+ (NSString *)writeImageToDisk:(UIImage *)image withKey:(NSString *)key;
+ (NSString *)writeDataToDisk:(NSData *)data withKey:(NSString *)key;
+ (void)emptyCache;

@end
