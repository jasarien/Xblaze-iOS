//
//  XfireScreenshot.h
//  Xblaze-iPhone
//
//  Created by James on 20/04/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XfireScreenshot : NSObject {
	
	NSNumber *_index;
	NSNumber *_gameID;
	NSString *_screenshotDescription;
}

@property (nonatomic, retain) NSNumber *index;
@property (nonatomic, retain) NSNumber *gameID;
@property (nonatomic, retain) NSString *screenshotDescription;

- (id)initWithIndex:(NSNumber *)index
			 gameID:(NSNumber *)gameID
		description:(NSString *)description;

- (NSURL *)thumbnailURL;
- (NSURL *)mediumURL;
- (NSURL *)fullsizeURL;

@end
