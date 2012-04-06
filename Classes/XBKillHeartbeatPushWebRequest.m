//
//  XBKillHeartbeatPushWebRequest.m
//  Xblaze-iPhone
//
//  Created by James Addyman on 06/04/2012.
//  Copyright (c) 2012 JamSoft. All rights reserved.
//

#import "XBKillHeartbeatPushWebRequest.h"

@implementation XBKillHeartbeatPushWebRequest

- (id)initWithBodyString:(NSString *)bodyString
{
	if ((self = [super initWithBodyString:bodyString]))
	{
		_urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", serverRoot, killHeartbeatResource]]];
		[_urlRequest setHTTPMethod:@"POST"];
		[_urlRequest setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
		[_urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		[_urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	}
	
	return self;
}

@end
