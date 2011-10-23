//
//  GMGridViewCell.h
//  GMGridView
//
//  Created by Gulam Moledina on 11-10-22.
//  Copyright (c) 2011 GMoledina.ca. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GMGridViewCell : UIView

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, assign, getter=isInShakingMode) BOOL inShakingMode;

- (id)initContentView:(UIView *)contentView;
- (void)shake:(BOOL)on;


@end
