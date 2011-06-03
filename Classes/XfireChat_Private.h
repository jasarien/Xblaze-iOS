/*******************************************************************
	FILE:		XfireChat_Private.h
	
	COPYRIGHT:
		Copyright 2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Private methods for XfireChat.
	
	HISTORY:
		2009 01 03  Created.
*******************************************************************/

#import "XfireChat.h"

@interface XfireChat (Private)

- (void)receivePacket:(XfirePacket *)pkt;

@end
