//
//  GMGridViewLayoutStrategy.m
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

#import "GMGridViewLayoutStrategies.h"

//////////////////////////////////////////////////////////////
#pragma mark - 
#pragma mark - Factory implementation
//////////////////////////////////////////////////////////////

@implementation GMGridViewLayoutStrategyFactory

+ (id<GMGridViewLayoutStrategy>)strategyFromType:(GMGridViewLayoutStrategyType)type
{
    id<GMGridViewLayoutStrategy> strategy = nil;
    
    switch (type) {
        case GMGridViewLayoutVertical:
            strategy = [[GMGridViewLayoutVerticalStrategy alloc] init];
            break;
        case GMGridViewLayoutHorizontal:
        default:
            strategy = [[GMGridViewLayoutHorizontalStrategy alloc] init];
            break;
    }
    
    return strategy;
}

@end



//////////////////////////////////////////////////////////////
#pragma mark - 
#pragma mark - Strategy base class implementation
//////////////////////////////////////////////////////////////

@implementation GMGridViewLayoutStrategyBase

@synthesize type          = _type;
@synthesize itemCount     = _itemCount;
@synthesize itemSize      = _itemSize;
@synthesize itemSpacing   = _itemSpacing;
@synthesize contentBounds = _contentBounds;
@synthesize contentSize   = _contentSize;

@end



//////////////////////////////////////////////////////////////
#pragma mark - 
#pragma mark - Vertical strategy implementation
//////////////////////////////////////////////////////////////

@implementation GMGridViewLayoutVerticalStrategy

@synthesize numberOfItemsPerRow = _numberOfItemsPerRow;

- (id)init
{
    if ((self = [super init])) 
    {
        _type = GMGridViewLayoutVertical;
    }
    
    return self;
}

- (void)rebaseWithItemCount:(NSInteger)count havingSize:(CGSize)itemSize andSpacing:(NSInteger)spacing insideOfBounds:(CGRect)bounds
{
    _itemCount     = count;
    _itemSize      = itemSize;
    _itemSpacing   = spacing;
    _contentBounds = bounds;
    
    _numberOfItemsPerRow = 1;
    
    while ((self.numberOfItemsPerRow + 1) * (self.itemSize.width + self.itemSpacing) - self.itemSpacing < self.contentBounds.size.width)
    {
        _numberOfItemsPerRow++;
    }
    
    NSInteger numberOfRows = ceil(self.itemCount / (1.0 * self.numberOfItemsPerRow));
    
    _contentSize = CGSizeMake(ceil(MIN(self.itemCount, self.numberOfItemsPerRow) * (self.itemSize.width + self.itemSpacing)) - self.itemSpacing, 
                              ceil(numberOfRows * (self.itemSize.height + self.itemSpacing)) - self.itemSpacing);
}

- (CGPoint)originForItemAtPosition:(NSInteger)position
{
    CGPoint origin = CGPointZero;
        
    if (self.numberOfItemsPerRow > 0 && position >= 0) 
    {
        NSUInteger col = position % self.numberOfItemsPerRow; 
        NSUInteger row = position / self.numberOfItemsPerRow;
        
        origin = CGPointMake(col * (self.itemSize.width + self.itemSpacing),
                             row * (self.itemSize.height + self.itemSpacing));
    }
    
    return origin;
}

- (NSInteger)itemPositionFromLocation:(CGPoint)location
{
    int col = (int) (location.x / (self.itemSize.width + self.itemSpacing)); 
    int row = (int) (location.y / (self.itemSize.height + self.itemSpacing));
    
    int position = col + row * self.numberOfItemsPerRow;
    
    if (position >= [self itemCount] || position < 0) 
    {
        position = GMGV_INVALID_POSITION;
    }
    else
    {
        CGPoint itemOrigin = [self originForItemAtPosition:position];
        CGRect itemFrame = CGRectMake(itemOrigin.x, 
                                      itemOrigin.y, 
                                      self.itemSize.width, 
                                      self.itemSize.height);
        
        if (!CGRectContainsPoint(itemFrame, location)) 
        {
            position = GMGV_INVALID_POSITION;
        }
    }
    
    return position;
}

