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


#define NUMBER_ITEMS_ON_LOAD 200

//////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark ViewController (privates methods)
//////////////////////////////////////////////////////////////

@interface ViewController () <GMGridViewDataSource, GMGridViewDelegate>
{
    __weak GMGridView *mw_gmGridView;
    NSMutableOrderedSet *m_data;
    CGSize m_itemSize;
    CGFloat m_itemPadding;
}

- (void)addMoreItem;
- (void)removeItem;
- (void)refreshItem;
- (void)segmentedControlChanged:(UISegmentedControl *)control;
- (void)presentInfo;

@end


//////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark ViewController implementation
//////////////////////////////////////////////////////////////

@implementation ViewController


- (id)init
{
    if ((self =[super init])) 
    {
        UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addMoreItem)];
        
        UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        space.width = 10;
        
        UIBarButtonItem *removeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(removeItem)];
        
        UIBarButtonItem *space2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        space2.width = 10;
        
        UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshItem)];
    
        UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Swap", @"Push", nil]];
        segmentedControl.frame = CGRectMake(0, 0, 150, 30);
        [segmentedControl addTarget:self action:@selector(segmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
        segmentedControl.selectedSegmentIndex = 0;

        UIBarButtonItem *segmentedBarItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
        
        
        self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:addButton, space, removeButton, space2, refreshButton, nil];
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:segmentedBarItem, nil];
        
                
        m_data = [[NSMutableOrderedSet alloc] init];
        
        for (int i = 0; i < NUMBER_ITEMS_ON_LOAD; i ++) 
        {
            [m_data addObject:[NSString stringWithFormat:@"%d", i]];
        }
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) 
        {
            m_itemSize = CGSizeMake(60, 50);
            m_itemPadding = 10;
        }
        else
        {
            m_itemSize = CGSizeMake(120, 90);
            m_itemPadding = 15;
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
    
    GMGridView *gmGridView = [[GMGridView alloc] initWithFrame:self.view.bounds];
    gmGridView.style = GMGridViewStyleSwap;
    gmGridView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    gmGridView.itemPadding = m_itemPadding;
    gmGridView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:gmGridView];
    mw_gmGridView = gmGridView;
    
    mw_gmGridView.delegate = self;
    mw_gmGridView.dataSource = self;
    
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

- (NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView
{
    return [m_data count];
}

- (NSInteger)widthForItemsInGMGridView:(GMGridView *)gridView
{
    return m_itemSize.width;
}

- (NSInteger)heightForItemsInGMGridView:(GMGridView *)gridView
{
    return m_itemSize.height;
}

- (UIView *)GMGridView:(GMGridView *)gridView viewForItemAtIndex:(NSInteger)index
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
    label.text = (NSString *)[m_data objectAtIndex:index];
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

- (void)GMGridView:(GMGridView *)gridView itemAtIndex:(NSInteger)oldIndex movedToIndex:(NSInteger)newIndex
{
    [m_data moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:oldIndex] toIndex:newIndex];
}

- (void)GMGridView:(GMGridView *)gridView didStartMovingView:(UIView *)view
{
    view.backgroundColor = [UIColor orangeColor];
    view.layer.shadowOpacity = 0.7;
}

- (void)GMGridView:(GMGridView *)gridView didEndMovingView:(UIView *)view
{
    view.backgroundColor = [UIColor redColor];
    view.layer.shadowOpacity = 0;
}


//////////////////////////////////////////////////////////////
#pragma mark private methods
//////////////////////////////////////////////////////////////

- (void)addMoreItem
{
    // Example: adding object at the last position
    NSString *newItem = [NSString stringWithFormat:@"%d", (int)(arc4random() % 1000)];
    
    if (![m_data containsObject:newItem]) 
    {
        [m_data addObject:newItem];
        
        [mw_gmGridView insertObjectAtIndex:[m_data count] - 1];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Duplicate" 
                                                            message:[NSString stringWithFormat:@"Data already contains '%@'", newItem] 
                                                           delegate:nil 
                                                  cancelButtonTitle:@"OK" 
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)removeItem
{
    // Example: removing last item
    if ([m_data count] > 0) 
    {
        NSInteger index = [m_data count] - 1;
        
        [mw_gmGridView removeObjectAtIndex:index];
        [m_data removeObjectAtIndex:index];
    }
}

- (void)refreshItem
{
    // Example: reloading last item
    if ([m_data count] > 0) 
    {
        int index = [m_data count] - 1;
        
        NSString *newMessage = [NSString stringWithFormat:@"%d", (arc4random() % 1000)];
        
        if (![m_data containsObject:newMessage]) 
        {
            [m_data replaceObjectAtIndex:index withObject:newMessage];
            [mw_gmGridView reloadObjectAtIndex:index];
        }
    }
}

- (void)presentInfo
{
    NSString *info = @"Long-press an item and its color will change; letting you know that you can now move it around.";
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Info" 
                                                        message:info 
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK" 
                                              otherButtonTitles:nil];
    
    [alertView show];
}

- (void)segmentedControlChanged:(UISegmentedControl *)control
{
    switch (control.selectedSegmentIndex) 
    {
        case 1:
            mw_gmGridView.style = GMGridViewStylePush;
            break;
        case 0:
        default:
            mw_gmGridView.style = GMGridViewStyleSwap;
            break;
    }
}

@end
