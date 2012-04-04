//
//  XBMissedMessagesPushWebRequest.m
//  Xblaze-iPhone
//
//  Created by James Addyman on 03/04/2012.
//  Copyright (c) 2012 JamSoft. All rights reserved.
//

#import "XBMissedMessagesPushWebRequest.h"

@implementation XBMissedMessagesPushWebRequest

- (id)initWithBodyString:(NSString *)bodyString
{
	if ((self = [super initWithBodyString:bodyString]))
	{
		_urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", serverRoot, missedMessagesResource]]];
		[_urlRequest setHTTPMethod:@"POST"];
		[_urlRequest setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
		[_urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		[_urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	}
	
	return self;
}

@end
