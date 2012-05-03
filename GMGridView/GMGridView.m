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

#import <QuartzCore/QuartzCore.h>
#import "GMGridView.h"
#import "GMGridViewCell+Extended.h"
#import "GMGridViewLayoutStrategies.h"
#import "UIGestureRecognizer+GMGridViewAdditions.h"

static const NSInteger kTagOffset = 50;
static const CGFloat kDefaultAnimationDuration = 0.3;
static const UIViewAnimationOptions kDefaultAnimationOptions = UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction;


//////////////////////////////////////////////////////////////
#pragma mark - Private interface
//////////////////////////////////////////////////////////////

@interface GMGridView () <UIGestureRecognizerDelegate, UIScrollViewDelegate>
{
    // Sorting Gestures
    UIPanGestureRecognizer       *_sortingPanGesture;
    UILongPressGestureRecognizer *_longPressGesture;
    
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
    BOOL _inTransformingState;
    
    // Rotation
    BOOL _rotationActive;
}

@property (nonatomic, readonly) BOOL itemsSubviewsCacheIsValid;
@property (nonatomic, strong) NSArray *itemSubviewsCache;
@property (atomic) NSInteger firstPositionLoaded;
@property (atomic) NSInteger lastPositionLoaded;

- (void)commonInit;

// Gestures
- (void)sortingPanGestureUpdated:(UIPanGestureRecognizer *)panGesture;
- (void)longPressGestureUpdated:(UILongPressGestureRecognizer *)longPressGesture;
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
- (void)recomputeSizeAnimated:(BOOL)animated;
- (void)relayoutItemsAnimated:(BOOL)animated;
- (NSArray *)itemSubviews;
- (GMGridViewCell *)cellForItemAtIndex:(NSInteger)position;
- (GMGridViewCell *)newItemSubViewForPosition:(NSInteger)position;
- (NSInteger)positionForItemSubview:(GMGridViewCell *)view;
- (void)setSubviewsCacheAsInvalid;
- (CGRect)rectForPoint:(CGPoint)point inPaggingMode:(BOOL)pagging;

// Lazy loading
- (void)loadRequiredItems;
- (void)cleanupUnseenItems;
- (void)queueReusableCell:(GMGridViewCell *)cell;

// Memory warning
- (void)receivedMemoryWarningNotification:(NSNotification *)notification;

// Rotation handling
- (void)receivedWillRotateNotification:(NSNotification *)notification;

@end



//////////////////////////////////////////////////////////////
#pragma mark - Implementation
//////////////////////////////////////////////////////////////

@implementation GMGridView

