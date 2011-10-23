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

#import <Quartzcore/QuartzCore.h>
#import "GMGridView.h"
#import "GMGridViewCell.h"


#define GMGV_TAG_OFFSET 50
#define GMGV_INVALID_POSITION -1


//////////////////////////////////////////////////////////////
#pragma -
#pragma mark Private interface
//////////////////////////////////////////////////////////////

@interface GMGridView () <UIGestureRecognizerDelegate>
{
    // Views
    UIScrollView *_scrollView;
    
    // Sorting Gestures
    UIPanGestureRecognizer       *_sortingPanGesture;
    UILongPressGestureRecognizer *_sortingLongPressGesture;
    
    // Moving gestures
    UIPinchGestureRecognizer     *_pinchGesture;
    UITapGestureRecognizer       *_tapGesture;
    UIRotationGestureRecognizer  *_rotationGesture;
    UIPanGestureRecognizer       *_panGesture;
    
    // General vars
    NSInteger _numberOfItemsPerRow;
    NSInteger _numberTotalItems;
    CGSize    _itemSize;
    
    // Moving (sorting) control vars
    GMGridViewCell *_sortMovingItem;
    NSInteger _sortFuturePosition;
    CGPoint _sortMovingItemStartingPoint;
    BOOL _autoScrollActive;
    
    // Transforming control vars
    GMGridViewCell *_transformingItem;
    CGFloat _lastRotation;
    CGFloat _lastScale;
}

// Gestures
- (void)sortingPanGestureUpdated:(UIPanGestureRecognizer *)panGesture;
- (void)sortingLongPressGestureUpdated:(UILongPressGestureRecognizer *)longPressGesture;
- (void)tagGestureUpdated:(UITapGestureRecognizer *)tapGesture;
- (void)panGestureUpdated:(UIPanGestureRecognizer *)panGesture;
- (void)pinchGestureUpdated:(UIPinchGestureRecognizer *)pinchGesture;
- (void)rotationGestureUpdated:(UIRotationGestureRecognizer *)rotationGesture;

// Sorting movement control
- (void)sortingMoveDidStartAtPoint:(CGPoint)point;
- (void)sortingMoveDidContinueToPoint:(CGPoint)point;
- (void)sortingMoveDidStopAtPoint:(CGPoint)point;
- (void)sortingAutoScrollMovementCheck;
- (void)updateIndexOfItem:(UIView *)view toIndex:(NSInteger)index;

// Transformation control
- (void)transformingGestureDidFinish;
- (BOOL)isInTransformingState;

// Helpers & more
- (CGSize)relayoutItems;
- (CGPoint)originForItemAtPosition:(NSInteger)position;
- (NSInteger)itemPositionFromLocation:(CGPoint)location;
- (NSArray *)itemSubviews;
- (GMGridViewCell *)itemSubViewForPosition:(NSInteger)position;
- (GMGridViewCell *)createItemSubViewForPosition:(NSInteger)position;
- (NSInteger)positionForItemSubview:(GMGridViewCell *)view;



@end




//////////////////////////////////////////////////////////////
#pragma -
#pragma mark Implementation
//////////////////////////////////////////////////////////////

@implementation GMGridView

