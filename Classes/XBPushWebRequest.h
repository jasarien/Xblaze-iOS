//
//  XBPushWebRequest.h
//  Xblaze-iPhone
//
//  Created by James Addyman on 02/04/2012.
//  Copyright (c) 2012 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString const *serverRoot;
extern NSString const *registerResource;
extern NSString const *connectResource;
extern NSString const *unregisterResource;
extern NSString const *unregisterDeviceResource;
extern NSString const *heartbeatResource;
extern NSString const *missedMessagesResource;

@class XBPushWebRequest;

@protocol XBPushWebRequestDelegate <NSObject>

- (void)pushWebRequestDidFinishLoading:(XBPushWebRequest *)request;
- (void)pushWebRequest:(XBPushWebRequest *)request didFailWithError:(NSError *)error;

@end

@interface XBPushWebRequest : NSObject {
	
	NSMutableURLRequest *_urlRequest;
	NSURLConnection *_connection;
	NSHTTPURLResponse *_httpResponse;
	
	NSMutableData *_data;
	
	NSDictionary *_responseDictionary;
	
}

@property (nonatomic, assign) id <XBPushWebRequestDelegate> delegate;

- (id)initWithBodyString:(NSString *)bodyString;

- (void)start;
- (void)cancel;

- (BOOL)didSucceed;
- (BOOL)hasHTTPError;

- (NSUInteger)statusCode;
- (NSDictionary *)responseDictionary;

@end
