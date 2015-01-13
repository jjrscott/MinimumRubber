//
//  MRPath.h
//  MinimumRubber
//
//  Created by John Scott on 31/12/2014.
//  Copyright (c) 2014 John Scott. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreGraphics/CoreGraphics.h>

/**
 @typedef MRPathApplierBlock
    This is a block equivalent of CGPathApplierFunction.
 @see CGPathApplierFunction
 @see MRPathApply
*/

typedef void (^MRPathApplierBlock)(const CGPathElement *element, BOOL *stop);

/**
 @function MRPathElementTypePointsCount
    A convenience function for returning the number of points in the CGPathElement.points array for a given CGPathElementType.
 @param
    type path type
 @return
    The number of points in the CGPathElement.points array.
 @see CGPathElement
 */
CFIndex MRPathElementTypePointsCount(CGPathElementType type);

/**
 @function MRPathApply
    Block equivalent of CGPathApply
 @param path
    The path to which the block will be applied.
 @param block
    A pointer to the block to apply. See CGPathApplierFunction for more information.
 @see CGPathApply
*/
void MRPathApply(CGPathRef path,
                 MRPathApplierBlock block);

/**
 @function MRStringFromCGPath
    Returns a string representation of a given path. The returned string is in the format of SVG path data.
 @param path
    The path.
 @return
    A string containing data from the path. If path is NULL, returns nil.
 @see http://www.w3.org/TR/SVG/paths.html#PathData
 */
CFStringRef MRStringFromCGPath(CGPathRef path);

/**
 @function MRPathAddElement
 A convenience function that wraps all the CGPathAdd* functions that have CGPathElementTypes.
 @param path
 The mutable path to change.
 @param m
 A pointer to an affine transformation matrix, or NULL if no transformation is needed. If specified, Quartz applies the transformation to the point before changing the path.
 @param element
    Path element to add.
 @return
    A string containing data from the path. If path is NULL, returns nil.
 @see http://www.w3.org/TR/SVG/paths.html#PathData
 */
void MRPathAddElement(CGMutablePathRef path,
                      const CGAffineTransform *m,
                      const CGPathElement *element);

/**
 @function MRPathAddQuadToPointWithCurve
 Appends a number of quadratic Bézier curves from the current point in a path to the specified location using two control points, after an optional transformation. Before returning, this function updates the current point to the specified location (x,y).
 @param path
    The mutable path to change. The path must not be empty.
 @param m
    A pointer to an affine transformation matrix, or NULL if no transformation is needed. If specified, Quartz applies the transformation to the curve before it is added to the path.
 @param cp1x
    The x-coordinate of the first control point.
 @param cp1y
    The y-coordinate of the first control point.
 @param cp2x
    The x-coordinate of the second control point.
 @param cp2y
    The y-coordinate of the second control point.
 @param x
    The x-coordinate of the end point of the curve.
 @param y
    The y-coordinate of the end point of the curve.
 @link https://github.com/millermedeiros/SVGParser/blob/master/com/millermedeiros/geom/CubicBezier.as
 @see CGPathAddCurveToPoint
*/
void MRPathAddQuadToPointWithCurve(CGMutablePathRef path,
                                   const CGAffineTransform *m,
                                   CGFloat cp1x,
                                   CGFloat cp1y,
                                   CGFloat cp2x,
                                   CGFloat cp2y,
                                   CGFloat x,
                                   CGFloat y);