@synthesize sortingDelegate = _sortingDelegate, dataSource = _dataSource, transformDelegate = _transformDelegate;
@synthesize itemPadding = _itemPadding;
@synthesize style = _style;
@synthesize minimumPressDuration;
@synthesize centerGrid;

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
        _scrollView = [[UIScrollView alloc] initWithFrame:frame];
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _scrollView.backgroundColor = [UIColor clearColor];
        [self addSubview:_scrollView];
        
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tagGestureUpdated:)];
        _tapGesture.delegate = self;
        _tapGesture.numberOfTapsRequired = 1;
        _tapGesture.numberOfTouchesRequired = 1;
        [_scrollView addGestureRecognizer:_tapGesture];
        
        _pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureUpdated:)];
        _pinchGesture.delegate = self;
        [_scrollView addGestureRecognizer:_pinchGesture];
        
        _rotationGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotationGestureUpdated:)];
        _rotationGesture.delegate = self;
        [_scrollView addGestureRecognizer:_rotationGesture];
        
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureUpdated:)];
        _panGesture.delegate = self;
        [_panGesture setMaximumNumberOfTouches:2];
        [_panGesture setMinimumNumberOfTouches:2];
        [_scrollView addGestureRecognizer:_panGesture];
        
        // Sorting gestures
        _sortingPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(sortingPanGestureUpdated:)];
        _sortingPanGesture.delegate = self;
        [_scrollView addGestureRecognizer:_sortingPanGesture];
        
        _sortingLongPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(sortingLongPressGestureUpdated:)];
        _sortingLongPressGesture.numberOfTouchesRequired = 1;
        [_scrollView addGestureRecognizer:_sortingLongPressGesture];

        // Gesture dependencies
        [_scrollView.panGestureRecognizer setMaximumNumberOfTouches:1];
        [_scrollView.panGestureRecognizer requireGestureRecognizerToFail:_sortingPanGesture];
        
        self.itemPadding = 10;
        self.style = GMGridViewStylePush;
        self.minimumPressDuration = 0.2;
        
        _sortFuturePosition = GMGV_INVALID_POSITION;
        _itemSize = CGSizeZero;
        
        _lastScale = 1.0;
        _lastRotation = 0.0;
    }
    return self;
}


//////////////////////////////////////////////////////////////
#pragma mark Layout
//////////////////////////////////////////////////////////////

- (void)layoutSubviews 
{
    [super layoutSubviews];
    
    _scrollView.contentSize = [self relayoutItems];
    [_scrollView flashScrollIndicators];
}


//////////////////////////////////////////////////////////////
#pragma mark Custom drawing
//////////////////////////////////////////////////////////////

//+ (Class)layerClass
//{
//    return [CATiledLayer class];
//}

//- (void)drawRect:(CGRect)rect 
//{
//}


//////////////////////////////////////////////////////////////
#pragma mark Setters / getters
//////////////////////////////////////////////////////////////

- (void)setDataSource:(NSObject<GMGridViewDataSource> *)dataSource
{
    _dataSource = dataSource;
    [self reloadData];
}

- (void)setItemPadding:(NSInteger)itemPadding
{
    _itemPadding = itemPadding;
    [self setNeedsLayout];
}

- (void)setMinimumPressDuration:(CFTimeInterval)duration
{
    _sortingLongPressGesture.minimumPressDuration = duration;
}

- (CFTimeInterval)minimumPressDuration
{
    return _sortingLongPressGesture.minimumPressDuration;
}

//////////////////////////////////////////////////////////////
#pragma mark GestureRecognizer delegate
//////////////////////////////////////////////////////////////

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{    
    BOOL valid = YES;
    
    if (gestureRecognizer == _tapGesture) 
    {
        CGPoint locationTouch = [_tapGesture locationInView:_scrollView];
        valid = [self itemPositionFromLocation:locationTouch] != GMGV_INVALID_POSITION;
    }
    else if (gestureRecognizer == _sortingPanGesture) 
    {
        valid = (_sortMovingItem != nil);
    }
    else if(gestureRecognizer == _rotationGesture || gestureRecognizer == _pinchGesture || gestureRecognizer == _panGesture)
    {
        if ([gestureRecognizer numberOfTouches] == 2) 
        {
            CGPoint locationTouch1 = [gestureRecognizer locationOfTouch:0 inView:_scrollView];
            CGPoint locationTouch2 = [gestureRecognizer locationOfTouch:1 inView:_scrollView];
            
            NSInteger positionTouch1 = [self itemPositionFromLocation:locationTouch1];
            NSInteger positionTouch2 = [self itemPositionFromLocation:locationTouch2];
            
            valid = [self isInTransformingState] || ((positionTouch1 == positionTouch2) && (positionTouch1 != GMGV_INVALID_POSITION));
        }
        else
        {
            valid = NO;
        }
    }
    
    return valid;
}

//////////////////////////////////////////////////////////////
#pragma mark Sorting gestures & logic
//////////////////////////////////////////////////////////////

- (void)sortingLongPressGestureUpdated:(UILongPressGestureRecognizer *)longPressGesture
{
    switch (longPressGesture.state) 
    {
        case UIGestureRecognizerStateBegan:
        {
            CGPoint location = [longPressGesture locationInView:_scrollView];
            
            NSInteger position = [self itemPositionFromLocation:location];
            
            if (position != GMGV_INVALID_POSITION) 
            {
                [self sortingMoveDidStartAtPoint:location];
            }
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            if (_sortMovingItem) 
            {                
                CGPoint location = [longPressGesture locationInView:_scrollView];
                [self sortingMoveDidStopAtPoint:location];
            }
            break;
        }
        
        default:
            break;
    }
}

