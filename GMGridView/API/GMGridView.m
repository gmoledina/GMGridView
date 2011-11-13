//
//  GMGridView.m
//  GMGridView
//
//  Created by Gulam Moledina on 11-10-09.
//  Copyright (C) 2011 by Gulam Moledina.
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

#import <Quartzcore/QuartzCore.h>
#import "GMGridView.h"
#import "GMGridViewCell.h"
#import "GMGridViewLayoutStrategies.h"
#import "UIGestureRecognizer+GMGridViewAdditions.h"

static const NSUInteger kTagOffset = 50;
static const CGFloat kDefaultAnimationDuration = 0.3;
static const UIViewAnimationOptions kDefaultAnimationOptions = UIViewAnimationOptionBeginFromCurrentState;


//////////////////////////////////////////////////////////////
#pragma -
#pragma mark Private interface
//////////////////////////////////////////////////////////////

@interface GMGridView () <UIGestureRecognizerDelegate, UIScrollViewDelegate>
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
    NSInteger _numberTotalItems;
    CGSize    _itemSize;
    NSMutableSet *_reusableCells;
    
    // Moving (sorting) control vars
    GMGridViewCell *_sortMovingItem;
    NSInteger _sortFuturePosition;
    BOOL _autoScrollActive;
    
    CGPoint _minPossibleContentOffset;
    CGPoint _maxPossibleContentOffset;
    
    // Transforming control vars
    GMGridViewCell *_transformingItem;
    CGFloat _lastRotation;
    CGFloat _lastScale;
    BOOL _inFullSizeMode;
}

@property (nonatomic, readonly) BOOL itemsSubviewsCacheIsValid;
@property (nonatomic, strong) NSArray *itemSubviewsCache;
@property (nonatomic) NSInteger firstPositionLoaded;
@property (nonatomic) NSInteger lastPositionLoaded;


// Gestures
- (void)sortingPanGestureUpdated:(UIPanGestureRecognizer *)panGesture;
- (void)sortingLongPressGestureUpdated:(UILongPressGestureRecognizer *)longPressGesture;
- (void)tapGestureUpdated:(UITapGestureRecognizer *)tapGesture;
- (void)panGestureUpdated:(UIPanGestureRecognizer *)panGesture;
- (void)pinchGestureUpdated:(UIPinchGestureRecognizer *)pinchGesture;
- (void)rotationGestureUpdated:(UIRotationGestureRecognizer *)rotationGesture;

// Sorting movement control
- (void)sortingMoveDidStartAtPoint:(CGPoint)point;
- (void)sortingMoveDidContinueToPoint:(CGPoint)point;
- (void)sortingMoveDidStopAtPoint:(CGPoint)point;
- (void)sortingAutoScrollMovementCheck;

// Transformation control
- (void)transformingGestureDidBeginWithGesture:(UIGestureRecognizer *)gesture;
- (void)transformingGestureDidFinish;
- (BOOL)isInTransformingState;

// Helpers & more
- (void)recomputeSize;
- (void)relayoutItems;
- (NSArray *)itemSubviews;
- (GMGridViewCell *)itemSubViewForPosition:(NSInteger)position;
- (GMGridViewCell *)createItemSubViewForPosition:(NSInteger)position;
- (NSInteger)positionForItemSubview:(GMGridViewCell *)view;
- (void)setSubviewsCacheAsInvalid;

// Lazy loading
- (void)loadRequiredItems;
- (void)cleanupUnseenItems;
- (void)queueReusableCell:(GMGridViewCell *)cell;
- (GMGridViewCell *)dequeueReusableCell;

// Memory warning
- (void)receivedMemoryWarningNotification:(NSNotification *)notification;

@end



//////////////////////////////////////////////////////////////
#pragma -
#pragma mark Implementation
//////////////////////////////////////////////////////////////

@implementation GMGridView

@synthesize sortingDelegate = _sortingDelegate, dataSource = _dataSource, transformDelegate = _transformDelegate;
@synthesize mainSuperView = _mainSuperView;
@synthesize layoutStrategy = _layoutStrategy;
@synthesize itemSpacing = _itemSpacing;
@synthesize style = _style;
@synthesize minimumPressDuration;
@synthesize centerGrid = _centerGrid;
@synthesize minEdgeInsets = _minEdgeInsets;
@synthesize showFullSizeViewWithAlphaWhenTransforming;
@synthesize editing = _editing;

@synthesize itemsSubviewsCacheIsValid = _itemsSubviewsCacheIsValid;
@synthesize itemSubviewsCache;

