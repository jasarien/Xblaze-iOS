/*******************************************************************
	FILE:		XfirePacketLogger.h
	
	COPYRIGHT:
		Copyright 2007-2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Logs Xfire packets for future analysis.  Puts the file for
		each connection in the specified folder.
	
	HISTORY:
		2008 04 06  Changed copyright to BSD license.
		2008 03 01  Reworked to take in full path and to use
					a somewhat better file naming convention.
		2008 02 10  Eliminated secondary reader thread.
		2008 02 09  Added ability to log raw data (packets that do
					not properly decode).
		2008 01 12  Added copyright notice.
		2007 11 03  Created.
*******************************************************************/

#import <Foundation/Foundation.h>

@class XfirePacket;

@interface XfirePacketLogger : NSObject
{
	NSString *_cacheFolderPath;
	NSString *_cacheFileName;
	NSFileHandle *_cacheFileHandle;
}

// This creates a new cache folder at the specified path (if it does not exist)
// and creates a new, uniquely-named file in that folder.  Suggested location is a
// folder under ~/Library/Caches (e.g. ~/Library/Caches/Xfire).
- (id)initWithCacheFolderName:(NSString *)aName;

- (void)logOutbound:(XfirePacket *)aPacket;
- (void)logInbound:(XfirePacket *)aPacket;

- (void)logRawData:(NSData *)theData;

@end
