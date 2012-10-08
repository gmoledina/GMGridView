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
            strategy = [[GMGridViewLayoutHorizontalStrategy alloc] init];
            break;
        case GMGridViewLayoutHorizontalPagedLTR:
            strategy = [[GMGridViewLayoutHorizontalPagedLTRStrategy alloc] init];
            break;
        case GMGridViewLayoutHorizontalPagedTTB:
            strategy = [[GMGridViewLayoutHorizontalPagedTTBStrategy alloc] init];
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

@synthesize itemSize      = _itemSize;
@synthesize itemSpacing   = _itemSpacing;
@synthesize minEdgeInsets = _minEdgeInsets;
@synthesize centeredGrid  = _centeredGrid;

@synthesize itemCount     = _itemCount;
@synthesize edgeInsets    = _edgeInsets;
@synthesize gridBounds    = _gridBounds;
@synthesize contentSize   = _contentSize;


- (void)setupItemSize:(CGSize)itemSize andItemSpacing:(NSInteger)spacing withMinEdgeInsets:(UIEdgeInsets)edgeInsets andCenteredGrid:(BOOL)centered
{
    _itemSize      = itemSize;
    _itemSpacing   = spacing;
    _minEdgeInsets = edgeInsets;
    _centeredGrid  = centered;
}

- (void)setEdgeAndContentSizeFromAbsoluteContentSize:(CGSize)actualContentSize
{
    if (self.centeredGrid)
    {
        NSInteger widthSpace, heightSpace;        
        NSInteger top, left, bottom, right;
        
        widthSpace  = floor((self.gridBounds.size.width  - actualContentSize.width)  / 2.0);
        heightSpace = floor((self.gridBounds.size.height - actualContentSize.height) / 2.0);
        
        left   = MAX(widthSpace,  self.minEdgeInsets.left);
        right  = MAX(widthSpace,  self.minEdgeInsets.right);
        top    = MAX(heightSpace, self.minEdgeInsets.top);
        bottom = MAX(heightSpace, self.minEdgeInsets.bottom);
        
        _edgeInsets = UIEdgeInsetsMake(top, left, bottom, right);
    }
    else
    {
        _edgeInsets = self.minEdgeInsets;
    }
    
    _contentSize = CGSizeMake(actualContentSize.width  + self.edgeInsets.left + self.edgeInsets.right, 
                              actualContentSize.height + self.edgeInsets.top  + self.edgeInsets.bottom);
}

@end



//////////////////////////////////////////////////////////////
#pragma mark - 
#pragma mark - Vertical strategy implementation
//////////////////////////////////////////////////////////////

@implementation GMGridViewLayoutVerticalStrategy

@synthesize numberOfItemsPerRow = _numberOfItemsPerRow;

+ (BOOL)requiresEnablingPaging
{
    return NO;
}

- (id)init
{
    if ((self = [super init])) 
    {
        _type = GMGridViewLayoutVertical;
    }
    
    return self;
}

- (void)rebaseWithItemCount:(NSInteger)count insideOfBounds:(CGRect)bounds
{
    _itemCount  = count;
    _gridBounds = bounds;
    
    CGRect actualBounds = CGRectMake(0, 
                                     0, 
                                     bounds.size.width  - self.minEdgeInsets.right - self.minEdgeInsets.left, 
                                     bounds.size.height - self.minEdgeInsets.top   - self.minEdgeInsets.bottom);
    
    _numberOfItemsPerRow = 1;
    
    while ((self.numberOfItemsPerRow + 1) * (self.itemSize.width + self.itemSpacing) - self.itemSpacing <= actualBounds.size.width)
    {
        _numberOfItemsPerRow++;
    }
    
    NSInteger numberOfRows = ceil(self.itemCount / (1.0 * self.numberOfItemsPerRow));
    
    CGSize actualContentSize = CGSizeMake(ceil(MIN(self.itemCount, self.numberOfItemsPerRow) * (self.itemSize.width + self.itemSpacing)) - self.itemSpacing, 
                               ceil(numberOfRows * (self.itemSize.height + self.itemSpacing)) - self.itemSpacing);
    
    [self setEdgeAndContentSizeFromAbsoluteContentSize:actualContentSize];
}

- (CGPoint)originForItemAtPosition:(NSInteger)position
{
    CGPoint origin = CGPointZero;
        
    if (self.numberOfItemsPerRow > 0 && position >= 0) 
    {
        NSUInteger col = position % self.numberOfItemsPerRow; 
        NSUInteger row = position / self.numberOfItemsPerRow;
        
        origin = CGPointMake(col * (self.itemSize.width + self.itemSpacing) + self.edgeInsets.left,
                             row * (self.itemSize.height + self.itemSpacing) + self.edgeInsets.top);
    }
    
    return origin;
}

