//
//  XBUnregisterPushWebRequest.m
//  Xblaze-iPhone
//
//  Created by James Addyman on 02/04/2012.
//  Copyright (c) 2012 JamSoft. All rights reserved.
//

#import "XBUnregisterPushWebRequest.h"

@implementation XBUnregisterPushWebRequest

- (id)initWithBodyString:(NSString *)bodyString
{
	if ((self = [super initWithBodyString:bodyString]))
	{
		_urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", serverRoot, unregisterResource]]];
		[_urlRequest setHTTPMethod:@"POST"];
		[_urlRequest setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
		[_urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		[_urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	}
	
	return self;
}
@end
