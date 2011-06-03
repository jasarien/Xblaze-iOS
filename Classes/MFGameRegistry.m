/*******************************************************************
	FILE:		MFGameRegistry.m
	
	COPYRIGHT:
		Copyright 2007-2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Contains information about games.
		Requires the xfire_games.ini file.
		Requires the "Mac Games.plist" file
	
	HISTORY:
		2008 12 20  Revised to use a single plist file instead of the
		            separate INI file and Mac Games plist file.
		2008 04 06  Changed copyright to BSD license.
		2007 12 16  Added Mac Games list.
		2007 12 02  Added copyright notice.
		2007 11 25  Created.
*******************************************************************/

#import "MFGameRegistry.h"
#import "NSData_MFAdditions.h"

static MFGameRegistry *gRegistry = nil;

// Keys for information dictionary
NSString *kMFGameRegistryIDKey          = @"ID";
NSString *kMFGameRegistryLongNameKey    = @"LongName";
NSString *kMFGameRegistryShortNameKey   = @"ShortName";
NSString *kMFGameRegistryIconKey        = @"Icon";
NSString *kMFGameRegistryMacAppPathsKey = @"MacAppPaths";

// Private interfaces
@interface MFGameRegistry (Private)
- (BOOL)loadGamesFile:(NSString *)path;
- (BOOL)loadIconsFile:(NSString *)path;
@end

#define TRIM(_str) [(_str) stringByTrimmingCharactersInSet:wscs]

@implementation MFGameRegistry

@synthesize games=_games;

+ (id)registry
{
	if( gRegistry == nil )
	{
		gRegistry = [[MFGameRegistry alloc] init];
	}
	return gRegistry;
}

- (id)init
{
	self = [super init];
	if( self )
	{
		NSString *path;
		
		_version = 0;
		_defaultImage = nil;
		_games = nil;
		_macGames = nil;
		
		// Load the master game dictionary first
		path = [[NSBundle bundleForClass:[self class]] pathForResource:@"Games" ofType:@"plist"];
		if( path == nil )
		{
			// TODO: need to get some kind of warning up to the user
			DebugLog(@"Game information file is missing");
			[self release];
			return nil;
		}
		if( ! [self loadGamesFile:path] )
		{
			// TODO: need to get some kind of warning up to the user
			DebugLog(@"Could not load game information file");
			[self release];
			return nil;
		}
		
		_defaultImage = [[UIImage imageNamed:@"XfireLarge.png"] retain];
		
//		// Then load the icons file
//		path = [[NSBundle bundleForClass:[self class]] pathForResource:@"icons" ofType:@"mar"];
//		if( path == nil )
//		{
//			// TODO: need to get some kind of warning up to the user
//			NSLog(@"Game icons file is missing");
//			[self release];
//			return nil;
//		}
//		if( ! [self loadIconsFile:path] )
//		{
//			// TODO: need to get some kind of warning up to the user
//			NSLog(@"Could not load game icons file");
//			[self release];
//			return nil;
//		}
	}
	return self;
}

// This should never get called, but just in case...
- (void)dealloc
{
	[_games release];
	[_macGames release];
	[_defaultImage release];
	
	_games = nil;
	_macGames = nil;
	_defaultImage = nil;
	
	[super dealloc];
}

/*
The Games.plist file is a dictionary with two top level keys:
	Games							NSArray(NSDictionary)
	XfireGamesVersion				NSNumber(int)

The Games key is an array of NSDictionary objects representing a unique game.  The dictionary
keys are:
	ID			NSNumber(int)		Game ID as transmitted by Xfire network
	LongName	NSString			Long display name (English)
	ShortName	NSString			Short name used to look up the game icon
	MacAppPaths NSArray(NSString)	NSApplicationPath for matching
	Icon		NSImage
*/
- (BOOL)loadGamesFile:(NSString *)path
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
	if( dict == nil )
		return NO;
	
	NSNumber *ver = [dict objectForKey:@"XfireGamesVersion"];
	if( ver == nil )
		return NO;
	_version = [ver intValue];
	
	NSArray *games = [dict objectForKey:@"Games"];
	if( !games )
		return NO;
	
	_games = [[NSMutableDictionary alloc] init];
	_macGames = [[NSMutableDictionary alloc] init];
	
	int i, cnt;
	cnt = [games count];
	NSMutableDictionary *game;
	NSArray *appPaths;
	for( i = 0; i < cnt; i++ )
	{
		game = [NSMutableDictionary dictionaryWithDictionary:[games objectAtIndex:i]];
		id key = [game objectForKey:kMFGameRegistryIDKey];
		if( key )
		{
			[_games setObject:game forKey:key];
			
			appPaths = [game objectForKey:kMFGameRegistryMacAppPathsKey];
			if( appPaths != nil )
			{
				int j, cnt2;
				cnt2 = [appPaths count];
				for( j = 0; j < cnt2; j++ )
				{
					[_macGames setObject:game
						forKey:[[appPaths objectAtIndex:j] uppercaseString]];
				}
			}
		}
	}
	
	return YES;
}