@synthesize firstPositionLoaded = _firstPositionLoaded;
@synthesize lastPositionLoaded = _lastPositionLoaded;

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
        _scrollView.delegate = self;
        [self addSubview:_scrollView];
        
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureUpdated:)];
        _tapGesture.delegate = self;
        _tapGesture.numberOfTapsRequired = 1;
        _tapGesture.numberOfTouchesRequired = 1;
        [_scrollView addGestureRecognizer:_tapGesture];
        
        /////////////////////////////
        // Transformation gestures :
        
        _pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureUpdated:)];
        _pinchGesture.delegate = self;
        [self addGestureRecognizer:_pinchGesture];
        
        _rotationGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotationGestureUpdated:)];
        _rotationGesture.delegate = self;
        [self addGestureRecognizer:_rotationGesture];
        
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureUpdated:)];
        _panGesture.delegate = self;
        [_panGesture setMaximumNumberOfTouches:2];
        [_panGesture setMinimumNumberOfTouches:2];
        [self addGestureRecognizer:_panGesture];
        
        //////////////////////
        // Sorting gestures :
        
        _sortingPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(sortingPanGestureUpdated:)];
        _sortingPanGesture.delegate = self;
        [_scrollView addGestureRecognizer:_sortingPanGesture];
        
        _sortingLongPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(sortingLongPressGestureUpdated:)];
        _sortingLongPressGesture.numberOfTouchesRequired = 1;
        _sortingLongPressGesture.delegate = self;
        [_scrollView addGestureRecognizer:_sortingLongPressGesture];

        ////////////////////////
        // Gesture dependencies
        [_scrollView.panGestureRecognizer setMaximumNumberOfTouches:1];
        [_scrollView.panGestureRecognizer requireGestureRecognizerToFail:_sortingPanGesture];
        
        self.layoutStrategy = [GMGridViewLayoutStrategyFactory strategyFromType:GMGridViewLayoutVertical];
        
        self.mainSuperView = self;
        self.editing = NO;
        self.itemSpacing = 10;
        self.style = GMGridViewStyleSwap;
        self.minimumPressDuration = 0.2;
        self.showFullSizeViewWithAlphaWhenTransforming = YES;
        self.minEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
        self.clipsToBounds = NO;
        
        _sortFuturePosition = GMGV_INVALID_POSITION;
        _itemSize = CGSizeZero;
        
        _lastScale = 1.0;
        _lastRotation = 0.0;
        
        _minPossibleContentOffset = CGPointMake(0, 0);
        _maxPossibleContentOffset = CGPointMake(0, 0);
        
        _reusableCells = [[NSMutableSet alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedMemoryWarningNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

//////////////////////////////////////////////////////////////
#pragma mark Layout
//////////////////////////////////////////////////////////////

- (void)layoutSubviews 
{
    [super layoutSubviews];
    
    [self recomputeSize];
    [self relayoutItems];
    
    [_scrollView flashScrollIndicators];
}


//////////////////////////////////////////////////////////////
#pragma mark Setters / getters
//////////////////////////////////////////////////////////////

- (void)setDataSource:(NSObject<GMGridViewDataSource> *)dataSource
{
    _dataSource = dataSource;
    [self reloadData];
}

- (void)setMainSuperView:(UIView *)mainSuperView
{
    _mainSuperView = mainSuperView != nil ? mainSuperView : self;
}

- (void)setLayoutStrategy:(id<GMGridViewLayoutStrategy>)layoutStrategy
{
    _layoutStrategy = layoutStrategy;
    [self setNeedsLayout];
}

- (void)setItemSpacing:(NSInteger)itemSpacing
{
    _itemSpacing = itemSpacing;
    [self setNeedsLayout];
}

- (void)setCenterGrid:(BOOL)centerGrid
{
    _centerGrid = centerGrid;
    [self setNeedsLayout];
}

- (void)setMinEdgeInsets:(UIEdgeInsets)minEdgeInsets
{
    _minEdgeInsets = minEdgeInsets;
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

- (void)setEditing:(BOOL)editing
{
    if (![self isInTransformingState] 
        && ((self.isEditing && !editing) || (!self.isEditing && editing))) 
    {
        for (GMGridViewCell *cell in [self itemSubviews]) 
        {
            [cell setEditing:editing];
        }
        
        _editing = editing;
    }
}

//////////////////////////////////////////////////////////////
#pragma mark UIScrollView delegate
//////////////////////////////////////////////////////////////

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self performSelectorOnMainThread:@selector(loadRequiredItems) withObject:nil waitUntilDone:NO];
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
        valid = !self.isEditing && [self.layoutStrategy itemPositionFromLocation:locationTouch] != GMGV_INVALID_POSITION;
    }
    else if (gestureRecognizer == _sortingLongPressGesture)
    {
        valid = !self.isEditing && (self.sortingDelegate != nil);
    }
    else if (gestureRecognizer == _sortingPanGesture) 
    {
        valid = (_sortMovingItem != nil && [_sortingLongPressGesture hasRecognizedValidGesture]);
    }
    else if(gestureRecognizer == _rotationGesture || gestureRecognizer == _pinchGesture || gestureRecognizer == _panGesture)
    {
        if (self.transformDelegate != nil && [gestureRecognizer numberOfTouches] == 2) 
        {
            CGPoint locationTouch1 = [gestureRecognizer locationOfTouch:0 inView:_scrollView];
            CGPoint locationTouch2 = [gestureRecognizer locationOfTouch:1 inView:_scrollView];
            
            NSInteger positionTouch1 = [self.layoutStrategy itemPositionFromLocation:locationTouch1];
            NSInteger positionTouch2 = [self.layoutStrategy itemPositionFromLocation:locationTouch2];
            
            valid = !self.isEditing && ([self isInTransformingState] || ((positionTouch1 == positionTouch2) && (positionTouch1 != GMGV_INVALID_POSITION)));
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
            if (!_sortMovingItem) 
            { 
                CGPoint location = [longPressGesture locationInView:_scrollView];
                
                NSInteger position = [self.layoutStrategy itemPositionFromLocation:location];
                
                if (position != GMGV_INVALID_POSITION) 
                {
                    [self sortingMoveDidStartAtPoint:location];
                }
            }
            
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            [_sortingPanGesture end];
            
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
            break;
        }
        case UIGestureRecognizerStateBegan:
        {            
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
        CGPoint locationInScroll   = [_sortingPanGesture locationInView:_scrollView];

        CGFloat threshhold = _itemSize.height;
        CGPoint offset = _scrollView.contentOffset;
        
        // Going down
        if (locationInMainView.x + threshhold > self.bounds.size.width) 
        {            
            offset.x += _itemSize.width / 2;
            
            if (offset.x > _maxPossibleContentOffset.x) 
            {
                offset.x = _maxPossibleContentOffset.x;
            }
        }
        // Going up
        else if (locationInMainView.x - threshhold <= 0) 
        {            
            offset.x -= _itemSize.width / 2;
            
            if (offset.x < _minPossibleContentOffset.x) 
            {
                offset.x = _minPossibleContentOffset.x;
            }
        }
        
        // Going right
        if (locationInMainView.y + threshhold > self.bounds.size.height) 
        {            
            offset.y += _itemSize.height / 2;
            
            if (offset.y > _maxPossibleContentOffset.y) 
            {
                offset.y = _maxPossibleContentOffset.y;
            }
        }
        // Going left
        else if (locationInMainView.y - threshhold <= 0) 
        {            
            offset.y -= _itemSize.height / 2;
            
            if (offset.y < _minPossibleContentOffset.y) 
            {
                offset.y = _minPossibleContentOffset.y;
            }
        }
        
        if (offset.x != _scrollView.contentOffset.x || offset.y != _scrollView.contentOffset.y) 
        {
            [UIView animateWithDuration:kDefaultAnimationDuration 
                                  delay:0
                                options:kDefaultAnimationOptions | UIViewAnimationOptionAllowUserInteraction
                             animations:^{
                                 _scrollView.contentOffset = offset;
                             }
                             completion:^(BOOL finished){
                                 if (_autoScrollActive) 
                                 {
                                     [self sortingMoveDidContinueToPoint:locationInScroll];
                                 }
                                 
                                 [self sortingAutoScrollMovementCheck];
                             }
             ];
        }
        else
        {
            [self performSelector:@selector(sortingAutoScrollMovementCheck) withObject:nil afterDelay:0.5];
        }
    }
}

- (void)sortingMoveDidStartAtPoint:(CGPoint)point
{
    NSInteger position = [self.layoutStrategy itemPositionFromLocation:point];
    
    GMGridViewCell *item = [self itemSubViewForPosition:position];
    
    [_scrollView bringSubviewToFront:item];
    _sortMovingItem = item;
    
    CGRect frameInMainView = [_scrollView convertRect:_sortMovingItem.frame toView:self.mainSuperView];
    
    [_sortMovingItem removeFromSuperview];
    _sortMovingItem.frame = frameInMainView;
    [self.mainSuperView addSubview:_sortMovingItem];
    
    _sortFuturePosition = _sortMovingItem.tag - kTagOffset;
    _sortMovingItem.tag = 0;
    
    if ([self.sortingDelegate respondsToSelector:@selector(GMGridView:didStartMovingView:)])
    {
        [self.sortingDelegate GMGridView:self didStartMovingView:_sortMovingItem.contentView];
    }
    
    if ([self.sortingDelegate respondsToSelector:@selector(GMGridView:didStartMovingView:)]) 
    {
        [_sortMovingItem shake:[self.sortingDelegate GMGridView:self shouldAllowShakingBehaviorWhenMovingView:_sortMovingItem.contentView atIndex:position]];
    }
    else
    {
        [_sortMovingItem shake:YES];
    }
}

- (void)sortingMoveDidStopAtPoint:(CGPoint)point
{
    [_sortMovingItem shake:NO];
    
    _sortMovingItem.tag = _sortFuturePosition + kTagOffset;
    
    CGRect frameInScroll = [self.mainSuperView convertRect:_sortMovingItem.frame toView:_scrollView];
    
    [_sortMovingItem removeFromSuperview];
    _sortMovingItem.frame = frameInScroll;
    [_scrollView addSubview:_sortMovingItem];
    
    CGPoint newOrigin = [self.layoutStrategy originForItemAtPosition:_sortFuturePosition];
    CGRect newFrame = CGRectMake(newOrigin.x, newOrigin.y, _itemSize.width, _itemSize.height);
    
    [UIView animateWithDuration:kDefaultAnimationDuration 
                          delay:0
                        options:0
                     animations:^{
                         _sortMovingItem.transform = CGAffineTransformIdentity;
                         _sortMovingItem.frame = newFrame;
                     }
                     completion:^(BOOL finished){
                         if ([self.sortingDelegate respondsToSelector:@selector(GMGridView:didEndMovingView:)])
                         {
                             [self.sortingDelegate GMGridView:self didEndMovingView:_sortMovingItem.contentView];
                         }
                         
                         _sortMovingItem = nil;
                         _sortFuturePosition = GMGV_INVALID_POSITION;
                     }
     ];
}

- (void)sortingMoveDidContinueToPoint:(CGPoint)point
{
    int position = [self.layoutStrategy itemPositionFromLocation:point];
    int tag = position + kTagOffset;
    
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
                            if ((v.tag == tag || (v.tag < tag && v.tag >= _sortFuturePosition + kTagOffset)) && v != _sortMovingItem ) 
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
                            if ((v.tag == tag || (v.tag > tag && v.tag <= _sortFuturePosition + kTagOffset)) && v != _sortMovingItem) 
                            {
                                v.tag = v.tag + 1;
                                [_scrollView sendSubviewToBack:v];
                            }
                        }
                    }
                    
                    [self.sortingDelegate GMGridView:self moveItemAtIndex:_sortFuturePosition toIndex:position];
                    [self relayoutItems];
                    
                    break;
                }
                case GMGridViewStyleSwap:
                default:
                {
                    if (_sortMovingItem) 
                    {
                        UIView *v = [self itemSubViewForPosition:position];
                                                
                        v.tag = _sortFuturePosition + kTagOffset;
                        CGPoint origin = [self.layoutStrategy originForItemAtPosition:_sortFuturePosition];
                        
                        [UIView animateWithDuration:kDefaultAnimationDuration 
                                              delay:0
                                            options:kDefaultAnimationOptions
                                         animations:^{
                                             v.frame = CGRectMake(origin.x, origin.y, _itemSize.width, _itemSize.height);
                                         }
                                         completion:nil
                         ];
                    }
                    
                    [self.sortingDelegate GMGridView:self exchangeItemAtIndex:_sortFuturePosition withItemAtIndex:position];
                    
                    break;
                }
            }
        }
        
        _sortFuturePosition = position;
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
            [self transformingGestureDidBeginWithGesture:panGesture];
            _scrollView.scrollEnabled = NO;
            
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            if (panGesture.numberOfTouches != 2) 
            {
                [panGesture end];
            }
            
            CGPoint translate = [panGesture translationInView:_scrollView];
            [_transformingItem.contentView setCenter:CGPointMake(_transformingItem.contentView.center.x + translate.x, _transformingItem.contentView.center.y + translate.y)];
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
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(transformingGestureDidFinish) object:nil];
            [self performSelector:@selector(transformingGestureDidFinish) withObject:nil afterDelay:0.1];
            
            break;
        }
        case UIGestureRecognizerStateBegan:
        {
            [self transformingGestureDidBeginWithGesture:pinchGesture];
        }
        case UIGestureRecognizerStateChanged:
        {
            CGFloat currentScale = [[_transformingItem.contentView.layer valueForKeyPath:@"transform.scale"] floatValue];
            
            CGFloat scale = 1 - (_lastScale - [_pinchGesture scale]);
            
            //todo: compute these scale factors dynamically based on ratio of thumbnail/fullscreen sizes
            const CGFloat kMaxScale = 3;
            const CGFloat kMinScale = 0.5;
            
            scale = MIN(scale, kMaxScale / currentScale);
            scale = MAX(scale, kMinScale / currentScale);
            
            if (scale >= 0.5 && scale <= 3) 
            {
                CGAffineTransform currentTransform = [_transformingItem.contentView transform];
                CGAffineTransform newTransform = CGAffineTransformScale(currentTransform, scale, scale);
                _transformingItem.contentView.transform = newTransform;
                
                _lastScale = [_pinchGesture scale];
                
                currentScale += scale;
                                
                CGFloat alpha = 1 - (kMaxScale - currentScale);
                alpha = MAX(0, alpha);
                alpha = MIN(1, alpha);
                
                if (self.showFullSizeViewWithAlphaWhenTransforming && currentScale >= 1.5) 
                {
                    [_transformingItem stepToFullsizeWithAlpha:alpha];
                }
                
                _transformingItem.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:MIN(alpha, 0.9)];
            }
            
            break;
        }
        default:
        {
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
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(transformingGestureDidFinish) object:nil];
            [self performSelector:@selector(transformingGestureDidFinish) withObject:nil afterDelay:0.1];
            
            break;
        }
        case UIGestureRecognizerStateBegan:
        {
            [self transformingGestureDidBeginWithGesture:rotationGesture];
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            CGFloat rotation = [rotationGesture rotation] - _lastRotation;
            CGAffineTransform currentTransform = [_transformingItem.contentView transform];
            CGAffineTransform newTransform = CGAffineTransformRotate(currentTransform, rotation);
            _transformingItem.contentView.transform = newTransform;
            _lastRotation = [rotationGesture rotation];
            
            break;
        }
        default:
        {
        }
    }
}

