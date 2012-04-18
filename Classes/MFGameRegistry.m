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
@interface MFGameRegistry ()

- (NSString *)gamesListPath;
- (void)loadGamesFile;
- (void)getLatestGamesListIfNecessary;

@end

@implementation MFGameRegistry

@synthesize games = _games;

+ (id)registry
{
	if (gRegistry == nil)
	{
		gRegistry = [[MFGameRegistry alloc] init];
	}
	
	return gRegistry;
}

- (id)init
{
	if((self = [super init]))
	{		
		_version = 0;
		_defaultImage = nil;
		_games = nil;
		_macGames = nil;

		[self loadGamesFile];
		
		_defaultImage = [[UIImage imageNamed:@"XfireLarge.png"] retain];
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

- (NSString *)gamesListPath
{
	NSString *gamesListPath = nil;
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0)
	{
		gamesListPath = [paths objectAtIndex:0];
	}
	
	return [gamesListPath stringByAppendingPathComponent:@"Games.plist"];
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
- (void)loadGamesFile
{
	NSString *gamesListPath = [self gamesListPath];
	
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:gamesListPath];
	if (dict == nil)
	{
		dict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Games" ofType:@"plist"]];
		[self getLatestGamesListIfNecessary];
	}
	
	_version = [[dict objectForKey:@"XfireGamesVersion"] integerValue];
	
	NSArray *games = [dict objectForKey:@"Games"];
	
	[_games release];
	[_macGames release];
	
	_games = [[NSMutableDictionary alloc] init];
	_macGames = [[NSMutableDictionary alloc] init];
	
	for(NSDictionary *game in games)
	{
		id key = [game objectForKey:kMFGameRegistryIDKey];
		if (key)
		{
			[_games setObject:game forKey:key];
			
			NSArray *appPaths = [game objectForKey:kMFGameRegistryMacAppPathsKey];
			if (appPaths != nil)
			{
				for (NSString *appPath in appPaths)
				{
					[_macGames setObject:game
						forKey:[appPath uppercaseString]];
				}
			}
		}
	}
}

- (void)getLatestGamesListIfNecessary
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://xblaze.co.uk/games/version"]];
		NSHTTPURLResponse *urlResponse = nil;
		NSError *error = nil;
		NSData *response = [NSURLConnection sendSynchronousRequest:request
												 returningResponse:&urlResponse
															 error:&error];
		if (([urlResponse statusCode] == 200) && (error == nil))
		{
			NSString *responseString = [[[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding] autorelease];
			NSInteger version = [responseString integerValue];
			
			if (version > _version)
			{
				request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://xblaze.co.uk/games/Games.plist"]];
				response = [NSURLConnection sendSynchronousRequest:request
												 returningResponse:&urlResponse
															 error:&error];
				if (([urlResponse statusCode] == 200) && (error == nil))
				{
					responseString = [[[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding] autorelease];
					[responseString writeToFile:[self gamesListPath]
									 atomically:YES
									   encoding:NSUTF8StringEncoding
										  error:nil];
					dispatch_async(dispatch_get_main_queue(), ^{
						[self loadGamesFile];
					});
				}
				else
				{
					NSLog(@"GamesList download respose: %d, error: %@", [urlResponse statusCode], [error localizedDescription]);
				}
			}
			else
			{
				NSLog(@"No newer games list available");
			}
		}
		else
		{
			NSLog(@"GamesList version check respose: %d, error: %@", [urlResponse statusCode], [error localizedDescription]);
		}
		
	});
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
		
		//[gameInfo setObject:icon forKey:kMFGameRegistryIconKey];
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

+ (NSURL *)iconURLForGameID:(int)gid
{
	NSMutableDictionary *gameInfo = (NSMutableDictionary *)[self infoForGameID:gid];
	NSString *shortGameName = [gameInfo objectForKey:kMFGameRegistryShortNameKey];
	NSString *iconName = [[NSString stringWithFormat:@"XF_%@.ICO", shortGameName] uppercaseString];
	
	return [NSURL URLWithString:[NSString stringWithFormat:@"http://xblaze.co.uk/games/icons/%@", iconName]];
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
