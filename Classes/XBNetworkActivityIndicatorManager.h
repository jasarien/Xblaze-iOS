//
//  XBNetworkActivityIndicatorManager.h
//  Xblaze-iPhone
//
//  Created by James Addyman on 04/04/2012.
//  Copyright (c) 2012 JamSoft. All rights reserved.
//

#import "XBPushWebRequest.h"

@interface XBNetworkActivityIndicatorManager : XBPushWebRequest

+ (void)showNetworkActivity;
+ (void)hideNetworkActivity;

@end
