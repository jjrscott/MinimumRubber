//
//  MRPattern.m
//  Lascaux
//
//  Created by John Scott on 07/04/2016.
//  Copyright © 2016 John Scott. All rights reserved.
//

#import "MRPattern.h"

void _MRPatternDrawPatternCallback(void * __nullable info, CGContextRef __nullable context)
{
    MRPatternDrawPatternCallback block = (__bridge MRPatternDrawPatternCallback) info;
    block(context);
}

void _MRCGPatternReleaseInfoCallback(void * __nullable info)
{
    Block_release(info);
}


CGPatternRef __nullable MRPatternCreate(CGRect bounds,
                                        CGAffineTransform matrix,
                                        CGFloat xStep,
                                        CGFloat yStep,
                                        CGPatternTiling tiling,
                                        bool isColored,
                                        MRPatternDrawPatternCallback __nullable drawPattern)
{
    static const CGPatternCallbacks callbacks = {0, &_MRPatternDrawPatternCallback, &_MRCGPatternReleaseInfoCallback};
    
    void *info = Block_copy( (__bridge void*) drawPattern);
    
    CGPatternRef pattern = CGPatternCreate(info, bounds, matrix, xStep, yStep, tiling, isColored, &callbacks);
    
    return pattern;
}