- (void)transformingGestureDidBeginWithGesture:(UIGestureRecognizer *)gesture
{
    if (_inFullSizeMode && [gesture isKindOfClass:[UIPinchGestureRecognizer class]]) 
    {
        _pinchGesture.scale = 2.5;
    }
    
    if (_inFullSizeMode)
    {        
        _inFullSizeMode = NO;
                
        CGPoint center = _transformingItem.fullSizeView.center;
        
        [_transformingItem switchToFullSizeMode:NO];
        CGAffineTransform newTransform = CGAffineTransformMakeScale(2.5, 2.5);
        _transformingItem.contentView.transform = newTransform;
        _transformingItem.contentView.center = center;
    }
    else if (!_transformingItem) 
    {
        CGPoint locationTouch = [gesture locationOfTouch:0 inView:_scrollView];            
        NSInteger positionTouch = [self.layoutStrategy itemPositionFromLocation:locationTouch];
        _transformingItem = [self itemSubViewForPosition:positionTouch];
        
        CGRect frameInMainView = [_scrollView convertRect:_transformingItem.frame toView:self.mainSuperView];
        
        [_transformingItem removeFromSuperview];
        _transformingItem.frame = self.mainSuperView.bounds;
        _transformingItem.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _transformingItem.contentView.frame = frameInMainView;
        [self.mainSuperView addSubview:_transformingItem];
        [self.mainSuperView bringSubviewToFront:_transformingItem];
        
        _transformingItem.fullSize = [self.transformDelegate GMGridView:self sizeInFullSizeForView:_transformingItem.contentView];
        _transformingItem.fullSizeView = [self.transformDelegate GMGridView:self fullSizeViewForView:_transformingItem];
        
        if ([self.transformDelegate respondsToSelector:@selector(GMGridView:didStartTransformingView:)]) 
        {
            [self.transformDelegate GMGridView:self didStartTransformingView:_transformingItem.contentView];
        }
    }
}

