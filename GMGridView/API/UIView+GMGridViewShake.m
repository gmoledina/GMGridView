//
//  UIView+GMGridViewShake.m
//  GMGridView
//
//  Created by Gulam Moledina on 11-10-22.
//  Copyright (c) 2011 GMoledina.ca. All rights reserved.
//
//  Latest code can be found on GitHub: https://github.com/gmoledina/GMGridView
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
// 
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <Quartzcore/QuartzCore.h>
#import "UIView+GMGridViewShake.h"

@interface UIView (GMGridViewShake_Privates)

- (void)shakeEnded:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;

@end




@implementation UIView (GMGridViewShake)

- (void)shakeStatus:(BOOL)enabled
{
    if (enabled) 
    {
        CGFloat rotation = 4 * M_PI / 180;
        
        self.transform = CGAffineTransformMakeRotation(-1 * rotation);
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationRepeatAutoreverses:YES];
        [UIView setAnimationRepeatCount:MAXFLOAT];
        [UIView setAnimationDuration:0.17];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(shakeEnded:finished:context:)];
        
        self.transform = CGAffineTransformMakeRotation(rotation);
        
        [UIView commitAnimations];
    }
    else
    {
        [self.layer removeAllAnimations];
    }
}

- (void)shakeEnded:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context 
{
    [UIView animateWithDuration:0.2 animations:^{
        self.transform = CGAffineTransformIdentity;
    }];
}

@end
