//
//  GMGridView.h
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

#import <UIKit/UIKit.h>
#import "GMGridView-Constants.h"
#import "GMGridViewCell.h"

@protocol GMGridViewDataSource;
@protocol GMGridViewActionDelegate;
@protocol GMGridViewSortingDelegate;
@protocol GMGridViewTransformationDelegate;
@protocol GMGridViewLayoutStrategy;

typedef enum
{
    GMGridViewStylePush = 0,
    GMGridViewStyleSwap
} GMGridViewStyle;

typedef enum
{
	GMGridViewScrollPositionNone,
	GMGridViewScrollPositionTop,
	GMGridViewScrollPositionMiddle,
	GMGridViewScrollPositionBottom
} GMGridViewScrollPosition;

typedef enum
{
    GMGridViewItemAnimationNone = 0,
    GMGridViewItemAnimationFade,
    GMGridViewItemAnimationScroll = 1<<7 // scroll to the item before showing the animation
} GMGridViewItemAnimation;

//////////////////////////////////////////////////////////////
#pragma mark Interface GMGridView
//////////////////////////////////////////////////////////////

@interface GMGridView : UIScrollView

// Delegates
@property (nonatomic, gm_weak) IBOutlet NSObject<GMGridViewDataSource> *dataSource;                    // Required
@property (nonatomic, gm_weak) IBOutlet NSObject<GMGridViewActionDelegate> *actionDelegate;            // Optional - to get taps callback & deleting item
@property (nonatomic, gm_weak) IBOutlet NSObject<GMGridViewSortingDelegate> *sortingDelegate;          // Optional - to enable sorting
@property (nonatomic, gm_weak) IBOutlet NSObject<GMGridViewTransformationDelegate> *transformDelegate; // Optional - to enable fullsize mode

// Layout Strategy
@property (nonatomic, strong) IBOutlet id<GMGridViewLayoutStrategy> layoutStrategy; // Default is GMGridViewLayoutVerticalStrategy

// Editing Mode
@property (nonatomic, getter=isEditing) BOOL editing; // Default is NO - When set to YES, all gestures are disabled and delete buttons shows up on cells
- (void)setEditing:(BOOL)editing animated:(BOOL)animated;

// Customizing Options
@property (nonatomic, gm_weak) IBOutlet UIView *mainSuperView;        // Default is self
@property (nonatomic) GMGridViewStyle style;                          // Default is GMGridViewStyleSwap
@property (nonatomic) NSInteger itemSpacing;                          // Default is 10
@property (nonatomic) BOOL centerGrid;                                // Default is YES
@property (nonatomic) UIEdgeInsets minEdgeInsets;                     // Default is (5, 5, 5, 5)
@property (nonatomic) CFTimeInterval minimumPressDuration;            // Default is 0.2; if set to 0, the view wont be scrollable
@property (nonatomic) BOOL showFullSizeViewWithAlphaWhenTransforming; // Default is YES - not working right now
@property (nonatomic) BOOL enableEditOnLongPress;                     // Default is NO
@property (nonatomic) BOOL disableEditOnEmptySpaceTap;                // Default is NO

@property (nonatomic, readonly) UIScrollView *scrollView __attribute__((deprecated)); // The grid now inherits directly from UIScrollView

