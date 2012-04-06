//
//  XBPushManager.h
//  Xblaze-iPhone
//
//  Created by James Addyman on 12/02/2012.
//  Copyright (c) 2012 JamSoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XBPushWebRequest.h"

@class XBPushManager;

@protocol XBPushManagerDelegate <NSObject>

@optional
- (void)pushManagerDidRegister:(XBPushManager *)pushManager;
- (void)pushManager:(XBPushManager *)pushManager didFailToRegisterWithError:(NSError *)error;
- (void)pushManagerDidUnregister:(XBPushManager *)pushManager;
- (void)pushManager:(XBPushManager *)pushManager didFailToUnregisterWithError:(NSError *)error;
- (void)pushManagerDidUnregisterDevice:(XBPushManager *)pushManager;
- (void)pushManager:(XBPushManager *)pushManager didFailToUnregisterDeviceWithError:(NSError *)error;
- (void)pushManager:(XBPushManager *)pushManager didLoadMissedMessages:(NSArray *)missedMessages;
- (void)pushManager:(XBPushManager *)pushManager didFailToLoadMissedMessagesWithError:(NSError *)error;

@end

@interface XBPushManager : NSObject <XBPushWebRequestDelegate> {
	
	NSMutableArray *_activeRequests;
	
	NSTimer *_heartbeatTimer;
	
}

@property (nonatomic, assign) id<XBPushManagerDelegate> delegate;

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *passwordHash;
@property (nonatomic, copy) NSString *pushToken;

+ (XBPushManager *)sharedInstance;

- (void)registerToServer;
- (void)unregisterFromServer;
- (void)unregisterDeviceFromServer;
- (void)connectToServer;
- (void)sendHeartbeatToServer;
- (void)sendKillHeartbeatToServer;

- (void)startHeartbeat;
- (void)stopHeartbeat;

- (void)downloadMissedMessages;

@end
