//
//  ViewController.m
//  GMGridView
//
//  Created by Gulam Moledina on 11-10-09.
//  Copyright (c) 2011 GMoledina.ca. All rights reserved.
//

#import "ViewController.h"
#import "GMGridView.h"
#import <QuartzCore/QuartzCore.h>

//////////////////////////////////////////////////////////////
#pragma mark ViewController (privates methods)
//////////////////////////////////////////////////////////////

@interface ViewController () <DraggableGridViewDataSource, DraggableGridViewDelegate>
{
    GMGridView *mw_draggableView;
    NSMutableOrderedSet *m_data;
    CGSize m_itemSize;
}

- (void)addMoreItem;
- (void)removeItem;
- (void)refreshItem;
- (void)segmentedControlChanged:(UISegmentedControl *)control;
- (void)presentInfo;

@end


//////////////////////////////////////////////////////////////
#pragma mark ViewController implementation
//////////////////////////////////////////////////////////////
@implementation ViewController


- (id)init
{
    if ((self =[super init])) 
    {
        // Left bar
        
        UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addMoreItem)];
        
        UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        space.width = 10;
        
        UIBarButtonItem *removeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(removeItem)];
        
        UIBarButtonItem *space2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        space2.width = 10;
        
        UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshItem)];
    
        self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:addButton, space, removeButton, space2, refreshButton, nil];
    
        
        
        // Right bar
        
        UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Swap", @"Push", nil]];
        segmentedControl.frame = CGRectMake(0, 0, 150, 30);
        [segmentedControl addTarget:self action:@selector(segmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
        segmentedControl.selectedSegmentIndex = 0;

        UIBarButtonItem *segmentedBarItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
        
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:segmentedBarItem, nil];
        
        
        // Data
        
        m_data = [[NSMutableOrderedSet alloc] init];
        
        for (int i = 0; i < 200; i ++) 
        {
            [m_data addObject:[NSString stringWithFormat:@"%d", i]];
        }
        
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) 
        {
            m_itemSize = CGSizeMake(60, 50);
        }
        else
        {
            m_itemSize = CGSizeMake(120, 90);
        }
    }
    
    return self;
}

//////////////////////////////////////////////////////////////
#pragma mark controller events
//////////////////////////////////////////////////////////////
- (void)loadView 
{
    [super loadView];
    self.view.backgroundColor = [UIColor redColor];
    
    GMGridView *draggableView = [[GMGridView alloc] initWithFrame:self.view.bounds];
    draggableView.style = DraggableGridViewStyleSwap;
    draggableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    draggableView.itemPadding = 15;

    [self.view addSubview:draggableView];
    mw_draggableView = draggableView;
    
    mw_draggableView.delegate = self;
    mw_draggableView.dataSource = self;
    
    
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
    infoButton.frame = CGRectMake(self.view.bounds.size.width - 40, 
                                  self.view.bounds.size.height - 40, 
                                  40,
                                  40);
    infoButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [infoButton addTarget:self action:@selector(presentInfo) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:infoButton];
}


//////////////////////////////////////////////////////////////
#pragma mark memory management
//////////////////////////////////////////////////////////////
//- (void)didReceiveMemoryWarning {
//    [super didReceiveMemoryWarning];
//}

//////////////////////////////////////////////////////////////
#pragma mark orientation management
//////////////////////////////////////////////////////////////
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}


//////////////////////////////////////////////////////////////
#pragma mark DraggableGridViewDataSource
//////////////////////////////////////////////////////////////

- (NSInteger)numberOfItemsInDraggableView:(GMGridView *)draggableView
{
    return [m_data count];
}

- (NSInteger)widthForItemsInDraggableView:(GMGridView *)draggableView
{
    return m_itemSize.width;
}

- (NSInteger)heightForItemsInDraggableView:(GMGridView *)draggableView
{
    return m_itemSize.height;
}

- (UIView *)draggableView:(GMGridView *)draggableView viewForItemAtIndex:(NSInteger)index
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, m_itemSize.width, m_itemSize.height)];
    view.backgroundColor = [UIColor redColor];
    view.layer.masksToBounds = NO;
    view.layer.cornerRadius = 8;
    view.layer.shadowColor = [UIColor grayColor].CGColor;
    view.layer.shadowOffset = CGSizeMake(5, 5);
    view.layer.shadowPath = [UIBezierPath bezierPathWithRect:view.bounds].CGPath;
    view.layer.shadowRadius = 8;
    
    UILabel *label = [[UILabel alloc] initWithFrame:view.frame];
    NSString *message = (NSString *)[m_data objectAtIndex:index];
    label.text = message;
    label.textAlignment = UITextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor blackColor];
    label.font = [UIFont boldSystemFontOfSize:20];
    [view addSubview:label];
    
    return view;
}


//////////////////////////////////////////////////////////////
#pragma mark DraggableGridViewProtocol
//////////////////////////////////////////////////////////////

- (void)draggableView:(GMGridView *)draggableView itemAtIndex:(NSInteger)oldIndex movedToIndex:(NSInteger)newIndex
{
    [m_data moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:oldIndex] toIndex:newIndex];
}

- (void)draggableView:(GMGridView *)draggableView didStartMovingView:(UIView *)view
{
    view.backgroundColor = [UIColor orangeColor];
    view.layer.shadowOpacity = 0.7;
}

- (void)draggableView:(GMGridView *)draggableView didEndMovingView:(UIView *)view
{
    view.backgroundColor = [UIColor redColor];
    view.layer.shadowOpacity = 0;
}


//////////////////////////////////////////////////////////////
#pragma mark public methods
//////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////
#pragma mark private methods
//////////////////////////////////////////////////////////////

- (void)addMoreItem
{
    NSString *newItem = [NSString stringWithFormat:@"%d", (int)(arc4random() % 1000)];
    
    if (![m_data containsObject:newItem]) 
    {
        [m_data addObject:newItem];
        
        [mw_draggableView insertObjectAtIndex:[m_data count] - 1];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Duplicate" message:[NSString stringWithFormat:@"Data already contains '%@'", newItem] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        [alertView show];
    }
}

- (void)removeItem
{
    if ([m_data count] > 0) 
    {
        NSInteger index = [m_data count] - 1;
        
        [mw_draggableView removeObjectAtIndex:index];
        [m_data removeObjectAtIndex:index];
    }
}

- (void)refreshItem
{
    if ([m_data count] > 0) 
    {
        int index = [m_data count] - 1;
        
        NSString *newMessage = [NSString stringWithFormat:@"%d", (arc4random() % 1000)];
        
        if (![m_data containsObject:newMessage]) 
        {
            [m_data replaceObjectAtIndex:index withObject:newMessage];
            [mw_draggableView reloadObjectAtIndex:index];
        }
    }
}

- (void)presentInfo
{
    NSString *info = @"Long-press an item and its color will change; letting you know that you can now move it around.";
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Info" message:info delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    [alertView show];
}

- (void)segmentedControlChanged:(UISegmentedControl *)control
{
    switch (control.selectedSegmentIndex) 
    {
        case 1:
            mw_draggableView.style = DraggableGridViewStylePush;
            break;
        case 0:
        default:
            mw_draggableView.style = DraggableGridViewStyleSwap;
            break;
    }
}


//////////////////////////////////////////////////////////////
#pragma mark control events
//////////////////////////////////////////////////////////////

@end