- (void)sortingPanGestureUpdated:(UIPanGestureRecognizer *)panGesture
{
    switch (panGesture.state) 
    {
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            _autoScrollActive = NO;
            _sortMovingItemStartingPoint = CGPointZero;
            break;
        }
        case UIGestureRecognizerStateBegan:
        {
            _sortMovingItemStartingPoint = [panGesture locationInView:_scrollView];
            
            _autoScrollActive = YES;
            [self sortingAutoScrollMovementCheck];
            
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [panGesture translationInView:_scrollView];
            CGPoint offset = translation;
            CGPoint locationInScroll = [panGesture locationInView:_scrollView];
                        
            _sortMovingItem.transform = CGAffineTransformMakeTranslation(offset.x, offset.y);
            [self sortingMoveDidContinueToPoint:locationInScroll];
            
            break;
        }
        default:
            break;
    }
}



- (void)sortingAutoScrollMovementCheck
{    
    if (_sortMovingItem && _autoScrollActive) 
    {
        CGPoint locationInMainView = [_sortingPanGesture locationInView:self];
        CGPoint locationInScroll = [_sortingPanGesture locationInView:_scrollView];
        CGRect visibleRect = CGRectMake(_scrollView.contentOffset.x, 
                                        _scrollView.contentOffset.y, 
                                        _scrollView.bounds.size.width, 
                                        _scrollView.bounds.size.height);
        
        void (^completionBlock)(void) = ^{
            if (_autoScrollActive) 
            {
                [self sortingMoveDidContinueToPoint:locationInScroll];
            }
            
            [self sortingAutoScrollMovementCheck];
        };
        
        if (locationInMainView.y + _itemSize.height/2 > self.bounds.size.height) 
        {
            CGAffineTransform transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, _itemSize.height);
            
            CGRect newVisiblerect = CGRectApplyAffineTransform(visibleRect, transform);
            
            [UIView animateWithDuration:0.2 
                                  delay:0 
                                options:0 
                             animations:^{
                                 [_scrollView scrollRectToVisible:newVisiblerect animated:NO];
                             }
                             completion:^(BOOL finished){
                                 completionBlock();
                             }
             ];
        }
        else if (locationInMainView.y - _itemSize.height/2 <= 0) 
        {
            CGAffineTransform transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, -1 * _itemSize.height);
            
            CGRect newVisiblerect = CGRectApplyAffineTransform(visibleRect, transform);
            
            [UIView animateWithDuration:0.2 
                                  delay:0 
                                options:0 
                             animations:^{
                                 [_scrollView scrollRectToVisible:newVisiblerect animated:NO];
                             }
                             completion:^(BOOL finished){
                                 completionBlock();
                             }
             ];
        }
        else
        {
            [self performSelector:@selector(sortingAutoScrollMovementCheck) withObject:nil afterDelay:0.5];
        }
    }
}

//////////////////////////////////////////////////////////////
#pragma mark Transformation gestures & logic
//////////////////////////////////////////////////////////////

- (void)panGestureUpdated:(UIPanGestureRecognizer *)panGesture
{
    switch (panGesture.state) 
    {
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(transformingGestureDidFinish) object:nil];
            [self performSelector:@selector(transformingGestureDidFinish) withObject:nil afterDelay:0.1];
            
            _scrollView.scrollEnabled = YES;
            
            break;
        }
        case UIGestureRecognizerStateBegan:
        {
            if (!_transformingItem) 
            {
                CGPoint locationTouch = [_pinchGesture locationOfTouch:0 inView:_scrollView];            
                NSInteger positionTouch = [self itemPositionFromLocation:locationTouch];
                _transformingItem = [self itemSubViewForPosition:positionTouch];
                
                [_scrollView bringSubviewToFront:_transformingItem];
                [self.transformDelegate GMGridView:self didStartTransformingView:_transformingItem.contentView];
            }
            
            _scrollView.scrollEnabled = NO;
        }
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translate = [panGesture translationInView:_scrollView];
            [_transformingItem setCenter:CGPointMake(_transformingItem.center.x + translate.x, _transformingItem.center.y + translate.y)];
            [panGesture setTranslation:CGPointZero inView:_scrollView];
            break;
        }
        default:
        {
        }
    }
}

