//
//  XfireScreenshot.m
//  Xblaze-iPhone
//
//  Created by James on 20/04/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import "XfireScreenshot.h"

@implementation XfireScreenshot

@synthesize index = _index;
@synthesize gameID = _gameID;
@synthesize screenshotDescription = _screenshotDescription;

- (id)initWithIndex:(NSNumber *)index
			 gameID:(NSNumber *)gameID
		description:(NSString *)description
{
	if ((self = [super init]))
	{
		self.index = index;
		self.gameID = gameID;
		self.screenshotDescription = description;
	}
	
	return self;
}

- (void)dealloc
{
	self.index = nil;
	self.gameID = nil;	
	self.screenshotDescription = nil;
	
	[super dealloc];
}

- (NSURL *)thumbnailURL
{
	NSString *urlString = [NSString stringWithFormat:@"http://screenshot.xfire.com/s/%u-0.jpg", [self.index unsignedIntValue]];
	NSURL *thumbnailURL = [NSURL URLWithString:urlString];
	
	return thumbnailURL;
}

- (NSURL *)fullsizeURL
{
	NSString *urlString = [NSString stringWithFormat:@"http://screenshot.xfire.com/s/%u-4.jpg", [self.index unsignedIntValue]];
	NSURL *fullSizeURL = [NSURL URLWithString:urlString];	
	
	return fullSizeURL;
}

- (NSURL *)mediumURL
{
	NSString *urlString = [NSString stringWithFormat:@"http://screenshot.xfire.com/s/%u-3.jpg", [self.index unsignedIntValue]];
	NSURL *mediumURL = [NSURL URLWithString:urlString];	
	
	return mediumURL;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"\nIndex: %u,\ngameID: %u\ndescription: %@", [self.index unsignedIntValue], [self.gameID unsignedIntValue], self.screenshotDescription];
}

@end