@synthesize sortingDelegate = _sortingDelegate, dataSource = _dataSource, transformDelegate = _transformDelegate, actionDelegate = _actionDelegate;
@synthesize mainSuperView = _mainSuperView;
@synthesize layoutStrategy = _layoutStrategy;
@synthesize itemSpacing = _itemSpacing;
@synthesize style = _style;
@synthesize minimumPressDuration;
@synthesize centerGrid = _centerGrid;
@synthesize minEdgeInsets = _minEdgeInsets;
@synthesize showFullSizeViewWithAlphaWhenTransforming;
@synthesize editing = _editing;
@synthesize enableEditOnLongPress;
@synthesize disableEditOnEmptySpaceTap;

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
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) 
    {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit
{
    _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureUpdated:)];
    _tapGesture.delegate = self;
    _tapGesture.numberOfTapsRequired = 1;
    _tapGesture.numberOfTouchesRequired = 1;
    _tapGesture.cancelsTouchesInView = NO;
    [self addGestureRecognizer:_tapGesture];
    
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
    [self addGestureRecognizer:_sortingPanGesture];
    
    _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureUpdated:)];
    _longPressGesture.numberOfTouchesRequired = 1;
    _longPressGesture.delegate = self;
    _longPressGesture.cancelsTouchesInView = NO;
    [self addGestureRecognizer:_longPressGesture];
    
    ////////////////////////
    // Gesture dependencies
    UIPanGestureRecognizer *panGestureRecognizer = nil;
    if ([self respondsToSelector:@selector(panGestureRecognizer)]) // iOS5 only
    { 
        panGestureRecognizer = self.panGestureRecognizer;
    }
    else 
    {
        for (UIGestureRecognizer *gestureRecognizer in self.gestureRecognizers) 
        { 
            if ([gestureRecognizer  isKindOfClass:NSClassFromString(@"UIScrollViewPanGestureRecognizer")]) 
            {
                panGestureRecognizer = (UIPanGestureRecognizer *) gestureRecognizer;
            }
        }
    }
    [panGestureRecognizer setMaximumNumberOfTouches:1];
    [panGestureRecognizer requireGestureRecognizerToFail:_sortingPanGesture];
    
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
    _centerGrid = YES;
    
    _lastScale = 1.0;
    _lastRotation = 0.0;
    
    _minPossibleContentOffset = CGPointMake(0, 0);
    _maxPossibleContentOffset = CGPointMake(0, 0);
    
    _reusableCells = [[NSMutableSet alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedMemoryWarningNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedWillRotateNotification:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
}

//////////////////////////////////////////////////////////////
#pragma mark Layout
//////////////////////////////////////////////////////////////

- (void)applyWithoutAnimation:(void (^)(void))animations 
{
    if (animations) 
    {
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        animations();
        [CATransaction commit];
    }
}

- (void)layoutSubviewsWithAnimation:(GMGridViewItemAnimation)animation
{
    [self recomputeSizeAnimated:!(animation & GMGridViewItemAnimationNone)];
    [self relayoutItemsAnimated:animation & GMGridViewItemAnimationFade]; // only supported animation for now
    [self loadRequiredItems];
}

- (void)layoutSubviews 
{
    [super layoutSubviews];
    
    if (_rotationActive) 
    {
         _rotationActive = NO;
        
        // Updating all the items size
        
        CGSize itemSize = [self.dataSource GMGridView:self sizeForItemsInInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
        
        if (!CGSizeEqualToSize(_itemSize, itemSize)) 
        {
            _itemSize = itemSize;
            
            [[self itemSubviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                if (obj != _transformingItem) 
                {
                    GMGridViewCell *cell = (GMGridViewCell *)obj;
                    cell.bounds = CGRectMake(0, 0, _itemSize.width, _itemSize.height);
                    cell.contentView.frame = cell.bounds;
                }
            }];
        }
        
        // Updating the fullview size
        
        if (_transformingItem && _inFullSizeMode) 
        {
            NSInteger position = _transformingItem.tag - kTagOffset;
            CGSize fullSize = [self.transformDelegate GMGridView:self sizeInFullSizeForCell:_transformingItem atIndex:position inInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
            
            if (!CGSizeEqualToSize(fullSize, _transformingItem.fullSize)) 
            {
                CGPoint center = _transformingItem.fullSizeView.center;
                _transformingItem.fullSize = fullSize;
                _transformingItem.fullSizeView.center = center;
            }
        }
        
        // Adding alpha animation to make the relayouting more smooth
        
        CATransition *transition = [CATransition animation];
        transition.duration = 0.25f;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
        [self.layer addAnimation:transition forKey:@"rotationAnimation"];
        
        [self applyWithoutAnimation:^{
            [self layoutSubviewsWithAnimation:GMGridViewItemAnimationNone];
        }];
        
        // Fixing the contentOffset when pagging enabled
        
        if (self.pagingEnabled) 
        {
            [self setContentOffset:[self rectForPoint:self.contentOffset inPaggingMode:YES].origin animated:YES];
        }
    }
    else 
    {
        [self layoutSubviewsWithAnimation:GMGridViewItemAnimationNone];
    }
}

//////////////////////////////////////////////////////////////
#pragma mark Orientation and memory management
//////////////////////////////////////////////////////////////

- (void)receivedMemoryWarningNotification:(NSNotification *)notification
{
    [self cleanupUnseenItems];
    [_reusableCells removeAllObjects];
}

- (void)receivedWillRotateNotification:(NSNotification *)notification
{
    _rotationActive = YES;
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
    
    self.pagingEnabled = [[self.layoutStrategy class] requiresEnablingPaging];
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
    _longPressGesture.minimumPressDuration = duration;
}

- (CFTimeInterval)minimumPressDuration
{
    return _longPressGesture.minimumPressDuration;
}

- (void)setEditing:(BOOL)editing
{
    [self setEditing:editing animated:NO];
	
    if ([self.actionDelegate respondsToSelector:@selector(GMGridView:changedEdit:)]) {
        [self.actionDelegate GMGridView:self changedEdit:editing];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    if ([self.actionDelegate respondsToSelector:@selector(GMGridView:processDeleteActionForItemAtIndex:)]
        &&![self isInTransformingState] 
        && ((self.isEditing && !editing) || (!self.isEditing && editing))) 
    {
        for (GMGridViewCell *cell in [self itemSubviews]) 
        {
            NSInteger index = [self positionForItemSubview:cell];
            if (index != GMGV_INVALID_POSITION)
            {
                BOOL allowEdit = editing && [self.dataSource GMGridView:self canDeleteItemAtIndex:index];
                [cell setEditing:allowEdit animated:animated];
            }
        }
        
        _editing = editing;
    }
}

//////////////////////////////////////////////////////////////
#pragma mark UIScrollView delegate replacement
//////////////////////////////////////////////////////////////

- (void)contentOffset:(CGPoint)contentOffset
{
    BOOL valueChanged = !CGPointEqualToPoint(contentOffset, self.contentOffset);
    
    [super setContentOffset:contentOffset];

    if (valueChanged) 
    {
        [self loadRequiredItems];
    }
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
    BOOL isScrolling = self.isDragging || self.isDecelerating;
    
    if (gestureRecognizer == _tapGesture) 
    {
        if (self.editing && self.disableEditOnEmptySpaceTap) {
            CGPoint locationTouch = [_tapGesture locationInView:self];
            NSInteger position = [self.layoutStrategy itemPositionFromLocation:locationTouch];
            
            valid = (position == GMGV_INVALID_POSITION);
        } else {
            valid = !isScrolling && !self.isEditing && ![_longPressGesture hasRecognizedValidGesture];
        }
    }
    else if (gestureRecognizer == _longPressGesture)
    {
        valid = (self.sortingDelegate || self.enableEditOnLongPress) && !isScrolling && !self.isEditing;
    }
    else if (gestureRecognizer == _sortingPanGesture) 
    {
        valid = (_sortMovingItem != nil && [_longPressGesture hasRecognizedValidGesture]);
    }
    else if(gestureRecognizer == _rotationGesture || gestureRecognizer == _pinchGesture || gestureRecognizer == _panGesture)
    {
        if (self.transformDelegate != nil && [gestureRecognizer numberOfTouches] == 2) 
        {
            CGPoint locationTouch1 = [gestureRecognizer locationOfTouch:0 inView:self];
            CGPoint locationTouch2 = [gestureRecognizer locationOfTouch:1 inView:self];
            
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

- (void)longPressGestureUpdated:(UILongPressGestureRecognizer *)longPressGesture
{
    if (self.enableEditOnLongPress && !self.editing) {
        CGPoint locationTouch = [longPressGesture locationInView:self];
        NSInteger position = [self.layoutStrategy itemPositionFromLocation:locationTouch];
        
        if (position != GMGV_INVALID_POSITION) 
        {
            if (!self.editing) {
                self.editing = YES;
            }
        }
        return;
    }
    
    switch (longPressGesture.state) 
    {
        case UIGestureRecognizerStateBegan:
        {
            if (!_sortMovingItem) 
            { 
                CGPoint location = [longPressGesture locationInView:self];
                
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
                CGPoint location = [longPressGesture locationInView:self];
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
            CGPoint translation = [panGesture translationInView:self];
            CGPoint offset = translation;
            CGPoint locationInScroll = [panGesture locationInView:self];
            
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
        locationInMainView = CGPointMake(locationInMainView.x - self.contentOffset.x,
                                         locationInMainView.y -self.contentOffset.y
        );
        
        
        CGFloat threshhold = _itemSize.height;
        CGPoint offset = self.contentOffset;
        CGPoint locationInScroll = [_sortingPanGesture locationInView:self];
        
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
        
        if (offset.x != self.contentOffset.x || offset.y != self.contentOffset.y) 
        {
            [UIView animateWithDuration:kDefaultAnimationDuration 
                                  delay:0
                                options:kDefaultAnimationOptions
                             animations:^{
                                 self.contentOffset = offset;
                             }
                             completion:^(BOOL finished){
                                 
                                 self.contentOffset = offset;
                                 
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
    
    GMGridViewCell *item = [self cellForItemAtIndex:position];
    
    [self bringSubviewToFront:item];
    _sortMovingItem = item;
    
    CGRect frameInMainView = [self convertRect:_sortMovingItem.frame toView:self.mainSuperView];
    
    [_sortMovingItem removeFromSuperview];
    _sortMovingItem.frame = frameInMainView;
    [self.mainSuperView addSubview:_sortMovingItem];
    
    _sortFuturePosition = _sortMovingItem.tag - kTagOffset;
    _sortMovingItem.tag = 0;
    
    if ([self.sortingDelegate respondsToSelector:@selector(GMGridView:didStartMovingCell:)])
    {
        [self.sortingDelegate GMGridView:self didStartMovingCell:_sortMovingItem];
    }
    
    if ([self.sortingDelegate respondsToSelector:@selector(GMGridView:shouldAllowShakingBehaviorWhenMovingCell:atIndex:)]) 
    {
        [_sortMovingItem shake:[self.sortingDelegate GMGridView:self shouldAllowShakingBehaviorWhenMovingCell:_sortMovingItem atIndex:position]];
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
    
    CGRect frameInScroll = [self.mainSuperView convertRect:_sortMovingItem.frame toView:self];
    
    [_sortMovingItem removeFromSuperview];
    _sortMovingItem.frame = frameInScroll;
    [self addSubview:_sortMovingItem];
    
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
                         if ([self.sortingDelegate respondsToSelector:@selector(GMGridView:didEndMovingCell:)])
                         {
                             [self.sortingDelegate GMGridView:self didEndMovingCell:_sortMovingItem];
                         }
                         
                         _sortMovingItem = nil;
                         _sortFuturePosition = GMGV_INVALID_POSITION;
                         
                         [self setSubviewsCacheAsInvalid];
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
                                [self sendSubviewToBack:v];
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
                                [self sendSubviewToBack:v];
                            }
                        }
                    }
                    
                    [self.sortingDelegate GMGridView:self moveItemAtIndex:_sortFuturePosition toIndex:position];
                    [self relayoutItemsAnimated:YES];
                    
                    break;
                }
                case GMGridViewStyleSwap:
                default:
                {
                    if (_sortMovingItem) 
                    {
                        UIView *v = [self cellForItemAtIndex:position];
                        
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
            
            self.scrollEnabled = YES;
            
            break;
        }
        case UIGestureRecognizerStateBegan:
        {
            [self transformingGestureDidBeginWithGesture:panGesture];
            self.scrollEnabled = NO;
            
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            if (panGesture.numberOfTouches != 2) 
            {
                [panGesture end];
            }
            
            CGPoint translate = [panGesture translationInView:self];
            [_transformingItem.contentView setCenter:CGPointMake(_transformingItem.contentView.center.x + translate.x, _transformingItem.contentView.center.y + translate.y)];
            [panGesture setTranslation:CGPointZero inView:self];
            
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
            
            if (scale >= kMinScale && scale <= kMaxScale) 
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
    _inFullSizeMode = NO;
    
    if (_inTransformingState && [gesture isKindOfClass:[UIPinchGestureRecognizer class]]) 
    {
        _pinchGesture.scale = 2.5;
    }
    
    if (_inTransformingState)
    {        
        _inTransformingState = NO;
        
        CGPoint center = _transformingItem.fullSizeView.center;
        
        [_transformingItem switchToFullSizeMode:NO];
        CGAffineTransform newTransform = CGAffineTransformMakeScale(2.5, 2.5);
        _transformingItem.contentView.transform = newTransform;
        _transformingItem.contentView.center = center;
    }
    else if (!_transformingItem) 
    {        
        CGPoint locationTouch = [gesture locationOfTouch:0 inView:self];            
        NSInteger positionTouch = [self.layoutStrategy itemPositionFromLocation:locationTouch];
        _transformingItem = [self cellForItemAtIndex:positionTouch];
        
        CGRect frameInMainView = [self convertRect:_transformingItem.frame toView:self.mainSuperView];
        
        [_transformingItem removeFromSuperview];
        _transformingItem.frame = self.mainSuperView.bounds;
        _transformingItem.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _transformingItem.contentView.frame = frameInMainView;
        [self.mainSuperView addSubview:_transformingItem];
        [self.mainSuperView bringSubviewToFront:_transformingItem];
        
        _transformingItem.fullSize = [self.transformDelegate GMGridView:self sizeInFullSizeForCell:_transformingItem atIndex:positionTouch inInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
        _transformingItem.fullSizeView = [self.transformDelegate GMGridView:self fullSizeViewForCell:_transformingItem atIndex:positionTouch];
        
        if ([self.transformDelegate respondsToSelector:@selector(GMGridView:didStartTransformingCell:)]) 
        {
            [self.transformDelegate GMGridView:self didStartTransformingCell:_transformingItem];
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
        if (_lastScale > 2 && !_inTransformingState) 
        {            
            _lastRotation = 0;
            _lastScale = 1;
            
            [self bringSubviewToFront:_transformingItem];
            
            CGFloat rotationValue = atan2f(_transformingItem.contentView.transform.b, _transformingItem.contentView.transform.a); 
            
            _transformingItem.contentView.transform = CGAffineTransformIdentity;
            
            [_transformingItem switchToFullSizeMode:YES];
            _transformingItem.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.9];
            
            _transformingItem.fullSizeView.transform =  CGAffineTransformMakeRotation(rotationValue);
            
            [UIView animateWithDuration:kDefaultAnimationDuration 
                                  delay:0
                                options:kDefaultAnimationOptions
                             animations:^{
                                 _transformingItem.fullSizeView.transform = CGAffineTransformIdentity;
                             }
                             completion:nil
             ];
            
            _inTransformingState = YES;
            _inFullSizeMode = YES;
            
            if ([self.transformDelegate respondsToSelector:@selector(GMGridView:didEnterFullSizeForCell:)])
            {
                [self.transformDelegate GMGridView:self didEnterFullSizeForCell:_transformingItem];
            }
            
            // Transfer the gestures on the fullscreen to make is they are accessible (depends on self.mainSuperView)
            [_transformingItem.fullSizeView addGestureRecognizer:_pinchGesture];
            [_transformingItem.fullSizeView addGestureRecognizer:_rotationGesture];
            [_transformingItem.fullSizeView addGestureRecognizer:_panGesture];
        }
        else if (!_inTransformingState)
        {
            _lastRotation = 0;
            _lastScale = 1.0;
            
            GMGridViewCell *transformingView = _transformingItem;
            _transformingItem = nil;
            
            NSInteger position = [self positionForItemSubview:transformingView];
            CGPoint origin = [self.layoutStrategy originForItemAtPosition:position];
            
            CGRect finalFrameInScroll = CGRectMake(origin.x, origin.y, _itemSize.width, _itemSize.height);
            CGRect finalFrameInSuperview = [self convertRect:finalFrameInScroll toView:self.mainSuperView];
            
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
                                 [self addSubview:transformingView];
                                 
                                 transformingView.fullSizeView = nil;
                                 _inFullSizeMode = NO;
                                 
                                 if ([self.transformDelegate respondsToSelector:@selector(GMGridView:didEndTransformingCell:)])
                                 {
                                     [self.transformDelegate GMGridView:self didEndTransformingCell:transformingView];
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
#pragma mark Tap gesture
//////////////////////////////////////////////////////////////

- (void)tapGestureUpdated:(UITapGestureRecognizer *)tapGesture
{
    CGPoint locationTouch = [_tapGesture locationInView:self];
    NSInteger position = [self.layoutStrategy itemPositionFromLocation:locationTouch];
    
    if (position != GMGV_INVALID_POSITION) 
    {
        if (!self.editing) {
            [self cellForItemAtIndex:position].highlighted = NO;
            [self.actionDelegate GMGridView:self didTapOnItemAtIndex:position];
        }
    }
    else
    { 
        if([self.actionDelegate respondsToSelector:@selector(GMGridViewDidTapOnEmptySpace:)])
        {
            [self.actionDelegate GMGridViewDidTapOnEmptySpace:self];
        }
        
        if (self.disableEditOnEmptySpaceTap) {
            self.editing = NO;
        }
    }
}

//////////////////////////////////////////////////////////////
#pragma mark private methods
//////////////////////////////////////////////////////////////

- (void)setSubviewsCacheAsInvalid
{
    _itemsSubviewsCacheIsValid = NO;
}

- (GMGridViewCell *)newItemSubViewForPosition:(NSInteger)position
{
    GMGridViewCell *cell = [self.dataSource GMGridView:self cellForItemAtIndex:position];
    CGPoint origin = [self.layoutStrategy originForItemAtPosition:position];
    CGRect frame = CGRectMake(origin.x, origin.y, _itemSize.width, _itemSize.height);
    
    // To make sure the frame is not animated
    [self applyWithoutAnimation:^{
        cell.frame = frame;
        cell.contentView.frame = cell.bounds;
    }];

    cell.tag = position + kTagOffset;
    BOOL canEdit = self.editing && [self.dataSource GMGridView:self canDeleteItemAtIndex:position];
    [cell setEditing:canEdit animated:NO];
    
    __gm_weak GMGridView *weakSelf = self; 
    cell.deleteBlock = ^(GMGridViewCell *aCell)
    {
        NSInteger index = [weakSelf positionForItemSubview:aCell];
        if (index != GMGV_INVALID_POSITION) 
        {
            BOOL canDelete = YES;
            if ([weakSelf.dataSource respondsToSelector:@selector(GMGridView:canDeleteItemAtIndex:)]) 
            {
                canDelete = [weakSelf.dataSource GMGridView:weakSelf canDeleteItemAtIndex:index];
            }
            
            if (canDelete && [weakSelf.actionDelegate respondsToSelector:@selector(GMGridView:processDeleteActionForItemAtIndex:)]) 
            {
                [weakSelf.actionDelegate GMGridView:weakSelf processDeleteActionForItemAtIndex:index];
            }
        }
    };
    
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
        @synchronized(self)
        {
            NSMutableArray *itemSubViews = [[NSMutableArray alloc] initWithCapacity:_numberTotalItems];
            
            for (UIView * v in [self subviews]) 
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
    }
    
    return subviews;
}

- (GMGridViewCell *)cellForItemAtIndex:(NSInteger)position
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

- (void)recomputeSizeAnimated:(BOOL)animated
{
    [self.layoutStrategy setupItemSize:_itemSize andItemSpacing:self.itemSpacing withMinEdgeInsets:self.minEdgeInsets andCenteredGrid:self.centerGrid];
    [self.layoutStrategy rebaseWithItemCount:_numberTotalItems insideOfBounds:self.bounds];
    
    CGSize contentSize = [self.layoutStrategy contentSize];
    
    _minPossibleContentOffset = CGPointMake(0, 0);
    _maxPossibleContentOffset = CGPointMake(contentSize.width - self.bounds.size.width + self.contentInset.right, 
                                            contentSize.height - self.bounds.size.height + self.contentInset.bottom);
    
    BOOL shouldUpdateScrollviewContentSize = !CGSizeEqualToSize(self.contentSize, contentSize);
    
    if (shouldUpdateScrollviewContentSize)
    {
        if (animated)
        {
            [UIView animateWithDuration:kDefaultAnimationDuration
                                  delay:0 
                                options:kDefaultAnimationOptions 
                             animations:^{
                                 self.contentSize = contentSize;
                             }
                             completion:nil];
        }
        else
        {
            self.contentSize = contentSize;
        }
    }
    
}

- (void)relayoutItemsAnimated:(BOOL)animated
{    
    void (^layoutBlock)(void) = ^{
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
    };
    
    if (animated) 
    {
        [UIView animateWithDuration:kDefaultAnimationDuration 
                              delay:0
                            options:kDefaultAnimationOptions
                         animations:^{
                             layoutBlock();
                         }
                         completion:nil
         ];
    }
    else 
    {
        layoutBlock();
    }
}

- (CGRect)rectForPoint:(CGPoint)point inPaggingMode:(BOOL)pagging
{
    CGRect targetRect = CGRectZero;
    
    if (self.pagingEnabled) 
    {
        CGPoint originScroll = CGPointZero;
        
        CGSize pageSize =  CGSizeMake(self.bounds.size.width  - self.contentInset.left - self.contentInset.right, 
                                           self.bounds.size.height - self.contentInset.top  - self.contentInset.bottom);
        
        CGFloat pageX = ceilf(point.x / pageSize.width);
        CGFloat pageY = ceilf(point.y / pageSize.height);
        
        originScroll = CGPointMake(pageX * pageSize.width, 
                                   pageY *pageSize.height);
        
        /*
        while (originScroll.x + pageSize.width < point.x) 
        {
            originScroll.x += pageSize.width;
        }
        
        while (originScroll.y + pageSize.height < point.y) 
        {
            originScroll.y += pageSize.height;
        }
        */
        targetRect = CGRectMake(originScroll.x, originScroll.y, pageSize.width, pageSize.height);
    }
    else 
    {
        targetRect = CGRectMake(point.x, point.y, _itemSize.width, _itemSize.height);
    }
    
    return targetRect;
}

//////////////////////////////////////////////////////////////
#pragma mark loading/destroying items & reusing cells
//////////////////////////////////////////////////////////////

- (void)loadRequiredItems
{
    NSRange rangeOfPositions = [self.layoutStrategy rangeOfPositionsInBoundsFromOffset: self.contentOffset];
    NSRange loadedPositionsRange = NSMakeRange(self.firstPositionLoaded, self.lastPositionLoaded - self.firstPositionLoaded);

    // calculate new position range
    self.firstPositionLoaded = self.firstPositionLoaded == GMGV_INVALID_POSITION ? rangeOfPositions.location : MIN(self.firstPositionLoaded, (NSInteger)rangeOfPositions.location);
    self.lastPositionLoaded  = self.lastPositionLoaded == GMGV_INVALID_POSITION ? NSMaxRange(rangeOfPositions) : MAX(self.lastPositionLoaded, (NSInteger)(rangeOfPositions.length + rangeOfPositions.location));
    
    // remove now invisible items
    [self setSubviewsCacheAsInvalid];
    [self cleanupUnseenItems];
    
    // add new cells
    BOOL forceLoad = self.firstPositionLoaded == GMGV_INVALID_POSITION || self.lastPositionLoaded == GMGV_INVALID_POSITION;
    NSInteger positionToLoad;
    for (NSUInteger i = 0; i < rangeOfPositions.length; i++) 
    {
        positionToLoad = i + rangeOfPositions.location;
        
        if ((forceLoad || !NSLocationInRange(positionToLoad, loadedPositionsRange)) && positionToLoad < _numberTotalItems) 
        {
            if (![self cellForItemAtIndex:positionToLoad]) 
            {
                GMGridViewCell *cell = [self newItemSubViewForPosition:positionToLoad];
                [self addSubview:cell];
            }
        }
    }    
}


- (void)cleanupUnseenItems
{
    NSRange rangeOfPositions = [self.layoutStrategy rangeOfPositionsInBoundsFromOffset: self.contentOffset];
    GMGridViewCell *cell;
    
    if ((NSInteger)rangeOfPositions.location > self.firstPositionLoaded) 
    {
        for (NSInteger i = self.firstPositionLoaded; i < (NSInteger)rangeOfPositions.location; i++) 
        {
            cell = [self cellForItemAtIndex:i];
            if(cell)
            {
                [self queueReusableCell:cell];
                [cell removeFromSuperview];
            }
        }
        
        self.firstPositionLoaded = rangeOfPositions.location;
        [self setSubviewsCacheAsInvalid];
    }
    
    if ((NSInteger)NSMaxRange(rangeOfPositions) < self.lastPositionLoaded) 
    {
        for (NSInteger i = NSMaxRange(rangeOfPositions); i <= self.lastPositionLoaded; i++)
        {
            cell = [self cellForItemAtIndex:i];
            if(cell)
            {
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
        cell.backgroundColor = [UIColor clearColor];
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

- (GMGridViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier
{
    GMGridViewCell *cell = nil;
    
    for (GMGridViewCell *reusableCell in [_reusableCells allObjects]) 
    {
        if ([reusableCell.reuseIdentifier isEqualToString:identifier]) 
        {
            cell = reusableCell;
            break;
        }
    }
    
    if (cell) 
    {
        [_reusableCells removeObject:cell];
    }
    
    return cell;
}

//////////////////////////////////////////////////////////////
#pragma mark public methods
//////////////////////////////////////////////////////////////

- (void)reloadData
{
    CGPoint previousContentOffset = self.contentOffset;
    
    [[self itemSubviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop)
    {
        if ([obj isKindOfClass:[GMGridViewCell class]]) 
        {
            [(UIView *)obj removeFromSuperview];
            [self queueReusableCell:(GMGridViewCell *)obj];
        }
    }];
    
    self.firstPositionLoaded = GMGV_INVALID_POSITION;
    self.lastPositionLoaded  = GMGV_INVALID_POSITION;
    
    [self setSubviewsCacheAsInvalid];
    
    NSUInteger numberItems = [self.dataSource numberOfItemsInGMGridView:self];    
    _itemSize = [self.dataSource GMGridView:self sizeForItemsInInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    _numberTotalItems = numberItems;
    
    [self recomputeSizeAnimated:NO];
    
    CGPoint newContentOffset = CGPointMake(MIN(_maxPossibleContentOffset.x, previousContentOffset.x), MIN(_maxPossibleContentOffset.y, previousContentOffset.y));
    newContentOffset = CGPointMake(MAX(newContentOffset.x, _minPossibleContentOffset.x), MAX(newContentOffset.y, _minPossibleContentOffset.y));
    
    self.contentOffset = newContentOffset;
    
    [self loadRequiredItems];
    
    [self setSubviewsCacheAsInvalid];
    [self setNeedsLayout];
}

- (void)reloadObjectAtIndex:(NSInteger)index animated:(BOOL)animated
{
    [self reloadObjectAtIndex:index withAnimation:animated ? GMGridViewItemAnimationScroll : GMGridViewItemAnimationNone];
}

- (void)reloadObjectAtIndex:(NSInteger)index withAnimation:(GMGridViewItemAnimation)animation
{    
    NSAssert((index >= 0 && index < _numberTotalItems), @"Invalid index");
    
    UIView *currentView = [self cellForItemAtIndex:index];
    
    GMGridViewCell *cell = [self newItemSubViewForPosition:index];
    CGPoint origin = [self.layoutStrategy originForItemAtPosition:index];
    cell.frame = CGRectMake(origin.x, origin.y, _itemSize.width, _itemSize.height);
    cell.alpha = 0;
    [self addSubview:cell];
    
    currentView.tag = kTagOffset - 1;
    BOOL shouldScroll = animation & GMGridViewItemAnimationScroll;
    BOOL animate = animation & GMGridViewItemAnimationFade;
    [UIView animateWithDuration:animate ? kDefaultAnimationDuration : 0.f 
                          delay:0.f
                        options:kDefaultAnimationOptions
                     animations:^{
                         if (shouldScroll) {
                             [self scrollToObjectAtIndex:index atScrollPosition:GMGridViewScrollPositionNone animated:NO];
                         }
                         currentView.alpha = 0;
                         cell.alpha = 1;
                     } 
                     completion:^(BOOL finished){
                         [currentView removeFromSuperview];
                     }
     ];
    
    [self setSubviewsCacheAsInvalid];
}

- (void)scrollToObjectAtIndex:(NSInteger)index atScrollPosition:(GMGridViewScrollPosition)scrollPosition animated:(BOOL)animated
{
    index = MAX(0, index);
    index = MIN(index, _numberTotalItems);
    
    CGPoint origin = [self.layoutStrategy originForItemAtPosition:index];
    CGRect targetRect = [self rectForPoint:origin inPaggingMode:self.pagingEnabled];
    
    if (!self.pagingEnabled)
    {
        CGRect gridRect = CGRectMake(origin.x, origin.y, _itemSize.width, _itemSize.height);

        switch (scrollPosition)
        {
            case GMGridViewScrollPositionNone:
            default:
                targetRect = gridRect; // no special coordinate handling
                break;

            case GMGridViewScrollPositionTop:
                targetRect.origin.y = gridRect.origin.y;	// set target y origin to cell's y origin
                break;
                
            case GMGridViewScrollPositionMiddle:
                targetRect.origin.y = MAX(gridRect.origin.y - (CGFloat)ceilf((targetRect.size.height - gridRect.size.height) * 0.5), 0.0);
                break;
                
            case GMGridViewScrollPositionBottom:
                targetRect.origin.y = MAX((CGFloat)floorf(gridRect.origin.y - (targetRect.size.height - gridRect.size.height)), 0.0);
                break;
        }
    }
    
    // Better performance animating ourselves instead of using animated:YES in scrollRectToVisible
    [UIView animateWithDuration:animated ? kDefaultAnimationDuration : 0
                          delay:0
                        options:kDefaultAnimationOptions
                     animations:^{
                         [self scrollRectToVisible:targetRect animated:NO];
                     } 
                     completion:^(BOOL finished){
                     }
     ];
}

- (void)insertObjectAtIndex:(NSInteger)index animated:(BOOL)animated
{
    [self insertObjectAtIndex:index withAnimation: animated ? GMGridViewItemAnimationScroll : GMGridViewItemAnimationNone];
}

- (void)insertObjectAtIndex:(NSInteger)index withAnimation:(GMGridViewItemAnimation)animation
{
    NSAssert((index >= 0 && index <= _numberTotalItems), @"Invalid index specified");
    
    GMGridViewCell *cell = nil;
    
    if (index >= self.firstPositionLoaded && index <= self.lastPositionLoaded) 
    {        
        cell = [self newItemSubViewForPosition:index];
        
        for (int i = _numberTotalItems - 1; i >= index; i--)
        {
            UIView *oldView = [self cellForItemAtIndex:i];
            oldView.tag = oldView.tag + 1;
        }
        
        if (animation & GMGridViewItemAnimationFade) {
            cell.alpha = 0;
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDelay:kDefaultAnimationDuration];
            [UIView setAnimationDuration:kDefaultAnimationDuration];
            cell.alpha = 1.0;
            [UIView commitAnimations];
        }
        [self addSubview:cell];
    }
    
    _numberTotalItems++;
    [self recomputeSizeAnimated:!(animation & GMGridViewItemAnimationNone)];
    
    BOOL shouldScroll = animation & GMGridViewItemAnimationScroll;
    if (shouldScroll)
    {
        [UIView animateWithDuration:kDefaultAnimationDuration 
                              delay:0
                            options:kDefaultAnimationOptions
                         animations:^{
                             [self scrollToObjectAtIndex:index atScrollPosition:GMGridViewScrollPositionNone animated:NO];
                         } 
                         completion:^(BOOL finished){
                             [self layoutSubviewsWithAnimation:animation];
                         }
         ];
    }
    else 
    {
        [self layoutSubviewsWithAnimation:animation];
    }
    
    [self setSubviewsCacheAsInvalid];
}

- (void)removeObjectAtIndex:(NSInteger)index animated:(BOOL)animated
{
    [self removeObjectAtIndex:index withAnimation:GMGridViewItemAnimationNone];
}

- (void)removeObjectAtIndex:(NSInteger)index withAnimation:(GMGridViewItemAnimation)animation
{
    NSAssert((index >= 0 && index < _numberTotalItems), @"Invalid index specified");
    
    GMGridViewCell *cell = [self cellForItemAtIndex:index];
    
    for (int i = index + 1; i < _numberTotalItems; i++)
    {
        GMGridViewCell *oldView = [self cellForItemAtIndex:i];
        oldView.tag = oldView.tag - 1;
    }
    
    cell.tag = kTagOffset - 1;
    _numberTotalItems--;
    
    BOOL shouldScroll = animation & GMGridViewItemAnimationScroll;
    BOOL animate = animation & GMGridViewItemAnimationFade;
    [UIView animateWithDuration:animate ? kDefaultAnimationDuration : 0.f
                          delay:0.f
                        options:kDefaultAnimationOptions
                     animations:^{
                         cell.contentView.alpha = 0.3f;
                         cell.alpha = 0.f;
                         
                         if (shouldScroll) {
                             [self scrollToObjectAtIndex:index atScrollPosition:GMGridViewScrollPositionNone animated:NO];
                         }
                         [self recomputeSizeAnimated:!(animation & GMGridViewItemAnimationNone)];
                     } 
                     completion:^(BOOL finished) {
                         cell.contentView.alpha = 1.f;
                         [self queueReusableCell:cell];
                         [cell removeFromSuperview];
                         
                         self.firstPositionLoaded = self.lastPositionLoaded = GMGV_INVALID_POSITION;
                         [self loadRequiredItems];
                         [self relayoutItemsAnimated:animate];
                     }
     ];
    
    [self setSubviewsCacheAsInvalid];
}

- (void)swapObjectAtIndex:(NSInteger)index1 withObjectAtIndex:(NSInteger)index2 animated:(BOOL)animated
{
    [self swapObjectAtIndex:index1 withObjectAtIndex:index2 withAnimation:animated ? GMGridViewItemAnimationScroll : GMGridViewItemAnimationNone];
}

- (void)swapObjectAtIndex:(NSInteger)index1 withObjectAtIndex:(NSInteger)index2 withAnimation:(GMGridViewItemAnimation)animation
{
    NSAssert((index1 >= 0 && index1 < _numberTotalItems), @"Invalid index1 specified");
    NSAssert((index2 >= 0 && index2 < _numberTotalItems), @"Invalid index2 specified");
    
    GMGridViewCell *view1 = [self cellForItemAtIndex:index1];
    GMGridViewCell *view2 = [self cellForItemAtIndex:index2];
    
    view1.tag = index2 + kTagOffset;
    view2.tag = index1 + kTagOffset;
    
    CGPoint view1Origin = [self.layoutStrategy originForItemAtPosition:index2];
    CGPoint view2Origin = [self.layoutStrategy originForItemAtPosition:index1];
    
    view1.frame = CGRectMake(view1Origin.x, view1Origin.y, _itemSize.width, _itemSize.height);
    view2.frame = CGRectMake(view2Origin.x, view2Origin.y, _itemSize.width, _itemSize.height);
    
    
    CGRect visibleRect = CGRectMake(self.contentOffset.x,
                                    self.contentOffset.y, 
                                    self.contentSize.width, 
                                    self.contentSize.height);
    
    // Better performance animating ourselves instead of using animated:YES in scrollRectToVisible
    BOOL shouldScroll = animation & GMGridViewItemAnimationScroll;
    [UIView animateWithDuration:kDefaultAnimationDuration 
                          delay:0
                        options:kDefaultAnimationOptions
                     animations:^{
                         if (shouldScroll) {
                             if (!CGRectIntersectsRect(view2.frame, visibleRect)) 
                             {
                                 [self scrollToObjectAtIndex:index1 atScrollPosition:GMGridViewScrollPositionNone animated:NO];
                             }
                             else if (!CGRectIntersectsRect(view1.frame, visibleRect)) 
                             {
                                 [self scrollToObjectAtIndex:index2 atScrollPosition:GMGridViewScrollPositionNone animated:NO];
                             }
                         }
                     } 
                     completion:^(BOOL finished) {
                         [self setNeedsLayout];
                     }];
}


//////////////////////////////////////////////////////////////
#pragma mark depracated public methods
//////////////////////////////////////////////////////////////

- (UIScrollView *)scrollView
{
    return self;
}

@end