- (void)pinchGestureUpdated:(UIPinchGestureRecognizer *)pinchGesture
{    
    switch (pinchGesture.state) 
    {
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            _lastScale = 1.0;
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(transformingGestureDidFinish) object:nil];
            [self performSelector:@selector(transformingGestureDidFinish) withObject:nil afterDelay:0.1];
            
            break;
        }
        case UIGestureRecognizerStateBegan:
        {
            if (!_transformingItem) 
            {
                CGPoint locationTouch = [_pinchGesture locationOfTouch:0 inView:_scrollView];            
                NSInteger positionTouch = [self itemPositionFromLocation:locationTouch];
                _transformingItem = [self itemSubViewForPosition:positionTouch];
                
                [_scrollView bringSubviewToFront:_transformingItem];
                [self.transformDelegate GMGridView:self didStartTransformingView:_transformingItem.contentView];
            }
        }
        case UIGestureRecognizerStateChanged:
        default:
        {
            if ([_pinchGesture scale] >= 0.5 && [_pinchGesture scale] <= 3) 
            {
                CGFloat scale = ([_pinchGesture scale] - _lastScale) + 1;
                
                CGAffineTransform currentTransform = [_transformingItem transform];
                CGAffineTransform newTransform = CGAffineTransformScale(currentTransform, scale, scale);
                _transformingItem.transform = newTransform;
                
                _lastScale = [_pinchGesture scale];
            }
            
            break;
        }
    }
}

- (void)rotationGestureUpdated:(UIRotationGestureRecognizer *)rotationGesture
{
    switch (rotationGesture.state) 
    {
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            _lastRotation = 0;
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(transformingGestureDidFinish) object:nil];
            [self performSelector:@selector(transformingGestureDidFinish) withObject:nil afterDelay:0.1];
            
            break;
        }
        case UIGestureRecognizerStateBegan:
        {
            if (!_transformingItem) 
            {
                CGPoint locationTouch = [_rotationGesture locationOfTouch:0 inView:_scrollView];            
                NSInteger positionTouch = [self itemPositionFromLocation:locationTouch];
                _transformingItem = [self itemSubViewForPosition:positionTouch];
                
                [_scrollView bringSubviewToFront:_transformingItem];
                [self.transformDelegate GMGridView:self didStartTransformingView:_transformingItem.contentView];
            }
        }
        case UIGestureRecognizerStateChanged:
        default:
        {
            CGFloat rotation = [rotationGesture rotation] - _lastRotation;
            CGAffineTransform currentTransform = [_transformingItem transform];
            CGAffineTransform newTransform = CGAffineTransformRotate(currentTransform, rotation);
            _transformingItem.transform = newTransform;
            _lastRotation = [rotationGesture rotation];
            break;
        }
    }
}

- (void)tagGestureUpdated:(UITapGestureRecognizer *)tapGesture
{
    CGPoint locationTouch = [_tapGesture locationInView:_scrollView];
    NSInteger position = [self itemPositionFromLocation:locationTouch];
    
    if (position != GMGV_INVALID_POSITION) 
    {
        NSLog(@"Did tap at index %d", position);
    }
}

//////////////////////////////////////////////////////////////
#pragma mark Privates Movement control
//////////////////////////////////////////////////////////////

- (BOOL)isInTransformingState
{
    return _transformingItem != nil;
}

- (void)transformingGestureDidFinish
{
    if ([self isInTransformingState]) 
    {
        GMGridViewCell *transformingView = _transformingItem;
        _transformingItem = nil;
        
        NSInteger position = [self positionForItemSubview:transformingView];
        CGPoint origin = [self originForItemAtPosition:position];
        
        [UIView animateWithDuration:0.3 
                         animations:^{
                             transformingView.transform = CGAffineTransformIdentity;
                             transformingView.frame = CGRectMake(origin.x, origin.y, _itemSize.width, _itemSize.height);
                         } 
                         completion:^(BOOL finished){
                             [self relayoutItems];
                             [self.transformDelegate GMGridView:self didEndTransformingView:transformingView.contentView inFullsize:NO];
                         }
         ];
    }
}

