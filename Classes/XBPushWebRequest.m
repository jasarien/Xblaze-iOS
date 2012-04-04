//
//  XBPushWebRequest.m
//  Xblaze-iPhone
//
//  Created by James Addyman on 02/04/2012.
//  Copyright (c) 2012 JamSoft. All rights reserved.
//

#import "XBPushWebRequest.h"
#import "SBJson.h"
#import "XBNetworkActivityIndicatorManager.h"

NSString const *serverRoot = @"http://megalion.local:8080/";
NSString const *registerResource = @"register";
NSString const *connectResource = @"connect";
NSString const *unregisterResource = @"unregister";
NSString const *unregisterDeviceResource = @"unregisterDevice";
NSString const *heartbeatResource = @"heartbeat";
NSString const *missedMessagesResource = @"missedMessages";

@implementation XBPushWebRequest

@synthesize delegate = _delegate;

- (id)initWithBodyString:(NSString *)bodyString
{
	if ((self = [super init]))
	{
		
	}
	
	return self;
}

- (void)dealloc
{
	[_connection cancel];
	[_httpResponse release];
	[_data release];
	[super dealloc];
}

- (void)start
{
	[_data release];
	_data = [[NSMutableData alloc] init];
	
	_connection = [NSURLConnection connectionWithRequest:_urlRequest
												delegate:self];
	[XBNetworkActivityIndicatorManager showNetworkActivity];
}

- (void)cancel
{
	[_connection cancel];
	[_data release], _data = nil;
	[_httpResponse release], _httpResponse = nil;
	[XBNetworkActivityIndicatorManager hideNetworkActivity];
}

- (BOOL)didSucceed
{
	if ([self statusCode] == 200)
		return YES;
	
	return NO;
}

- (BOOL)hasHTTPError
{
	if (([self statusCode] != 200) && [self statusCode] != 0)
		return YES;
	
	return NO;
}

- (NSUInteger)statusCode
{
	return [_httpResponse statusCode];
}

- (NSDictionary *)responseDictionary
{
	return _responseDictionary;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[XBNetworkActivityIndicatorManager hideNetworkActivity];
	
	[_responseDictionary release];
	
	SBJsonParser *parser = [[SBJsonParser alloc] init];
	_responseDictionary = [[parser objectWithData:_data] retain];
	
	[parser release];
	[_data release], _data = nil;
	
	if ([self didSucceed])
	{
		if ([self.delegate respondsToSelector:@selector(pushWebRequestDidFinishLoading:)])
		{
			[self.delegate pushWebRequestDidFinishLoading:self];
		}
	}
	else
	{
		[self connection:_connection didFailWithError:[NSError errorWithDomain:@"com.jamsoft.xblaze"
																		  code:[self statusCode]
																	  userInfo:[NSDictionary dictionaryWithObject:[NSHTTPURLResponse localizedStringForStatusCode:[self statusCode]]
																										   forKey:NSLocalizedDescriptionKey]]];
	}
	
	_connection = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[XBNetworkActivityIndicatorManager hideNetworkActivity];
	
	[_data release], _data = nil;
	_connection = nil;
	
	if ([self.delegate respondsToSelector:@selector(pushWebRequest:didFailWithError:)])
	{
		[self.delegate pushWebRequest:self didFailWithError:error];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_data appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	[_httpResponse release];
	_httpResponse = (NSHTTPURLResponse *)[response retain];
}

@end
