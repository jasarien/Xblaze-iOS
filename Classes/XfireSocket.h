/*******************************************************************
	FILE:		XfireSocket.h
	
	COPYRIGHT:
		Copyright 2007-2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Abstracts away a socket.  Surprisingly, Cocoa does not include
		a direct wrapper for a socket (or CFSocket).  This exists
		because in the future a UDP connection may be required (some
		games like Halo use UDP for server queries).  I wanted a common
		interface logic.
	
	HISTORY:
		2008 04 06  Changed copyright to BSD license.
		2008 01 12  Rewrote using CFSocket and a delegate approach.
		2007 11 17  Created.
*******************************************************************/

#import <Foundation/Foundation.h>

@interface XfireSocket : NSObject
{
	CFSocketRef _sock;
	CFRunLoopSourceRef _runLoopSource;
	NSRunLoop *_runLoop;
	id _delegate;
}
- (void)setDelegate:(id)aDelegate;
- (id)delegate;

- (NSString *)ourAddress;
- (unsigned int)ourAddressInteger;

- (void)scheduleInRunLoop:(NSRunLoop *)aLoop;

- (void)close; // close and disconnect
- (BOOL)isConnected;

@end

@interface XfireSocket (TCPSocket)
- (id)initWithTCPConnectionToHost:(NSString *)aHost port:(unsigned short)aPort;
- (id)initWithTCPConnectionToIP:(NSString *)aIP port:(unsigned short)aPort;
- (BOOL)sendData:(NSData *)data;
- (NSString *)peerAddress;
@end

enum {
	kXfireSocketNormalDisconnect = 1,
	kXfireSocketAbnormalTermination
};

@interface NSObject (XfireSocketDelegate)
- (void)socket:(XfireSocket *)aSock didReceiveData:(NSData *)data fromAddress:(NSData *)address;
- (void)socketDidDisconnect:(XfireSocket *)aSock reason:(int)reasonCode;
@end
