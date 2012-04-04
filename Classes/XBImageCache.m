//
//  XBAvatarCache.m
//  Xblaze-iPhone
//
//  Created by James on 13/01/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import "XBImageCache.h"

@implementation XBImageCache

+ (void)writeImage:(UIImage *)image forKey:(NSString *)cacheKey
{
	NSString *appCachesPath = nil;
	NSString *cachePath = nil;
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0)
	{
		appCachesPath = [paths objectAtIndex:0];
	}
	
	if (![appCachesPath length])
	{
		DebugLog(@"Unable to get path for caches directory...");
		return;
	}
	
	cachePath = [appCachesPath stringByAppendingPathComponent:@"AvatarCache"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath])
	{ // create cache directory
		NSError *error = nil;
		[[NSFileManager defaultManager] createDirectoryAtPath:cachePath
								  withIntermediateDirectories:YES
												   attributes:nil
														error:&error];
		if (error)
		{
			DebugLog(@"Unable to create cache directory: %@", [error localizedDescription]);
			return;
		}
	}
	
	NSString *filename = [cachePath stringByAppendingPathComponent:[cacheKey lastPathComponent]];
	NSData *imageData = UIImagePNGRepresentation(image);
	[imageData writeToFile:filename atomically:YES];
}

+ (UIImage *)readImageFromCacheForKey:(NSString *)cacheKey
{
	NSString *appCachesPath = nil;
	NSString *cachePath = nil;
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0)
	{
		appCachesPath = [paths objectAtIndex:0];
	}
	
	if (![appCachesPath length])
	{
		DebugLog(@"Unable to get path for caches directory...");
		return nil;
	}
	
	cachePath = [appCachesPath stringByAppendingPathComponent:@"AvatarCache"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath])
	{ // create cache directory
		//DebugLog(@"AvatarCache hasn't been created yet... creating it, but returning nil because there's nothing here");
		
		NSError *error = nil;
		[[NSFileManager defaultManager] createDirectoryAtPath:cachePath
								  withIntermediateDirectories:YES
												   attributes:nil
														error:&error];
		if (error)
		{
			DebugLog(@"Unable to create cache directory: %@", [error localizedDescription]);
			return nil;
		}
		
		return nil;
	}
	
	NSString *filename = [cachePath stringByAppendingPathComponent:[cacheKey lastPathComponent]];
	UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfFile:filename]];
	
	if (!image)
	{
		return nil;
	}
	
	return [image autorelease];
}

@end
