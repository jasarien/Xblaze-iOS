//
//  XBPushManager.m
//  Xblaze-iPhone
//
//  Created by James Addyman on 12/02/2012.
//  Copyright (c) 2012 JamSoft. All rights reserved.
//

#import "XBPushManager.h"
#import "XBRegisterPushWebRequest.h"
#import "XBUnregisterPushWebRequest.h"
#import "XBUnregisterDevicePushWebRequest.h"
#import "XBConnectPushWebRequest.h"
#import "XBHeartbeatPushWebRequest.h"
#import "XBMissedMessagesPushWebRequest.h"
#import "SBJson.h"

#define heartbeatInterval 120

@implementation XBPushManager

@synthesize delegate = _delegate;

@synthesize username = _username;
@synthesize passwordHash = _passwordHash;
@synthesize pushToken = _pushToken;

static XBPushManager *_sharedInstance;

+ (XBPushManager *)sharedInstance
{
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
		_sharedInstance = [[self alloc] init];
	});
	return _sharedInstance;
}

- (id)init
{
	if ((self = [super init]))
	{
		_activeRequests = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (void)dealloc
{
	[_activeRequests release];
	[self stopHeartbeat];
	
	self.username = nil;
	self.passwordHash = nil;
	self.pushToken = nil;
	
    [super dealloc];
}

- (void)registerToServer
{
	if (![self.username length] ||
		![self.passwordHash length] ||
		![self.pushToken length])
	{
		return;
	}
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	NSDictionary *device = [NSDictionary dictionaryWithObject:self.pushToken forKey:@"pushToken"];
	NSDictionary *user = [NSDictionary dictionaryWithObjectsAndKeys:self.username, @"username", self.passwordHash, @"passwordHash", device, @"device", nil];
	[dict setObject:user forKey:@"user"];
	
	NSString *bodyString = [dict JSONRepresentation];
	
	XBRegisterPushWebRequest *request = [[[XBRegisterPushWebRequest alloc] initWithBodyString:bodyString] autorelease];
	[request setDelegate:self];
	[_activeRequests addObject:request];
	[request start];
}

- (void)unregisterFromServer
{
	if (![self.username length] ||
		![self.passwordHash length] ||
		![self.pushToken length])
	{
		return;
	}
	
	NSDictionary *user = [NSDictionary dictionaryWithObject:self.username forKey:@"username"];
	NSDictionary *dict = [NSDictionary dictionaryWithObject:user forKey:@"user"];
	
	NSString *bodyString = [dict JSONRepresentation];
	
	XBUnregisterPushWebRequest *request = [[[XBUnregisterPushWebRequest alloc] initWithBodyString:bodyString] autorelease];
	[request setDelegate:self];
	[_activeRequests addObject:request];
	[request start];
	
	[self stopHeartbeat];
}

- (void)unregisterDeviceFromServer
{
	if (![self.username length] ||
		![self.passwordHash length] ||
		![self.pushToken length])
	{
		return;
	}
	
	NSDictionary *user = [NSDictionary dictionaryWithObject:self.username forKey:@"username"];
	NSDictionary *device = [NSDictionary dictionaryWithObject:self.pushToken forKey:@"pushToken"];
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:user, @"user", device, @"device", nil];
	
	NSString *bodyString = [dict JSONRepresentation];
	
	XBUnregisterDevicePushWebRequest *request = [[[XBUnregisterDevicePushWebRequest alloc] initWithBodyString:bodyString] autorelease];
	[request setDelegate:self];
	[_activeRequests addObject:request];
	[request start];
	
	[self stopHeartbeat];
}

- (void)connectToServer
{
	if (![self.username length] ||
		![self.passwordHash length] ||
		![self.pushToken length])
	{
		return;
	}
	
	NSDictionary *user = [NSDictionary dictionaryWithObject:self.username forKey:@"username"];
	NSDictionary *dict = [NSDictionary dictionaryWithObject:user forKey:@"user"];
	
	NSString *bodyString = [dict JSONRepresentation];
	
	XBConnectPushWebRequest *request = [[[XBConnectPushWebRequest alloc] initWithBodyString:bodyString] autorelease];
	[request setDelegate:self];
	[_activeRequests addObject:request];
	[request start];
	
	[self stopHeartbeat];
}

- (void)sendHeartbeatToServer
{
	if (![self.username length] ||
		![self.passwordHash length] ||
		![self.pushToken length])
	{
		return;
	}
	
	NSLog(@"Sending heartbeat");
	
	NSDictionary *user = [NSDictionary dictionaryWithObject:self.username forKey:@"username"];
	NSDictionary *dict = [NSDictionary dictionaryWithObject:user forKey:@"user"];
	
	NSString *bodyString = [dict JSONRepresentation];
	
	XBHeartbeatPushWebRequest *request = [[[XBHeartbeatPushWebRequest alloc] initWithBodyString:bodyString] autorelease];
	[request setDelegate:self];
	[_activeRequests addObject:request];
	[request start];
}

- (void)startHeartbeat
{
	[self sendHeartbeatToServer];
	_heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:heartbeatInterval
													   target:self
													 selector:@selector(heartbeatTimerExpired:)
													 userInfo:nil
													  repeats:YES];
}

