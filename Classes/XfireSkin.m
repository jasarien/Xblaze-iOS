/*******************************************************************
	FILE:		XfireSkin.m
	
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

#import "XfireSkin.h"

@interface XfireSkin (Private)
- (id)initWithName:(NSString *)n theme:(NSString *)t;
@end

XfireSkin *gTheSkin = nil;

@implementation XfireSkin

+ (XfireSkin *)theSkin
{
	if( gTheSkin == nil )
	{
		//gTheSkin = [[XfireSkin alloc] initWithName:@"Shadow" theme:@"default"];
		gTheSkin = [[XfireSkin alloc] initWithName:@"Xblaze, iPhone" theme:@"default"];
	}
	return gTheSkin;
}

- (id)initWithName:(NSString *)n theme:(NSString *)t
{
	self = [super init];
	if( self )
	{
		_skinName = [n copy];
		_themeName = [t copy];
	}
	return self;
}

- (void)dealloc
{
	[_skinName release];
	[_themeName release];
	[super dealloc];
}

- (NSString *)name
{
	return _skinName;
}

- (NSString *)theme
{
	return _themeName;
}

@end
