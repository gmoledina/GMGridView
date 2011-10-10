//
//  GMGridView.m
//  GMGridView
//
//  Created by Gulam Moledina on 11-10-09.
//  Copyright (c) 2011 GMoledina.ca. All rights reserved.
//

#import "GMGridView.h"

#define GMGV_POSITION_AND_TAG_OFFSET 50

//////////////////////////////////////////////////////////////
#pragma -
#pragma mark Private interface
//////////////////////////////////////////////////////////////

@interface GMGridView () <UIGestureRecognizerDelegate>
{
    // Views
    UIScrollView *m_scrollView;
    NSMutableOrderedSet *m_orderedSubviews;
    
    // Gestures
    UIPanGestureRecognizer *m_panGesture;
    UILongPressGestureRecognizer *m_longPressGesture;
    
    // General vars
    NSInteger m_numberOfItemsInRow;
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
- (NSInteger)itemPositionFromLocation:(CGPoint)location;


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
        m_orderedSubviews = [[NSMutableOrderedSet alloc] init];
        
        m_panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureUpdated:)];
        m_panGesture.delegate = self;
        [self addGestureRecognizer:m_panGesture];
        
        m_longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureUpdated:)];
        [self addGestureRecognizer:m_longPressGesture];
        
        m_scrollView = [[UIScrollView alloc] initWithFrame:frame];
        m_scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        m_scrollView.backgroundColor = [UIColor yellowColor];
        [m_scrollView.panGestureRecognizer requireGestureRecognizerToFail:m_panGesture];
        [self addSubview:m_scrollView];
        
        self.itemPadding = 10;
        self.style = DraggableGridViewStylePush;
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

- (void)setDataSource:(NSObject<DraggableGridViewDataSource> *)dataSource
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
                UIView *item = [m_scrollView viewWithTag:position];
                
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
    
    m_futurePosition = m_movingItem.tag;
        
    [self.delegate draggableView:self didStartMovingView:m_movingItem];
}

