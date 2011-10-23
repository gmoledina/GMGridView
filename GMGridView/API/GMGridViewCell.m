//
//  GMGridViewCell.m
//  GMGridView
//
//  Created by Gulam Moledina on 11-10-22.
//  Copyright (c) 2011 GMoledina.ca. All rights reserved.
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


@end



//////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Implementation GMGridViewCell
//////////////////////////////////////////////////////////////

@implementation GMGridViewCell

@synthesize contentView = _contentView;
@synthesize inShakingMode = _inShakingMode;

//////////////////////////////////////////////////////////////
#pragma mark Constructors
//////////////////////////////////////////////////////////////

- (id)initWithFrame:(CGRect)frame
{
    if ([self initContentView:nil]) 
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

- (void)setContentView:(UIView *)contentView
{
    [self shake:NO];
    [_contentView removeFromSuperview];
    _contentView = contentView;
    _contentView.frame = self.bounds;
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_contentView];
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

@end
