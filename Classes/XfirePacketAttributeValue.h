/*******************************************************************
	FILE:		XfirePacketAttributeValue.h
	
	COPYRIGHT:
		Copyright 2007-2008, the MacFire.org team.
		Use of this software is governed by the license terms
		indicated in the License.txt file (a BSD license).
	
	DESCRIPTION:
		Represents a value in an XfirePacketAttributeMap.  The only
		reason this class exists is to ensure that array types are
		correct when sent packets have empty arrays.  It's a CYA in
		case the Xfire master server requires correct types keys for
		attribute values.  Otherwise it is just a wrapper around
		the various Cocoa types that represent values in Xfire packets.
	
	HISTORY:
		2008 04 06  Changed copyright to BSD license.
		2008 01 12  Added copyright notice.
		2007 11 13  Created.
*******************************************************************/

#import <Foundation/Foundation.h>

#define kXfirePacketAttributeInvalidType         (-1)
#define kXfirePacketAttributeStringType          (0x01) /* NSString */
#define kXfirePacketAttributeUInt32Type          (0x02) /* NSNumber(unsigned int) */
#define kXfirePacketAttributeUUIDType            (0x03) /* NSData(16) */
#define kXfirePacketAttributeArrayType           (0x04) /* NSArray */
#define kXfirePacketAttributeStringAttrMapType   (0x05) /* XfirePacketAttributeMap */
#define kXfirePacketAttributeDIDType             (0x06) /* NSData(21) */
#define kXfirePacketAttributeUInt64Type          (0x07) /* NSNumber(unsigned long long) */
#define kXfirePacketAttributeUInt8Type           (0x08) /* NSNumber(unsigned char) */
#define kXfirePacketAttributeIntAttrMapType      (0x09) /* XfirePacketAttributeMap */

@class XfirePacketAttributeMap;

@interface XfirePacketAttributeValue : NSObject
{
	int _typeID;
	id  _value;
	int _arrayElementType; // only useful for arrays, otherwise undefined
}

+ (id)attributeValueWithString:(NSString *)str;
+ (id)attributeValueWithInt:(unsigned int)val;
+ (id)attributeValueWithInt64:(unsigned long long)val;
+ (id)attributeValueWithByte:(unsigned char)val;
+ (id)attributeValueWithNumber:(NSNumber *)nbr; // should be unsigned int anyway
+ (id)attributeValueWithUUID:(NSData *)uuid; // 16 byte
+ (id)attributeValueWithDid:(NSData *)did;
+ (id)attributeValueWithArray:(NSArray *)arr;
+ (id)attributeValueWithArray:(NSArray *)arr emptyElementType:(int)et;
+ (id)attributeValueWithAttributeMap:(XfirePacketAttributeMap *)map;

- (int)typeID;
- (id)value;
- (int)arrayElementType;

@end