- (void)sortingMoveDidStartAtPoint:(CGPoint)point
{
    NSInteger position = [self itemPositionFromLocation:point];
    
    GMGridViewCell *item = (GMGridViewCell *)[_scrollView viewWithTag:position + GMGV_TAG_OFFSET];
    
    [_scrollView bringSubviewToFront:item];
    _sortMovingItem = item;
    
    
    CGRect frameInMainView = CGRectMake(_sortMovingItem.frame.origin.x - _scrollView.contentOffset.x, 
                                        _sortMovingItem.frame.origin.y - _scrollView.contentOffset.y, 
                                        _sortMovingItem.frame.size.width,
                                        _sortMovingItem.frame.size.height);
    
    [_sortMovingItem removeFromSuperview];
    _sortMovingItem.frame = frameInMainView;
    [self addSubview:_sortMovingItem];
    
    _sortFuturePosition = _sortMovingItem.tag - GMGV_TAG_OFFSET;
    
    [self.sortingDelegate GMGridView:self didStartMovingView:_sortMovingItem.contentView];
    
    if ([self.sortingDelegate GMGridView:self shouldAllowShakingBehaviorWhenMovingView:_sortMovingItem.contentView atIndex:position]) 
    {
        [_sortMovingItem shake:YES];
    }
}


- (void)sortingMoveDidStopAtPoint:(CGPoint)point
{
    [_sortMovingItem shake:NO];
    
    _sortMovingItem.tag = _sortFuturePosition + GMGV_TAG_OFFSET;
    
    
    CGPoint position = [self originForItemAtPosition:_sortFuturePosition];
    CGRect frameInScroll = CGRectMake(position.x, 
                                      position.y, 
                                      _sortMovingItem.frame.size.width,
                                      _sortMovingItem.frame.size.height);
    
    [_sortMovingItem removeFromSuperview];
    
    _sortMovingItem.frame = frameInScroll;
    [_scrollView addSubview:_sortMovingItem];
     
    
    
    [self updateIndexOfItem:_sortMovingItem toIndex:_sortFuturePosition];
    
    [UIView animateWithDuration:0.2 
                     animations:^{
                         _sortMovingItem.transform = CGAffineTransformIdentity;
                         _sortMovingItem.frame = frameInScroll;
                     }
                     completion:^(BOOL finished){
                         [self.sortingDelegate GMGridView:self didEndMovingView:_sortMovingItem.contentView];
                         _sortMovingItem = nil;
                         _sortFuturePosition = GMGV_INVALID_POSITION;
                         [self relayoutItems];
                     }
     ];
}


- (void)sortingMoveDidContinueToPoint:(CGPoint)point
{
    int position = [self itemPositionFromLocation:point];
    int tag = position + GMGV_TAG_OFFSET;
    
    if (position != GMGV_INVALID_POSITION && position != _sortFuturePosition && position < _numberTotalItems) 
    {
        BOOL positionTaken = NO;
        
        for (UIView *v in [self itemSubviews])
        {
            if (v != _sortMovingItem && v.tag == tag) 
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
                    if (position > _sortFuturePosition) 
                    {
                        for (UIView *v in [self itemSubviews])
                        {
                            if (v != _sortMovingItem && (v.tag == tag || (v.tag < tag && v.tag >= _sortFuturePosition + GMGV_TAG_OFFSET))) 
                            {
                                v.tag = v.tag - 1;
                                [_scrollView sendSubviewToBack:v];
                            }
                        }
                    }
                    else
                    {
                        for (UIView *v in [self itemSubviews])
                        {
                            if (v != _sortMovingItem && (v.tag == tag || (v.tag > tag && v.tag <= _sortFuturePosition + GMGV_TAG_OFFSET))) 
                            {
                                v.tag = v.tag + 1;
                                [_scrollView sendSubviewToBack:v];
                            }
                        }
                    }
                    break;
                }
                case GMGridViewStyleSwap:
                default:
                {
                    UIView *v = [_scrollView viewWithTag:tag];
                    v.tag = _sortFuturePosition + GMGV_TAG_OFFSET;
                    [_scrollView sendSubviewToBack:v];
                    [self updateIndexOfItem:v toIndex:v.tag - GMGV_TAG_OFFSET];
                    break;
                }
            }
        }
        
        _sortFuturePosition = position;
        
        [self setNeedsLayout];
    }
}


