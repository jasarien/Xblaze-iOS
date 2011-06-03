/*******************************************************************
	FILE:		XfirePacketLogger.m
	
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
		2008 01 12  Rewrote the format of the output to make it easier
		            to read.
		2007 11 03  Created.
*******************************************************************/

#import "XfirePacketLogger.h"
#import "NSData_XfireAdditions.h"
#import "XfirePacket.h"
#import "XfirePacketAttributeValue.h"


@interface XfirePacketLogger (Private)
- (NSString *)unusedCacheFileNameAtPath:(NSString *)path;
- (NSString *)logMessageForPacket:(XfirePacket *)pkt  inbound:(BOOL)inbound;
- (void)logMessageForMap:(XfirePacketAttributeMap *)map indent:(NSString *)indent string:(NSMutableString *)desc;
- (void)logMessageForValue:(XfirePacketAttributeValue *)val indent:(NSString *)indent string:(NSMutableString *)desc;
- (NSString *)logMessageForRawData:(NSData *)theData inbound:(BOOL)inbound;
- (NSString *)nameForPacketID:(unsigned int)pktID;
- (NSString *)nameForTypeID:(unsigned int)typeID;
@end

@implementation XfirePacketLogger

- (NSString *)currentDateFormat
{
	NSString *str;
	
	NSDateFormatter *dateFormatter;
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];// NSDateFormatterShortStyle];
	[dateFormatter setDateFormat:@"yyyyMMdd"];
	str = [dateFormatter stringFromDate:[NSDate date]];
	[dateFormatter release];
	
	return str;
}

- (id)initWithCacheFolderName:(NSString *)aName;
{
	self = [super init];
	if( self )
	{
		// First make sure the folder exists
		_cacheFolderPath = [aName copy];
		
		// Now create a new log file name
		_cacheFileName = [self unusedCacheFileNameAtPath:_cacheFolderPath];
		[_cacheFileName retain];
		
		// NSFileHandle-fileHandleForWritingAtPath: requires the file to exist   grr
		[[NSData data] writeToFile:_cacheFileName atomically:NO];
		
		// Then create a new file to contain the log
		_cacheFileHandle = [[NSFileHandle fileHandleForWritingAtPath:_cacheFileName] retain];
	}
	return self;
}

- (void)dealloc
{
	[_cacheFolderPath release];
	[_cacheFileName release];
	[_cacheFileHandle closeFile];
	[_cacheFileHandle release];
	
	[super dealloc];
}

- (NSString *)unusedCacheFileNameAtPath:(NSString *)path
{
	NSString *fileName;
	NSString *formattedDate;
	BOOL found;
	int i;
	
	found = NO;
	i = 1;
	formattedDate = [self currentDateFormat];
	while( !found )
	{
		fileName = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ %d.txt", formattedDate, i ]];
		if( ! [[NSFileManager defaultManager] fileExistsAtPath:fileName] )
		{
			found = YES;
		}
		else
		{
			i++;
		}
	}
	
	return fileName;
}

- (void)logOutbound:(XfirePacket *)aPacket
{
	if( _cacheFileHandle )
	{
		NSString *desc = [self logMessageForPacket:aPacket inbound:NO];
		DebugLog(@"%@", desc);
		[_cacheFileHandle writeData:[desc dataUsingEncoding:NSUTF8StringEncoding]];
	}
}

- (void)logInbound:(XfirePacket *)aPacket
{
	if( _cacheFileHandle )
	{
		NSString *desc = [self logMessageForPacket:aPacket inbound:YES];
		DebugLog(@"%@", desc);
		[_cacheFileHandle writeData:[desc dataUsingEncoding:NSUTF8StringEncoding]];
	}
}

- (void)logRawData:(NSData *)theData
{
	if( _cacheFileHandle )
	{
		NSString *desc = [self logMessageForRawData:theData inbound:YES];
		[_cacheFileHandle writeData:[desc dataUsingEncoding:NSUTF8StringEncoding]];
	}
}

- (NSString *)logMessageForPacket:(XfirePacket *)pkt inbound:(BOOL)inbound
{
	NSMutableString				*desc = [NSMutableString stringWithCapacity:1024];
	unsigned int				pktID;
	
	[desc appendString:@"************************************************************************\n"];
	if( inbound )
		[desc appendString:@"IN     "];
	else
		[desc appendString:@"OUT    "];
	pktID = [pkt packetID];
	[desc appendFormat:@"%@\nPacket ID = %u (%@)\n", [[NSDate date] description], pktID, [self nameForPacketID:pktID]];
	
	[self logMessageForMap:[pkt attributes] indent:@"  " string:desc];
	
	NSData *content = [pkt raw];
	if( content )
		[desc appendString:[content enhancedDescription]];
	[desc appendString:@"\n\n"];
	
	return desc;
}

- (NSString *)logMessageForRawData:(NSData *)theData inbound:(BOOL)inbound
{
	NSMutableString				*desc = [NSMutableString stringWithCapacity:1024];
	
	[desc appendString:@"************************************************************************\n"];
	if( inbound )
		[desc appendString:@"IN     "];
	else
		[desc appendString:@"OUT    "];
	[desc appendFormat:@"%@\nUNDECODED\n", [[NSDate date] description]];
	
	[desc appendString:[theData enhancedDescription]];
	[desc appendString:@"\n\n"];
	
	return desc;
}