- (BOOL)isInTransformingState
{
    return _transformingItem != nil;
}

- (void)transformingGestureDidFinish
{
    if ([self isInTransformingState]) 
    {
        if (_lastScale > 2 && !_inFullSizeMode) 
        {            
            _lastRotation = 0;
            _lastScale = 1;
            
            [self bringSubviewToFront:_transformingItem];
        
            CGFloat rotationValue = atan2f(_transformingItem.contentView.transform.b, _transformingItem.contentView.transform.a); 

            _transformingItem.contentView.transform = CGAffineTransformIdentity;

            [_transformingItem switchToFullSizeMode:YES];
            _transformingItem.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.9];
            
            _transformingItem.fullSizeView.transform =  CGAffineTransformMakeRotation(rotationValue);
            [UIView animateWithDuration:kDefaultAnimationDuration animations:^{
                _transformingItem.fullSizeView.transform = CGAffineTransformIdentity;
            }];
            
            _inFullSizeMode = YES;
            
            if ([self.transformDelegate respondsToSelector:@selector(GMGridView:didEnterFullSizeForView:)])
            {
                [self.transformDelegate GMGridView:self didEnterFullSizeForView:_transformingItem.contentView];
            }
            
            // Transfer the gestures on the fullscreen to make is they are accessible (depends on self.mainSuperView)
            [_transformingItem.fullSizeView addGestureRecognizer:_pinchGesture];
            [_transformingItem.fullSizeView addGestureRecognizer:_rotationGesture];
            [_transformingItem.fullSizeView addGestureRecognizer:_panGesture];
        }
        else if (!_inFullSizeMode)
        {
            _lastRotation = 0;
            _lastScale = 1.0;
            
            GMGridViewCell *transformingView = _transformingItem;
            _transformingItem = nil;
            
            NSInteger position = [self positionForItemSubview:transformingView];
            CGPoint origin = [self.layoutStrategy originForItemAtPosition:position];
            
            CGRect finalFrameInScroll = CGRectMake(origin.x, origin.y, _itemSize.width, _itemSize.height);
            CGRect finalFrameInSuperview = [_scrollView convertRect:finalFrameInScroll toView:self.mainSuperView];
            
            [transformingView switchToFullSizeMode:NO];
            transformingView.autoresizingMask = UIViewAutoresizingNone;
            
            [UIView animateWithDuration: kDefaultAnimationDuration
                                  delay:0
                                options: kDefaultAnimationOptions
                             animations:^{
                                 transformingView.contentView.transform = CGAffineTransformIdentity;
                                 transformingView.contentView.frame = finalFrameInSuperview;
                                 transformingView.backgroundColor = [UIColor clearColor];
                             } 
                             completion:^(BOOL finished){

                                 [transformingView removeFromSuperview];
                                 transformingView.frame = finalFrameInScroll;
                                 transformingView.contentView.frame = transformingView.bounds;
                                 [_scrollView addSubview:transformingView];
                                 
                                 transformingView.fullSizeView = nil;
                                 
                                 if ([self.transformDelegate respondsToSelector:@selector(GMGridView:didEndTransformingView:)])
                                 {
                                    [self.transformDelegate GMGridView:self didEndTransformingView:transformingView.contentView];
                                 }
                                 
                                 // Transfer the gestures back
                                 [self addGestureRecognizer:_pinchGesture];
                                 [self addGestureRecognizer:_rotationGesture];
                                 [self addGestureRecognizer:_panGesture];
                             }
             ];
        }
    }
}

