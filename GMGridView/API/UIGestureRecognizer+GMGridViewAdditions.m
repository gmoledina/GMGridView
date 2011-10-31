//
//  UIGestureRecognizer+GMGridViewGestureAdditions.m
//  GMGridView
//
//  Created by Gulam Moledina on 11-10-30.
//  Copyright (c) 2011 GMoledina.ca. All rights reserved.
//

#import "UIGestureRecognizer+GMGridViewAdditions.h"

@implementation UIGestureRecognizer (GMGridViewAdditions)

- (void)end
{
    BOOL currentStatus = self.enabled;
    self.enabled = NO;
    self.enabled = currentStatus;
}

- (BOOL)hasRecognizedValidGesture
{
    return (self.state == UIGestureRecognizerStateChanged || self.state == UIGestureRecognizerStateBegan);
}

@end