- (BOOL)loadIconsFile:(NSString *)path
{
	return NO;
//	BOOL rv = NO;
//	
//	@try
//	{
//		NSData *d = [NSData dataWithContentsOfFile:path];
//		if( d == nil )
//			return NO;
//		
//		NSArray *fls = [d unarchivedFiles];
//		if( fls == nil )
//			return NO;
//		
//		// now we have the list of files
//		// build a dictionary for quick lookup
//		// then put the icon images into the _games ivar
//		NSMutableDictionary *imgMap = [NSMutableDictionary dictionary];
//		NSString *path;
//		UIImage *img;
//		id file;
//		
//		int i, cnt;
//		cnt = [fls count];
//		for( i = 0; i < cnt; i++ )
//		{
//			file = [fls objectAtIndex:i];
//			path = [[file path] uppercaseString];
//			img = [[UIImage alloc] initWithData:[file data]];
//			if( img )
//			{
//				[imgMap setObject:img forKey:path];
//			}
//			else
//			{
//				// skip it
//				// in initial run there was only 1 that failed
//				// Preview can't load it either
//				NSLog(@"Could not load image for %@", path);
//			}
//		}
//		
//		_defaultImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"XfireLarge" ofType:@"png"]];
//		
//		// then put the icon images into the _games ivar
//		NSEnumerator *gameNumer = [_games objectEnumerator];
//		NSMutableDictionary *gameInfo;
//		NSString *imgFileName;
//		while( (gameInfo = [gameNumer nextObject]) != nil )
//		{
//			// find the proper image
//			imgFileName = [gameInfo objectForKey:kMFGameRegistryShortNameKey];
//			if( imgFileName ) // skip those without short names
//			{
//				imgFileName = [[NSString stringWithFormat:@"XF_%@.ICO", imgFileName] uppercaseString];
//				img = [imgMap objectForKey:imgFileName];
//				if( img )
//				{
//					[gameInfo setObject:img forKey:kMFGameRegistryIconKey];
//				}
//				else
//				{
//					if( _defaultImage )
//						[gameInfo setObject:_defaultImage forKey:kMFGameRegistryIconKey];
//				}
//			}
//		}
//		
//		rv = YES;
//	}
//	@catch( NSException *e )
//	{
//		NSLog(@"Caught exception loading icons file: %@", e);
//		rv = NO;
//	}
//	
//	return rv;
}

- (UIImage *)defaultImage
{
	return _defaultImage;
}

- (UIImage *)iconForGameID:(int)gid
{
	NSMutableDictionary *gameInfo = (NSMutableDictionary *)[self infoForGameID:gid];
	UIImage *icon = [gameInfo objectForKey:kMFGameRegistryIconKey];
	if (!icon)
	{
		NSString *shortGameName = [gameInfo objectForKey:kMFGameRegistryShortNameKey];
		NSString *iconFileName = [[NSString stringWithFormat:@"XF_%@.ICO", shortGameName] uppercaseString];
		icon = [UIImage imageNamed:iconFileName];
		if (!icon)
		{
			icon = _defaultImage;
		}
		
		[gameInfo setObject:icon forKey:kMFGameRegistryIconKey];
	}
	
	return icon;
}

+ (NSDictionary *)infoForGameID:(int)gid
{
	return [[self registry] infoForGameID:gid];
}

- (NSDictionary *)infoForGameID:(int)gid
{
	return [_games objectForKey:[NSNumber numberWithInt:gid]];
}

+ (NSString *)longNameForGameID:(int)gid
{
	return [[self infoForGameID:gid] objectForKey:kMFGameRegistryLongNameKey];
}

+ (NSDictionary *)infoForMacApplication:(NSDictionary *)appInfo
{
	return [[self registry] infoForMacApplication:appInfo];
}

- (NSDictionary *)infoForMacApplication:(NSDictionary *)appInfo
{
	NSString *appPath = [[[appInfo objectForKey:@"NSApplicationPath"] lastPathComponent] uppercaseString];
	return [_macGames objectForKey:appPath];
}

- (NSString *)description
{
	int i, cnt;
	NSMutableString *str = [NSMutableString string];
	NSArray *keys = [[_games allKeys] sortedArrayUsingSelector:@selector(compare:)];
	NSDictionary *game;
	
	[str appendFormat:@"MFGameRegistry, version %d\n",_version];
	
	cnt = [keys count];
	for( i = 0; i < cnt; i++ )
	{
		game = [_games objectForKey:[keys objectAtIndex:i]];
		[str appendFormat:@"  %5d  %5d  %@  %@  -  \"%@\"\n",
			i,
			[[game objectForKey:kMFGameRegistryIDKey] intValue],
			([game objectForKey:kMFGameRegistryMacAppPathsKey] ? @"Mac" : @"   "),
			[game objectForKey:kMFGameRegistryShortNameKey],
			[game objectForKey:kMFGameRegistryLongNameKey]
			];
	}
	[str appendFormat:@"%@",_macGames];
	
	return str;
}

@end
