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

// use special weak keyword
#if !defined gm_weak && __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_5_0 && !defined (GM_DONT_USE_ARC_WEAK_FEATURE)
#define gm_weak weak
#define __gm_weak __weak
#define gm_nil(x)
#elif !defined gm_weak
#define gm_weak unsafe_unretained
#define __gm_weak __unsafe_unretained
#define gm_nil(x) x = nil
#endif

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


//////////////////////////////////////////////////////////////
#pragma mark Interface GMGridView
//////////////////////////////////////////////////////////////

@interface GMGridView : UIView
{
    
}

// Delegates
@property (nonatomic, gm_weak) NSObject<GMGridViewDataSource> *dataSource;                    // Required
@property (nonatomic, gm_weak) NSObject<GMGridViewActionDelegate> *actionDelegate;            // Optional - to get taps callback
@property (nonatomic, gm_weak) NSObject<GMGridViewSortingDelegate> *sortingDelegate;          // Optional - to enable sorting
@property (nonatomic, gm_weak) NSObject<GMGridViewTransformationDelegate> *transformDelegate; // Optional - to enable fullsize mode

// Layout Strategy
@property (nonatomic, strong) id<GMGridViewLayoutStrategy> layoutStrategy; // Default is GMGridViewLayoutVerticalStrategy

// Editing Mode
@property (nonatomic, getter=isEditing) BOOL editing; // Default is NO - When set to YES, all gestures are disabled and delete buttons shows up on cells

// Customizing Options
@property (nonatomic, gm_weak) UIView *mainSuperView;                 // Default is self
@property (nonatomic) GMGridViewStyle style;                          // Default is GMGridViewStyleSwap
@property (nonatomic) NSInteger itemSpacing;                          // Default is 10
@property (nonatomic) BOOL centerGrid;                                // Default is YES
@property (nonatomic) UIEdgeInsets minEdgeInsets;                     // Default is (5, 5, 5, 5)
@property (nonatomic) CFTimeInterval minimumPressDuration;            // Default is 0.2; if set to 0, the scrollView will not be scrollable
@property (nonatomic) BOOL showFullSizeViewWithAlphaWhenTransforming; // Default is YES - not working right now

@property (nonatomic, strong) UIScrollView *scrollView;


// Reusable cells
- (GMGridViewCell *)dequeueReusableCell;

// Cells
- (GMGridViewCell *)cellForItemAtIndex:(NSInteger)position;

// Actions
- (void)reloadData;
- (void)insertObjectAtIndex:(NSInteger)index;
- (void)removeObjectAtIndex:(NSInteger)index;
- (void)reloadObjectAtIndex:(NSInteger)index;
- (void)swapObjectAtIndex:(NSInteger)index1 withObjectAtIndex:(NSInteger)index2;
- (void)scrollToObjectAtIndex:(NSInteger)index animated:(BOOL)animated;

@end


//////////////////////////////////////////////////////////////
#pragma mark Protocol GMGridViewDataSource
//////////////////////////////////////////////////////////////

@protocol GMGridViewDataSource <NSObject>

@required
// Populating subview items 
- (NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView;
- (CGSize)sizeForItemsInGMGridView:(GMGridView *)gridView;
- (GMGridViewCell *)GMGridView:(GMGridView *)gridView cellForItemAtIndex:(NSInteger)index;

@optional
// Required to enable editing mode
- (void)GMGridView:(GMGridView *)gridView deleteItemAtIndex:(NSInteger)index;

@end


//////////////////////////////////////////////////////////////
#pragma mark Protocol GMGridViewActionDelegate
//////////////////////////////////////////////////////////////

@protocol GMGridViewActionDelegate <NSObject>

@required
- (void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position;

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
- (CGSize)GMGridView:(GMGridView *)gridView sizeInFullSizeForCell:(GMGridViewCell *)cell atIndex:(NSInteger)index;
- (UIView *)GMGridView:(GMGridView *)gridView fullSizeViewForCell:(GMGridViewCell *)cell atIndex:(NSInteger)index;

// Transformation (pinch, drag, rotate) of the item
@optional
- (void)GMGridView:(GMGridView *)gridView didStartTransformingCell:(GMGridViewCell *)cell;
- (void)GMGridView:(GMGridView *)gridView didEnterFullSizeForCell:(GMGridViewCell *)cell;
- (void)GMGridView:(GMGridView *)gridView didEndTransformingCell:(GMGridViewCell *)cell;

@end
