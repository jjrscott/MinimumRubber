//
//  MRPath.m
//  MinimumRubber
//
//  Created by John Scott on 31/12/2014.
//  Copyright (c) 2014 John Scott. All rights reserved.
//

#import "MRPath.h"

CFIndex MRPathElementTypePointsCount(CGPathElementType type)
{
    switch (type)
    {
        case kCGPathElementMoveToPoint:
            return 1;
            break;
            
        case kCGPathElementAddLineToPoint:
            return 1;
            break;
            
        case kCGPathElementAddQuadCurveToPoint:
            return 2;
            break;
            
        case kCGPathElementAddCurveToPoint:
            return 3;
            break;
            
        case kCGPathElementCloseSubpath:
            return 0;
            break;
            
        default:
            break;
    }
    return 0;
}

CFStringRef MRStringFromPathElementType(CGPathElementType type)
{
    switch (type)
    {
        case kCGPathElementMoveToPoint:
            return CFSTR("MoveToPoint");
            break;
            
        case kCGPathElementAddLineToPoint:
            return CFSTR("AddLineToPoint");
            break;
            
        case kCGPathElementAddQuadCurveToPoint:
            return CFSTR("AddQuadCurveToPoint");
            break;
            
        case kCGPathElementAddCurveToPoint:
            return CFSTR("AddCurveToPoint");
            break;
            
        case kCGPathElementCloseSubpath:
            return CFSTR("CloseSubpath");
            break;
            
        default:
            break;
    }
    return NULL;
}

void _MRStringFromCGPathFunction(void *info,
                                const CGPathElement *element)
{
    CFMutableStringRef string = info;
    
    if (CFStringGetLength(string))
    {
        CFStringAppend(string, CFSTR(" "));
    }
    
    switch (element->type)
    {
        case kCGPathElementMoveToPoint:
            CFStringAppend(string, CFSTR("M"));
            break;
            
        case kCGPathElementAddLineToPoint:
            CFStringAppend(string, CFSTR("L"));
            break;
            
        case kCGPathElementAddQuadCurveToPoint:
            CFStringAppend(string, CFSTR("Q"));
            break;
            
        case kCGPathElementAddCurveToPoint:
            CFStringAppend(string, CFSTR("C"));
            break;
            
        case kCGPathElementCloseSubpath:
            CFStringAppend(string, CFSTR("Z"));
            break;
            
        default:
            break;
    }

    CFIndex pointsCount = MRPathElementTypePointsCount(element->type);
    
    for (CFIndex index=0; index<pointsCount; index++)
    {
        CFStringAppendFormat(string, NULL, CFSTR(" %.3f %.3f"), element->points[index].x, element->points[index].y);
    }
}


CFStringRef MRStringFromCGPath(CGPathRef path)
{
    CFMutableStringRef string = NULL;
    if (path)
    {
        string = CFStringCreateMutable(NULL, 0);
        
        CGPathApply(path, string, _MRStringFromCGPathFunction);
    }
    
    return string;
}

struct _MRPathApplierInfo
{
    void *block;
    BOOL stop;
};

void _MRPathApplierFunction(void *info,
                                const CGPathElement *element)
{
    struct _MRPathApplierInfo *applierInfo = info;
    if (!applierInfo->stop)
    {
        MRPathApplierBlock block = (__bridge MRPathApplierBlock) applierInfo->block;
        block(element, &(applierInfo->stop));
    }
}

void MRPathApply(CGPathRef path, MRPathApplierBlock block)
{
    struct _MRPathApplierInfo applierInfo;
    applierInfo.block = (__bridge void*) block;
    applierInfo.stop = NO;
    
    CGPathApply(path, &applierInfo, _MRPathApplierFunction);
}

void MRPathAddElement(CGMutablePathRef path, const CGAffineTransform *m, const CGPathElement *element)
{
    switch (element->type)
    {
        case kCGPathElementMoveToPoint:
            CGPathMoveToPoint(path, m, element->points[0].x, element->points[0].y);
            break;
            
        case kCGPathElementAddLineToPoint:
            CGPathAddLineToPoint(path, m, element->points[0].x, element->points[0].y);
            break;
            
        case kCGPathElementAddQuadCurveToPoint:
            CGPathAddQuadCurveToPoint(path, m, element->points[0].x, element->points[0].y, element->points[1].x, element->points[1].y);
            break;
            
        case kCGPathElementAddCurveToPoint:
            CGPathAddCurveToPoint(path, m, element->points[0].x, element->points[0].y, element->points[1].x, element->points[1].y, element->points[2].x, element->points[2].y);
            break;
            
        case kCGPathElementCloseSubpath:
            CGPathCloseSubpath(path);
            break;
            
        default:
            break;
    }
}

