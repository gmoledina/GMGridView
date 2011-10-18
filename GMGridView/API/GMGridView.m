//
//  GMGridView.m
//  GMGridView
//
//  Created by Gulam Moledina on 11-10-09.
//  Copyright (C) 2011 by Gulam Moledina.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "GMGridView.h"

#define GMGV_TAG_OFFSET 50

//////////////////////////////////////////////////////////////
#pragma -
#pragma mark Private interface
//////////////////////////////////////////////////////////////

@interface GMGridView () <UIGestureRecognizerDelegate>
{
    // Views
    UIScrollView *m_scrollView;
    
    // Gestures
    UIPanGestureRecognizer *m_panGesture;
    UILongPressGestureRecognizer *m_longPressGesture;
    
    // General vars
    NSInteger m_numberOfItemsPerRow;
    NSInteger m_numberTotalItems;
    CGSize m_itemSize;
    
    // Moving control vars
    UIView *m_movingItem;
    NSInteger m_futurePosition;
    CGPoint m_movingItemStartingPoint;
}

// Gestures
- (void)panGestureUpdated:(UIPanGestureRecognizer *)panGesture;
- (void)longPressGestureUpdated:(UILongPressGestureRecognizer *)longPressGesture;

// Movement control
- (void)movingDidStartAtPoint:(CGPoint)point;
- (void)movingDidContinueToPoint:(CGPoint)point;
- (void)movingDidStopAtPoint:(CGPoint)point;
- (void)updateIndexOfItem:(UIView *)view toIndex:(NSInteger)index;

// Helpers & more
- (CGSize)relayoutItems;
- (CGPoint)originForItemAtPosition:(NSInteger)position;
- (NSInteger)itemPositionFromLocation:(CGPoint)location;
- (NSArray *)itemSubviews;
- (UIView *)itemSubViewForPosition:(NSInteger)position;
- (NSInteger)positionForItemSubview:(UIView *)view;

@end




//////////////////////////////////////////////////////////////
#pragma -
#pragma mark Implementation
//////////////////////////////////////////////////////////////

@implementation GMGridView

@synthesize delegate = mw_delegate, dataSource = mw_dataSource;
@synthesize itemPadding = m_itemPadding;
@synthesize style = m_style;
@synthesize minimumPressDuration;

//////////////////////////////////////////////////////////////
#pragma mark Constructors and destructor
//////////////////////////////////////////////////////////////

- (id)init
{
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) 
    {        
        m_panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureUpdated:)];
        m_panGesture.delegate = self;
        [self addGestureRecognizer:m_panGesture];
        
        m_longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureUpdated:)];
        [self addGestureRecognizer:m_longPressGesture];
        
        m_scrollView = [[UIScrollView alloc] initWithFrame:frame];
        m_scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        m_scrollView.backgroundColor = [UIColor clearColor];
        [m_scrollView.panGestureRecognizer requireGestureRecognizerToFail:m_panGesture];
        [self addSubview:m_scrollView];
        
        self.itemPadding = 10;
        self.style = GMGridViewStylePush;
        self.minimumPressDuration = 0.2;
        
        m_futurePosition = -1;
        m_itemSize = CGSizeZero;
    }
    return self;
}


//////////////////////////////////////////////////////////////
#pragma mark Layout
//////////////////////////////////////////////////////////////

- (void)layoutSubviews 
{
    [super layoutSubviews];
    
    m_scrollView.contentSize = [self relayoutItems];
    [m_scrollView flashScrollIndicators];
}


//////////////////////////////////////////////////////////////
#pragma mark Custom drawing
//////////////////////////////////////////////////////////////

//- (void)drawRect:(CGRect)rect {
//    // Drawing code
//}


//////////////////////////////////////////////////////////////
#pragma mark Setters / getters
//////////////////////////////////////////////////////////////

- (void)setDataSource:(NSObject<GMGridViewDataSource> *)dataSource
{
    mw_dataSource = dataSource;
    [self reloadData];
}

- (void)setItemPadding:(NSInteger)itemPadding
{
    m_itemPadding = itemPadding;
    [self setNeedsLayout];
}