//////////////////////////////////////////////////////////////
#pragma mark public methods
//////////////////////////////////////////////////////////////

- (void)reloadData
{
    [[self itemSubviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop){
        [(UIView *)obj removeFromSuperview];
    }];
    
    NSUInteger numberItems = [self.dataSource numberOfItemsInGMGridView:self];
    NSUInteger width       = [self.dataSource widthForItemsInGMGridView:self];
    NSUInteger height      = [self.dataSource heightForItemsInGMGridView:self];
    
    _itemSize = CGSizeMake(width, height);
    _numberTotalItems = numberItems;
    
    for (int i = 0; i < numberItems; i++) 
    {        
        GMGridViewCell *cell = [self createItemSubViewForPosition:i];
        
        [_scrollView addSubview:cell];
    }
    
    [self setNeedsLayout];
}

- (void)reloadObjectAtIndex:(NSInteger)index
{
    NSAssert((index >= 0 && index < _numberTotalItems), @"Invalid index");
    
    UIView *currentView = [self itemSubViewForPosition:index];
    
    GMGridViewCell *cell = [self createItemSubViewForPosition:index];
    cell.frame = currentView.frame;
    cell.alpha = 0;
    [_scrollView addSubview:cell];
    
    
    [UIView animateWithDuration:0.3 
                          delay:0 
                        options:0 
                     animations:^{
                         currentView.alpha = 0;
                         cell.alpha = 1;
                     } 
                     completion:^(BOOL finished){
                        [currentView removeFromSuperview];
                     }
     ];
}

- (void)insertObjectAtIndex:(NSInteger)index
{
    NSAssert((index >= 0 && index <= _numberTotalItems), @"Invalid index specified");
    
    GMGridViewCell *cell = [self createItemSubViewForPosition:index];
    CGPoint origin = [self originForItemAtPosition:index];
    cell.frame = CGRectMake(origin.x, origin.y, _itemSize.width, _itemSize.height);
    
    for (int i = index; i < _numberTotalItems; i++)
    {
        UIView *oldView = [self itemSubViewForPosition:i];
        oldView.tag = oldView.tag + 1;
    }
    
    _numberTotalItems++;
    [_scrollView addSubview:cell];
    
    // instead of calling [self setNeedsLayout] so we can animate to the item even if it's at the bottom
    _scrollView.contentSize = [self relayoutItems];
    [_scrollView scrollRectToVisible:cell.frame animated:YES];
}

- (void)removeObjectAtIndex:(NSInteger)index
{
    NSAssert((index >= 0 && index < _numberTotalItems), @"Invalid index specified");
    
    GMGridViewCell *cell = [self itemSubViewForPosition:index];
    
    for (int i = index + 1; i < _numberTotalItems; i++)
    {
        GMGridViewCell *oldView = [self itemSubViewForPosition:i];
        oldView.tag = oldView.tag - 1;
    }
    
    [UIView animateWithDuration:0.2 
                          delay:0 
                        options:0 
                     animations:^{
                         cell.alpha = 0;
                     } 
                     completion:^(BOOL finished){
                         [cell removeFromSuperview];
                         _numberTotalItems--;
                         [self setNeedsLayout];
                     }
     ];
}

- (void)swapObjectAtIndex:(NSInteger)index1 withObjectAtIndex:(NSInteger)index2
{
    NSAssert((index1 >= 0 && index1 < _numberTotalItems), @"Invalid index1 specified");
    NSAssert((index2 >= 0 && index2 < _numberTotalItems), @"Invalid index2 specified");

    GMGridViewCell *view1 = [self itemSubViewForPosition:index1];
    GMGridViewCell *view2 = [self itemSubViewForPosition:index2];
    
    NSInteger tempTag = view1.tag;
    view1.tag = view2.tag;
    view2.tag = tempTag;
    
    [self setNeedsLayout];
}


//////////////////////////////////////////////////////////////
#pragma mark private methods
//////////////////////////////////////////////////////////////

- (GMGridViewCell *)createItemSubViewForPosition:(NSInteger)position
{
    UIView *contentView = [self.dataSource GMGridView:self viewForItemAtIndex:position];
    
    GMGridViewCell *cell = [[GMGridViewCell alloc] initContentView:contentView];
    cell.frame = CGRectMake(0, 0, _itemSize.width, _itemSize.height);
    cell.tag = position + GMGV_TAG_OFFSET;
    
    return cell;
}

