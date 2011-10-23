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

#define NUMBER_ITEMS_ON_LOAD 250

//////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark ViewController (privates methods)
//////////////////////////////////////////////////////////////

@interface ViewController () <GMGridViewDataSource, GMGridViewSortingDelegate, GMGridViewTransformationDelegate>
{
    __weak GMGridView *_gmGridView;
    NSMutableArray *_data;
    CGSize _itemSize;
    CGFloat _itemPadding;
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
        
                
        _data = [[NSMutableArray alloc] init];
        
        for (int i = 0; i < NUMBER_ITEMS_ON_LOAD; i ++) 
        {
            [_data addObject:[NSString stringWithFormat:@"%d", i]];
        }
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) 
        {
            _itemSize = CGSizeMake(140, 110);
            _itemPadding = 10;
        }
        else
        {
            _itemSize = CGSizeMake(230, 175);
            _itemPadding = 15;
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
    gmGridView.itemPadding = _itemPadding;
    gmGridView.centerGrid = YES;
    gmGridView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:gmGridView];
    _gmGridView = gmGridView;
    
    _gmGridView.sortingDelegate = self;
    _gmGridView.transformDelegate = self;
    _gmGridView.dataSource = self;
    
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
    return [_data count];
}

- (NSInteger)widthForItemsInGMGridView:(GMGridView *)gridView
{
    return _itemSize.width;
}

- (NSInteger)heightForItemsInGMGridView:(GMGridView *)gridView
{
    return _itemSize.height;
}

- (UIView *)GMGridView:(GMGridView *)gridView viewForItemAtIndex:(NSInteger)index
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _itemSize.width, _itemSize.height)];
    view.backgroundColor = [UIColor redColor];
    view.layer.masksToBounds = NO;
    view.layer.cornerRadius = 8;
    view.layer.shadowColor = [UIColor grayColor].CGColor;
    view.layer.shadowOffset = CGSizeMake(5, 5);
    view.layer.shadowPath = [UIBezierPath bezierPathWithRect:view.bounds].CGPath;
    view.layer.shadowRadius = 8;
    
    UILabel *label = [[UILabel alloc] initWithFrame:view.frame];
    label.text = (NSString *)[_data objectAtIndex:index];
    label.textAlignment = UITextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor blackColor];
    label.font = [UIFont boldSystemFontOfSize:20];
    [view addSubview:label];
    
    return view;
}

- (CGSize)GMGridView:(GMGridView *)gridView fullSizeForView:(UIView *)view
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) 
    {
        return CGSizeMake(310, 310);
    }
    else
    {
        return CGSizeMake(700, 700);
    }
}

- (UIView *)GMGridView:(GMGridView *)gridView fullSizeViewForView:(UIView *)view
{
    UIView *fullView = [[UIView alloc] init];
    fullView.backgroundColor = [UIColor yellowColor];
    fullView.layer.masksToBounds = NO;
    fullView.layer.cornerRadius = 8;

    return fullView;
}


//////////////////////////////////////////////////////////////
#pragma mark DraggableGridViewSortingDelegate
//////////////////////////////////////////////////////////////

- (BOOL)GMGridView:(GMGridView *)gridView shouldAllowShakingBehaviorWhenMovingView:(UIView *)view atIndex:(NSInteger)index
{
    return YES;
}

- (void)GMGridView:(GMGridView *)gridView itemAtIndex:(NSInteger)oldIndex movedToIndex:(NSInteger)newIndex
{
    [_data exchangeObjectAtIndex:oldIndex withObjectAtIndex:newIndex];
}

- (void)GMGridView:(GMGridView *)gridView didStartMovingView:(UIView *)view
{
    [UIView animateWithDuration:0.3 
                          delay:0 
                        options:UIViewAnimationOptionAllowUserInteraction 
                     animations:^{
                         view.backgroundColor = [UIColor orangeColor];
                         view.layer.shadowOpacity = 0.7;
                     } 
                     completion:nil
     ];
}

- (void)GMGridView:(GMGridView *)gridView didEndMovingView:(UIView *)view
{
    [UIView animateWithDuration:0.3 
                          delay:0 
                        options:UIViewAnimationOptionAllowUserInteraction 
                     animations:^{  
                         view.backgroundColor = [UIColor redColor];
                         view.layer.shadowOpacity = 0;
                     }
                     completion:nil
     ];
}


//////////////////////////////////////////////////////////////
#pragma mark DraggableGridViewTransformingDelegate
//////////////////////////////////////////////////////////////

- (void)GMGridView:(GMGridView *)gridView didStartTransformingView:(UIView *)view
{
    [UIView animateWithDuration:0.5 
                          delay:0 
                        options:UIViewAnimationOptionAllowUserInteraction 
                     animations:^{
                         view.backgroundColor = [UIColor blueColor];
                         view.layer.shadowOpacity = 0.7;
                     } 
                     completion:nil];
}

- (void)GMGridView:(GMGridView *)gridView didEndTransformingView:(UIView *)view
{
    [UIView animateWithDuration:0.5 
                          delay:0 
                        options:UIViewAnimationOptionAllowUserInteraction 
                     animations:^{
                         view.backgroundColor = [UIColor redColor];
                         view.layer.shadowOpacity = 0;
                     } 
                     completion:nil];
}

- (void)GMGridView:(GMGridView *)gridView didEnterFullSizeForView:(UIView *)view
{
    
}


//////////////////////////////////////////////////////////////
#pragma mark private methods
//////////////////////////////////////////////////////////////

- (void)addMoreItem
{
    // Example: adding object at the last position
    NSString *newItem = [NSString stringWithFormat:@"%d", (int)(arc4random() % 1000)];
    
    [_data addObject:newItem];
    [_gmGridView insertObjectAtIndex:[_data count] - 1];
}

- (void)removeItem
{
    // Example: removing last item
    if ([_data count] > 0) 
    {
        NSInteger index = [_data count] - 1;
        
        [_gmGridView removeObjectAtIndex:index];
        [_data removeObjectAtIndex:index];
    }
}

- (void)refreshItem
{
    // Example: reloading last item
    if ([_data count] > 0) 
    {
        int index = [_data count] - 1;
        
        NSString *newMessage = [NSString stringWithFormat:@"%d", (arc4random() % 1000)];
        
        [_data replaceObjectAtIndex:index withObject:newMessage];
        [_gmGridView reloadObjectAtIndex:index];
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
            _gmGridView.style = GMGridViewStylePush;
            break;
        case 0:
        default:
            _gmGridView.style = GMGridViewStyleSwap;
            break;
    }
}

@end
