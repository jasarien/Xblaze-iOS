/*******************************************************************
	FILE:		XfirePacketGenerator.h
	
	COPYRIGHT:
		Copyright 2007-2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Helps generating packets.  It flattens the XfirePacketAttributeMap
		into the stream of bytes required by the protocol.
	
	HISTORY:
		2008 04 06  Changed copyright to BSD license.
		2008 01 12  Added copyright notice.
		2007 11 03  Created.
*******************************************************************/

#import <Foundation/Foundation.h>

#import "XfirePacket.h"

@interface XfirePacketGenerator : NSObject
{
	NSMutableData *_data;
	XfirePacketID _pktID;
	XfirePacketAttributeMap *_attributes;
}

+ (id)generatorWithID:(XfirePacketID)anID attributes:(XfirePacketAttributeMap *)attributes;

- (NSData *)generate;

@end
