/*******************************************************************
	FILE:		NSData_MFAdditions.h
	
	COPYRIGHT:
		Copyright 2007-2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Useful methods for the NSData class.
	
	HISTORY:
		2008 04 06  Changed copyright to BSD license.
		2007 12 02  Added copyright notice.
		2007 10 14  Created.
*******************************************************************/

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface NSData (MFAdditions)

// These are complementary methods
+ (NSData *)archivedDataWithFiles:(NSArray *)paths;
- (NSArray *)unarchivedFiles;

// Compress/decompress
- (NSData *)compressedZlibData;
- (NSData *)decompressedZlibData;

@end
