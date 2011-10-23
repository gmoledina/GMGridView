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

@protocol GMGridViewDataSource;
@protocol GMGridViewSortingDelegate;
@protocol GMGridViewTransformationDelegate;

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

@property (nonatomic, weak) id<GMGridViewDataSource> dataSource;
@property (nonatomic, weak) id<GMGridViewSortingDelegate> sortingDelegate;
@property (nonatomic, weak) id<GMGridViewTransformationDelegate> transformDelegate;

@property (nonatomic, assign) NSInteger itemPadding;
@property (nonatomic, assign) BOOL centerGrid;
@property (nonatomic, assign) GMGridViewStyle style;
@property (nonatomic) CFTimeInterval minimumPressDuration; // If set to 0, the scrollView will not be scrollable

- (void)reloadData;
- (void)insertObjectAtIndex:(NSInteger)index;
- (void)removeObjectAtIndex:(NSInteger)index;
- (void)swapObjectAtIndex:(NSInteger)index1 withObjectAtIndex:(NSInteger)index2;
- (void)reloadObjectAtIndex:(NSInteger)index;

@end


//////////////////////////////////////////////////////////////
#pragma mark Protocol GMGridViewDataSource
//////////////////////////////////////////////////////////////

@protocol GMGridViewDataSource

- (NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView;
- (NSInteger)widthForItemsInGMGridView:(GMGridView *)gridView;
- (NSInteger)heightForItemsInGMGridView:(GMGridView *)gridView;
- (UIView *)GMGridView:(GMGridView *)gridView viewForItemAtIndex:(NSInteger)index;
- (void)GMGridView:(GMGridView *)gridView itemAtIndex:(NSInteger)oldIndex movedToIndex:(NSInteger)newIndex;

//@optional
- (CGSize)GMGridView:(GMGridView *)gridView fullSizeForView:(UIView *)view;
- (UIView *)GMGridView:(GMGridView *)gridView fullSizeViewForView:(UIView *)view;

@end


//////////////////////////////////////////////////////////////
#pragma mark Protocol GMGridViewSortingDelegate
//////////////////////////////////////////////////////////////

@protocol GMGridViewSortingDelegate

- (void)GMGridView:(GMGridView *)gridView didStartMovingView:(UIView *)view;
- (void)GMGridView:(GMGridView *)gridView didEndMovingView:(UIView *)view;
- (BOOL)GMGridView:(GMGridView *)gridView shouldAllowShakingBehaviorWhenMovingView:(UIView *)view atIndex:(NSInteger)index;

@end

//////////////////////////////////////////////////////////////
#pragma mark Protocol GMGridViewTransformationDelegate
//////////////////////////////////////////////////////////////

@protocol GMGridViewTransformationDelegate

- (void)GMGridView:(GMGridView *)gridView didStartTransformingView:(UIView *)view;
- (void)GMGridView:(GMGridView *)gridView didEnterFullSizeForView:(UIView *)view;
- (void)GMGridView:(GMGridView *)gridView didEndTransformingView:(UIView *)view;



@end