- (NSRange)rangeOfPositionsInBoundsFromOffset:(CGPoint)offset
{
    CGPoint contentOffset = CGPointMake(MAX(0, offset.x), 
                                        MAX(0, offset.y));
    
    CGFloat itemHeight = self.itemSize.height + self.itemSpacing;
    
    CGFloat firstRow = (int)(contentOffset.y / itemHeight);

    CGFloat lastRow = ceil((contentOffset.y + self.contentBounds.size.height) / itemHeight);
    
    NSInteger firstPosition = firstRow * self.numberOfItemsPerRow;
    NSInteger lastPosition  = ((lastRow + 1) * self.numberOfItemsPerRow);
    
    return NSMakeRange(firstPosition, (lastPosition - firstPosition));
}

@end


//////////////////////////////////////////////////////////////
#pragma mark - 
#pragma mark - Horizontal strategy implementation
//////////////////////////////////////////////////////////////

@implementation GMGridViewLayoutHorizontalStrategy

@synthesize numberOfItemsPerColumn = _numberOfItemsPerColumn;

- (id)init
{
    if ((self = [super init])) 
    {
        _type = GMGridViewLayoutHorizontal;
    }
    
    return self;
}

- (void)rebaseWithItemCount:(NSInteger)count havingSize:(CGSize)itemSize andSpacing:(NSInteger)spacing insideOfBounds:(CGRect)bounds
{
    _itemCount     = count;
    _itemSize      = itemSize;
    _itemSpacing   = spacing;
    _contentBounds = bounds;
    
    _numberOfItemsPerColumn = 1;
    
    while ((_numberOfItemsPerColumn + 1) * (self.itemSize.height + self.itemSpacing) - self.itemSpacing < self.contentBounds.size.height)
    {
        _numberOfItemsPerColumn++;
    }
    
    NSInteger numberOfColumns = ceil(self.itemCount / (1.0 * self.numberOfItemsPerColumn));
            
    _contentSize = CGSizeMake(ceil(numberOfColumns * (self.itemSize.width + self.itemSpacing)) - self.itemSpacing, 
                              ceil(MIN(self.itemCount, self.numberOfItemsPerColumn) * (self.itemSize.height + self.itemSpacing)) - self.itemSpacing);
}

- (CGPoint)originForItemAtPosition:(NSInteger)position
{
    CGPoint origin = CGPointZero;
    
    if (self.numberOfItemsPerColumn > 0 && position >= 0) 
    {
        NSUInteger col = position / self.numberOfItemsPerColumn; 
        NSUInteger row = position % self.numberOfItemsPerColumn;
        
        origin = CGPointMake(col * (self.itemSize.width + self.itemSpacing),
                             row * (self.itemSize.height + self.itemSpacing));
    }
    
    return origin;
}

- (NSInteger)itemPositionFromLocation:(CGPoint)location
{
    int col = (int) (location.x / (self.itemSize.width + self.itemSpacing)); 
    int row = (int) (location.y / (self.itemSize.height + self.itemSpacing));
    
    int position = row + col * self.numberOfItemsPerColumn;
    
    if (position >= [self itemCount] || position < 0) 
    {
        position = GMGV_INVALID_POSITION;
    }
    else
    {
        CGPoint itemOrigin = [self originForItemAtPosition:position];
        CGRect itemFrame = CGRectMake(itemOrigin.x, 
                                      itemOrigin.y, 
                                      self.itemSize.width, 
                                      self.itemSize.height);
        
        if (!CGRectContainsPoint(itemFrame, location)) 
        {
            position = GMGV_INVALID_POSITION;
        }
    }
    
    return position;
}

- (NSRange)rangeOfPositionsInBoundsFromOffset:(CGPoint)offset
{
    CGPoint contentOffset = CGPointMake(MAX(0, offset.x), 
                                        MAX(0, offset.y));
    
    CGFloat itemWidth = self.itemSize.width + self.itemSpacing;
    
    CGFloat firstCol = (int)(contentOffset.x / itemWidth);
    
    CGFloat lastCol = ceil((contentOffset.x + self.contentBounds.size.width) / itemWidth);
    
    NSInteger firstPosition = firstCol * self.numberOfItemsPerColumn;
    NSInteger lastPosition  = ((lastCol + 1) * self.numberOfItemsPerColumn);
    
    return NSMakeRange(firstPosition, (lastPosition - firstPosition));
}

@end