- (NSInteger)itemPositionFromLocation:(CGPoint)location
{
    CGPoint relativeLocation = CGPointMake(location.x - self.edgeInsets.left,
                                           location.y - self.edgeInsets.top);
    
    int col = (int) (relativeLocation.x / (self.itemSize.width + self.itemSpacing)); 
    int row = (int) (relativeLocation.y / (self.itemSize.height + self.itemSpacing));
    
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
    
    CGFloat firstRow = MAX(0, (int)(contentOffset.y / itemHeight) - 1);

    CGFloat lastRow = ceil((contentOffset.y + self.gridBounds.size.height) / itemHeight);
    
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

+ (BOOL)requiresEnablingPaging
{
    return NO;
}

- (id)init
{
    if ((self = [super init])) 
    {
        _type = GMGridViewLayoutHorizontal;
    }
    
    return self;
}

- (void)rebaseWithItemCount:(NSInteger)count insideOfBounds:(CGRect)bounds
{
    _itemCount  = count;
    _gridBounds = bounds;
    
    CGRect actualBounds = CGRectMake(0, 
                                     0, 
                                     bounds.size.width  - self.minEdgeInsets.right - self.minEdgeInsets.left, 
                                     bounds.size.height - self.minEdgeInsets.top   - self.minEdgeInsets.bottom);
    
    _numberOfItemsPerColumn = 1;
    
    while ((_numberOfItemsPerColumn + 1) * (self.itemSize.height + self.itemSpacing) - self.itemSpacing <= actualBounds.size.height)
    {
        _numberOfItemsPerColumn++;
    }
    
    NSInteger numberOfColumns = ceil(self.itemCount / (1.0 * self.numberOfItemsPerColumn));
            
    CGSize actualContentSize = CGSizeMake(ceil(numberOfColumns * (self.itemSize.width + self.itemSpacing)) - self.itemSpacing, 
                               ceil(MIN(self.itemCount, self.numberOfItemsPerColumn) * (self.itemSize.height + self.itemSpacing)) - self.itemSpacing);
    
    [self setEdgeAndContentSizeFromAbsoluteContentSize:actualContentSize];
}

- (CGPoint)originForItemAtPosition:(NSInteger)position
{
    CGPoint origin = CGPointZero;
    
    if (self.numberOfItemsPerColumn > 0 && position >= 0) 
    {
        NSUInteger col = position / self.numberOfItemsPerColumn; 
        NSUInteger row = position % self.numberOfItemsPerColumn;
        
        origin = CGPointMake(col * (self.itemSize.width + self.itemSpacing) + self.edgeInsets.left,
                             row * (self.itemSize.height + self.itemSpacing) + self.edgeInsets.top);
    }
    
    return origin;
}

- (NSInteger)itemPositionFromLocation:(CGPoint)location
{
    CGPoint relativeLocation = CGPointMake(location.x - self.edgeInsets.left,
                                           location.y - self.edgeInsets.top);

    int col = (int) (relativeLocation.x / (self.itemSize.width + self.itemSpacing)); 
    int row = (int) (relativeLocation.y / (self.itemSize.height + self.itemSpacing));
    
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
    
    CGFloat firstCol = MAX(0, (int)(contentOffset.x / itemWidth) - 1);
    
    CGFloat lastCol = ceil((contentOffset.x + self.gridBounds.size.width) / itemWidth);
    
    NSInteger firstPosition = firstCol * self.numberOfItemsPerColumn;
    NSInteger lastPosition  = ((lastCol + 1) * self.numberOfItemsPerColumn);
    
    return NSMakeRange(firstPosition, (lastPosition - firstPosition));
}

@end



//////////////////////////////////////////////////////////////
#pragma mark - 
#pragma mark - HorizontalPaged strategy implementation
//////////////////////////////////////////////////////////////

@implementation GMGridViewLayoutHorizontalPagedStrategy

@synthesize numberOfItemsPerPage = _numberOfItemsPerPage;
@synthesize numberOfItemsPerRow  = _numberOfItemsPerRow;
@synthesize numberOfPages        = _numberOfPages;

+ (BOOL)requiresEnablingPaging
{
    return YES;
}

- (void)rebaseWithItemCount:(NSInteger)count insideOfBounds:(CGRect)bounds
{
    [super rebaseWithItemCount:count insideOfBounds:bounds];
    
    _numberOfItemsPerRow = 1;
    
    NSInteger gridContentMaxWidth = self.gridBounds.size.width - self.minEdgeInsets.right - self.minEdgeInsets.left;
    
    while ((self.numberOfItemsPerRow + 1) * (self.itemSize.width + self.itemSpacing) - self.itemSpacing <= gridContentMaxWidth)
    {
        _numberOfItemsPerRow++;
    }
    
    _numberOfItemsPerPage = _numberOfItemsPerRow * _numberOfItemsPerColumn;
    _numberOfPages = ceil(self.itemCount * 1.0 / self.numberOfItemsPerPage);
    
    CGSize onePageSize = CGSizeMake(self.numberOfItemsPerRow * (self.itemSize.width + self.itemSpacing) - self.itemSpacing, 
                                    self.numberOfItemsPerColumn * (self.itemSize.height + self.itemSpacing) - self.itemSpacing);
    
    if (self.centeredGrid)
    {
        NSInteger widthSpace, heightSpace;        
        NSInteger top, left, bottom, right;
        
        widthSpace  = floor((self.gridBounds.size.width  - onePageSize.width)  / 2.0);
        heightSpace = floor((self.gridBounds.size.height - onePageSize.height) / 2.0);
        
        left   = MAX(widthSpace,  self.minEdgeInsets.left);
        right  = MAX(widthSpace,  self.minEdgeInsets.right);
        top    = MAX(heightSpace, self.minEdgeInsets.top);
        bottom = MAX(heightSpace, self.minEdgeInsets.bottom);
        
        _edgeInsets = UIEdgeInsetsMake(top, left, bottom, right);
    }
    else
    {
        _edgeInsets = self.minEdgeInsets;
    }
    
    _contentSize = CGSizeMake(bounds.size.width * self.numberOfPages, 
                              bounds.size.height);
}

- (NSInteger)pageForItemAtIndex:(NSInteger)index
{    
    return MAX(0, floor(index * 1.0 / self.numberOfItemsPerPage * 1.0));
}

- (CGPoint)originForItemAtColumn:(NSInteger)column row:(NSInteger)row page:(NSInteger)page 
{
    CGPoint offset = CGPointMake(page * self.gridBounds.size.width, 
                                 0);
    
    CGFloat x = column * (self.itemSize.width + self.itemSpacing) + self.edgeInsets.left;
    CGFloat y = row * (self.itemSize.height + self.itemSpacing) + self.edgeInsets.top;
    
    return CGPointMake(x + offset.x, 
                       y + offset.y);
}

- (NSInteger)positionForItemAtColumn:(NSInteger)column row:(NSInteger)row page:(NSInteger)page
{
    return column + row * self.numberOfItemsPerRow + (page * self.numberOfItemsPerPage); 
}

- (NSInteger)columnForItemAtPosition:(NSInteger)position
{
    position %= self.numberOfItemsPerPage;
    return position % self.numberOfItemsPerRow;;
}

- (NSInteger)rowForItemAtPosition:(NSInteger)position
{
    position %= self.numberOfItemsPerPage;
    return floor(position / self.numberOfItemsPerRow);
}

- (CGPoint)originForItemAtPosition:(NSInteger)position
{
    NSUInteger page = [self pageForItemAtIndex:position];
    
    position %= self.numberOfItemsPerPage;
        
    NSUInteger row = [self rowForItemAtPosition:position];
    NSUInteger column = [self columnForItemAtPosition:position];
    
    CGPoint origin = [self originForItemAtColumn:column row:row page:page];
    
    return origin;
}

- (NSInteger)itemPositionFromLocation:(CGPoint)location
{
    CGFloat page = 0;
    while ((page + 1) * self.gridBounds.size.width < location.x) 
    {
        page++;
    }
    
    CGPoint originForFirstItemInPage = [self originForItemAtColumn:0 row:0 page:page];
    
    CGPoint relativeLocation = CGPointMake(location.x - originForFirstItemInPage.x,
                                           location.y - originForFirstItemInPage.y);

    int col = (int) (relativeLocation.x / (self.itemSize.width + self.itemSpacing)); 
    int row = (int) (relativeLocation.y / (self.itemSize.height + self.itemSpacing));
    
    int position = [self positionForItemAtColumn:col row:row page:page];
 
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
    
    NSInteger page = floor(contentOffset.x / self.gridBounds.size.width);
    
    NSInteger firstPosition = MAX(0, (page - 1) * self.numberOfItemsPerPage);
    NSInteger lastPosition  = MIN(firstPosition + 3 * self.numberOfItemsPerPage, self.itemCount);
    
    return NSMakeRange(firstPosition, (lastPosition - firstPosition));
}

@end


//////////////////////////////////////////////////////////////
#pragma mark - 
#pragma mark - HorizontalPagedLTR strategy implementation
//////////////////////////////////////////////////////////////

@implementation GMGridViewLayoutHorizontalPagedLTRStrategy

- (id)init
{
    if ((self = [super init])) 
    {
        _type = GMGridViewLayoutHorizontalPagedLTR;
    }
    
    return self;
}

// Nothing to change, LTR is already the behavior of the base class

@end


//////////////////////////////////////////////////////////////
#pragma mark - 
#pragma mark - HorizontalPagedRTL strategy implementation
//////////////////////////////////////////////////////////////

@implementation GMGridViewLayoutHorizontalPagedTTBStrategy

- (id)init
{
    if ((self = [super init])) 
    {
        _type = GMGridViewLayoutHorizontalPagedTTB;
    }
    
    return self;
}

- (NSInteger)positionForItemAtColumn:(NSInteger)column row:(NSInteger)row page:(NSInteger)page
{
    return row + column * self.numberOfItemsPerColumn + (page * self.numberOfItemsPerPage); 
}

- (NSInteger)columnForItemAtPosition:(NSInteger)position
{
    position %= self.numberOfItemsPerPage;
    return floor(position / self.numberOfItemsPerColumn);
}

- (NSInteger)rowForItemAtPosition:(NSInteger)position
{
    position %= self.numberOfItemsPerPage;
    return position % self.numberOfItemsPerColumn;
}

@end

