
#import <Cocoa/Cocoa.h>

NSString *kMFGameRegistryIDKey          = @"ID";
NSString *kMFGameRegistryLongNameKey    = @"LongName";
NSString *kMFGameRegistryShortNameKey   = @"ShortName";
NSString *kMFGameRegistryIconKey        = @"Icon";
NSString *kMFGameRegistryMacAppPathsKey = @"MacAppPaths";

NSMutableDictionary* LoadINI (NSString *path, int *ver);
void MergeMacGames( NSArray *macgames, NSMutableDictionary *xfiregames );
NSMutableArray* MakeIntoArray( NSMutableDictionary *dic );

int MyMain(NSArray *args);
int main(int argc, const char **argv)
{
	int rv;
	
	@try
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSMutableArray *args = [NSMutableArray array];
		int i;
		for( i = 1; i < argc; i++ )
		{
			[args addObject:[NSString stringWithCString:argv[i]]];
		}
		rv = MyMain(args);
		[pool release];
	}
	@catch( NSException *e )
	{
		NSLog(@"Uncaught exception: %@", e);
		rv = -1;
	}
	
	return rv;
}

// load Xfire game list
// load Mac Games list
// merge Mac and Xfire games lists
// turn the dictionary into a suitable array to write to the file
// write the file
int MyMain(NSArray *args)
{
	int ver;
	
	NSMutableDictionary *ini = LoadINI(@"xfire_games.ini", &ver);
	if( !ini )
	{
		NSLog(@"Unable to open xfire_games.ini");
		return -1;
	}
	
	NSArray *macgames = [NSArray arrayWithContentsOfFile:@"Mac Games.plist"];
	if( !macgames )
	{
		NSLog(@"Unable to open Mac Games.plist");
		return -1;
	}
	
	MergeMacGames( macgames, ini );
	
	NSMutableArray *arr;
	arr = MakeIntoArray(ini);
	
	NSMutableDictionary *finaldict = [NSMutableDictionary dictionary];
	[finaldict setObject:[NSNumber numberWithInt:ver] forKey:@"XfireGamesVersion"];
	[finaldict setObject:arr forKey:@"Games"];
	
	if( finaldict )
	{
		[finaldict writeToFile:@"Games new.plist" atomically:NO];
		NSLog(@"Wrote to \"Games new.plist\"");
	}
	
	return 0;
}

