 /*******************************************************************
	FILE:		MFGameRegistry.h
	
	COPYRIGHT:
		Copyright 2007-2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Contains information about games, contained in the Games.plist
		file.  (The content of that plist is similar to the real Xfire
		client's xfire_games.ini file.)
	
	HISTORY:
		2008 12 20  Revised to use a single plist file instead of the
		            separate INI file and Mac Games plist file.
		2008 04 06  Changed copyright to BSD license.
		2007 12 16  Added Mac Games list.
		2007 12 02  Added copyright notice.
		2007 11 25  Created.
*******************************************************************/

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface MFGameRegistry : NSObject
{
	NSInteger				_version;
	UIImage					*_defaultImage;
	
	// _games key is the game ID, object has the keys identified by constants below
	// _macGames contains the same dictionaries, and uses the uppercase string of the app path as its key
	NSMutableDictionary		*_games;
	NSMutableDictionary		*_macGames;
}

@property (nonatomic, readonly) NSMutableDictionary *games;


// Singleton
+ (id)registry;

+ (NSDictionary *)infoForGameID:(int)gid;
- (NSDictionary *)infoForGameID:(int)gid;

// helper
+ (NSString *)longNameForGameID:(int)gid;
+ (NSURL *)iconURLForGameID:(int)gid;

// pass the dictionary containing keys as populated by NSWorkspace
+ (NSDictionary *)infoForMacApplication:(NSDictionary *)appInfo;
- (NSDictionary *)infoForMacApplication:(NSDictionary *)appInfo;

- (UIImage *)defaultImage;
- (UIImage *)iconForGameID:(int)gid;

@end

// Keys for information dictionary
// Every dictionary has the ID key.  Not every dictionary has the others.
extern NSString *kMFGameRegistryIDKey;              // NSNumber(int)
extern NSString *kMFGameRegistryLongNameKey;        // NSString
extern NSString *kMFGameRegistryShortNameKey;       // NSString
extern NSString *kMFGameRegistryIconKey;            // NSImage
extern NSString *kMFGameRegistryMacAppPathsKey;     // NSArray(NSString)