- (void)setMinimumPressDuration:(CFTimeInterval)duration
{
    m_longPressGesture.minimumPressDuration = duration;
}

- (CFTimeInterval)minimumPressDuration
{
    return m_longPressGesture.minimumPressDuration;
}

//////////////////////////////////////////////////////////////
#pragma mark GestureRecognizer delegate
//////////////////////////////////////////////////////////////

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)longPressGestureUpdated:(UILongPressGestureRecognizer *)longPressGesture
{
    switch (longPressGesture.state) 
    {
        case UIGestureRecognizerStateBegan:
        {
            CGPoint location = [longPressGesture locationInView:m_scrollView];
            
            NSInteger position = [self itemPositionFromLocation:location];
            
            if (position >= 0) 
            {
                UIView *item = [m_scrollView viewWithTag:position+GMGV_TAG_OFFSET];
                
                if (CGRectContainsPoint(item.frame, location)) 
                {                    
                    [m_scrollView bringSubviewToFront:item];
                    m_movingItem = item;
                    
                    [self movingDidStartAtPoint:location];
                }
            }
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            if (m_movingItem) 
            {                
                CGPoint location = [longPressGesture locationInView:m_scrollView];
                [self movingDidStopAtPoint:location];
                m_movingItem = nil;
            }
            break;
        }
        
        default:
            break;
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return (m_movingItem != nil);
}

- (void)panGestureUpdated:(UIPanGestureRecognizer *)panGesture
{
    switch (panGesture.state) 
    {
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            m_movingItemStartingPoint = CGPointZero;
            break;
        }
        case UIGestureRecognizerStateBegan:
        {
            m_movingItemStartingPoint = [panGesture locationInView:m_scrollView];

            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [panGesture translationInView:m_scrollView];
            CGPoint offset = translation;
            
            m_movingItem.transform = CGAffineTransformMakeTranslation(offset.x, offset.y);
            [self movingDidContinueToPoint:[panGesture locationInView:m_scrollView]];

            break;
        }
        default:
            break;
    }
}


//////////////////////////////////////////////////////////////
#pragma mark Privates Movement control
//////////////////////////////////////////////////////////////

- (void)movingDidStartAtPoint:(CGPoint)point
{
    [self bringSubviewToFront:m_movingItem];
    
    m_futurePosition = m_movingItem.tag - GMGV_TAG_OFFSET;
        
    [self.delegate GMGridView:self didStartMovingView:m_movingItem];
}

- (void)movingDidContinueToPoint:(CGPoint)point
{
    int position = [self itemPositionFromLocation:point];
    int tag = position + GMGV_TAG_OFFSET;
    
    if (position >= 0 && position != m_futurePosition && position < m_numberTotalItems) 
    {
        BOOL positionTaken = NO;
        
        for (UIView *v in [self itemSubviews])
        {
            if (v != m_movingItem && v.tag == tag) 
            {
                positionTaken = YES;
                break;
            }
        }
        
        if (positionTaken)
        {
            switch (self.style) 
            {
                case GMGridViewStylePush:
                {
                    if (position > m_futurePosition) 
                    {
                        for (UIView *v in [self itemSubviews])
                        {
                            if (v.tag == tag || (v.tag < tag && v.tag >= m_futurePosition + GMGV_TAG_OFFSET)) 
                            {
                                v.tag = v.tag - 1;
                                [m_scrollView sendSubviewToBack:v];
                            }
                        }
                    }
                    else
                    {
                        for (UIView *v in [self itemSubviews])
                        {
                            if (v.tag == tag || (v.tag > tag && v.tag <= m_futurePosition + GMGV_TAG_OFFSET)) 
                            {
                                v.tag = v.tag + 1;
                                [m_scrollView sendSubviewToBack:v];
                            }
                        }
                    }
                    break;
                }
                case GMGridViewStyleSwap:
                default:
                {
                    UIView *v = [m_scrollView viewWithTag:tag];
                    v.tag = m_futurePosition + GMGV_TAG_OFFSET;
                    [m_scrollView sendSubviewToBack:v];
                    [self updateIndexOfItem:v toIndex:v.tag - GMGV_TAG_OFFSET];
                    break;
                }
            }
        }
        
        m_futurePosition = position;
        
        [self setNeedsLayout];
    }
}