//////////////////////////////////////////////////////////////
#pragma mark Tap
//////////////////////////////////////////////////////////////

- (void)tapGestureUpdated:(UITapGestureRecognizer *)tapGesture
{
    CGPoint locationTouch = [_tapGesture locationInView:_scrollView];
    NSInteger position = [self.layoutStrategy itemPositionFromLocation:locationTouch];
    
    if (position != GMGV_INVALID_POSITION) 
    {
        NSLog(@"Did tap at index %d", position); // todo
    }
}

//////////////////////////////////////////////////////////////
#pragma mark private methods
//////////////////////////////////////////////////////////////

- (void)setSubviewsCacheAsInvalid
{
    _itemsSubviewsCacheIsValid = NO;
}

- (GMGridViewCell *)createItemSubViewForPosition:(NSInteger)position
{
    UIView *contentView = [self.dataSource GMGridView:self viewForItemAtIndex:position];
    
    GMGridViewCell *cell = [self dequeueReusableCell];
    
    if (!cell) 
    {
        cell = [[GMGridViewCell alloc] initContentView:contentView];
        cell.deleteButtonIcon = [UIImage imageNamed:@"close_x.png"];
        cell.deleteButtonOffset = CGPointMake(-15, -15);
        cell.deleteBlock = ^(GMGridViewCell *cell)
        {
            NSInteger index = [self positionForItemSubview:cell];
            if (index != GMGV_INVALID_POSITION) 
            {
                [self removeObjectAtIndex:index];
                //todo: tell the delegate !!!!
            }
        };
    }
    else
    {
        cell.contentView = contentView;
    }
    
    CGPoint origin = [self.layoutStrategy originForItemAtPosition:position];
    
    cell.frame = CGRectMake(origin.x, origin.y, _itemSize.width, _itemSize.height);
    cell.tag = position + kTagOffset;
    cell.editing = self.editing;
    
    return cell;
}

