//
//  XBNetworkActivityIndicatorManager.m
//  Xblaze-iPhone
//
//  Created by James Addyman on 04/04/2012.
//  Copyright (c) 2012 JamSoft. All rights reserved.
//

#import "XBNetworkActivityIndicatorManager.h"

@implementation XBNetworkActivityIndicatorManager

NSInteger _activityCount = 0;

+ (void)showNetworkActivity
{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	_activityCount++;
}

+ (void)hideNetworkActivity
{
	if (_activityCount > 0)
		_activityCount--;
	
	if (_activityCount == 0)
	{
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	}
	
}

@end
