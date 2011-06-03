//
//  XBAvatarCache.h
//  Xblaze-iPhone
//
//  Created by James on 13/01/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface XBImageCache : NSObject {

}

+ (void)writeImage:(UIImage *)image forKey:(NSString *)cacheKey;
+ (UIImage *)readImageFromCacheForKey:(NSString *)cacheKey;

@end