- (NSArray *)itemSubviews
{
    NSArray *subviews = nil;
    
    if (self.itemsSubviewsCacheIsValid) 
    {
        subviews = [self.itemSubviewsCache copy];
    }
    else
    {
        NSMutableArray *itemSubViews = [[NSMutableArray alloc] initWithCapacity:_numberTotalItems];
        
        for (UIView * v in [_scrollView subviews]) 
        {
            if ([v isKindOfClass:[GMGridViewCell class]]) 
            {
                [itemSubViews addObject:v];
            }
        }
        
        subviews = itemSubViews;
        
        self.itemSubviewsCache = [subviews copy];
        _itemsSubviewsCacheIsValid = YES;
    }
    
    return subviews;
}

- (GMGridViewCell *)itemSubViewForPosition:(NSInteger)position
{
    GMGridViewCell *view = nil;
    
    for (GMGridViewCell *v in [self itemSubviews]) 
    {
        if (v.tag == position + kTagOffset) 
        {
            view = v;
            break;
        }
    }
    
    return view;
}

- (NSInteger)positionForItemSubview:(GMGridViewCell *)view
{
    return view.tag >= kTagOffset ? view.tag - kTagOffset : GMGV_INVALID_POSITION;
}

- (void)recomputeSize
{
    CGRect actualBounds = CGRectMake(0, 
                                     0, 
                                     self.bounds.size.width  - self.minEdgeInsets.right - self.minEdgeInsets.left, 
                                     self.bounds.size.height - self.minEdgeInsets.top   - self.minEdgeInsets.bottom);
    
    [self.layoutStrategy rebaseWithItemCount:_numberTotalItems havingSize:_itemSize andSpacing:self.itemSpacing insideOfBounds:actualBounds];
    
    _scrollView.contentSize = [self.layoutStrategy contentSize];
    
    if (self.centerGrid)
    {
        NSInteger widthSpace, heightSpace;        
        NSInteger top, left, bottom, right;
        
        widthSpace  = (self.bounds.size.width  - _scrollView.contentSize.width)  / 2;
        heightSpace = (self.bounds.size.height - _scrollView.contentSize.height) / 2;
        
        left   = (widthSpace  < self.minEdgeInsets.left)   ? self.minEdgeInsets.left   : widthSpace;
        right  = (widthSpace  < self.minEdgeInsets.right)  ? self.minEdgeInsets.right  : widthSpace;
        top    = (heightSpace < self.minEdgeInsets.top)    ? self.minEdgeInsets.top    : heightSpace;
        bottom = (heightSpace < self.minEdgeInsets.bottom) ? self.minEdgeInsets.bottom : heightSpace;
        
        _scrollView.contentInset = UIEdgeInsetsMake(top, left, bottom, right);
    }
    else
    {
        _scrollView.contentInset = self.minEdgeInsets;
    }
    
    _minPossibleContentOffset = CGPointMake(-1 * (_scrollView.contentInset.left), 
                                            -1 * (_scrollView.contentInset.top));
    _maxPossibleContentOffset = CGPointMake(_scrollView.contentSize.width - _scrollView.bounds.size.width + _scrollView.contentInset.right, 
                                            _scrollView.contentSize.height - _scrollView.bounds.size.height + _scrollView.contentInset.bottom);
}

- (void)relayoutItems
{    
    [UIView animateWithDuration:kDefaultAnimationDuration 
                          delay:0
                        options:kDefaultAnimationOptions
                     animations:^{
                         
                         for (UIView *view in [self itemSubviews])
                         {        
                             if (view != _sortMovingItem && view != _transformingItem) 
                             {
                                 NSInteger index = view.tag - kTagOffset;
                                 CGPoint origin = [self.layoutStrategy originForItemAtPosition:index];
                                 CGRect newFrame = CGRectMake(origin.x, origin.y, _itemSize.width, _itemSize.height);
                                 
                                 // IF statement added for performance reasons (Time Profiling in instruments)
                                 if (!CGRectEqualToRect(newFrame, view.frame)) 
                                 {
                                     view.frame = newFrame;
                                 }
                             }
                         }
                     }
                     completion:^(BOOL finished) {
                         
                     }
     ];
}


//////////////////////////////////////////////////////////////
#pragma mark loading/destroying items & reusing cells
//////////////////////////////////////////////////////////////