- (void)stopHeartbeat
{
	[_heartbeatTimer invalidate], _heartbeatTimer = nil;
}

- (void)heartbeatTimerExpired:(NSTimer *)timer
{
	[self sendHeartbeatToServer];
}

- (void)downloadMissedMessages
{
	if (![self.username length] ||
		![self.passwordHash length] ||
		![self.pushToken length])
	{
		return;
	}
	
	NSLog(@"Sending heartbeat");
	
	NSDictionary *user = [NSDictionary dictionaryWithObject:self.username forKey:@"username"];
	NSDictionary *dict = [NSDictionary dictionaryWithObject:user forKey:@"user"];
	
	NSString *bodyString = [dict JSONRepresentation];
	
	XBMissedMessagesPushWebRequest *request = [[[XBMissedMessagesPushWebRequest alloc] initWithBodyString:bodyString] autorelease];
	[request setDelegate:self];
	[_activeRequests addObject:request];
	[request start];
}

- (void)pushWebRequestDidFinishLoading:(XBPushWebRequest *)request
{
	NSDictionary *response = [request responseDictionary];
	
	if ([request isMemberOfClass:[XBRegisterPushWebRequest class]])
	{
		[self startHeartbeat];
		if ([self.delegate respondsToSelector:@selector(pushManagerDidRegister:)])
		{
			[self.delegate pushManagerDidRegister:self];
		}
	}
	else if ([request isMemberOfClass:[XBUnregisterPushWebRequest class]])
	{
		if ([self.delegate respondsToSelector:@selector(pushManagerDidUnregister:)])
		{
			[self.delegate pushManagerDidUnregister:self];
		}		
	}
	else if ([request isMemberOfClass:[XBUnregisterDevicePushWebRequest class]])
	{
		if ([self.delegate respondsToSelector:@selector(pushManagerDidUnregisterDevice:)])
		{
			[self.delegate pushManagerDidUnregisterDevice:self];
		}
	}
	else if ([request isMemberOfClass:[XBConnectPushWebRequest class]])
	{
		
	}
	else if ([request isMemberOfClass:[XBHeartbeatPushWebRequest class]])
	{
		NSLog(@"Heartbeat sent successfully");
	}
	else if ([request isMemberOfClass:[XBMissedMessagesPushWebRequest class]])
	{		
		if ([self.delegate respondsToSelector:@selector(pushManager:didLoadMissedMessages:)])
		{
			NSMutableArray *missedMessages = [NSMutableArray array];
			for (NSDictionary *dict in [response objectForKey:@"missedMessages"])
			{
				NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"date"] doubleValue]];
				NSDictionary *missedMessage = [NSDictionary dictionaryWithObjectsAndKeys:[dict objectForKey:@"username"], @"username", [dict objectForKey:@"message"], @"message", date, @"date", nil];
				[missedMessages addObject:missedMessage];
			}
			
			[missedMessages sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
				return [[obj1 objectForKey:@"date"] compare:[obj2 objectForKey:@"date"]];
			}];
			
			[self.delegate pushManager:self didLoadMissedMessages:[[missedMessages copy] autorelease]];
		}
	}
	
	[_activeRequests removeObject:request];
}

- (void)pushWebRequest:(XBPushWebRequest *)request didFailWithError:(NSError *)error
{
	NSLog(@"Request did fail: %d - %@", [error code], [error localizedDescription]);
	
	if ([request isMemberOfClass:[XBRegisterPushWebRequest class]])
	{
		if ([self.delegate respondsToSelector:@selector(pushManager:didFailToRegisterWithError:)])
		{
			[self.delegate pushManager:self didFailToRegisterWithError:error];
		}
	}
	else if ([request isMemberOfClass:[XBUnregisterPushWebRequest class]])
	{
		if ([self.delegate respondsToSelector:@selector(pushManager:didFailToUnregisterWithError:)])
		{
			[self.delegate pushManager:self didFailToUnregisterWithError:error];
		}
	}
	else if ([request isMemberOfClass:[XBUnregisterDevicePushWebRequest class]])
	{
		if ([self.delegate respondsToSelector:@selector(pushManager:didFailToUnregisterDeviceWithError:)])
		{
			[self.delegate pushManager:self didFailToUnregisterDeviceWithError:error];
		}
	}
	else if ([request isMemberOfClass:[XBConnectPushWebRequest class]])
	{
		
	}
	else if ([request isMemberOfClass:[XBHeartbeatPushWebRequest class]])
	{
		
	}
	else if ([request isMemberOfClass:[XBMissedMessagesPushWebRequest class]])
	{
		if ([self.delegate respondsToSelector:@selector(pushManager:didFailToLoadMissedMessagesWithError:)])
		{
			[self.delegate pushManager:self didFailToLoadMissedMessagesWithError:error];
		}
	}
	
	[_activeRequests removeObject:request];
}

@end
