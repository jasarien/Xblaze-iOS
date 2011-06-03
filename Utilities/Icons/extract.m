
#import <Cocoa/Cocoa.h>
#import "MFWin32DLLResourceFile.h"

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
		fprintf(stderr,"Usage: extract file.dll\n");
		return -1;
	}
	NSString *dllPath = [args objectAtIndex:0];
	NSData *d = [NSData dataWithContentsOfFile:dllPath];
	if( !d )
	{
		fprintf(stderr,"Unable to read file %s\n",[dllPath UTF8String]);
		return -1;
	}
	MFWin32DLLResourceFile *f = [[MFWin32DLLResourceFile alloc] initWithData:d];
	
	// Make sure the folder exists
	NSString *folderPath = [dllPath stringByAppendingString:@"_icons"];
	NSFileManager *manager = [NSFileManager defaultManager];
	if( [manager fileExistsAtPath:folderPath] )
	{
		NSLog(@"deleting existing folder %@",folderPath);
		[manager removeFileAtPath:folderPath handler:nil];
	}
	[manager createDirectoryAtPath:folderPath attributes:nil];
	
	// Walk through all ICONS data and write them to files
	NSArray *icons = [f resourcesOfType:@"ICONS"];
	NSEnumerator *iconEnumer = [icons objectEnumerator];
	MFWin32DLLResource *res;
	while( (res = [iconEnumer nextObject]) != nil )
	{
		NSString *filePath = [folderPath stringByAppendingPathComponent:[res identifier]];
		NSData *iconData = [res data];
		
		NSImage *img = [[NSImage alloc] initWithData:iconData];
		if( img )
		{
			[iconData writeToFile:filePath atomically:NO];
		}
		else
		{
			NSLog(@"Bad icon data for %@, file not exported",[res identifier]);
		}
	}
	
	return 0;
}




