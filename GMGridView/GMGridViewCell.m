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

#import "GMGridViewCell+Extended.h"
#import "UIView+GMGridViewAdditions.h"

//////////////////////////////////////////////////////////////
#pragma mark - Interface Private
//////////////////////////////////////////////////////////////

@interface GMGridViewCell(Private)

- (void)actionDelete;

@end

//////////////////////////////////////////////////////////////
#pragma mark - Implementation GMGridViewCell
//////////////////////////////////////////////////////////////

@implementation GMGridViewCell

@synthesize contentView = _contentView;
@synthesize editing = _editing;
@synthesize inShakingMode = _inShakingMode;
@synthesize fullSize = _fullSize;
@synthesize fullSizeView = _fullSizeView;
@synthesize inFullSizeMode = _inFullSizeMode;
@synthesize defaultFullsizeViewResizingMask = _defaultFullsizeViewResizingMask;
@synthesize deleteButton = _deleteButton;
@synthesize deleteBlock = _deleteBlock;
@synthesize deleteButtonIcon = _deleteButtonIcon;
@synthesize deleteButtonOffset;
@synthesize reuseIdentifier;
@synthesize highlighted;

//////////////////////////////////////////////////////////////
#pragma mark Constructors
//////////////////////////////////////////////////////////////

- (id)init
{
    return self = [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) 
    {
        self.autoresizesSubviews = !YES;
        self.editing = NO;
        
        UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.deleteButton = deleteButton;
        [self.deleteButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        self.deleteButtonIcon = nil;
        self.deleteButtonOffset = CGPointMake(-5, -5);
        self.deleteButton.alpha = 0;
        [self addSubview:deleteButton];
        [deleteButton addTarget:self action:@selector(actionDelete) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}


//////////////////////////////////////////////////////////////
#pragma mark UIView
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

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.highlighted = YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.highlighted = NO;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.highlighted = NO;
}

//////////////////////////////////////////////////////////////
#pragma mark Setters / getters
//////////////////////////////////////////////////////////////

- (void)setContentView:(UIView *)contentView
{
    [self shake:NO];
    [self.contentView removeFromSuperview];
    
    if(self.contentView)
    {
        contentView.frame = self.contentView.frame;
    }
    else
    {
        contentView.frame = self.bounds;
    }
    
    _contentView = contentView;
    
    self.contentView.autoresizingMask = UIViewAutoresizingNone;
    [self addSubview:self.contentView];
    
    [self bringSubviewToFront:self.deleteButton];
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
    
    [self bringSubviewToFront:self.deleteButton];
}

- (void)setFullSize:(CGSize)fullSize
{
    _fullSize = fullSize;
    
    [self setNeedsLayout];
}

- (void)setEditing:(BOOL)editing
{
    [self setEditing:editing animated:NO];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    if (editing != _editing) {
        _editing = editing;
        if (animated) {
            [UIView animateWithDuration:0.2f
                                  delay:0.f
                                options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseOut
                             animations:^{
                                 self.deleteButton.alpha = editing ? 1.f : 0.f;
                             }
                             completion:nil];
        }else {
            self.deleteButton.alpha = editing ? 1.f : 0.f;
        }
		
        self.contentView.userInteractionEnabled = !editing;
        [self shakeStatus:editing];
    }
}

- (void)setDeleteButtonOffset:(CGPoint)offset
{
    self.deleteButton.frame = CGRectMake(offset.x, 
                                         offset.y, 
                                         self.deleteButton.frame.size.width, 
                                         self.deleteButton.frame.size.height);
}

- (CGPoint)deleteButtonOffset
{
    return self.deleteButton.frame.origin;
}

- (void)setDeleteButtonIcon:(UIImage *)deleteButtonIcon
{
    [self.deleteButton setImage:deleteButtonIcon forState:UIControlStateNormal];
    
    if (deleteButtonIcon) 
    {
        self.deleteButton.frame = CGRectMake(self.deleteButton.frame.origin.x, 
                                             self.deleteButton.frame.origin.y, 
                                             deleteButtonIcon.size.width, 
                                             deleteButtonIcon.size.height);
        
        [self.deleteButton setTitle:nil forState:UIControlStateNormal];
        [self.deleteButton setBackgroundColor:[UIColor clearColor]];
    }
    else
    {
        self.deleteButton.frame = CGRectMake(self.deleteButton.frame.origin.x, 
                                             self.deleteButton.frame.origin.y, 
                                             35, 
                                             35);
        
        [self.deleteButton setTitle:@"X" forState:UIControlStateNormal];
        [self.deleteButton setBackgroundColor:[UIColor lightGrayColor]];
    }
    
    
}

- (UIImage *)deleteButtonIcon
{
    return [self.deleteButton currentImage];
}


- (void)setHighlighted:(BOOL)aHighlighted {
    highlighted = aHighlighted;
	
	[self.contentView recursiveEnumerateSubviewsUsingBlock:^(UIView *view, BOOL *stop) {
		if ([view respondsToSelector:@selector(setHighlighted:)]) {
			[(UIControl*)view setHighlighted:highlighted];
		}
	}];
}


//////////////////////////////////////////////////////////////
#pragma mark Private methods
//////////////////////////////////////////////////////////////

- (void)actionDelete
{
    if (self.deleteBlock) 
    {
        self.deleteBlock(self);
    }
}

//////////////////////////////////////////////////////////////
#pragma mark Public methods
//////////////////////////////////////////////////////////////

- (void)prepareForReuse
{
    self.fullSize = CGSizeZero;
    self.fullSizeView = nil;
    self.editing = NO;
    self.deleteBlock = nil;
}

- (void)shake:(BOOL)on
{
    if ((on && !self.inShakingMode) || (!on && self.inShakingMode)) 
    {
        [self.contentView shakeStatus:on];
        _inShakingMode = on;
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
        
        _inFullSizeMode = YES;
        
        self.fullSizeView.alpha = MAX(self.fullSizeView.alpha, self.contentView.alpha);
        self.contentView.alpha  = 0;
        
        [UIView animateWithDuration:0.3 
                         animations:^{
                             self.fullSizeView.alpha = 1;
                             self.fullSizeView.frame = CGRectMake(self.fullSizeView.frame.origin.x, self.fullSizeView.frame.origin.y, self.fullSize.width, self.fullSize.height);
                             self.fullSizeView.center = center;
                         } 
                         completion:^(BOOL finished){
                             [self setNeedsLayout];
                         }
		 ];
    }
    else
    {
        self.fullSizeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        _inFullSizeMode = NO;
        self.fullSizeView.alpha = 0;
        self.contentView.alpha  = 0.6;
        
        [UIView animateWithDuration:0.3 
                         animations:^{
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
    return; // not supported anymore - to be fixed
    
    if (![self isInFullSizeMode]) 
    {
        alpha = MAX(0, alpha);
        alpha = MIN(1, alpha);
        
        self.fullSizeView.alpha = alpha;
        self.contentView.alpha  = 1.4 - alpha;
    }
}

@end
