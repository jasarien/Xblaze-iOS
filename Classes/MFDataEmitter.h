/*******************************************************************
	FILE:		MFDataEmitter.h
	
	COPYRIGHT:
		Copyright 2007-2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		A class to emit specific kinds of data.  It uses some rules
		similar to Xfire encoding rules.  It generates an NSData result
		suitable for being scanned by MFDataScanner.  It is similar in
		concept to an NSArchiver, but more limited with more direct
		control over the results.
	
	HISTORY:
		2008 04 06  Changed copyright to BSD license.
		2007 12 02  Added copyright notice.
		2007 12 01  Created.
*******************************************************************/

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface MFDataEmitter : NSObject
{
	NSMutableData *_data;
}

+ (id)emitter;
+ (id)emitterWithCapacity:(unsigned long)cap;
- (id)init;
- (id)initWithCapacity:(unsigned long)cap;

// Get the result
- (NSData *)data;

// Emit primitive values
- (void)emitUInt8:(UInt8)value;
- (void)emitUInt16:(UInt16)value;
- (void)emitUInt32:(UInt32)value;
- (void)emitString:(NSString *)str;
- (void)emitData:(NSData *)data;

@end