- (NSArray *)itemSubviews
{    
    NSMutableArray *itemSubViews = [[NSMutableArray alloc] initWithCapacity:_numberTotalItems];
    
    for (UIView * v in [_scrollView subviews]) 
    {
        if (v.tag >= GMGV_TAG_OFFSET && [v isKindOfClass:[GMGridViewCell class]]) 
        {
            [itemSubViews addObject:v];
        }
    }
        
    return itemSubViews;
}

- (GMGridViewCell *)itemSubViewForPosition:(NSInteger)position
{
    GMGridViewCell *view = nil;
    
    for (GMGridViewCell *v in [self itemSubviews]) 
    {
        if (v.tag == position + GMGV_TAG_OFFSET) 
        {
            view = v;
            break;
        }
    }
    
    return view;
}

- (NSInteger)positionForItemSubview:(GMGridViewCell *)view
{
    NSInteger position = GMGV_INVALID_POSITION;
    
    for (GMGridViewCell *v in [self itemSubviews]) 
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
    NSUInteger col = position % _numberOfItemsPerRow;
    NSUInteger row = position / _numberOfItemsPerRow;
    
    CGFloat originX = col * (_itemSize.width + self.itemPadding) + self.itemPadding;
    CGFloat originY = row * (_itemSize.height + self.itemPadding) + self.itemPadding;
    
    return CGPointMake(originX, originY);
}


- (void)updateIndexOfItem:(GMGridViewCell *)view toIndex:(NSInteger)index
{
    NSUInteger oldIndex = [self positionForItemSubview:view];
    
    if (index >= 0 && oldIndex != index && oldIndex < _numberTotalItems) 
    {
        [self.dataSource GMGridView:self itemAtIndex:oldIndex movedToIndex:index];
    }
}


- (NSInteger)itemPositionFromLocation:(CGPoint)location
{
    int col = (int) (location.x / (_itemSize.width + self.itemPadding)); 
    int row = (int) (location.y / (_itemSize.height + self.itemPadding));
    
    int position = col + row * _numberOfItemsPerRow;
    
    if (position >= _numberTotalItems || position < 0) 
    {
        position = GMGV_INVALID_POSITION;
    }
    else
    {
        UIView *item = [_scrollView viewWithTag:position+GMGV_TAG_OFFSET];
        
        if (!CGRectContainsPoint(item.frame, location))
        {
            position = GMGV_INVALID_POSITION;
        }
    }
    
    return position;
}

- (CGSize)relayoutItems
{
    NSUInteger itemsPerRow = 1;
    
    while ((itemsPerRow+1) * (_itemSize.width + self.itemPadding) + self.itemPadding < self.bounds.size.width)
    {
        itemsPerRow++;
    }
    
    _numberOfItemsPerRow = itemsPerRow;
    int numberOfRowsInPage = ceil(_numberTotalItems / (1.0 * _numberOfItemsPerRow));
    
    if (self.centerGrid)
    {
        int extraSpace = self.bounds.size.width - (itemsPerRow * (_itemSize.width + self.itemPadding)) - self.itemPadding;
        extraSpace /= 2;
        _scrollView.contentInset = UIEdgeInsetsMake(0, extraSpace, 0, extraSpace);
    }
    else
    {
        _scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }
    
    
    [UIView animateWithDuration:0.3 
                          delay:0
                        options:UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         
                         for (UIView *view in [self itemSubviews])
                         {        
                             if (view != _sortMovingItem && view != _transformingItem) 
                             {
                                 NSInteger index = view.tag - GMGV_TAG_OFFSET;
                                 CGPoint origin = [self originForItemAtPosition:index];
                                 
                                 view.frame = CGRectMake(origin.x, origin.y, _itemSize.width, _itemSize.height);
                             }
                         }
                     }
                     completion:^(BOOL finished) {
                         
                     }];
    
    return CGSizeMake(self.bounds.size.width - _scrollView.contentInset.left - _scrollView.contentInset.right, 
                      ceil(numberOfRowsInPage * (_itemSize.height + self.itemPadding) + self.itemPadding));
}




@end
