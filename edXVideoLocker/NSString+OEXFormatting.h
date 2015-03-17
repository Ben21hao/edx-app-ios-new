//
//  NSString+OEXFormatting.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/4/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (OEXFormatting)

/// Converts a string to UPPERCASE using the display locale
- (NSString*)oex_uppercaseStringInCurrentLocale;

/// Performs named string substitution. Subtitutable parts of the string should be in curly braces
/// and correspond to entries in the parameters dictionary.
/// For example, if the format string is "{bookcount} books" and parameters is @{"bookcount" : @3}
/// The resulting string will be "3 books"
/// If this is a DEBUG build, strings with missing parameters or substitutions without
/// corresponding parameters will cause an assertion
+ (NSString*)oex_stringWithFormat:(NSString*)format parameters:(NSDictionary*)parameters;


@end
