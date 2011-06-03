
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
	if( [args count] != 1 )
	{
		fprintf(stderr,"Usage: testid icons.mar\n");
		return -1;
	}
	
	NSData *fileData = [NSData dataWithContentsOfFile:[args objectAtIndex:0]];
	if( !fileData )
	{
		fprintf(stderr, "Unable to open file\n");
		return -1;
	}
	
	NSArray *files = [fileData unarchivedFiles];
	if( !files )
	{
		fprintf(stderr, "Unable to extract archive\n");
		return -1;
	}
	
	// try to create the NSImage and check for success
	NSEnumerator *e = [files objectEnumerator];
	id f;
	while( (f = [e nextObject]) != nil )
	{
		NSString *s = [f path];
		NSData   *d = [f data];
		NSImage  *m = [[NSImage alloc] initWithData:d];
		
		if( s && d )
		{
			fprintf(stdout,"%20s %p\n",[s UTF8String],m);
		}
		else
		{
			fprintf(stdout,"error !\n");
		}
	}
	
	return 0;
}




