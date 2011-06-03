
#import "MFWin32DLLResourceFile.h"
#import "MFDataScanner.h"

@interface MFWin32DLLScanner : NSObject
{
	MFDataScanner *_scanner;
}
- (id)initWithData:(NSData *)data;
- (BOOL)scan:(MFWin32DLLResourceFile *)destObj;
@end

@interface MFWin32DLLResourceFile (Private)
- (void)addResource:(MFWin32DLLResource *)res forType:(id)typeID identifier:(id)resID;
- (NSMutableDictionary *)identifiersForType:(id)typeID;
@end

@implementation MFWin32DLLResourceFile

- (id)initWithData:(NSData *)data // pass the entire .DLL file
{
	self = [super init];
	if( self )
	{
		BOOL result = NO;
		
		resources = [[NSMutableDictionary alloc] init];
		@try
		{
			MFWin32DLLScanner *scanner = [[[MFWin32DLLScanner alloc] initWithData:data] autorelease];
			result = [scanner scan:self];
		}
		@catch( NSException *e )
		{
			[self release];
			return nil;
		}
		
		if( !result )
		{
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)dealloc
{
	[resources release];
	[super dealloc];
}

//- (NSEnumerator *)allResourcesEnumerator
//{
//	return nil;
//}

- (NSArray *)resourceTypes
{
	return [resources allKeys];
}

- (NSArray *)resourcesOfType:(id)typeID
{
	NSDictionary *types = [self identifiersForType:typeID];
	return [types allValues];
}

- (MFWin32DLLResource *)resourceForType:(id)typeID identifier:(id)ident
{
	return nil;
}

- (void)addResource:(MFWin32DLLResource *)res forType:(id)typeID identifier:(id)resID
{
	NSMutableDictionary *types = [self identifiersForType:typeID];
	if( types == nil )
	{
		types = [NSMutableDictionary dictionary];
		[((NSMutableDictionary*)resources) setObject:types forKey:typeID];
	}
	
	[types setObject:res forKey:resID];
}

- (NSMutableDictionary *)identifiersForType:(id)typeID
{
	return [resources objectForKey:typeID];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"MFWin32DLLResourceFile {%@}",[resources description]];
}

@end

@interface MFWin32DLLResource (Private)
- (id)initWithType:(id)typeID identifier:(id)resID;
- (void)addData:(NSData *)dat forLanguage:(id)langID;
@end

@implementation MFWin32DLLResource
- (id)initWithType:(id)typeID identifier:(id)resID
{
	self = [super init];
	if( self )
	{
		type = [typeID retain];
		identifier = [resID retain];
		languages = [[NSMutableDictionary alloc] init];
	}
	return self;
}
- (void)dealloc
{
	[type release];
	[identifier release];
	[languages release];
	[super dealloc];
}
- (void)addData:(NSData *)dat forLanguage:(id)langID
{
	[((NSMutableDictionary*)languages) setObject:dat forKey:langID];
}
- (id)type
{
	return type;
}
- (id)identifier
{
	return identifier;
}
- (NSArray *)languages
{
	return [languages allKeys];
}
- (NSData *)dataForLanguage:(id)lang
{
	return [languages objectForKey:lang];
}
- (NSData *)data
{
	return [languages objectForKey:[[languages keyEnumerator] nextObject]];
}
- (NSString *)description
{
	return [NSString stringWithFormat:@"MFWin32DLLResource(%@:%@, %d langs)",type,identifier,[languages count]];
}
@end



/**********************************************************************************/
#pragma mark Declarations Copied from WINNT.H

#define IMAGE_DOS_SIGNATURE                 0x5A4D      // MZ
#define IMAGE_NT_SIGNATURE                  0x00004550  // PE00

typedef UInt16 WORD;
typedef UInt8  BYTE;
typedef SInt32 LONG;
typedef UInt32 DWORD;
typedef char   CHAR;

#define IMAGE_DIRECTORY_ENTRY_RESOURCE        2   // Resource Directory

typedef struct _IMAGE_DOS_HEADER {      // DOS .EXE header
    WORD   e_magic;                     // Magic number
    WORD   e_cblp;                      // Bytes on last page of file
    WORD   e_cp;                        // Pages in file
    WORD   e_crlc;                      // Relocations
    WORD   e_cparhdr;                   // Size of header in paragraphs
    WORD   e_minalloc;                  // Minimum extra paragraphs needed
    WORD   e_maxalloc;                  // Maximum extra paragraphs needed
    WORD   e_ss;                        // Initial (relative) SS value
    WORD   e_sp;                        // Initial SP value
    WORD   e_csum;                      // Checksum
    WORD   e_ip;                        // Initial IP value
    WORD   e_cs;                        // Initial (relative) CS value
    WORD   e_lfarlc;                    // File address of relocation table
    WORD   e_ovno;                      // Overlay number
    WORD   e_res[4];                    // Reserved words
    WORD   e_oemid;                     // OEM identifier (for e_oeminfo)
    WORD   e_oeminfo;                   // OEM information; e_oemid specific
    WORD   e_res2[10];                  // Reserved words
    LONG   e_lfanew;                    // File address of new exe header
  } IMAGE_DOS_HEADER, *PIMAGE_DOS_HEADER;


typedef struct _IMAGE_DATA_DIRECTORY {
    DWORD   VirtualAddress;
    DWORD   Size;
} IMAGE_DATA_DIRECTORY, *PIMAGE_DATA_DIRECTORY;

#define IMAGE_NUMBEROF_DIRECTORY_ENTRIES    16

typedef struct _IMAGE_OPTIONAL_HEADER {
    //
    // Standard fields.
    //

    WORD    Magic;
    BYTE    MajorLinkerVersion;
    BYTE    MinorLinkerVersion;
    DWORD   SizeOfCode;
    DWORD   SizeOfInitializedData;
    DWORD   SizeOfUninitializedData;
    DWORD   AddressOfEntryPoint;
    DWORD   BaseOfCode;
    DWORD   BaseOfData;

    //
    // NT additional fields.
    //

    DWORD   ImageBase;
    DWORD   SectionAlignment;
    DWORD   FileAlignment;
    WORD    MajorOperatingSystemVersion;
    WORD    MinorOperatingSystemVersion;
    WORD    MajorImageVersion;
    WORD    MinorImageVersion;
    WORD    MajorSubsystemVersion;
    WORD    MinorSubsystemVersion;
    DWORD   Win32VersionValue;
    DWORD   SizeOfImage;
    DWORD   SizeOfHeaders;
    DWORD   CheckSum;
    WORD    Subsystem;
    WORD    DllCharacteristics;
    DWORD   SizeOfStackReserve;
    DWORD   SizeOfStackCommit;
    DWORD   SizeOfHeapReserve;
    DWORD   SizeOfHeapCommit;
    DWORD   LoaderFlags;
    DWORD   NumberOfRvaAndSizes;
    IMAGE_DATA_DIRECTORY DataDirectory[IMAGE_NUMBEROF_DIRECTORY_ENTRIES];
} IMAGE_OPTIONAL_HEADER32, *PIMAGE_OPTIONAL_HEADER32;

typedef struct _IMAGE_FILE_HEADER {
    WORD    Machine;
    WORD    NumberOfSections;
    DWORD   TimeDateStamp;
    DWORD   PointerToSymbolTable;
    DWORD   NumberOfSymbols;
    WORD    SizeOfOptionalHeader;
    WORD    Characteristics;
} IMAGE_FILE_HEADER, *PIMAGE_FILE_HEADER;

typedef struct _IMAGE_NT_HEADERS {
    DWORD Signature;
    IMAGE_FILE_HEADER FileHeader;
    IMAGE_OPTIONAL_HEADER32 OptionalHeader;
} IMAGE_NT_HEADERS32, *PIMAGE_NT_HEADERS32;

#define IMAGE_SIZEOF_SHORT_NAME              8

typedef struct _IMAGE_SECTION_HEADER {
    BYTE    Name[IMAGE_SIZEOF_SHORT_NAME];
    union {
            DWORD   PhysicalAddress;
            DWORD   VirtualSize;
    } Misc;
    DWORD   VirtualAddress;
    DWORD   SizeOfRawData;
    DWORD   PointerToRawData;
    DWORD   PointerToRelocations;
    DWORD   PointerToLinenumbers;
    WORD    NumberOfRelocations;
    WORD    NumberOfLinenumbers;
    DWORD   Characteristics;
} IMAGE_SECTION_HEADER, *PIMAGE_SECTION_HEADER;

typedef struct _IMAGE_RESOURCE_DIRECTORY {
    DWORD   Characteristics;
    DWORD   TimeDateStamp;
    WORD    MajorVersion;
    WORD    MinorVersion;
    WORD    NumberOfNamedEntries;
    WORD    NumberOfIdEntries;
//  IMAGE_RESOURCE_DIRECTORY_ENTRY DirectoryEntries[];
} IMAGE_RESOURCE_DIRECTORY, *PIMAGE_RESOURCE_DIRECTORY;

#define IMAGE_RESOURCE_NAME_IS_STRING        0x80000000
#define IMAGE_RESOURCE_DATA_IS_DIRECTORY     0x80000000

typedef struct _IMAGE_RESOURCE_DIRECTORY_ENTRY {
    union {
        struct {
            DWORD NameOffset:31;
            DWORD NameIsString:1;
        };
        DWORD   Name;
        WORD    Id;
    };
    union {
        DWORD   OffsetToData;
        struct {
            DWORD   OffsetToDirectory:31;
            DWORD   DataIsDirectory:1;
        };
    };
} IMAGE_RESOURCE_DIRECTORY_ENTRY, *PIMAGE_RESOURCE_DIRECTORY_ENTRY;

typedef struct _IMAGE_RESOURCE_DIRECTORY_STRING {
    WORD    Length;
    CHAR    NameString[ 1 ];
} IMAGE_RESOURCE_DIRECTORY_STRING, *PIMAGE_RESOURCE_DIRECTORY_STRING;



typedef struct _IMAGE_RESOURCE_DATA_ENTRY {
    DWORD   OffsetToData;
    DWORD   Size;
    DWORD   CodePage;
    DWORD   Reserved;
} IMAGE_RESOURCE_DATA_ENTRY, *PIMAGE_RESOURCE_DATA_ENTRY;


/**********************************************************************************/
@interface MFWin32DLLScanner (Private)
- (IMAGE_DOS_HEADER)scanDOSHeader;
- (IMAGE_NT_HEADERS32)scanNTHeader;
- (IMAGE_SECTION_HEADER)scanSectionHeader;
- (IMAGE_RESOURCE_DIRECTORY)scanResDir;
- (IMAGE_RESOURCE_DIRECTORY_ENTRY)scanResDirEnt;
- (IMAGE_RESOURCE_DATA_ENTRY)scanResDataEnt;
- (id)getResName:(IMAGE_RESOURCE_DIRECTORY_ENTRY*)resDirEnt resourcesOffset:(unsigned long)resSecOff;
@end

@implementation MFWin32DLLScanner

- (id)initWithData:(NSData *)data
{
	self = [super init];
	if( self )
	{
		_scanner = [[MFDataScanner alloc] initWithData:data];
	}
	return self;
}

- (void)dealloc
{
	[_scanner release];
	[super dealloc];
}

/*
Scan PE formatted (Win32) executable
*/
- (BOOL)scan:(MFWin32DLLResourceFile *)destObj
{
	int i, j, k;
	
	// Scan DOS header
	IMAGE_DOS_HEADER dosHeader = [self scanDOSHeader];
	if( dosHeader.e_magic != IMAGE_DOS_SIGNATURE )
		return NO;
	
	// Move to location of NT header
	[_scanner seek:dosHeader.e_lfanew];
	
	// Scan NT header
	IMAGE_NT_HEADERS32 ntHeader = [self scanNTHeader];
	if( ntHeader.Signature != IMAGE_NT_SIGNATURE )
		return NO;
	
	// Scan section header map
	// Copy the .rsrc section header
	IMAGE_SECTION_HEADER secHeader;
	IMAGE_SECTION_HEADER resSec;
	BOOL foundResSec = NO;
	
	if( ntHeader.FileHeader.NumberOfSections > 0 )
	{
		for( i = 0; i < ntHeader.FileHeader.NumberOfSections; i++ )
		{
			secHeader = [self scanSectionHeader];
			
			if( strcmp((char*)secHeader.Name,".rsrc") == 0 )
			{
				memcpy(&resSec,&secHeader,sizeof(resSec));
				foundResSec = YES;
			}
		}
	}
	
	if( !foundResSec )
		return NO;
	
	// Scan the main resource "directory" entry
	// This tells us the number of types to scan
	[_scanner seek:resSec.PointerToRawData];
	IMAGE_RESOURCE_DIRECTORY resDir = [self scanResDir];
	IMAGE_RESOURCE_DIRECTORY_ENTRY resTypeEnt;
	
	// Scan each type's directory entry and follow it down to resource IDs and languages
	for( i = 0; i < (resDir.NumberOfNamedEntries+resDir.NumberOfIdEntries); i++ )
	{
		resTypeEnt = [self scanResDirEnt];
		id typeName = [self getResName:&resTypeEnt resourcesOffset:resSec.PointerToRawData];
		//NSLog(@"Type %@",typeName);
		
		// Scan the resource ID directory entry for this type
		unsigned long curResTypePos = [_scanner tell];
		[_scanner seek:(resSec.PointerToRawData+(resTypeEnt.OffsetToData^IMAGE_RESOURCE_DATA_IS_DIRECTORY))];
		
		IMAGE_RESOURCE_DIRECTORY typeDir = [self scanResDir];
		IMAGE_RESOURCE_DIRECTORY_ENTRY resIdentEnt;
		//NSLog(@"  # IDs = %u", (typeDir.NumberOfNamedEntries+typeDir.NumberOfIdEntries));
		
		// Scan each identifier's directory entry and follow down to languages
		for( j = 0; j < (typeDir.NumberOfNamedEntries+typeDir.NumberOfIdEntries); j++ )
		{
			resIdentEnt = [self scanResDirEnt];
			id resIdent = [self getResName:&resIdentEnt resourcesOffset:resSec.PointerToRawData];
			//NSLog(@"    ID %@", resIdent);
			
			unsigned long curResIDPos = [_scanner tell];
			[_scanner seek:(resSec.PointerToRawData+(resIdentEnt.OffsetToData^IMAGE_RESOURCE_DATA_IS_DIRECTORY))];
			
			// Scan the language directory entry for this resource ID
			IMAGE_RESOURCE_DIRECTORY langDir = [self scanResDir];
			IMAGE_RESOURCE_DIRECTORY_ENTRY resLangEnt;
			//NSLog(@"      # langs = %u",(langDir.NumberOfNamedEntries+langDir.NumberOfIdEntries));
			
			MFWin32DLLResource *resObj = [[MFWin32DLLResource alloc] initWithType:typeName identifier:resIdent];
			[resObj autorelease];
			
			// Scan each language's directory entry and the raw data
			for( k = 0; k < (langDir.NumberOfNamedEntries+langDir.NumberOfIdEntries); k++ )
			{
				resLangEnt = [self scanResDirEnt];
				id langIdent = [self getResName:&resLangEnt resourcesOffset:resSec.PointerToRawData];
				//NSLog(@"        lang %@",langIdent);
				
				unsigned long curResLangPos = [_scanner tell];
				
				// Scan the data entry for this resource type+ID+lang
				[_scanner seek:(resSec.PointerToRawData+resLangEnt.OffsetToData)];
				
				IMAGE_RESOURCE_DATA_ENTRY dataEnt = [self scanResDataEnt];
				
				// Scan the resource's data
				[_scanner seek:(resSec.PointerToRawData + dataEnt.OffsetToData - resSec.VirtualAddress)];
				NSData *resData = [_scanner scanDataOfLength:dataEnt.Size];
				
				// Build the MFWin32DLLResource for this
				[resObj addData:resData forLanguage:langIdent];
				
				[_scanner seek:curResLangPos];
			}
			
			[destObj addResource:resObj forType:typeName identifier:resIdent];
			
			[_scanner seek:curResIDPos];
		}
		
		[_scanner seek:curResTypePos];
	}
	
	return YES;
}

- (IMAGE_DOS_HEADER)scanDOSHeader
{
	IMAGE_DOS_HEADER h;
	int i;
	h.e_magic    = [_scanner scanUInt16];
	h.e_cblp     = [_scanner scanUInt16];
	h.e_cp       = [_scanner scanUInt16];
	h.e_crlc     = [_scanner scanUInt16];
	h.e_cparhdr  = [_scanner scanUInt16];
	h.e_minalloc = [_scanner scanUInt16];
	h.e_maxalloc = [_scanner scanUInt16];
	h.e_ss       = [_scanner scanUInt16];
	h.e_sp       = [_scanner scanUInt16];
	h.e_csum     = [_scanner scanUInt16];
	h.e_ip       = [_scanner scanUInt16];
	h.e_cs       = [_scanner scanUInt16];
	h.e_lfarlc   = [_scanner scanUInt16];
	h.e_ovno     = [_scanner scanUInt16];
	for( i = 0; i < 4; i++ )
		h.e_res[i] = [_scanner scanUInt16];
	h.e_oemid    = [_scanner scanUInt16];
	h.e_oeminfo  = [_scanner scanUInt16];
	for( i = 0; i < 10; i++ )
		h.e_res2[i] = [_scanner scanUInt16];
	h.e_lfanew   = [_scanner scanUInt32];
	
	return h;
}

- (IMAGE_NT_HEADERS32)scanNTHeader
{
	IMAGE_NT_HEADERS32 h;
	int i;
	
	h.Signature = [_scanner scanUInt32];
	
	h.FileHeader.Machine = [_scanner scanUInt16];
	h.FileHeader.NumberOfSections = [_scanner scanUInt16];
	h.FileHeader.TimeDateStamp = [_scanner scanUInt32];
	h.FileHeader.PointerToSymbolTable = [_scanner scanUInt32];
	h.FileHeader.NumberOfSymbols = [_scanner scanUInt32];
	h.FileHeader.SizeOfOptionalHeader = [_scanner scanUInt16];
	h.FileHeader.Characteristics = [_scanner scanUInt16];
	
	if( h.FileHeader.SizeOfOptionalHeader != 0xe0 ) // size of IMAGE_OPTIONAL_HEADERS32
		[NSException raise:@"DLLScanner" format:@"Invalid NT image"];
	
	h.OptionalHeader.Magic = [_scanner scanUInt16];
	h.OptionalHeader.MajorLinkerVersion = [_scanner scanUInt8];
	h.OptionalHeader.MinorLinkerVersion = [_scanner scanUInt8];
	h.OptionalHeader.SizeOfCode = [_scanner scanUInt32];
	h.OptionalHeader.SizeOfInitializedData = [_scanner scanUInt32];
	h.OptionalHeader.SizeOfUninitializedData = [_scanner scanUInt32];
	h.OptionalHeader.AddressOfEntryPoint = [_scanner scanUInt32];
	h.OptionalHeader.BaseOfCode = [_scanner scanUInt32];
	h.OptionalHeader.BaseOfData = [_scanner scanUInt32];
	h.OptionalHeader.ImageBase = [_scanner scanUInt32];
	h.OptionalHeader.SectionAlignment = [_scanner scanUInt32];
	h.OptionalHeader.FileAlignment = [_scanner scanUInt32];
	h.OptionalHeader.MajorOperatingSystemVersion = [_scanner scanUInt16];
	h.OptionalHeader.MinorOperatingSystemVersion = [_scanner scanUInt16];
	h.OptionalHeader.MajorImageVersion = [_scanner scanUInt16];
	h.OptionalHeader.MinorImageVersion = [_scanner scanUInt16];
	h.OptionalHeader.MajorSubsystemVersion = [_scanner scanUInt16];
	h.OptionalHeader.MinorSubsystemVersion = [_scanner scanUInt16];
	h.OptionalHeader.Win32VersionValue = [_scanner scanUInt32];
	h.OptionalHeader.SizeOfImage = [_scanner scanUInt32];
	h.OptionalHeader.SizeOfHeaders = [_scanner scanUInt32];
	h.OptionalHeader.CheckSum = [_scanner scanUInt32];
	h.OptionalHeader.Subsystem = [_scanner scanUInt16];
	h.OptionalHeader.DllCharacteristics = [_scanner scanUInt16];
	h.OptionalHeader.SizeOfStackReserve = [_scanner scanUInt32];
	h.OptionalHeader.SizeOfStackCommit = [_scanner scanUInt32];
	h.OptionalHeader.SizeOfHeapReserve = [_scanner scanUInt32];
	h.OptionalHeader.SizeOfHeapCommit = [_scanner scanUInt32];
	h.OptionalHeader.LoaderFlags = [_scanner scanUInt32];
	h.OptionalHeader.NumberOfRvaAndSizes = [_scanner scanUInt32];
	if( h.OptionalHeader.NumberOfRvaAndSizes > IMAGE_NUMBEROF_DIRECTORY_ENTRIES )
		[NSException raise:@"DLLScanner" format:@"Too many DataDirectory entries (%d)",h.OptionalHeader.NumberOfRvaAndSizes];
	for( i = 0; i < h.OptionalHeader.NumberOfRvaAndSizes; i++ )
	{
		h.OptionalHeader.DataDirectory[i].VirtualAddress = [_scanner scanUInt32];
		h.OptionalHeader.DataDirectory[i].Size = [_scanner scanUInt32];
	}
	
	return h;
}

- (IMAGE_SECTION_HEADER)scanSectionHeader
{
	IMAGE_SECTION_HEADER h;
	int i;
	
	for( i = 0; i < IMAGE_SIZEOF_SHORT_NAME; i++ )
		h.Name[i] = [_scanner scanUInt8];
	h.Misc.VirtualSize = [_scanner scanUInt32];
	h.VirtualAddress = [_scanner scanUInt32];
	h.SizeOfRawData = [_scanner scanUInt32];
	h.PointerToRawData = [_scanner scanUInt32];
	h.PointerToRelocations = [_scanner scanUInt32];
	h.PointerToLinenumbers = [_scanner scanUInt32];
	h.NumberOfRelocations = [_scanner scanUInt16];
	h.NumberOfLinenumbers = [_scanner scanUInt16];
	h.Characteristics = [_scanner scanUInt32];
	
	return h;
}

- (IMAGE_RESOURCE_DIRECTORY)scanResDir
{
	IMAGE_RESOURCE_DIRECTORY d;
	
	d.Characteristics = [_scanner scanUInt32];
	d.TimeDateStamp = [_scanner scanUInt32];
	d.MajorVersion = [_scanner scanUInt16];
	d.MinorVersion = [_scanner scanUInt16];
	d.NumberOfNamedEntries = [_scanner scanUInt16];
	d.NumberOfIdEntries = [_scanner scanUInt16];
	
	return d;
}

- (IMAGE_RESOURCE_DIRECTORY_ENTRY)scanResDirEnt
{
	IMAGE_RESOURCE_DIRECTORY_ENTRY e;
	
	e.Name = [_scanner scanUInt32];
	e.OffsetToData = [_scanner scanUInt32];
	
	return e;
}

- (IMAGE_RESOURCE_DATA_ENTRY)scanResDataEnt
{
	IMAGE_RESOURCE_DATA_ENTRY e;
	
	e.OffsetToData = [_scanner scanUInt32];
	e.Size = [_scanner scanUInt32];
	e.CodePage = [_scanner scanUInt32];
	e.Reserved = [_scanner scanUInt32];
	
	return e;
}

- (id)getResName:(IMAGE_RESOURCE_DIRECTORY_ENTRY*)resDirEnt resourcesOffset:(unsigned long)resSecOff
{
	id n;
	
	if( resDirEnt->Name & IMAGE_RESOURCE_NAME_IS_STRING )
	{
		unsigned long curPos;
		curPos = [_scanner tell];
		[_scanner seek:(resSecOff+(resDirEnt->Name^IMAGE_RESOURCE_NAME_IS_STRING))];
		n = [_scanner scanUTF16String];
		[_scanner seek:curPos];
	}
	else
	{
		n = [NSNumber numberWithUnsignedInt:resDirEnt->Name];
	}
	
	return n;
}

@end

