//
//  GMGridView.h
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

#import <UIKit/UIKit.h>

@protocol GMGridViewDelegate;
@protocol GMGridViewDataSource;

typedef enum
{
    GMGridViewStylePush = 0,
    GMGridViewStyleSwap
} GMGridViewStyle;


//////////////////////////////////////////////////////////////
#pragma mark Interface DraggableGridView
//////////////////////////////////////////////////////////////

@interface GMGridView : UIView
{
    
}

@property (nonatomic, weak) id<GMGridViewDataSource> dataSource;
@property (nonatomic, weak) id<GMGridViewDelegate> delegate;

@property (nonatomic, assign) NSInteger itemPadding;
@property (nonatomic, assign) GMGridViewStyle style;
@property (nonatomic) CFTimeInterval minimumPressDuration; // If set to 0, the scrollView will not be scrollable

- (void)reloadData;
- (void)insertObjectAtIndex:(NSInteger)index;
- (void)removeObjectAtIndex:(NSInteger)index;
- (void)swapObjectAtIndex:(NSInteger)index1 withObjectAtIndex:(NSInteger)index2;
- (void)reloadObjectAtIndex:(NSInteger)index;

@end


//////////////////////////////////////////////////////////////
#pragma mark Protocol DraggableGridViewDataSource
//////////////////////////////////////////////////////////////

@protocol GMGridViewDataSource

- (NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView;
- (NSInteger)widthForItemsInGMGridView:(GMGridView *)gridView;
- (NSInteger)heightForItemsInGMGridView:(GMGridView *)gridView;
- (UIView *)GMGridView:(GMGridView *)gridView viewForItemAtIndex:(NSInteger)index;

@end


//////////////////////////////////////////////////////////////
#pragma mark Protocol DraggableGridViewDelegate
//////////////////////////////////////////////////////////////

@protocol GMGridViewDelegate

- (void)GMGridView:(GMGridView *)gridView didStartMovingView:(UIView *)view;
- (void)GMGridView:(GMGridView *)gridView didEndMovingView:(UIView *)view;
- (void)GMGridView:(GMGridView *)gridView itemAtIndex:(NSInteger)oldIndex movedToIndex:(NSInteger)newIndex;

@end
