/*******************************************************************
	FILE:		XfireSkin.h
	
	COPYRIGHT:
		Copyright 2007-2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		A thin class for a skin.  This is only used upon login when
		the Xfire protocol requires the annunciation of skin.  Since
		MacFire doesn't use skins, this currently only supports one skin.
	
	HISTORY:
		2008 04 06  Changed copyright to BSD license.
		2008 01 12  Added copyright notice.
		2007 11 23  Created.
*******************************************************************/

#import <Foundation/Foundation.h>

@interface XfireSkin : NSObject
{
	NSString *_skinName;
	NSString *_themeName;
}

// Currenly only support one skin for the purpose of network
+ (XfireSkin *)theSkin;

- (NSString *)name;
- (NSString *)theme;

@end
