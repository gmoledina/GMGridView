//
//  GMGridViewLayoutStrategy.h
//  GMGridView
//
//  Created by Gulam Moledina on 11-10-28.
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

#define GMGV_INVALID_POSITION -1

@protocol GMGridViewLayoutStrategy;


typedef enum {
    GMGridViewLayoutVertical = 0,
    GMGridViewLayoutHorizontal,
    // A paged horizontal strategy in which in each page the items flow from top left to bottom right
    // Example:
    // ______________________
    // | 1  2  3 | 10 11 12 |
    // | 4  5  6 | 13 14    |
    // | 7  8  9 |          |
    // ----------------------
    // NOTE: For this strategy to work properly and center the elements in each page, make sure that 
    // the grid's left inset is zero. For example:
    // gmGridView.minEdgeInsets = UIEdgeInsetsMake(6, 0, 0, 0);
    // as well as that paging is enabled for this grid:
    // gmGridView.pagingEnabled = YES;
    GMGridViewLayoutHorizontalPagedLtr
} GMGridViewLayoutStrategyType;



//////////////////////////////////////////////////////////////
#pragma mark - Strategy Factory
//////////////////////////////////////////////////////////////

@interface GMGridViewLayoutStrategyFactory

+ (id<GMGridViewLayoutStrategy>)strategyFromType:(GMGridViewLayoutStrategyType)type;

@end


//////////////////////////////////////////////////////////////
#pragma mark - The strategy protocol
//////////////////////////////////////////////////////////////

@protocol GMGridViewLayoutStrategy <NSObject>

- (GMGridViewLayoutStrategyType)type;

// Setup
- (void)rebaseWithItemCount:(NSInteger)count havingSize:(CGSize)itemSize andSpacing:(NSInteger)spacing insideOfBounds:(CGRect)bounds;

// Fetching the result
- (CGSize)contentSize;
- (CGPoint)originForItemAtPosition:(NSInteger)position;
- (NSInteger)itemPositionFromLocation:(CGPoint)location;

- (NSRange)rangeOfPositionsInBoundsFromOffset:(CGPoint)offset;

@end


//////////////////////////////////////////////////////////////
#pragma mark - Strategy Base class
//////////////////////////////////////////////////////////////

@interface GMGridViewLayoutStrategyBase : NSObject
{
    @protected
    // All of these vars should be set in the init method
    GMGridViewLayoutStrategyType _type;
    
    // All of these vars should be set in the rebase method of the child class
    NSInteger _itemCount;
    CGSize _itemSize;
    NSInteger _itemSpacing;
    CGRect _contentBounds;
    CGSize _contentSize;
}

@property (nonatomic, readonly) GMGridViewLayoutStrategyType type;
@property (nonatomic, readonly) NSInteger itemCount;
@property (nonatomic, readonly) CGSize itemSize;
@property (nonatomic, readonly) NSInteger itemSpacing;
@property (nonatomic, readonly) CGRect contentBounds;
@property (nonatomic, readonly) CGSize contentSize;

@end

//////////////////////////////////////////////////////////////
#pragma mark - Vertical strategy
//////////////////////////////////////////////////////////////

@interface GMGridViewLayoutVerticalStrategy : GMGridViewLayoutStrategyBase <GMGridViewLayoutStrategy>
{
    @protected
    NSInteger _numberOfItemsPerRow;
}

@property (nonatomic, readonly) NSInteger numberOfItemsPerRow;

@end

//////////////////////////////////////////////////////////////
#pragma mark - Horizontal strategy
//////////////////////////////////////////////////////////////

@interface GMGridViewLayoutHorizontalStrategy : GMGridViewLayoutStrategyBase <GMGridViewLayoutStrategy>
{
    @protected
    NSInteger _numberOfItemsPerColumn;
}

@property (nonatomic, readonly) NSInteger numberOfItemsPerColumn;

@end

//////////////////////////////////////////////////////////////
#pragma mark - Horizontal Paged LTR strategy
//////////////////////////////////////////////////////////////

@interface GMGridViewLayoutHorizontalPagedLtrStrategy : GMGridViewLayoutHorizontalStrategy <GMGridViewLayoutStrategy>
{
@protected
    NSUInteger _numberOfPages;
    NSUInteger _numberOfColumnsPerPage;
    // left padding on each page. So that the content can be centered in the page
    CGFloat _pagePaddingLeft;
}

@property (nonatomic, readonly) NSUInteger numberOfPages;
@property (nonatomic, readonly) NSUInteger numberOfColumnsPerPage;
- (NSUInteger) pageForContentOffset:(CGPoint)offset;
- (CGPoint)originForItemAtColumn:(NSInteger)column row:(NSInteger)row page:(NSInteger)page;
- (CGPoint)originForPage:(NSUInteger)page;
@end