- (void)movingDidStopAtPoint:(CGPoint)point
{
    m_movingItem.tag = m_futurePosition + GMGV_TAG_OFFSET;
    [self updateIndexOfItem:m_movingItem toIndex:m_movingItem.tag - GMGV_TAG_OFFSET];
    m_futurePosition = -1;
    
    [self.delegate GMGridView:self didEndMovingView:m_movingItem];
    
    [UIView animateWithDuration:0.2 animations:^() {
        m_movingItem.transform = CGAffineTransformIdentity;
        m_movingItem = nil;
        [self relayoutItems];
    }];
}


//////////////////////////////////////////////////////////////
#pragma mark public methods
//////////////////////////////////////////////////////////////

- (void)reloadData
{
    [[self itemSubviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop){
        [(UIView *)obj removeFromSuperview];
    }];
    
    //todo: clear lazy loaded
    
    NSUInteger numberItems = [self.dataSource numberOfItemsInGMGridView:self];
    NSUInteger width       = [self.dataSource widthForItemsInGMGridView:self];
    NSUInteger height      = [self.dataSource heightForItemsInGMGridView:self];
    
    for (int i = 0; i < numberItems; i++) 
    {        
        UIView *itemView = [self.dataSource GMGridView:self viewForItemAtIndex:i];
        itemView.frame = CGRectMake(0, 0, width, height);
        itemView.tag = i + GMGV_TAG_OFFSET;

        [m_scrollView addSubview:itemView];
    }
    
    m_itemSize = CGSizeMake(width, height);
    m_numberTotalItems = numberItems;
    [self setNeedsLayout];
}

- (void)reloadObjectAtIndex:(NSInteger)index
{
    NSAssert((index >= 0 && index < m_numberTotalItems), @"Invalid index");
    
    UIView *currentView = [self itemSubViewForPosition:index];
    
    UIView *view = [self.dataSource GMGridView:self viewForItemAtIndex:index];
    view.frame = currentView.frame;
    view.tag = currentView.tag;
    currentView.tag += m_numberTotalItems + 999;
    view.alpha = 0;
    [m_scrollView addSubview:view];
    
    //todo clear lazy loaded data
    
    [UIView animateWithDuration:0.3 delay:0 options:0 animations:^{
        currentView.alpha = 0;
        view.alpha = 1;
    } 
    completion:^(BOOL finished)
    {
         [currentView removeFromSuperview];
    }];
}

- (void)insertObjectAtIndex:(NSInteger)index
{
    NSAssert((index >= 0 && index <= m_numberTotalItems), @"Invalid index specified");
    
    UIView *view = [self.dataSource GMGridView:self viewForItemAtIndex:index];
    CGPoint origin = [self originForItemAtPosition:index];
    view.frame = CGRectMake(origin.x, origin.y, m_itemSize.width, m_itemSize.height);
    view.tag = index + GMGV_TAG_OFFSET;
    
    for (int i = index; i < m_numberTotalItems; i++)
    {
        UIView *oldView = [self itemSubViewForPosition:i];
        oldView.tag = oldView.tag + 1;
    }
    
    m_numberTotalItems++;
    [m_scrollView addSubview:view];
    [self setNeedsLayout];
}

- (void)removeObjectAtIndex:(NSInteger)index
{
    NSAssert((index >= 0 && index < m_numberTotalItems), @"Invalid index specified");
    
    UIView *view = [self itemSubViewForPosition:index];
    
    for (int i = index + 1; i < m_numberTotalItems; i++)
    {
        UIView *oldView = [self itemSubViewForPosition:i];
        oldView.tag = oldView.tag - 1;
    }
    
    [UIView animateWithDuration:0.2 delay:0 options:0 animations:^{
        view.alpha = 0;
    } 
    completion:^(BOOL finished)
    {
         [view removeFromSuperview];
         m_numberTotalItems--;
         [self setNeedsLayout];
    }];
}

