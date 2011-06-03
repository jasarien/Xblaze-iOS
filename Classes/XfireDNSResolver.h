//
//  DNSResolver.h
//  DNSResolver
//
//  Created by james on 12/02/2010.
//  Copyright 2010 Truphone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CFNetwork/CFNetwork.h>

@protocol  XfireDNSResolverDelegate;

@interface XfireDNSResolver : NSObject {
	
	CFHostRef _hostRef;
		
	id <XfireDNSResolverDelegate> _delegate;
}

- (id)initWithHostName:(NSString *)hostName;

- (BOOL)startResolution;

@property (nonatomic, assign) id <XfireDNSResolverDelegate> delegate;

@end

@protocol XfireDNSResolverDelegate <NSObject>

@optional
- (void)resolver:(XfireDNSResolver *)resolver didFinishResolvingHostName:(NSString *)hostName toAddresses:(NSArray *)ipAddresses;
- (void)resolver:(XfireDNSResolver *)resolver didFailToResolveHostName:(NSString *)hostName withError:(NSError *)error;

@end
