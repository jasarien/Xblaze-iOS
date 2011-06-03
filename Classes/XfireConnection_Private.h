/*******************************************************************
	FILE:		XfireConnection_Private.h
	
	COPYRIGHT:
		Copyright 2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Library-private interfaces for XfireConnection.  Most of these
		interfaces are used elsewhere in the library (e.g. by
		XfireLoginConnection) so these have to be in a separate file.
	
	HISTORY:
		2008 04 06  Changed copyright to BSD license.
		2008 02 10  Eliminated secondary reader thread.
		2008 01 11  Added copyright notice.
		            Should be less likely to have problems later.
		2007 11 19  Created.
*******************************************************************/

@interface XfireConnection (Private)

- (id)initWithHost:(NSString *)aHost port:(unsigned short)aPort;

// Send arbitrary data
// Should only be used by external classes (XfireLoginConnection) to send the "UA01" key!!!
- (void)sendData:(NSData *)dat;

// same as -sendPacket, except doesn't check X
// used for slightly reduced overhead
- (void)sendPacketSafe:(XfirePacket *)pkt;

// Subclass override stuff
- (void)connectionDidConnect;
- (void)connectionWillDisconnect;
- (void)receiverProcessData:(NSData *)data;

// return YES or NO whether to continue
- (BOOL)receiverProcessPacket:(XfirePacket *)pkt;

@end