typedef struct
{
    UInt32 count;
    CGFloat values[10];
} _MRFLoatArray;

BOOL _MRFLoatArrayContainsValue(_MRFLoatArray *array, CGFloat value)
{
    for (CFIndex index=0; index<array->count; index++)
    {
        if (value == array->values[index])
        {
            return YES;
        }
    }
    return NO;
}

struct _Line {
    CGPoint start;
    CGPoint end;
};

CGPoint _LineGetIntermediate(struct _Line line, CGFloat ratio)
{
    return CGPointMake(line.start.x + ((line.end.x - line.start.x) * ratio), line.start.y + ((line.end.y - line.start.y) * ratio));
}

void MRPathAddQuadToPointWithCurve(CGMutablePathRef path,
                           const CGAffineTransform *m, CGFloat cp1x, CGFloat cp1y,
                           CGFloat cp2x, CGFloat cp2y, CGFloat x, CGFloat y)
{
    struct _Line baseLines[3];
    baseLines[0].start = CGPathGetCurrentPoint(path);
    baseLines[0].end = CGPointMake(cp1x, cp1y);
    baseLines[1].start = CGPointMake(cp1x, cp1y);
    baseLines[1].end = CGPointMake(cp2x, cp2y);
    baseLines[2].start = CGPointMake(cp2x, cp2y);
    baseLines[2].end = CGPointMake(x, y);

    struct _Line subLines[5];
    subLines[0].start = _LineGetIntermediate(baseLines[0], .5);
    subLines[0].end = _LineGetIntermediate(baseLines[1], .5);
    subLines[1].start = _LineGetIntermediate(baseLines[1], .5);
    subLines[1].end = _LineGetIntermediate(baseLines[2], .5);
    subLines[2].start = _LineGetIntermediate(subLines[0], .5);
    subLines[2].end = _LineGetIntermediate(subLines[1], .5);
    subLines[3].start = _LineGetIntermediate(baseLines[0], .375);
    subLines[3].end = _LineGetIntermediate(subLines[2], .125);
    subLines[4].start = _LineGetIntermediate(baseLines[2], .625);
    subLines[4].end = _LineGetIntermediate(subLines[2], .875);
    
    CGPoint anchors[4];
    anchors[0] = _LineGetIntermediate(subLines[3], 0.5);
    anchors[1] = _LineGetIntermediate(subLines[2], 0.5);
    anchors[2] = _LineGetIntermediate(subLines[4], 0.5);
    anchors[3] = CGPointMake(x, y);
    
    
    CGPoint controls[4];
    controls[0] = subLines[3].start;
    controls[1] = _LineGetIntermediate(subLines[2], .125);
    controls[2] = _LineGetIntermediate(subLines[2], .875);
    controls[3] = _LineGetIntermediate(baseLines[2], .625);
    
    for (CFIndex index=0; index<4; index++)
    {
        CGPathAddQuadCurveToPoint(path, m, controls[index].x, controls[index].y, anchors[index].x, anchors[index].y);
    }
}

typedef void (^_MRPathStraightBlock)(const CGPoint from, const CGPoint to, BOOL *stop);

void _MRPathStraights(CGPathRef path, _MRPathStraightBlock block)
{
    __block CGPoint subpathOriginPoint;
    __block CGPoint currentPoint;
    MRPathApply(path, ^(const CGPathElement *element, BOOL *stop)
                {
                    if (element->type == kCGPathElementMoveToPoint)
                    {
                        subpathOriginPoint = element->points[0];
                        currentPoint = subpathOriginPoint;
                    }
                    else if (element->type == kCGPathElementCloseSubpath)
                    {
                        block(currentPoint, subpathOriginPoint, stop);
                        currentPoint = subpathOriginPoint;
                    }
                    else
                    {
                        block(currentPoint, element->points[0], stop);
                        currentPoint = element->points[0];
                    }
                });
}