- (void)logMessageForMap:(XfirePacketAttributeMap *)map indent:(NSString *)indent string:(NSMutableString *)desc
{
	NSEnumerator *keyEnumerator = [map keyEnumerator];
	id key;
	XfirePacketAttributeValue *val;
	NSString *newIndent = [indent stringByAppendingString:@"  "];
	int tid;
	
	while( (key = [keyEnumerator nextObject]) != nil )
	{
		val = [map objectForKey:key];
		tid = [val typeID];
		
		[desc appendFormat:@"%@%@ = %@ (%u)", indent, key, [self nameForTypeID:tid], tid];
		
		[self logMessageForValue:val indent:newIndent string:desc];
	}
}

- (void)logMessageForValue:(XfirePacketAttributeValue *)val indent:(NSString *)indent string:(NSMutableString *)desc
{
	unsigned int tid = [val typeID];
	NSString *newIndent = [indent stringByAppendingString:@"  "];
	
	
	switch( tid )
	{
		case 1:
			[desc appendFormat:@" \"%@\"\n", [val value]];
			break;
		
		case 2:
			{
				NSNumber *nbr = [val value];
				unsigned int nbrVal = [nbr unsignedIntValue];
				[desc appendFormat:@" %u (0x%08x)\n", nbrVal, nbrVal];
			}
			break;
		
		case 3:
			[desc appendFormat:@" %@\n", [val value]];
			break;
		
		case 4:
			{
				int i, cnt;
				NSArray *arr = [val value];
				cnt = [arr count];
				
				[desc appendFormat:@" element type = %@, count = %u\n", [self nameForTypeID:[val arrayElementType]], cnt];
				
				for( i = 0; i < cnt; i++ )
				{
					[desc appendFormat:@"%@[%3u]  ", indent, i];
					[self logMessageForValue:[arr objectAtIndex:i] indent:newIndent string:desc];
				}
			}
			break;
		
		case 7:
			{
				NSNumber *nbr = [val value];
				unsigned long long nbrVal = [nbr unsignedLongLongValue];
				[desc appendFormat:@" %llu (0x%016llx)\n", nbrVal, nbrVal];
			}
			break;
		
		case 8:
			{
				NSNumber *nbr = [val value];
				unsigned int nbrVal = [nbr unsignedCharValue];
				[desc appendFormat:@" %u (0x%02x)\n", nbrVal, nbrVal];
			}
			break;
		
		case 5:
		case 9:
			{
				XfirePacketAttributeMap *newMap = [val value];
				[desc appendFormat:@" #attrs = %u\n",[newMap count]];
				[self logMessageForMap:[val value] indent:newIndent string:desc];
			}
			break;
		
		case 6:
			[desc appendFormat:@" %@\n",[val value]];
			break;
	}
}

- (NSString *)nameForPacketID:(unsigned int)pktID
{
	switch( pktID )
	{
		case 1:    return @"Authentication information";
		case 2:    return @"Chat message";
		case 3:    return @"Client version";
		case 4:    return @"Game status change";
		case 5:    return @"Request info for Friends of Friends";
		case 6:    return @"Add Friend request";
		case 7:    return @"Accept friend invitation";
		case 8:    return @"Decline friend invitation";
		case 9:    return @"Remove friend";
		case 10:   return @"Change preferences";
		case 12:   return @"User search";
		case 13:   return @"Keepalive";
		case 14:   return @"Change nickname";
		case 16:   return @"Client information";
		case 17:   return @"Client network information";
		case 23:   return @"Download information request";
		case 24:   return @"Channel information request ??";
		case 26:   return @"Create new custom friend group";
		case 27:   return @"Delete custom friend group";
		case 28:   return @"Rename custom friend group";
		case 29:   return @"Add friend to custom group";
		case 30:   return @"Remove friend from custom group";
		case 32:   return @"Change status text";
		case 36:   return @"Change friend group list";
		case 37:   return @"Info view information request";
		case 128:  return @"Login challenge";
		case 129:  return @"Login failure - bad password";
		case 130:  return @"Login success";
		case 131:  return @"Friends list (change)";
		case 132:  return @"Friend session ID change";
		case 133:  return @"Chat message";
		case 134:  return @"Login failure - version too old";
		case 135:  return @"Game status change";
		case 136:  return @"Friend of Friend info";
		case 137:  return @"Add-friend-request confirmation";
		case 138:  return @"Incoming friend request";
		case 139:  return @"Incoming friend removal";
		case 141:  return @"User preferences";
		case 143:  return @"User search response";
		case 144:  return @"Server keepalive response";
		case 145:  return @"Disconnect notification";
		case 147:  return @"Voice chat info";
		case 151:  return @"Custom friend group name";
		case 152:  return @"Custom friend group membership";
		case 153:  return @"New custom friend group ID";
		case 154:  return @"Friend status message changed";
		case 156:  return @"In-game information changed";
		case 161:  return @"Nickname changed";
		case 163:  return @"Friend group list";
		default:   return @"Unknown";
	}
	
	return @"Unknown";
}

- (NSString *)nameForTypeID:(unsigned int)typeID
{
	switch( typeID )
	{
		case 1: return @"str";
		case 2: return @"int32";
		case 3: return @"UUID";
		case 4: return @"array";
		case 5: return @"map(str)";
		case 6: return @"DID";
		case 7: return @"int64";
		case 8: return @"int8";
		case 9: return @"map(int)";
		default: return @"";
	}
	return @"";
}

@end
