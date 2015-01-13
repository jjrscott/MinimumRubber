//
//  MRFont.h
//  MinimumRubber
//
//  Created by John Scott on 31/12/2014.
//  Copyright (c) 2014 John Scott. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreGraphics/CoreGraphics.h>

/**
 @function MRFontDataCreateWithNameAndPaths
 @abstract
    Create a TrueType font from the CGPaths provided.
 @param name
    The font name
 @param startCharCode
    The Unicode code point for the first glyph (note that the first CGPath in the array is used for .notdef, startCharCode is used for the 2nd CGPath onwards)
 @param paths
    An array of CGPaths to be converted to glyphs. One CGPath per glyph.
 @param emSize
    The size of one em. This will determine the size of your glyphs relative to glyphs from other fonts.
 @return
    The TrueType font data.
 */

CFDataRef MRFontDataCreateWithNameAndPaths(CFStringRef name, UInt16 startCharCode, CFArrayRef paths, CGFloat emSize);


