//
//  GMGridViewCell+Extended.h
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

#import <Foundation/Foundation.h>
#import "GMGridView-Constants.h"
#import "GMGridView.h"
#import "GMGridViewCell.h"

typedef void (^GMGridViewCellDeleteBlock)(GMGridViewCell*);

//////////////////////////////////////////////////////////////
#pragma mark - Interface GMGridViewCell (Extended)
//////////////////////////////////////////////////////////////

@interface GMGridViewCell () 

@property (nonatomic, strong) UIView *fullSizeView;
@property (nonatomic, assign) CGSize fullSize;

@property (nonatomic, readonly, getter=isInShakingMode) BOOL inShakingMode;
@property (nonatomic, readonly, getter=isInFullSizeMode) BOOL inFullSizeMode;

@property (nonatomic, getter=isEditing) BOOL editing;
- (void)setEditing:(BOOL)editing animated:(BOOL)animated;

@property (nonatomic, copy) GMGridViewCellDeleteBlock deleteBlock;

@property (nonatomic, assign) UIViewAutoresizing defaultFullsizeViewResizingMask;
@property (nonatomic, gm_weak) UIButton *deleteButton;

- (void)prepareForReuse;
- (void)shake:(BOOL)on; // shakes the contentView only, not the fullsize one

- (void)switchToFullSizeMode:(BOOL)fullSizeEnabled;
- (void)stepToFullsizeWithAlpha:(CGFloat)alpha; // not supported yet

@end
