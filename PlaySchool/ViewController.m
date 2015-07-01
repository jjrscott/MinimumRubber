//
//  ViewController.m
//  PlaySchool
//
//  Created by John Scott on 13/01/2015.
//  Copyright (c) 2015 John Scott. All rights reserved.
//

#import "ViewController.h"

#import "MinimumRubber.h"
@import CoreText;

@interface ViewController ()
{
    IBOutlet UILabel *_label;
    IBOutlet UITextView *_textView;
}

@end

@implementation ViewController

#define FONT_NAME "PlaySchool-Regular"

+(void)load
{
    CGFloat ascender = 952;
    CGFloat decender = -213;
    CGFloat capHeight = 714;
    CGFloat emSize = 1000;
    
    CGMutablePathRef emptyPath = CGPathCreateMutable();
    CGPathMoveToPoint(emptyPath, NULL, 0, ascender);
    CGPathCloseSubpath(emptyPath);
    CGPathMoveToPoint(emptyPath, NULL, 0, decender);
    CGPathCloseSubpath(emptyPath);
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGRect rect = CGRectMake(0, 0, capHeight, capHeight);
    CGPathAddEllipseInRect(path, NULL, rect);
    CGAffineTransform foo = CGAffineTransformTranslate(CGAffineTransformMakeScale(-1, 1), -CGRectGetMaxX(rect), 0) ;
    CGFloat baa = 70;
    CGPathMoveToPoint(path, NULL, CGRectGetMaxX(rect) + 40, 0);
    CGPathCloseSubpath(path);
    CGPathAddEllipseInRect(path, &foo, CGRectInset(rect, baa, baa) );
    //    CGPathAddRect(path, NULL, CGRectMake(0, 0, 500, 500));
    
    CFMutableArrayRef paths = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
    CFArrayAppendValue(paths, emptyPath);
    CFArrayAppendValue(paths, path);
    
    
    
    CFRelease(emptyPath);
    CFRelease(path);
    
    
    CFDataRef fontData = MRFontDataCreateWithNameAndPaths(CFSTR(FONT_NAME), 0xe000, paths, emSize);
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(fontData);
    CGFontRef font = CGFontCreateWithDataProvider(provider);
    
    CFErrorRef error;
    if (! CTFontManagerRegisterGraphicsFont(font, &error)) {
        CFStringRef errorDescription = CFErrorCopyDescription(error);
        NSLog(@"Failed to load font: %@", errorDescription);
        CFRelease(errorDescription);
    }
    else
    {
        CFRelease(font);
    }
    CFRelease(provider);

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIFont *font = [UIFont fontWithName:@(FONT_NAME) size:18];
    
    _label.font = font;
    _label.text = @"This is a symbol we just made: \ue000.\n\nDoesn't it look nice in this UILabel?";
    
    _textView.font = font;
    _textView.text = @"This is a symbol we just made: \ue000.\n\nDoesn't it look nice in this UITextView?";
}

@end