NSMutableDictionary* LoadINI (NSString *path, int *v)
{
	NSString				*fileContent;
	NSArray					*fileLines;
	NSCharacterSet			*wscs = [NSCharacterSet whitespaceCharacterSet];
	NSEnumerator			*lineEnumer;
	NSString				*sectionKey;
	int						curGameID;
	NSString				*lineText;
	NSMutableDictionary		*curGameDict;
	NSMutableDictionary		*_games;
	int						_version = 0;
	
	// Force NSString to separate out the lines for us
	fileContent = [NSString stringWithContentsOfFile:path];
	if( fileContent == nil ) return NO;
	
	// The xfire_games.ini file uses CRLF to end each line, we must look at the same
	fileLines = [fileContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	//fileLines = [fileContent componentsSeparatedByString:@"\r\n"];
	if( fileLines == nil ) return NO;
	
	// Anything before the first [xxx] tag is ignored
	sectionKey = nil;
	curGameID = -1;
	
	_games = [[NSMutableDictionary alloc] init];
	
	lineEnumer = [fileLines objectEnumerator];
	while( (lineText = [lineEnumer nextObject]) != nil )
	{
		// Trim white-space from the ends (start/finish)
		// If there's anything left, process it as key/value pair or section key
		lineText = [lineText stringByTrimmingCharactersInSet:wscs];
		if( [lineText length] > 0 )
		{
			NSRange rng1, rng2;
			rng1 = [lineText rangeOfString:@"="];
			if( rng1.location == NSNotFound )
			{
				// no '=' on the line, assume it's a section key
				rng1 = [lineText rangeOfString:@"["];
				rng2 = [lineText rangeOfString:@"]"];
				if( (rng1.location == NSNotFound) || (rng2.location == NSNotFound) )
				{
					// not an '=' line or a '[...]' line
					// ignore it
				}
				else if( rng2.location < rng1.location )
				{
					// invalid line, ignore (ordered ']...[')
				}
				else
				{
					sectionKey = [lineText substringWithRange:
						NSMakeRange( rng1.location+rng1.length,
							rng2.location-rng1.length  ) ];
					
					// the section key may be one of:
					//  [Version]    file version
					//  [##]         a game key number
					//  [##_#]       multiple entries for game number (e.g. [4601_1] [4601_2]
					
					rng1 = [sectionKey rangeOfString:@"_"];
					if( rng1.length > 0 )
					{
						NSString *tmp = [sectionKey substringWithRange:NSMakeRange(0,rng1.location)];
						curGameID = [tmp intValue];
						
						curGameDict = [NSMutableDictionary dictionary];
						NSNumber *t2 = [NSNumber numberWithInt:curGameID];
						[curGameDict setObject:t2 forKey:kMFGameRegistryIDKey];
						[_games setObject:curGameDict forKey:t2];
					}
					else if( [sectionKey isEqualToString:@"Version"] )
					{
						curGameID = -1;
						curGameDict = nil;
					}
					else
					{
						curGameID = [sectionKey intValue];
						
						curGameDict = [NSMutableDictionary dictionary];
						NSNumber *t2 = [NSNumber numberWithInt:curGameID];
						[curGameDict setObject:t2 forKey:kMFGameRegistryIDKey];
						[_games setObject:curGameDict forKey:t2];
					}
				}
			}
			else // contains '='
			{
				NSString *minorKey;
				NSString *minorValue;
				
				minorKey = [lineText substringWithRange:NSMakeRange(0,rng1.location)];
				minorValue = [lineText substringWithRange:NSMakeRange(rng1.location+rng1.length,
					[lineText length] - rng1.location - rng1.length)];
				
				// now trim, to be safe
				minorKey = [minorKey stringByTrimmingCharactersInSet:wscs];
				minorValue = [minorValue stringByTrimmingCharactersInSet:wscs];
				
				if( [sectionKey isEqualToString:@"Version"] )
				{
					if( [minorKey isEqualToString:@"Version"] )
					{
						_version = [minorValue intValue];
					}
				}
				else if( [minorKey isEqualToString:kMFGameRegistryLongNameKey] ||
					[minorKey isEqualToString:kMFGameRegistryShortNameKey] )
				{
					// check for consistency
					NSString *tmp = [curGameDict objectForKey:minorKey];
					if( tmp )
					{
						if( ![tmp isEqualToString:minorValue] )
						{
							NSLog(@"Inconsistent INI file (%@=%@ or %@)",minorKey,tmp,minorValue);
						}
					}
					else
					{
						[curGameDict setObject:minorValue forKey:minorKey];
					}
				}
			}
		}
	}
	
	*v = _version;
	return _games;
}

void MergeMacGames( NSArray *macgames, NSMutableDictionary *xfiregames )
{
	int i, cnt;
	cnt = [macgames count];
	NSDictionary *d1;
	NSMutableDictionary *d2;
	
	for( i = 0; i < cnt; i++ )
	{
		d1 = [macgames objectAtIndex:i];
		d2 = [xfiregames objectForKey:[d1 objectForKey:@"GameID"]];
		if( !d2 )
		{
			NSLog(@"Can't find Xfire game for %@",d1);
		}
		else
		{
			NSMutableArray *a = [d2 objectForKey:@"MacAppPaths"];
			if( !a )
			{
				a = [NSMutableArray array];
				[d2 setObject:a forKey:@"MacAppPaths"];
			}
			[a addObject:[d1 objectForKey:@"AppPath"]];
		}
	}
}

NSMutableArray* MakeIntoArray( NSMutableDictionary *dic )
{
	NSArray *keys = [dic allKeys];
	keys = [keys sortedArrayUsingSelector:@selector(compare:)];
	int i, cnt;
	NSDictionary *srcDict;
	
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[keys count]];
	
	cnt = [keys count];
	for( i = 0; i < cnt; i++ )
	{
		srcDict = [dic objectForKey:[keys objectAtIndex:i]];
		[arr addObject:srcDict];
	}
	
	return arr;
}