- (void)loadRequiredItems
{
    NSRange rangeOfPositions = [self.layoutStrategy rangeOfPositionsInBoundsFromOffset: _scrollView.contentOffset];
    NSRange loadedPositionsRange = NSMakeRange(self.firstPositionLoaded, self.lastPositionLoaded - self.firstPositionLoaded);
    
    BOOL forceLoad = self.firstPositionLoaded == GMGV_INVALID_POSITION || self.lastPositionLoaded == GMGV_INVALID_POSITION;

    NSInteger positionToLoad;
    
    for (int i = 0; i < rangeOfPositions.length; i++) 
    {
        positionToLoad = i + rangeOfPositions.location;
        
        if ((forceLoad || !NSLocationInRange(positionToLoad, loadedPositionsRange)) && positionToLoad < _numberTotalItems) 
        {
            if (![self itemSubViewForPosition:positionToLoad]) 
            {
                GMGridViewCell *cell = [self createItemSubViewForPosition:positionToLoad];
                [_scrollView addSubview:cell];
            }
        }
    }
    
    self.firstPositionLoaded = self.firstPositionLoaded == GMGV_INVALID_POSITION ? rangeOfPositions.location : MIN(self.firstPositionLoaded, rangeOfPositions.location);
    self.lastPositionLoaded  = self.lastPositionLoaded == GMGV_INVALID_POSITION ? NSMaxRange(rangeOfPositions) : MAX(self.lastPositionLoaded, rangeOfPositions.length + rangeOfPositions.location);
    
    [self setSubviewsCacheAsInvalid];
    
    //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cleanupUnseenItems) object:nil];
    //[self performSelector:@selector(cleanupUnseenItems) withObject:nil afterDelay:0.5];
    
    [self performSelectorInBackground:@selector(cleanupUnseenItems) withObject:nil];
    
}


- (void)cleanupUnseenItems
{
    NSRange rangeOfPositions = [self.layoutStrategy rangeOfPositionsInBoundsFromOffset: _scrollView.contentOffset];
    GMGridViewCell *cell;
    
    if (rangeOfPositions.location > self.firstPositionLoaded) 
    {
        for (int i = self.firstPositionLoaded; i < rangeOfPositions.location; i++) 
        {
            cell = [self itemSubViewForPosition:i];
            if(cell)
            {
                NSLog(@"Removing item at position %d", i);
                [self queueReusableCell:cell];
                [cell removeFromSuperview];
            }
        }
        
        self.firstPositionLoaded = rangeOfPositions.location;
        [self setSubviewsCacheAsInvalid];
    }
    
    if (NSMaxRange(rangeOfPositions) < self.lastPositionLoaded) 
    {
        for (int i = NSMaxRange(rangeOfPositions); i <= self.lastPositionLoaded; i++)
        {
            cell = [self itemSubViewForPosition:i];
            if(cell)
            {
                NSLog(@"Removing item at position %d", i);
                [self queueReusableCell:cell];
                [cell removeFromSuperview];
            }
        }
        
        self.lastPositionLoaded = NSMaxRange(rangeOfPositions);
        [self setSubviewsCacheAsInvalid];
    }
}

- (void)queueReusableCell:(GMGridViewCell *)cell
{
    if (cell) 
    {
        [cell prepareForReuse];
        cell.alpha = 1;
        [_reusableCells addObject:cell];
    }
}

- (GMGridViewCell *)dequeueReusableCell
{
    GMGridViewCell *cell = [_reusableCells anyObject];
    
    if (cell) 
    {
        [_reusableCells removeObject:cell];
    }
    
    return cell;
}

- (void)receivedMemoryWarningNotification:(NSNotification *)notification
{
    [self cleanupUnseenItems];
    [_reusableCells removeAllObjects];
}


//////////////////////////////////////////////////////////////
#pragma mark public methods
//////////////////////////////////////////////////////////////

- (void)reloadData
{
    [[self itemSubviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop){
        [(UIView *)obj removeFromSuperview];
    }];
    
    self.firstPositionLoaded = GMGV_INVALID_POSITION;
    self.lastPositionLoaded  = GMGV_INVALID_POSITION;
    
    [self setSubviewsCacheAsInvalid];
    
    NSUInteger numberItems = [self.dataSource numberOfItemsInGMGridView:self];    
    _itemSize = [self.dataSource sizeForItemsInGMGridView:self];
    _numberTotalItems = numberItems;
    
    [self recomputeSize];
    _scrollView.contentOffset = _minPossibleContentOffset;
    
    [self loadRequiredItems];
    
    [self setSubviewsCacheAsInvalid];
    [self setNeedsLayout];
}

- (void)reloadObjectAtIndex:(NSInteger)index
{    
    NSAssert((index >= 0 && index < _numberTotalItems), @"Invalid index");
    
    UIView *currentView = [self itemSubViewForPosition:index];
    
    GMGridViewCell *cell = [self createItemSubViewForPosition:index];
    CGPoint origin = [self.layoutStrategy originForItemAtPosition:index];
    cell.frame = CGRectMake(origin.x, origin.y, _itemSize.width, _itemSize.height);
    cell.alpha = 0;
    [_scrollView addSubview:cell];
    
    currentView.tag = kTagOffset - 1;
    
    // Better performance animating ourselves instead of using animated:YES in scrollRectToVisible
    [UIView animateWithDuration:kDefaultAnimationDuration 
                          delay:0
                        options:kDefaultAnimationOptions
                     animations:^{
                         [_scrollView scrollRectToVisible:cell.frame animated:NO];
                         currentView.alpha = 0;
                         cell.alpha = 1;
                     } 
                     completion:^(BOOL finished){
                         [currentView removeFromSuperview];
                     }
     ];
    
    
    [self setSubviewsCacheAsInvalid];
}

