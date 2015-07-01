//
//  MRFont.m
//  MinimumRubber
//
//  Created by John Scott on 31/12/2014.
//  Copyright (c) 2014 John Scott. All rights reserved.
//

#import "MRFont.h"

#import "MRPath.h"

#define DefineAppendIntegerWithType(type) \
void append ## type (CFMutableDataRef data, type value) \
{ \
    UInt8 bytes[sizeof(type)]; \
    for (UInt32 index=0; index<sizeof(type); index++) \
    { \
        bytes[index] = 0xff & (value >> (8*(sizeof(type) - 1 - index))); \
    } \
    CFDataAppendBytes(data, bytes, sizeof(type)); \
}

DefineAppendIntegerWithType(SInt8)
DefineAppendIntegerWithType(UInt8)
DefineAppendIntegerWithType(SInt16)
DefineAppendIntegerWithType(UInt16)
DefineAppendIntegerWithType(SInt32)
DefineAppendIntegerWithType(UInt32)
DefineAppendIntegerWithType(SInt64)
DefineAppendIntegerWithType(UInt64)

void appendCGFloat(CFMutableDataRef data, CGFloat value)
{
    appendSInt32(data, value * (1 << 16));
}

void _MRDataAppendData(CFMutableDataRef theData, CFDataRef data)
{
    CFDataAppendBytes(theData, CFDataGetBytePtr(data), CFDataGetLength(data));
}

UInt32 _MRDataChecksum(CFDataRef data)
{
    UInt32 checksum = 0;
    CFIndex valueCount = CFDataGetLength(data) / sizeof(UInt32);
    const UInt32 *values = (UInt32 *) CFDataGetBytePtr(data);
    
    for (CFIndex index=0; index<valueCount; index++)
    {
        checksum += values[index];
    }

    return checksum;
}