CGFloat MRPathGetLength(CGPathRef path)
{
    __block CGFloat length = 0;
    _MRPathStraights(path, ^(const CGPoint from, const CGPoint to, BOOL *stop)
                     {
                         CGFloat dx = to.x - from.x;
                         CGFloat dy = to.y - from.y;
                         CGFloat dh = hypot(dx, dy);
                         length += dh;
                     });
    return length;
}

CGAffineTransform MRPathGetCGAffineTransformToPosition(CGPathRef path,
                                                       const CGFloat position,
                                                       const BOOL rotate)
{
    __block CGAffineTransform transform = CGAffineTransformIdentity;
    
    __block CGFloat offset = 0;
    _MRPathStraights(path, ^(const CGPoint from, const CGPoint to, BOOL *stop)
    {
        CGFloat dx = to.x - from.x;
        CGFloat dy = to.y - from.y;
        CGFloat dh = hypot(dx, dy);
        if (offset + dh > position)
        {
            CGFloat cosA = dx/dh;
            CGFloat sinA = dy/dh;
            
            transform = CGAffineTransformTranslate(transform, from.x, from.y);
            
            CGFloat fd = (position - offset) / dh;
            
            transform = CGAffineTransformTranslate(transform, dx * fd, dy * fd);
            if (rotate)
            {
                transform = CGAffineTransformConcat(CGAffineTransformMake(cosA, sinA, -sinA, cosA, 0, 0), transform);
            }
            *stop = YES;
        }
        offset += dh;

    });
    
    return transform;
}

struct _MRPathMetricStraight {
    CGFloat x;
    CGFloat y;
    CGFloat dx;
    CGFloat dy;
    CGFloat dh;
    CGFloat cosA;
    CGFloat sinA;
};


struct MRPathMetrics {
    CFIndex straightsCount;
    struct _MRPathMetricStraight *straights;
    CGFloat totalLength;
};

MRPathMetricsRef MRPathGetMetrics(CGPathRef path)
{
    MRPathMetricsRef metrics = malloc(sizeof(struct MRPathMetrics));
    metrics->straightsCount = 0;
    metrics->straights = NULL;
    metrics->totalLength = 0;
    
    _MRPathStraights(path, ^(const CGPoint from, const CGPoint to, BOOL *stop)
                     {
                         metrics->straightsCount++;
                         if (metrics->straights)
                         {
                             metrics->straights = realloc(metrics->straights, metrics->straightsCount * sizeof(struct _MRPathMetricStraight));
                         }
                         else
                         {
                             metrics->straights = malloc(metrics->straightsCount * sizeof(struct _MRPathMetricStraight));
                         }
                         
                         struct _MRPathMetricStraight *straight = metrics->straights + (metrics->straightsCount - 1);
                         
                         straight->x = from.x;
                         straight->y = from.y;
                         
                         
                         straight->dx = to.x - from.x;
                         straight->dy = to.y - from.y;
                         straight->dh = hypot(straight->dx, straight->dy);
                         
                         straight->cosA = straight->dx/straight->dh;
                         straight->sinA = straight->dy/straight->dh;
                         
                         metrics->totalLength += straight->dh;
                     });
    return metrics;
}

void MRPathMetricsFree(MRPathMetricsRef metrics)
{
    if (metrics->straights)
    {
        free(metrics->straights);
    }
    if (!metrics)
    {
        abort();
    }
    free(metrics);
}

CGFloat MRPathMetricsGetLength(MRPathMetricsRef metrics)
{
    return metrics->totalLength;
}

CGAffineTransform MRPathMetricGetCGAffineTransformToPosition(MRPathMetricsRef metrics,
                                                             const CGFloat position,
                                                             const BOOL rotate)
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    CGFloat offset = 0;
    for (CFIndex straightIndex=0; straightIndex<metrics->straightsCount; straightIndex++)
    {
        const struct _MRPathMetricStraight *straight = metrics->straights + straightIndex;
        if (offset + straight->dh > position)
        {
            transform = CGAffineTransformTranslate(transform, straight->x, straight->y);
            
            CGFloat fd = (position - offset) / straight->dh;
            
            transform = CGAffineTransformTranslate(transform, straight->dx * fd, straight->dy * fd);
            if (rotate)
            {
                transform = CGAffineTransformConcat(CGAffineTransformMake(straight->cosA, straight->sinA, -straight->sinA, straight->cosA, 0, 0), transform);
            }
            break;
        }
        offset += straight->dh;
        
    }
    
    return transform;
}

