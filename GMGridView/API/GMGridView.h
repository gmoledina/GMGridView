//
//  GMGridView.h
//  GMGridView
//
//  Created by Gulam Moledina on 11-10-09.
//  Copyright (c) 2011 GMoledina.ca. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DraggableGridViewDelegate;
@protocol DraggableGridViewDataSource;

typedef enum
{
    DraggableGridViewStylePush = 0,
    DraggableGridViewStyleSwap
} DraggableGridViewStyle;


//////////////////////////////////////////////////////////////
#pragma mark Interface DraggableGridView
//////////////////////////////////////////////////////////////

@interface GMGridView : UIView
{
    
}

@property (nonatomic, weak) id<DraggableGridViewDataSource> dataSource;
@property (nonatomic, weak) id<DraggableGridViewDelegate> delegate;

@property (nonatomic, assign) NSInteger itemPadding;
@property (nonatomic, assign) DraggableGridViewStyle style;
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

@protocol DraggableGridViewDataSource

- (NSInteger)numberOfItemsInDraggableView:(GMGridView *)draggableView;
- (NSInteger)widthForItemsInDraggableView:(GMGridView *)draggableView;
- (NSInteger)heightForItemsInDraggableView:(GMGridView *)draggableView;
- (UIView *)draggableView:(GMGridView *)draggableView viewForItemAtIndex:(NSInteger)index;

@end


//////////////////////////////////////////////////////////////
#pragma mark Protocol DraggableGridViewDelegate
//////////////////////////////////////////////////////////////

@protocol DraggableGridViewDelegate

- (void)draggableView:(GMGridView *)draggableView didStartMovingView:(UIView *)view;
- (void)draggableView:(GMGridView *)draggableView didEndMovingView:(UIView *)view;
- (void)draggableView:(GMGridView *)draggableView itemAtIndex:(NSInteger)oldIndex movedToIndex:(NSInteger)newIndex;

@end
