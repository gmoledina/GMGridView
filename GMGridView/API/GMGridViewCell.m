//
//  GMGridViewCell.m
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

#import "GMGridViewCell.h"
#import "UIView+GMGridViewShake.h"

//////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Interface GMGridViewCell (Privates)
//////////////////////////////////////////////////////////////

@interface GMGridViewCell () 
{
    
}

@property (nonatomic, assign) UIViewAutoresizing defaultFullsizeViewResizingMask;

@end



//////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Implementation GMGridViewCell
//////////////////////////////////////////////////////////////

@implementation GMGridViewCell

@synthesize contentView = _contentView;
@synthesize inShakingMode = _inShakingMode;
@synthesize fullSize = _fullSize;
@synthesize fullSizeView = _fullSizeView;
@synthesize inFullSizeMode = _inFullSizeMode;
@synthesize defaultFullsizeViewResizingMask;

//////////////////////////////////////////////////////////////
#pragma mark Constructors
//////////////////////////////////////////////////////////////

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [self initContentView:nil])) 
    {
        self.frame = frame;
    }
    return self;
}

- (id)initContentView:(UIView *)contentView
{
    if ((self = [super initWithFrame:contentView.bounds])) 
    {
        self.contentView = contentView;
    }
    
    return self;
}


//////////////////////////////////////////////////////////////
#pragma mark 
//////////////////////////////////////////////////////////////

- (void)layoutSubviews
{
    if(self.inFullSizeMode)
    {
        CGPoint origin = CGPointMake((self.bounds.size.width - self.fullSize.width) / 2, 
                                     (self.bounds.size.height - self.fullSize.height) / 2);
        self.fullSizeView.frame = CGRectMake(origin.x, origin.y, self.fullSize.width, self.fullSize.height);
    }
    else
    {
        self.fullSizeView.frame = self.bounds;
    }
}

//////////////////////////////////////////////////////////////
#pragma mark 
//////////////////////////////////////////////////////////////

- (void)setContentView:(UIView *)contentView
{
    [self shake:NO];
    [_contentView removeFromSuperview];
    _contentView = contentView;
    _contentView.frame = self.bounds;
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_contentView];
}

- (void)setFullSizeView:(UIView *)fullSizeView
{
    if ([self isInFullSizeMode]) 
    {
        fullSizeView.frame = _fullSizeView.frame;
        fullSizeView.alpha = _fullSizeView.alpha;
    }
    else
    {
        fullSizeView.frame = self.bounds;
        fullSizeView.alpha = 0;
    }
    
    self.defaultFullsizeViewResizingMask = fullSizeView.autoresizingMask | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    fullSizeView.autoresizingMask = _fullSizeView.autoresizingMask;
    
    [_fullSizeView removeFromSuperview];
    _fullSizeView = fullSizeView;
    [self addSubview:_fullSizeView];
}

- (void)setFullSize:(CGSize)fullSize
{
    _fullSize = fullSize;
    
    [self setNeedsLayout];
}


//////////////////////////////////////////////////////////////
#pragma mark 
//////////////////////////////////////////////////////////////

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/


//////////////////////////////////////////////////////////////
#pragma mark Public methods
//////////////////////////////////////////////////////////////

- (void)shake:(BOOL)on
{
    if ((on && !self.inShakingMode) || (!on && self.inShakingMode)) 
    {
        [self.contentView shakeStatus:on];
        self.inShakingMode = on;
    }
}

- (void)switchToFullSizeMode:(BOOL)fullSizeEnabled
{
    if (fullSizeEnabled) 
    {
        self.fullSizeView.autoresizingMask = self.defaultFullsizeViewResizingMask;
        
        CGPoint center = self.fullSizeView.center;
        self.fullSizeView.frame = CGRectMake(self.fullSizeView.frame.origin.x, self.fullSizeView.frame.origin.y, self.fullSize.width, self.fullSize.height);
        self.fullSizeView.center = center;
        
        self.inFullSizeMode = YES;
        
        [UIView animateWithDuration:0.1 
                         animations:^{
                             self.fullSizeView.alpha = 1;
                             self.contentView.alpha  = 0;
                             self.backgroundColor = [UIColor clearColor];
                         } 
                         completion:^(BOOL finished){
                             [self setNeedsLayout];
                         }
        ];
    }
    else
    {
        self.fullSizeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.inFullSizeMode = NO;
        
        [UIView animateWithDuration:0.1 
                         animations:^{
                             self.fullSizeView.alpha = 0;
                             self.contentView.alpha  = 1;
                             self.fullSizeView.frame = self.bounds;
                         } 
                         completion:^(BOOL finished){
                             [self setNeedsLayout];
                         }
         ];
    }
}

- (void)stepToFullsizeWithAlpha:(CGFloat)alpha
{
    if (![self isInFullSizeMode]) 
    {
        if (alpha > 1) 
        {
            alpha = 1;
        }
        else if (alpha < 0)
        {
            alpha = 0;
        }
        
        self.fullSizeView.alpha = alpha;
        self.contentView.alpha  = 1.4 - alpha;
    }
}

@end
