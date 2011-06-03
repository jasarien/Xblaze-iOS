
#import <Cocoa/Cocoa.h>

@class MFWin32DLLResource;

@interface MFWin32DLLResourceFile : NSObject
{
	NSDictionary *resources; // key is type (NSString or NSNumber)
}

- (id)initWithData:(NSData *)data; // pass the entire .DLL file

//- (NSEnumerator *)allResourcesEnumerator;

- (NSArray *)resourceTypes;
- (NSArray *)resourcesOfType:(id)typeID;

- (MFWin32DLLResource *)resourceForType:(id)typeID identifier:(id)ident;

@end

@interface MFWin32DLLResource : NSObject
{
	id type;
	id identifier;
	NSDictionary *languages;
}
- (id)type;
- (id)identifier;
- (NSArray *)languages;
- (NSData *)dataForLanguage:(id)lang;
- (NSData *)data; // returns data for first language, if there is more than one language
@end



//#define MAKELANGID(p,s) (((unsigned)(s)) << 10)|(unsigned)(p))
//
//extern NSNumber* kMFWin32Lang_EN_US = MAKELANGID(LANG_ENGLISH,SUBLANG_ENGLISH_US);
//extern NSNumber* kMFWin32Lang_EN_UK = MAKELANGID(LANG_ENGLISH,SUBLANG_ENGLISH_UK);

/*
	/
		ICONS/
			ID-name/
				lang			(DATA)
				lang			(DATA)
				lang			(DATA)
			ID-name/
				lang
			ID-name/
				lang
		type/
			ID-name/
				lang
			ID-name/
				lang
		type/
			ID-name/
				lang
			ID-name/
				lang
		type/
			ID-name/
				lang
			ID-name/
				lang
*/