CFDataRef MRFontDataCreateWithNameAndPaths(CFStringRef name, UInt16 startCharCode, CFArrayRef paths, CGFloat emSize)
{
    CFMutableDataRef cmapData = CFDataCreateMutable(NULL, 0);
    CFMutableDataRef glyfData = CFDataCreateMutable(NULL, 0);
    CFMutableDataRef headData = CFDataCreateMutable(NULL, 0);
    CFMutableDataRef hheaData = CFDataCreateMutable(NULL, 0);
    CFMutableDataRef hmtxData = CFDataCreateMutable(NULL, 0);
    CFMutableDataRef locaData = CFDataCreateMutable(NULL, 0);
    CFMutableDataRef maxpData = CFDataCreateMutable(NULL, 0);
    CFMutableDataRef nameData = CFDataCreateMutable(NULL, 0);
    CFMutableDataRef postData = CFDataCreateMutable(NULL, 0);
    
    CFIndex pathsCount = CFArrayGetCount(paths);

    // glyf, loca, hmtx tables
    
    CGRect fontBoundingBox = CGRectNull;
    CFIndex maxPoints = 0;
    CFIndex maxContours = 0;
    
    appendUInt32(locaData, 0);
    
    for (CFIndex pathIndex=0; pathIndex<pathsCount; pathIndex++)
    {
        // glyf table
        
        CGPathRef path = CFArrayGetValueAtIndex(paths, pathIndex);

        const CGRect pathBoundingBox = CGPathGetPathBoundingBox(path);
        
        if (!CGPathIsEmpty(path))
        {
            CFMutableDataRef endPtsOfContours = CFDataCreateMutable(NULL, 0);
            CFMutableDataRef flags = CFDataCreateMutable(NULL, 0);
            CFMutableDataRef xCoordinates = CFDataCreateMutable(NULL, 0);
            CFMutableDataRef yCoordinates = CFDataCreateMutable(NULL, 0);
            
            __block CFIndex endPointOfPreviousContour = 0;
            __block SInt16 previousX = 0;
            __block SInt16 previousY = 0;
            __block CFIndex numberOfContours = 0;
            __block CFIndex numberOfPoints = 0;
            
            MRPathApply(path, ^(const CGPathElement *element, BOOL *stop) {
                CFIndex pointsCount = MRPathElementTypePointsCount(element->type);
                
                if (element->type == kCGPathElementCloseSubpath)
                {
                    numberOfContours++;
                    appendUInt16(endPtsOfContours, endPointOfPreviousContour-1);
                }
                else
                {
                    endPointOfPreviousContour += pointsCount;
                    numberOfPoints += pointsCount;
                    
                    for (CFIndex index=0; index<pointsCount; index++)
                    {
                        appendUInt8(flags, index+1==pointsCount ? 1 : 0);

                        SInt16 x = element->points[index].x;
                        SInt16 y = element->points[index].y;
                        
                        appendSInt16(xCoordinates, x - previousX);
                        appendSInt16(yCoordinates, y - previousY);
                        
                        previousX = x;
                        previousY = y;
                    }
                }
                

            });
            
            appendSInt16(glyfData, numberOfContours);
            appendSInt16(glyfData, CGRectGetMinX(pathBoundingBox));
            appendSInt16(glyfData, CGRectGetMinY(pathBoundingBox));
            appendSInt16(glyfData, CGRectGetMaxX(pathBoundingBox));
            appendSInt16(glyfData, CGRectGetMaxY(pathBoundingBox));
            
            _MRDataAppendData(glyfData, endPtsOfContours);
            appendUInt16(glyfData, 0); // instructionLength
            _MRDataAppendData(glyfData, flags);
            _MRDataAppendData(glyfData, xCoordinates);
            _MRDataAppendData(glyfData, yCoordinates);
            
            CFRelease(endPtsOfContours);
            CFRelease(flags);
            CFRelease(xCoordinates);
            CFRelease(yCoordinates);
            
            // values for head table
            
            fontBoundingBox = CGRectUnion(fontBoundingBox, pathBoundingBox);
//            NSLog(@"%x %@", pathIndex, NSStringFromCGRect(pathBoundingBox));
            maxContours = MAX(maxContours, numberOfContours);
            maxPoints = MAX(maxPoints, numberOfPoints);
        }
        
        // hmtx table
        
        appendUInt16(hmtxData, CGRectGetMaxX(pathBoundingBox)); // advanceWidth
        appendSInt16(hmtxData, 0); // left side bearing
        
        // Align start of the glyph data to 2 byte words
        while (CFDataGetLength(glyfData) % 2)
        {
            appendUInt8(glyfData, 0);
        }

        appendUInt32(locaData, CFDataGetLength(glyfData));
    }
    
    // post table
    
    appendCGFloat(postData, 3.0); // Version
    appendCGFloat(postData, 0.0); // italicAngle
    appendSInt16(postData, -75.); // underlinePosition
    appendSInt16(postData, 50.); // underlineThickness
    appendUInt32(postData, 0); // isFixedPitch
    appendUInt32(postData, 0); // minMemType42
    appendUInt32(postData, 0); // maxMemType42
    appendUInt32(postData, 0); // minMemType1
    appendUInt32(postData, 0); // maxMemType1
    
    // head table
    
    appendCGFloat(headData, 1.0); // Table version number 0x00010000 for version 1.0.
    appendCGFloat(headData, 1.0); // fontRevision Set by font manufacturer.
    appendUInt32(headData, 0); // checkSumAdjustment To compute: set it to 0, sum the entire font as ULONG, then store 0xB1B0AFBA - sum.
    appendUInt32(headData, 0x5F0F3CF5); // magicNumber Set to 0x5F0F3CF5.
    appendUInt16(headData, 0b0000000000001011); // flags
    appendUInt16(headData, emSize); // unitsPerEm Valid range is from 16 to 16384. This value should be a power of 2 for fonts that have TrueType outlines.
    
    CFAbsoluteTime createTime = CFAbsoluteTimeGetCurrent();
    
    createTime += 3061152000; // seconds from 1904 to 2001
    
    appendUInt64(headData, createTime); // created Number of seconds since 12:00 midnight, January 1, 1904. 64-bit integer
    appendUInt64(headData, createTime); // modified Number of seconds since 12:00 midnight, January 1, 1904. 64-bit integer
    appendSInt16(headData, CGRectGetMinX(fontBoundingBox)); // xMin For all glyph bounding boxes.
    appendSInt16(headData, CGRectGetMinY(fontBoundingBox)); // yMin For all glyph bounding boxes.
    appendSInt16(headData, CGRectGetMaxX(fontBoundingBox)); // xMax For all glyph bounding boxes.
    appendSInt16(headData, CGRectGetMaxY(fontBoundingBox)); // yMax For all glyph bounding boxes.
    appendUInt16(headData, 0); // macStyle
    appendUInt16(headData, 8); // lowestRecPPEM Smallest readable size in pixels.
    appendSInt16(headData, 2); // fontDirectionHint Deprecated (Set to 2).
    appendSInt16(headData, 1); // indexToLocFormat 0 for short offsets, 1 for long.
    appendSInt16(headData, 0); // glyphDataFormat 0 for current format.
    
    // maxp table
    
    appendCGFloat(maxpData, 1.0); // Table version number 0x00010000 for version 1.0.
    appendUInt16(maxpData, pathsCount); // numGlyphs The number of glyphs in the font.
    appendUInt16(maxpData, maxPoints); // maxPoints Maximum points in a non-composite glyph.
    appendUInt16(maxpData, maxContours); // maxContours Maximum contours in a non-composite glyph.
    appendUInt16(maxpData, 0); // maxCompositePoints Maximum points in a composite glyph.
    appendUInt16(maxpData, 0); // maxCompositeContours Maximum contours in a composite glyph.
    appendUInt16(maxpData, 2); // maxZones 1 if instructions do not use the twilight zone (Z0), or 2 if instructions do use Z0; should be set to 2 in most cases.
    appendUInt16(maxpData, 0); // maxTwilightPoints Maximum points used in Z0.
    appendUInt16(maxpData, 1); // maxStorage Number of Storage Area locations.
    appendUInt16(maxpData, 1); // maxFunctionDefs Number of FDEFs.
    appendUInt16(maxpData, 0); // maxInstructionDefs Number of IDEFs.
    appendUInt16(maxpData, 64); // maxStackElements Maximum stack depth2.
    appendUInt16(maxpData, 0); // maxSizeOfInstructions Maximum byte count for glyph instructions.
    appendUInt16(maxpData, 0); // maxComponentElements Maximum number of components referenced at “top level” for any composite glyph.
    appendUInt16(maxpData, 0); // maxComponentDepth Maximum levels of recursion; 1 for simple components.
    
    // hhea table
    
    appendCGFloat(hheaData, 1.0); // Table version number 0x00010000 for version 1.0.
    appendSInt16(hheaData, CGRectGetMaxY(fontBoundingBox)); // Ascender Typographic ascent. (Distance from baseline of highest ascender)
    appendSInt16(hheaData, CGRectGetMinY(fontBoundingBox)); // Descender Typographic descent. (Distance from baseline of lowest descender)
    appendSInt16(hheaData, 28); // LineGap Typographic line gap.
    appendUInt16(hheaData, MAX(0, CGRectGetMaxX(fontBoundingBox))); // advanceWidthMax Maximum advance width value in 'hmtx' table.
    appendSInt16(hheaData, 0); // minLeftSideBearing Minimum left sidebearing value in 'hmtx' table.
    appendSInt16(hheaData, CGRectGetMinX(fontBoundingBox)); // minRightSideBearing Minimum right sidebearing value; calculated as Min(aw - lsb - (xMax - xMin)).
    appendSInt16(hheaData, MAX(0, CGRectGetWidth(fontBoundingBox))); // xMaxExtent Max(lsb + (xMax - xMin)).
    appendSInt16(hheaData, 0); // caretSlopeRise Used to calculate the slope of the cursor (rise/run); 1 for vertical.
    appendSInt16(hheaData, 0); // caretSlopeRun 0 for vertical.
    appendSInt16(hheaData, 0); // caretOffset The amount by which a slanted highlight on a glyph needs to be shifted to produce the best appearance. Set to 0 for non-slanted fonts
    appendSInt16(hheaData, 0); // (reserved) set to 0
    appendSInt16(hheaData, 0); // (reserved) set to 0
    appendSInt16(hheaData, 0); // (reserved) set to 0
    appendSInt16(hheaData, 0); // (reserved) set to 0
    appendSInt16(hheaData, 0); // metricDataFormat 0 for current format.
    appendUInt16(hheaData, pathsCount); // numberOfHMetrics Number of hMetric entries in 'hmtx' table
    
    // name table
    
    CFMutableArrayRef names = CFArrayCreateMutable(NULL, 0, NULL);
    CFArrayAppendValue(names, CFSTR(""));
    CFArrayAppendValue(names, name);
    CFArrayAppendValue(names, CFSTR("Regular"));
    CFMutableStringRef fontIdentifier = CFStringCreateMutable(NULL, 0);
    CFStringAppend(fontIdentifier, CFSTR("1.000;UKWN;"));
    CFStringAppend(fontIdentifier, name);
    CFArrayAppendValue(names, fontIdentifier);
    CFArrayAppendValue(names, name);
    CFArrayAppendValue(names, CFSTR("MRFont Compiler 0.01"));
    CFArrayAppendValue(names, name);
    
    CFIndex stringCount = CFArrayGetCount(names);
    
    appendUInt16(nameData, 0); // format Format selector (=0).
    appendUInt16(nameData, stringCount); // count Number of name records.
    appendUInt16(nameData, 6 + stringCount * 12); // stringOffset Offset to start of string storage (from start of table).

    
    CFMutableDataRef stringData = CFDataCreateMutable(NULL, 0);
    
    for (CFIndex index=0; index<stringCount; index++)
    {
        appendUInt16(nameData, 1); // platformID Platform ID.
        appendUInt16(nameData, 0); // encodingID Platform-specific encoding ID.
        appendUInt16(nameData, 0); // languageID Language ID.
        appendUInt16(nameData, index); // nameID Name ID.
        
        CFStringRef string = CFArrayGetValueAtIndex(names, index);
        
        CFDataRef valueData = CFStringCreateExternalRepresentation(NULL, string, kCFStringEncodingMacRoman, ' ');
        
        appendUInt16(nameData, CFDataGetLength(valueData)); // length	String length (in bytes).
        appendUInt16(nameData, CFDataGetLength(stringData)); // offset String offset from start of storage area (in bytes).
        
        _MRDataAppendData(stringData, valueData);
        
        CFRelease(valueData);
    }
    
    CFRelease(fontIdentifier);
    
    _MRDataAppendData(nameData, stringData);
    
    // cmap table
    
    appendUInt16(cmapData, 0); // version Table version number (0).
    appendUInt16(cmapData, 1); // numTables Number of encoding tables that follow.
    appendUInt16(cmapData, 0); // platformID Platform ID.
    appendUInt16(cmapData, 4); // encodingID Platform-specific encoding ID.
    appendUInt32(cmapData, 12); // offset Byte offset from beginning of table to the subtable for this encoding.
    
    
    appendUInt16(cmapData, 4); // format Format number is set to 4
    appendUInt16(cmapData, 32 + 2 * (pathsCount - 1)); // length Length of subtable in bytes
    appendUInt16(cmapData, 0); // language Language code (see above)
    appendUInt16(cmapData, 4); // segCountX2 2 * segCount
    appendUInt16(cmapData, 4); // searchRange 2 * (2**FLOOR(log2(segCount)))
    appendUInt16(cmapData, 1); // entrySelector log2(searchRange/2)
    appendUInt16(cmapData, 0); // rangeShift (2 * segCount) - searchRange
    appendUInt16(cmapData, startCharCode + pathsCount - 2); // endCode[segCount] Ending character code for each segment, last = 0xFFFF.
    appendUInt16(cmapData, 0xFFFF); // endCode[segCount] Ending character code for each segment, last = 0xFFFF.
    appendUInt16(cmapData, 0); // reservedPad This value should be zero
    appendUInt16(cmapData, startCharCode); // startCode[segCount] Starting character code for each segment
    appendUInt16(cmapData, 0xFFFF); // startCode[segCount] Starting character code for each segment
    appendUInt16(cmapData, 0); // idDelta[segCount] Delta for all character codes in segment
    appendUInt16(cmapData, pathsCount - 2); // idDelta[segCount] Delta for all character codes in segment
    
    appendUInt16(cmapData, 4); // idRangeOffset[segCount] Offset in bytes to glyph indexArray, or 0
    appendUInt16(cmapData, 0); // idRangeOffset[segCount] Offset in bytes to glyph indexArray, or 0
    for (CFIndex index=0; index<(pathsCount - 1); index++)
    {
        appendUInt16(cmapData, 1 + index); // glyphIndexArray[variable] Glyph index array
    }

    CFMutableDataRef fontData = CFDataCreateMutable(NULL, 0);
    
    appendCGFloat(fontData, 1.0); // sfnt version 0x00010000 for version 1.0.
    appendUInt16(fontData, 9); // numTables Number of tables.
    appendUInt16(fontData, 128); // searchRange (Maximum power of 2 <= numTables) x 16.
    appendUInt16(fontData, 3); // entrySelector Log2(maximum power of 2 <= numTables).
    appendUInt16(fontData, 16); // rangeShift NumTables x 16-searchRange.

    struct {UInt8 tag[4]; CFDataRef data;} tables[] =
    {
        {"cmap", cmapData},
        {"glyf", glyfData},
        {"head", headData},
        {"hhea", hheaData},
        {"hmtx", hmtxData},
        {"loca", locaData},
        {"maxp", maxpData},
        {"name", nameData},
        {"post", postData},
    };
    
    UInt32 tableOffset = 12 + (16 * 9);
    
    for (CFIndex index=0; index<9; index++)
    {
        // tag 4 -byte identifier.
        for (CFIndex tagIndex=0; tagIndex<4; tagIndex++)
        {
            appendUInt8(fontData, tables[index].tag[tagIndex]);
        }
        
        appendUInt32(fontData, _MRDataChecksum(tables[index].data)); // checkSum CheckSum for this table.
        appendUInt32(fontData, tableOffset); // offset Offset from beginning of TrueType font file.
        const UInt32 tableLength = (UInt32) CFDataGetLength(tables[index].data);
        appendUInt32(fontData, tableLength); // length Length of this table.
        tableOffset += tableLength;
    }

    for (CFIndex index=0; index<9; index++)
    {
        _MRDataAppendData(fontData, tables[index].data);
    }
    
    CFRelease(cmapData);
    CFRelease(glyfData);
    CFRelease(headData);
    CFRelease(hheaData);
    CFRelease(hmtxData);
    CFRelease(locaData);
    CFRelease(maxpData);
    CFRelease(nameData);
    CFRelease(postData);
    
    return fontData;
}

