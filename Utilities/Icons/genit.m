
#import <Cocoa/Cocoa.h>
#import "NSData_XfireAdditions.h"

int MyMain(NSArray *args);
int main(int argc, const char **argv)
{
	int rv;
	
	@try
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSMutableArray *args = [NSMutableArray array];
		int i;
		for( i = 1; i < argc; i++ )
		{
			[args addObject:[NSString stringWithCString:argv[i]]];
		}
		rv = MyMain(args);
		[pool release];
	}
	@catch( NSException *e )
	{
		NSLog(@"Uncaught exception: %@", e);
		rv = -1;
	}
	
	return rv;
}

int MyMain(NSArray *args)
{
	NSData *coreData = [NSData archivedDataWithFiles:args];
	if( coreData == nil )
		return -1;
	
	[coreData writeToFile:@"icons.mar" atomically:NO];
	
	return 0;
}




