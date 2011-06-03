/*******************************************************************
	FILE:		XfirePacketScanner.h
	
	COPYRIGHT:
		Copyright 2007-2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Scans Xfire packets and creates an XfirePacketAttributeMap
		that contains the contents, if no errors occur.
	
	HISTORY:
		2008 04 06  Changed copyright to BSD license.
		2008 01 12  Added copyright notice.
		2007 10 28  Created.
*******************************************************************/

#import <Foundation/Foundation.h>

@class XfirePacketAttributeMap;

// Scans raw packets and decodes the next item
// If there isn't enough space for it, it will throw an exception
@interface XfirePacketScanner : NSObject
{
	NSData *_dat;
	unsigned int _idx;
	unsigned int _len;
	const unsigned char *_bytes;
}

+ (id)scannerWithData:(NSData *)data;
- (id)initWithData:(NSData *)data;

// Top level packet scan
// outputs are packetID and attribute map
- (BOOL)scan:(unsigned int *)packetID attributes:(XfirePacketAttributeMap **)attrs;

@end
