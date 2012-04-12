/*******************************************************************
	FILE:		XfireConnection.m
	
	COPYRIGHT:
		Copyright 2007-2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Abstract base class with common support for a threaded
		connection to some kind of IP socket.
	
	HISTORY:
		2008 04 06  Changed copyright to BSD license.
		2008 03 01  Changed to use external packet log cache file
					path with new session delegate method.
		2008 02 10  Eliminated secondary reader thread.
		2008 01 11  Rewrote using new threading and notification model.
		            Should be less likely to have problems later.
		2007 10 26  Created.
*******************************************************************/

#import "XfireConnection.h"
#import "XfireSession_Private.h"
#import "XfireConnection_Private.h"
#import "XfireLoginConnection.h"
#import "XfirePacket.h"
#import "XfirePacketLogger.h"

#define ENABLE_PACKET_LOG 0

@implementation XfireConnection

// The login connection is the initial connection to the Xfire server
// NOTE: This does not autorelease the result.
+ (id)newLoginConnectionToHost:(NSString *)host port:(unsigned short)portNumber
{
	return [[XfireLoginConnection alloc] initWithHost:host port:portNumber];
}

- (id)initWithHost:(NSString *)aHost port:(unsigned short)aPort
{
	self = [super init];
	if( self )
	{
		_host = [aHost retain];
		_port = aPort;
		_status = kXfireConnectionDisconnected;
		_socket = nil;
		_packetLogger = nil;
	}
	return self;
}

- (void)dealloc
{
	[self disconnect];
	
	[_host release];
	_host = nil;
	_session = nil;
	_port = 0;
	
	[super dealloc];
}

// Start a connection
- (void)connect
{
	if( [self status] != kXfireConnectionDisconnected )
		return;
	
#if ENABLE_PACKET_LOG
	NSString* logPath = @"PacketLog.txt";
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0)
	{
		logPath = [paths objectAtIndex:0];
	}
	
	if (![logPath length])
	{
		NSLog(@"Unable to get path for caches directory...");
		return;
	}
	
	
	if( logPath )
	{
		_packetLogger = [[XfirePacketLogger alloc] initWithCacheFolderName:logPath];
	}
#endif
	
	// We're starting up now
	_status = kXfireConnectionStarting;
		
	_socket = [[AsyncSocket alloc] initWithDelegate:self];
	NSError *connectError = nil;

	[_socket connectToHost:_host 
					onPort:XfirePortNumber 
			   withTimeout:XfireConnectionTimeout 
					 error:&connectError];
}

// End a connection
- (void)disconnect
{
	if( [self status] != kXfireConnectionConnected )
		return;
	
	_status = kXfireConnectionStopping;
	
	[self connectionWillDisconnect];
	
	[_socket disconnect];
	
	[_packetLogger release];
	_packetLogger = nil;
	
	_status = kXfireConnectionDisconnected;
}

- (XfireConnectionStatus)status
{
	return _status;
}

// Send keepalive, if applicable
- (void)keepAlive
{
	// no implementation here
}

// Get/set -- don't change this after set!
- (void)setSession:(XfireSession *)session
{
	_session = session;
}

- (XfireSession *)session
{
	return _session;
}

- (void)sendData:(NSData *)dat
{
	[_socket writeData:dat withTimeout:-1 tag:0];
}

// Sending data
// Can be used by outside objects, so it must lock.
// This locks to prevent being disconnected between the time we check
// the _status and actually send the data.
- (void)sendPacket:(XfirePacket *)pkt
{
	if( [self status] != kXfireConnectionConnected )
	{
		@throw [NSException exceptionWithName:@"XfireConnection"
			reason:@"Attempted to send packet to disconnected XfireConnection"
			userInfo:nil];
	}
	
	if( [pkt isKindOfClass:[XfireMutablePacket class]] )
	{
		[((XfireMutablePacket *)pkt) generate];
	}
	
	[self sendPacketSafe:pkt];
}

// Send a packet
- (void)sendPacketSafe:(XfirePacket *)pkt
{
	[_packetLogger logOutbound:pkt];
	[self sendData:[pkt raw]];
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	[_socket readDataWithTimeout:-1 tag:0];
	
	// Now we're "connected"
	_status = kXfireConnectionConnected;
	
	[self connectionDidConnect];
}

-(void)onSocket:(AsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag
{
	[self receiverProcessData:data];
	if ([sock isConnected])
	{
		[sock readDataWithTimeout:-1 tag:0];
	}
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
	[_socket disconnect];
	
	_status = kXfireConnectionStopping;
	
	[self connectionWillDisconnect];
	
	[_packetLogger release];
	_packetLogger = nil;
	
	_status = kXfireConnectionDisconnected;
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
	[_socket release];
	_socket = nil;
}

- (void)connectionDidConnect
{
}

- (void)connectionWillDisconnect
{
}

- (void)receiverProcessData:(NSData *)data
{
}

- (BOOL)receiverProcessPacket:(XfirePacket *)pkt
{
	return NO;
}

@end
