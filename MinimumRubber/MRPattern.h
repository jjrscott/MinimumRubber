//
//  MRPattern.h
//  Lascaux
//
//  Created by John Scott on 07/04/2016.
//  Copyright © 2016 John Scott. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreGraphics/CoreGraphics.h>

typedef void (^MRPatternDrawPatternCallback)(CGContextRef __nullable context);

CGPatternRef __nullable MRPatternCreate(CGRect bounds,
                                        CGAffineTransform matrix,
                                        CGFloat xStep,
                                        CGFloat yStep,
                                        CGPatternTiling tiling,
                                        bool isColored,
                                        MRPatternDrawPatternCallback __nullable drawPattern);