- (void)scrollToObjectAtIndex:(NSInteger)index
{
    NSAssert((index >= 0 && index < _numberTotalItems), @"Invalid index");
    
    CGPoint origin = [self.layoutStrategy originForItemAtPosition:index];
    
    // Better performance animating ourselves instead of using animated:YES in scrollRectToVisible
    [UIView animateWithDuration:kDefaultAnimationDuration 
                          delay:0
                        options:kDefaultAnimationOptions
                     animations:^{
                         [_scrollView scrollRectToVisible:CGRectMake(origin.x, origin.y, _itemSize.width, _itemSize.height) animated:NO];
                     } 
                     completion:^(BOOL finished){
                     }
     ];
}

- (void)insertObjectAtIndex:(NSInteger)index
{
    NSAssert((index >= 0 && index <= _numberTotalItems), @"Invalid index specified");
    
    GMGridViewCell *cell = nil;
    BOOL isInsertedObjectVisible = NO;
    
    if (index >= self.firstPositionLoaded && index <= self.lastPositionLoaded) 
    {
        isInsertedObjectVisible = YES;
        
        cell = [self createItemSubViewForPosition:index];
        
        for (int i = index; i < _numberTotalItems; i++)
        {
            UIView *oldView = [self itemSubViewForPosition:i];
            oldView.tag = oldView.tag + 1;
        }
        
        [_scrollView addSubview:cell];
    }
    
    _numberTotalItems++;
    [self recomputeSize];
    
    // We cant use cell.frame as it might not be loaded yet
    CGPoint newObjectOrigin = [self.layoutStrategy originForItemAtPosition:index];
    
    // Better performance animating ourselves instead of using animated:YES in scrollRectToVisible
    [UIView animateWithDuration:kDefaultAnimationDuration 
                          delay:0
                        options:kDefaultAnimationOptions
                     animations:^{
                         [_scrollView scrollRectToVisible:CGRectMake(newObjectOrigin.x, newObjectOrigin.y, _itemSize.width, _itemSize.height) animated:NO];
                     } 
                     completion:^(BOOL finished){
                     }
     ];
    
    
    [self setNeedsLayout];
    [self setSubviewsCacheAsInvalid];
}

- (void)removeObjectAtIndex:(NSInteger)index
{
    NSAssert((index >= 0 && index < _numberTotalItems), @"Invalid index specified");

    GMGridViewCell *cell = [self itemSubViewForPosition:index];
    _numberTotalItems--;
    
    for (int i = index + 1; i < _numberTotalItems; i++)
    {
        GMGridViewCell *oldView = [self itemSubViewForPosition:i];
        oldView.tag = oldView.tag - 1;
    }
    
    cell.tag = kTagOffset - 1;
    CGPoint origin = [self.layoutStrategy originForItemAtPosition:index];
    
    // Better performance animating ourselves instead of using animated:YES in scrollRectToVisible
    [UIView animateWithDuration:kDefaultAnimationDuration 
                          delay:0
                        options:kDefaultAnimationOptions
                     animations:^{
                         cell.contentView.alpha = 0.3;
                         cell.alpha = 0;
                         [_scrollView scrollRectToVisible:CGRectMake(origin.x, origin.y, _itemSize.width, _itemSize.height) animated:NO];
                     } 
                     completion:^(BOOL finished){
                         [self queueReusableCell:cell];
                         [cell removeFromSuperview];
                         
                         self.firstPositionLoaded = self.lastPositionLoaded = GMGV_INVALID_POSITION;
                         [self loadRequiredItems];
                         
                         [self setNeedsLayout];  
                     }
     ];
    
    [self setSubviewsCacheAsInvalid];
}

- (void)swapObjectAtIndex:(NSInteger)index1 withObjectAtIndex:(NSInteger)index2
{
    NSAssert((index1 >= 0 && index1 < _numberTotalItems), @"Invalid index1 specified");
    NSAssert((index2 >= 0 && index2 < _numberTotalItems), @"Invalid index2 specified");
        
    GMGridViewCell *view1 = [self itemSubViewForPosition:index1];
    GMGridViewCell *view2 = [self itemSubViewForPosition:index2];
    
    view1.tag = index2 + kTagOffset;
    view2.tag = index1 + kTagOffset;

    CGPoint view1Origin = [self.layoutStrategy originForItemAtPosition:index2];
    CGPoint view2Origin = [self.layoutStrategy originForItemAtPosition:index1];
    
    view1.frame = CGRectMake(view1Origin.x, view1Origin.y, _itemSize.width, _itemSize.height);
    view2.frame = CGRectMake(view2Origin.x, view2Origin.y, _itemSize.width, _itemSize.height);

    
    CGRect visibleRect = CGRectMake(_scrollView.contentOffset.x,
                                    _scrollView.contentOffset.y, 
                                    _scrollView.contentSize.width, 
                                    _scrollView.contentSize.height);
    
    // Better performance animating ourselves instead of using animated:YES in scrollRectToVisible
    [UIView animateWithDuration:kDefaultAnimationDuration 
                          delay:0
                        options:kDefaultAnimationOptions
                     animations:^{
                         if (!CGRectIntersectsRect(view2.frame, visibleRect)) 
                         {
                             [_scrollView scrollRectToVisible:view1.frame animated:NO];
                         }
                         else if (!CGRectIntersectsRect(view1.frame, visibleRect)) 
                         {
                             [_scrollView scrollRectToVisible:view2.frame animated:NO];
                         }
                     } 
                     completion:^(BOOL finished){

                     }
     ];
}


@end