// Reusable cells
- (GMGridViewCell *)dequeueReusableCell;                              // Should be called in GMGridView:cellForItemAtIndex: to reuse a cell
- (GMGridViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;

// Cells
- (GMGridViewCell *)cellForItemAtIndex:(NSInteger)position;           // Might return nil if cell not loaded yet

// Actions
- (void)reloadData;
- (void)insertObjectAtIndex:(NSInteger)index animated:(BOOL)animated;
- (void)insertObjectAtIndex:(NSInteger)index withAnimation:(GMGridViewItemAnimation)animation;
- (void)removeObjectAtIndex:(NSInteger)index animated:(BOOL)animated;
- (void)removeObjectAtIndex:(NSInteger)index withAnimation:(GMGridViewItemAnimation)animation;
- (void)reloadObjectAtIndex:(NSInteger)index animated:(BOOL)animated;
- (void)reloadObjectAtIndex:(NSInteger)index withAnimation:(GMGridViewItemAnimation)animation;
- (void)swapObjectAtIndex:(NSInteger)index1 withObjectAtIndex:(NSInteger)index2 animated:(BOOL)animated;
- (void)swapObjectAtIndex:(NSInteger)index1 withObjectAtIndex:(NSInteger)index2 withAnimation:(GMGridViewItemAnimation)animation;
- (void)scrollToObjectAtIndex:(NSInteger)index atScrollPosition:(GMGridViewScrollPosition)scrollPosition animated:(BOOL)animated;

// Force the grid to update properties in an (probably) animated way.
- (void)layoutSubviewsWithAnimation:(GMGridViewItemAnimation)animation;

@end


//////////////////////////////////////////////////////////////
#pragma mark Protocol GMGridViewDataSource
//////////////////////////////////////////////////////////////

@protocol GMGridViewDataSource <NSObject>

@required
// Populating subview items 
- (NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView;
- (CGSize)GMGridView:(GMGridView *)gridView sizeForItemsInInterfaceOrientation:(UIInterfaceOrientation)orientation;
- (GMGridViewCell *)GMGridView:(GMGridView *)gridView cellForItemAtIndex:(NSInteger)index;

@optional
// Allow a cell to be deletable. If not implemented, YES is assumed.
- (BOOL)GMGridView:(GMGridView *)gridView canDeleteItemAtIndex:(NSInteger)index;

@end


//////////////////////////////////////////////////////////////
#pragma mark Protocol GMGridViewActionDelegate
//////////////////////////////////////////////////////////////

@protocol GMGridViewActionDelegate <NSObject>

@required
- (void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position;

@optional
// Tap on space without any items
- (void)GMGridViewDidTapOnEmptySpace:(GMGridView *)gridView;
// Called when the delete-button has been pressed. Required to enable editing mode.
// This method wont delete the cell automatically. Call the delete method of the gridView when appropriate.
- (void)GMGridView:(GMGridView *)gridView processDeleteActionForItemAtIndex:(NSInteger)index;

- (void)GMGridView:(GMGridView *)gridView changedEdit:(BOOL)edit;

@end


//////////////////////////////////////////////////////////////
#pragma mark Protocol GMGridViewSortingDelegate
//////////////////////////////////////////////////////////////

@protocol GMGridViewSortingDelegate <NSObject>

@required
// Item moved - right place to update the data structure
- (void)GMGridView:(GMGridView *)gridView moveItemAtIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex;
- (void)GMGridView:(GMGridView *)gridView exchangeItemAtIndex:(NSInteger)index1 withItemAtIndex:(NSInteger)index2;

@optional
// Sorting started/ended - indexes are not specified on purpose (not the right place to update data structure)
- (void)GMGridView:(GMGridView *)gridView didStartMovingCell:(GMGridViewCell *)cell;
- (void)GMGridView:(GMGridView *)gridView didEndMovingCell:(GMGridViewCell *)cell;
// Enable/Disable the shaking behavior of an item being moved
- (BOOL)GMGridView:(GMGridView *)gridView shouldAllowShakingBehaviorWhenMovingCell:(GMGridViewCell *)view atIndex:(NSInteger)index;

@end

//////////////////////////////////////////////////////////////
#pragma mark Protocol GMGridViewTransformationDelegate
//////////////////////////////////////////////////////////////

@protocol GMGridViewTransformationDelegate <NSObject>

@required
// Fullsize
- (CGSize)GMGridView:(GMGridView *)gridView sizeInFullSizeForCell:(GMGridViewCell *)cell atIndex:(NSInteger)index inInterfaceOrientation:(UIInterfaceOrientation)orientation;
- (UIView *)GMGridView:(GMGridView *)gridView fullSizeViewForCell:(GMGridViewCell *)cell atIndex:(NSInteger)index;

// Transformation (pinch, drag, rotate) of the item
@optional
- (void)GMGridView:(GMGridView *)gridView didStartTransformingCell:(GMGridViewCell *)cell;
- (void)GMGridView:(GMGridView *)gridView didEnterFullSizeForCell:(GMGridViewCell *)cell;
- (void)GMGridView:(GMGridView *)gridView didEndTransformingCell:(GMGridViewCell *)cell;

@end