- (void)movingDidContinueToPoint:(CGPoint)point
{
    int position = [self itemPositionFromLocation:point];
        
    if (position >= 0 && position != m_futurePosition && (position - GMGV_POSITION_AND_TAG_OFFSET) < [m_orderedSubviews count]) 
    {
        BOOL positionTaken = NO;
        
        for (UIView *v in m_orderedSubviews)
        {
            if (v != m_movingItem && v.tag == position) 
            {
                positionTaken = YES;
                break;
            }
        }
        
        if (positionTaken)
        {
            switch (self.style) 
            {
                case DraggableGridViewStylePush:
                {
                    if (position > m_futurePosition) 
                    {
                        for (UIView *v in m_orderedSubviews)
                        {
                            if (v.tag == position || (v.tag < position && v.tag >= m_futurePosition)) 
                            {
                                v.tag = v.tag - 1;
                            }
                        }
                    }
                    else
                    {
                        for (UIView *v in m_orderedSubviews)
                        {
                            if (v.tag == position || (v.tag > position && v.tag <= m_futurePosition)) 
                            {
                                v.tag = v.tag + 1;
                            }
                        }
                    }
                    break;
                }
                case DraggableGridViewStyleSwap:
                default:
                {
                    UIView *v = [m_scrollView viewWithTag:position];
                    v.tag = m_futurePosition;
                    [self updateIndexOfItem:v toIndex:v.tag - GMGV_POSITION_AND_TAG_OFFSET];
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
    m_movingItem.tag = m_futurePosition;
    [self updateIndexOfItem:m_movingItem toIndex:m_movingItem.tag - GMGV_POSITION_AND_TAG_OFFSET];
    m_futurePosition = -1;
    
    [self.delegate draggableView:self didEndMovingView:m_movingItem];
    
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
    [m_orderedSubviews enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop){
        [(UIView *)obj removeFromSuperview];
    }];
    
    [m_orderedSubviews removeAllObjects];
    
    NSUInteger numberItems = [self.dataSource numberOfItemsInDraggableView:self];
    NSUInteger width       = [self.dataSource widthForItemsInDraggableView:self];
    NSUInteger height      = [self.dataSource heightForItemsInDraggableView:self];
    
    for (int i = 0; i < numberItems; i++) 
    {        
        UIView *itemView = [self.dataSource draggableView:self viewForItemAtIndex:i];
        itemView.frame = CGRectMake(0, 0, width, height);
        itemView.tag = i + GMGV_POSITION_AND_TAG_OFFSET;

        [m_scrollView addSubview:itemView];
        [m_orderedSubviews addObject:itemView];
    }
    
    m_itemSize = CGSizeMake(width, height);
    [self setNeedsLayout];
}

- (void)reloadObjectAtIndex:(NSInteger)index
{
    NSAssert((index >= 0 && index < [m_orderedSubviews count]), @"Invalid index");
    
    UIView *currentView = [m_orderedSubviews objectAtIndex:index];
    
    UIView *view = [self.dataSource draggableView:self viewForItemAtIndex:index];
    view.frame = currentView.frame;
    view.tag = currentView.tag;
    view.alpha = 0;
    [m_scrollView addSubview:view];
    
    [m_orderedSubviews replaceObjectAtIndex:index withObject:view];
    
    [UIView animateWithDuration:0.3 animations:^{
        currentView.alpha = 0;
        view.alpha = 1;
    } 
    completion:^(BOOL finished)
    {
         [currentView removeFromSuperview];
         [self setNeedsLayout];
    }];
}

- (void)insertObjectAtIndex:(NSInteger)index
{
    NSAssert((index >= 0 && index <= [m_orderedSubviews count]), @"Invalid index specified");
    
    UIView *view = [self.dataSource draggableView:self viewForItemAtIndex:index];
    view.frame = CGRectMake(-20, -20, m_itemSize.width, m_itemSize.height);
    view.tag = index + GMGV_POSITION_AND_TAG_OFFSET;
    
    for (int i = index; i < [m_orderedSubviews count]; i++) 
    {
        UIView *oldView = [m_orderedSubviews objectAtIndex:i];
        oldView.tag = oldView.tag + 1;
    }
    
    [m_orderedSubviews insertObject:view atIndex:index];
    [m_scrollView addSubview:view];
    [self setNeedsLayout];
}

- (void)removeObjectAtIndex:(NSInteger)index
{
    NSAssert((index >= 0 && index < [m_orderedSubviews count]), @"Invalid index specified");
    
    UIView *view = (UIView *)[m_orderedSubviews objectAtIndex:index];
    
    for (int i = index + 1; i < [m_orderedSubviews count]; i++) 
    {
        UIView *oldView = [m_orderedSubviews objectAtIndex:i];
        oldView.tag = oldView.tag - 1;
    }
    
    [m_orderedSubviews removeObjectAtIndex:index];
    
    [UIView animateWithDuration:0.2 delay:0 options:0 animations:^{
        view.alpha = 0;
    } 
    completion:^(BOOL finished)
    {
         [view removeFromSuperview];
         [self setNeedsLayout];
    }];
}

- (void)swapObjectAtIndex:(NSInteger)index1 withObjectAtIndex:(NSInteger)index2
{
    NSAssert((index1 >= 0 && index1 < [m_orderedSubviews count]), @"Invalid index1 specified");
    NSAssert((index2 >= 0 && index2 < [m_orderedSubviews count]), @"Invalid index2 specified");

    UIView *view1 = [m_orderedSubviews objectAtIndex:index1];
    UIView *view2 = [m_orderedSubviews objectAtIndex:index2];
    
    NSInteger tempTag = view1.tag;
    view1.tag = view2.tag;
    view2.tag = tempTag;
    
    [m_orderedSubviews exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
    [self setNeedsLayout];
}


//////////////////////////////////////////////////////////////
#pragma mark private methods
//////////////////////////////////////////////////////////////

- (void)updateIndexOfItem:(UIView *)view toIndex:(NSInteger)index
{
    NSUInteger oldIndex = [m_orderedSubviews indexOfObject:view];
    
    if (index >= 0 && oldIndex != index && oldIndex < [m_orderedSubviews count]) 
    {
        [m_orderedSubviews moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:oldIndex] toIndex:index];
        [self.delegate draggableView:self itemAtIndex:oldIndex movedToIndex:index];
    }
}

- (NSInteger)itemPositionFromLocation:(CGPoint)location
{
    int col = (int) (location.x / (m_itemSize.width + self.itemPadding)); 
    int row = (int) (location.y / (m_itemSize.height + self.itemPadding));
    
    int position = col + row * m_numberOfItemsInRow;
    
    if (position >= [m_orderedSubviews count] || position < 0) 
    {
        position = -1;
    }
    else
    {
        position += GMGV_POSITION_AND_TAG_OFFSET;
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
    
    m_numberOfItemsInRow = itemsPerRow;
    int numberOfRowsInPage = ceil( [m_orderedSubviews count] / (1.0 * m_numberOfItemsInRow));
    
    [UIView animateWithDuration:0.3 delay:0
                        options:UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         
                         for (UIView *view in m_orderedSubviews)
                         {        
                             if (view != m_movingItem) 
                             {
                                 NSInteger index = view.tag - GMGV_POSITION_AND_TAG_OFFSET;
                                 
                                 NSUInteger col = index % m_numberOfItemsInRow;
                                 NSUInteger row = index / m_numberOfItemsInRow;
                                 
                                 CGFloat originX = col * (m_itemSize.width + self.itemPadding) + self.itemPadding;
                                 CGFloat originY = row * (m_itemSize.height + self.itemPadding) + self.itemPadding;
                                 
                                 
                                 view.frame = CGRectMake(originX, originY, m_itemSize.width, m_itemSize.height);
                             }
                         }
                     }
                     completion:^(BOOL finished) {
                         
                     }];
    
    return CGSizeMake(self.bounds.size.width, ceil(numberOfRowsInPage * (m_itemSize.height + self.itemPadding) + self.itemPadding));
}


@end
