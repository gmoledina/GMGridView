//
//  UIView+GMGridViewShake.m
//  GMGridView
//
//  Created by Gulam Moledina on 11-10-22.
//  Copyright (c) 2011 GMoledina.ca. All rights reserved.
//

#import "UIView+GMGridViewShake.h"
#import <Quartzcore/QuartzCore.h>


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
        
        [UIView beginAnimations:@"earthquake" context:nil];
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
