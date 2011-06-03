//
//  DNSResolver.m
//  DNSResolver
//
//  Created by james on 12/02/2010.
//  Copyright 2010 Truphone. All rights reserved.
//

#import "XfireDNSResolver.h"
#include <netinet/in.h>     // INET6_ADDRSTRLEN
#include <arpa/nameser.h>   // NS_MAXDNAME
#include <netdb.h>          // getaddrinfo, struct addrinfo, AI_NUMERICHOST
#include <unistd.h>         // getopt

const NSString *kResolverKey = @"kResolverKey";
const NSString *kHostNameKey = @"kHostNameKey";

@implementation XfireDNSResolver
@synthesize delegate = _delegate;

void hostClientCallBack(CFHostRef host, CFHostInfoType typeInfo, const CFStreamError *error, void *info);

#pragma mark -
#pragma mark Initialisation

- (id)initWithHostName:(NSString *)hostName
{
	if ((self = [super init]))
	{
		_hostRef = CFHostCreateWithName(kCFAllocatorDefault, (CFStringRef)hostName);
		NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys:self, kResolverKey, hostName, kHostNameKey, nil];
		CFHostClientContext clientContext = { 0, (void *)context, CFRetain, CFRelease, NULL };
		CFHostSetClient(_hostRef, hostClientCallBack, &clientContext);
	}
	
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

#pragma mark -
#pragma mark Resolution

- (BOOL)startResolution
{
	CFHostScheduleWithRunLoop(_hostRef, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
	CFStreamError error;
	BOOL success = CFHostStartInfoResolution(_hostRef, kCFHostAddresses, &error);
	if (!success)
	{
		NSLog(@"CFHostStartInfoResolution returned error (%ld, %ld)\n", error.domain, error.error);
		return NO;
	}
	
	return YES;
}

#pragma mark -
#pragma mark CallBacks

void hostClientCallBack(CFHostRef host, CFHostInfoType typeInfo, const CFStreamError *error, void *info)
{
	NSDictionary *context = (NSDictionary *)info;
	XfireDNSResolver *self = [context objectForKey:kResolverKey];
	NSString *hostName = [context objectForKey:kHostNameKey];
    
    if (error->error == noErr) {
		
        switch (typeInfo) {
				
            case kCFHostAddresses:
			{
                CFArrayRef addresses = CFHostGetAddressing(host, NULL);
				struct sockaddr  *addr;
				char             ipAddress[INET6_ADDRSTRLEN];
				CFIndex          index, count;
				int              err;
				
				NSMutableArray *ipAddresses = [NSMutableArray array];
				
				count = CFArrayGetCount(addresses);
				for (index = 0; index < count; index++)
				{
					addr = (struct sockaddr *)CFDataGetBytePtr(CFArrayGetValueAtIndex(addresses, index));
					
					/* getnameinfo coverts an IPv4 or IPv6 address into a text string. */
					err = getnameinfo(addr, addr->sa_len, ipAddress, INET6_ADDRSTRLEN, NULL, 0, NI_NUMERICHOST);
					if (err == 0)
					{
						[ipAddresses addObject:[NSString stringWithUTF8String:ipAddress]];
					}
					else
					{
						if ([[self delegate] respondsToSelector:@selector(resolver:didFailToResolveHostName:withError:)])
						{
							NSError *anError = [NSError errorWithDomain:@"GetNameInfoErrorDomain" code:err userInfo:nil];
							[[self delegate] resolver:self didFailToResolveHostName:hostName withError:anError];
						}
						
						NSLog(@"DNSResolver: getnameinfo returned %d\n", err);
					}
				}
				
				if ([[self delegate] respondsToSelector:@selector(resolver:didFinishResolvingHostName:toAddresses:)])
				{
					[[self delegate] resolver:self didFinishResolvingHostName:hostName toAddresses:[[ipAddresses copy] autorelease]];
				}
				
                break;
			}
            default:
				if ([[self delegate] respondsToSelector:@selector(resolver:didFailToResolveHostName:withError:)])
				{
					NSError *anError = [NSError errorWithDomain:@"UnsupportedResolutionType" code:0 userInfo:nil];
					[[self delegate] resolver:self didFailToResolveHostName:hostName withError:anError];
				}
                NSLog(@"Unsupported CFHostInfoType (%d)\n", typeInfo);
                break;
        }
    } else {
		if ([[self delegate] respondsToSelector:@selector(resolver:didFailToResolveHostName:withError:)])
		{
			NSError *anError = [NSError errorWithDomain:@"CFNetworkErrorDomain" code:error->error userInfo:nil];
			[[self delegate] resolver:self didFailToResolveHostName:hostName withError:anError];
		}
		
        NSLog(@"Unable to resolve, error returned (%ld, %ld)\n", error->domain, error->error);
    }
	
	CFHostUnscheduleFromRunLoop(host, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    (void) CFHostSetClient(host, NULL, NULL);
    CFRelease(host);
}

@end