- (void)swapObjectAtIndex:(NSInteger)index1 withObjectAtIndex:(NSInteger)index2
{
    NSAssert((index1 >= 0 && index1 < m_numberTotalItems), @"Invalid index1 specified");
    NSAssert((index2 >= 0 && index2 < m_numberTotalItems), @"Invalid index2 specified");

    UIView *view1 = [self itemSubViewForPosition:index1];
    UIView *view2 = [self itemSubViewForPosition:index2];
    
    NSInteger tempTag = view1.tag;
    view1.tag = view2.tag;
    view2.tag = tempTag;
    
    [self setNeedsLayout];
}


//////////////////////////////////////////////////////////////
#pragma mark private methods
//////////////////////////////////////////////////////////////

- (NSArray *)itemSubviews
{
    // TODO: optimize (lazy loading)
    
    NSMutableArray *itemSubViews = [[NSMutableArray alloc] initWithCapacity:m_numberTotalItems];
    
    for (UIView * v in [m_scrollView subviews]) 
    {
        if (v.tag >= GMGV_TAG_OFFSET) 
        {
            [itemSubViews addObject:v];
        }
    }
    
    return itemSubViews;
}

- (UIView *)itemSubViewForPosition:(NSInteger)position
{
    UIView *view = nil;
    
    for (UIView *v in [self itemSubviews]) 
    {
        if (v.tag == position + GMGV_TAG_OFFSET) 
        {
            view = v;
            break;
        }
    }
    
    return view;
}

- (NSInteger)positionForItemSubview:(UIView *)view
{
    NSInteger position = -1;
    
    for (UIView *v in [self itemSubviews]) 
    {
        if (v == view) 
        {
            position = v.tag - GMGV_TAG_OFFSET;
            break;
        }
    }
    
    return position;
}

- (CGPoint)originForItemAtPosition:(NSInteger)position
{
    NSUInteger col = position % m_numberOfItemsPerRow;
    NSUInteger row = position / m_numberOfItemsPerRow;
    
    CGFloat originX = col * (m_itemSize.width + self.itemPadding) + self.itemPadding;
    CGFloat originY = row * (m_itemSize.height + self.itemPadding) + self.itemPadding;
    
    return CGPointMake(originX, originY);
}


- (void)updateIndexOfItem:(UIView *)view toIndex:(NSInteger)index
{
    NSUInteger oldIndex = [self positionForItemSubview:view];
    
    if (index >= 0 && oldIndex != index && oldIndex < m_numberTotalItems) 
    {
        [self.delegate GMGridView:self itemAtIndex:oldIndex movedToIndex:index];
    }
}


- (NSInteger)itemPositionFromLocation:(CGPoint)location
{
    int col = (int) (location.x / (m_itemSize.width + self.itemPadding)); 
    int row = (int) (location.y / (m_itemSize.height + self.itemPadding));
    
    int position = col + row * m_numberOfItemsPerRow;
    
    if (position >= m_numberTotalItems || position < 0) 
    {
        position = -1;
    }
    
    return position;
}

- (CGSize)relayoutItems
{
    NSUInteger itemsPerRow = 1;
    
    while ((itemsPerRow+1) * (m_itemSize.width + self.itemPadding) + self.itemPadding < self.bounds.size.width)
    {
        itemsPerRow++;
    }
    
    m_numberOfItemsPerRow = itemsPerRow;
    int numberOfRowsInPage = ceil(m_numberTotalItems / (1.0 * m_numberOfItemsPerRow));
    
    [UIView animateWithDuration:0.3 delay:0
                        options:UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         
                         for (UIView *view in [self itemSubviews])
                         {        
                             if (view != m_movingItem) 
                             {
                                 NSInteger index = view.tag - GMGV_TAG_OFFSET;
                                 CGPoint origin = [self originForItemAtPosition:index];
                                 
                                 view.frame = CGRectMake(origin.x, origin.y, m_itemSize.width, m_itemSize.height);
                             }
                         }
                     }
                     completion:^(BOOL finished) {
                         
                     }];
    
    return CGSizeMake(self.bounds.size.width, ceil(numberOfRowsInPage * (m_itemSize.height + self.itemPadding) + self.itemPadding));
}




@end
