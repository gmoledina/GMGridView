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

#import <QuartzCore/QuartzCore.h>
#import "UIView+GMGridViewAdditions.h"

@interface UIView (GMGridViewAdditions_Privates)


@end




@implementation UIView (GMGridViewAdditions)

- (void)shakeStatus:(BOOL)enabled
{
    if (enabled) 
    {
        CGFloat rotation = 0.03;
        
        CABasicAnimation *shake = [CABasicAnimation animationWithKeyPath:@"transform"];
        shake.duration = 0.13;
        shake.autoreverses = YES;
        shake.repeatCount  = MAXFLOAT;
        shake.removedOnCompletion = NO;
        shake.fromValue = [NSValue valueWithCATransform3D:CATransform3DRotate(self.layer.transform,-rotation, 0.0 ,0.0 ,1.0)];
        shake.toValue   = [NSValue valueWithCATransform3D:CATransform3DRotate(self.layer.transform, rotation, 0.0 ,0.0 ,1.0)];
        
        [self.layer addAnimation:shake forKey:@"shakeAnimation"];
    }
    else
    {
        [self.layer removeAnimationForKey:@"shakeAnimation"];
    }
}

- (void)recursiveEnumerateSubviewsUsingBlock:(void (^)(UIView *view, BOOL *stop))block {
	if (self.subviews.count == 0) {
		return;
	}
	for (UIView *subview in [self subviews]) {
		BOOL stop = NO;
		block(subview, &stop);
		if (stop) {
			return;
		}
		[subview recursiveEnumerateSubviewsUsingBlock:block];
	}
}
@end
