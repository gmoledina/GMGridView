//
//  ViewController.m
//  GMGridView
//
//  Created by Gulam Moledina on 11-10-09.
//  Copyright (c) 2011 GMoledina.ca. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "Demo1ViewController.h"
#import "GMGridView.h"
#import "OptionsViewController.h"

#define NUMBER_ITEMS_ON_LOAD 250

//////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark ViewController (privates methods)
//////////////////////////////////////////////////////////////

@interface Demo1ViewController () <GMGridViewDataSource, GMGridViewSortingDelegate, GMGridViewTransformationDelegate, GMGridViewActionDelegate>
{
    __gm_weak GMGridView *_gmGridView;
    UINavigationController *_optionsNav;
    UIPopoverController *_optionsPopOver;
    
    NSMutableArray *_data;
}

- (void)addMoreItem;
- (void)removeItem;
- (void)refreshItem;
- (void)presentInfo;
- (void)presentOptions:(UIBarButtonItem *)barButton;
- (void)optionsDoneAction;

@end


//////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark ViewController implementation
//////////////////////////////////////////////////////////////

@implementation Demo1ViewController


- (id)init
{
    if ((self =[super init])) 
    {
        self.title = @"Demo 1";
        
        UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addMoreItem)];
        
        UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        space.width = 10;
        
        UIBarButtonItem *removeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(removeItem)];
        
        UIBarButtonItem *space2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        space2.width = 10;
        
        UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshItem)];
        
        if ([self.navigationItem respondsToSelector:@selector(leftBarButtonItems)]) {
            self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:addButton, space, removeButton, space2, refreshButton, nil];
        }else {
            self.navigationItem.leftBarButtonItem = addButton;
        }
        
        UIBarButtonItem *optionsButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(presentOptions:)];
        
        if ([self.navigationItem respondsToSelector:@selector(rightBarButtonItems)]) {
            self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:optionsButton, nil];
        }else {
            self.navigationItem.rightBarButtonItem = optionsButton;
        }
        
        _data = [[NSMutableArray alloc] init];
        
        for (int i = 0; i < NUMBER_ITEMS_ON_LOAD; i ++) 
        {
            [_data addObject:[NSString stringWithFormat:@"%d", i]];
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
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSInteger spacing = INTERFACE_IS_PHONE ? 10 : 15;
    
    GMGridView *gmGridView = [[GMGridView alloc] initWithFrame:self.view.bounds];
    gmGridView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    gmGridView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:gmGridView];
    _gmGridView = gmGridView;
    
    _gmGridView.style = GMGridViewStyleSwap;
    _gmGridView.itemSpacing = spacing;
    _gmGridView.minEdgeInsets = UIEdgeInsetsMake(spacing, spacing, spacing, spacing);
    _gmGridView.centerGrid = YES;
    _gmGridView.actionDelegate = self;
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
    
    
    OptionsViewController *optionsController = [[OptionsViewController alloc] init];
    optionsController.gridView = gmGridView;
    optionsController.contentSizeForViewInPopover = CGSizeMake(400, 500);
    
    _optionsNav = [[UINavigationController alloc] initWithRootViewController:optionsController];
    
    if (INTERFACE_IS_PHONE)
    {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(optionsDoneAction)];
        optionsController.navigationItem.rightBarButtonItem = doneButton;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _gmGridView.mainSuperView = self.navigationController.view; //[UIApplication sharedApplication].keyWindow.rootViewController.view;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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
#pragma mark GMGridViewDataSource
//////////////////////////////////////////////////////////////

- (NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView
{
    return [_data count];
}

- (CGSize)sizeForItemsInGMGridView:(GMGridView *)gridView
{
    if (INTERFACE_IS_PHONE) 
    {
        return CGSizeMake(140, 110);
    }
    else
    {
        return CGSizeMake(230, 175);
    }
}

- (GMGridViewCell *)GMGridView:(GMGridView *)gridView cellForItemAtIndex:(NSInteger)index
{
    //NSLog(@"Creating view indx %d", index);
    
    CGSize size = [self sizeForItemsInGMGridView:gridView];
    
    GMGridViewCell *cell = [gridView dequeueReusableCell];
    
    if (!cell) 
    {
        cell = [[GMGridViewCell alloc] init];
        cell.deleteButtonIcon = [UIImage imageNamed:@"close_x.png"];
        cell.deleteButtonOffset = CGPointMake(-15, -15);
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        view.backgroundColor = [UIColor redColor];
        view.layer.masksToBounds = NO;
        view.layer.cornerRadius = 8;
        view.layer.shadowColor = [UIColor grayColor].CGColor;
        view.layer.shadowOffset = CGSizeMake(5, 5);
        view.layer.shadowPath = [UIBezierPath bezierPathWithRect:view.bounds].CGPath;
        view.layer.shadowRadius = 8;
        
        cell.contentView = view;
    }
    
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    UILabel *label = [[UILabel alloc] initWithFrame:cell.contentView.bounds];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    label.text = (NSString *)[_data objectAtIndex:index];
    label.textAlignment = UITextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor blackColor];
    label.font = [UIFont boldSystemFontOfSize:20];
    [cell.contentView addSubview:label];
    
    return cell;
}

- (void)GMGridView:(GMGridView *)gridView deleteItemAtIndex:(NSInteger)index
{
    [_data removeObjectAtIndex:index];
}

//////////////////////////////////////////////////////////////
#pragma mark GMGridViewActionDelegate
//////////////////////////////////////////////////////////////

- (void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position
{
    NSLog(@"DId tap at index %d", position);
}



//////////////////////////////////////////////////////////////
#pragma mark GMGridViewSortingDelegate
//////////////////////////////////////////////////////////////

- (void)GMGridView:(GMGridView *)gridView didStartMovingCell:(GMGridViewCell *)cell
{
    [UIView animateWithDuration:0.3 
                          delay:0 
                        options:UIViewAnimationOptionAllowUserInteraction 
                     animations:^{
                         cell.contentView.backgroundColor = [UIColor orangeColor];
                         cell.contentView.layer.shadowOpacity = 0.7;
                     } 
                     completion:nil
     ];
}

- (void)GMGridView:(GMGridView *)gridView didEndMovingCell:(GMGridViewCell *)cell
{
    [UIView animateWithDuration:0.3 
                          delay:0 
                        options:UIViewAnimationOptionAllowUserInteraction 
                     animations:^{  
                         cell.contentView.backgroundColor = [UIColor redColor];
                         cell.contentView.layer.shadowOpacity = 0;
                     }
                     completion:nil
     ];
}

- (BOOL)GMGridView:(GMGridView *)gridView shouldAllowShakingBehaviorWhenMovingCell:(GMGridViewCell *)cell atIndex:(NSInteger)index
{
    return YES;
}

- (void)GMGridView:(GMGridView *)gridView moveItemAtIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex
{
    NSObject *object = [_data objectAtIndex:oldIndex];
    [_data removeObject:object];
    [_data insertObject:object atIndex:newIndex];
}

- (void)GMGridView:(GMGridView *)gridView exchangeItemAtIndex:(NSInteger)index1 withItemAtIndex:(NSInteger)index2
{
    [_data exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
}


//////////////////////////////////////////////////////////////
#pragma mark DraggableGridViewTransformingDelegate
//////////////////////////////////////////////////////////////

- (CGSize)GMGridView:(GMGridView *)gridView sizeInFullSizeForCell:(GMGridViewCell *)cell atIndex:(NSInteger)index
{
    if (INTERFACE_IS_PHONE) 
    {
        return CGSizeMake(310, 310);
    }
    else
    {
        return CGSizeMake(700, 530);
    }
}

- (UIView *)GMGridView:(GMGridView *)gridView fullSizeViewForCell:(GMGridViewCell *)cell atIndex:(NSInteger)index
{
    UIView *fullView = [[UIView alloc] init];
    fullView.backgroundColor = [UIColor yellowColor];
    fullView.layer.masksToBounds = NO;
    fullView.layer.cornerRadius = 8;
    
    CGSize size = [self GMGridView:gridView sizeInFullSizeForCell:cell atIndex:index];
    fullView.bounds = CGRectMake(0, 0, size.width, size.height);
    
    UILabel *label = [[UILabel alloc] initWithFrame:fullView.bounds];
    label.text = [NSString stringWithFormat:@"Fullscreen View for cell at index %d", index];
    label.textAlignment = UITextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    if (INTERFACE_IS_PHONE) 
    {
        label.font = [UIFont boldSystemFontOfSize:15];
    }
    else
    {
        label.font = [UIFont boldSystemFontOfSize:20];
    }
    
    [fullView addSubview:label];
    
    
    return fullView;
}

- (void)GMGridView:(GMGridView *)gridView didStartTransformingCell:(GMGridViewCell *)cell
{
    [UIView animateWithDuration:0.5 
                          delay:0 
                        options:UIViewAnimationOptionAllowUserInteraction 
                     animations:^{
                         cell.contentView.backgroundColor = [UIColor blueColor];
                         cell.contentView.layer.shadowOpacity = 0.7;
                     } 
                     completion:nil];
}

- (void)GMGridView:(GMGridView *)gridView didEndTransformingCell:(GMGridViewCell *)cell
{
    [UIView animateWithDuration:0.5 
                          delay:0 
                        options:UIViewAnimationOptionAllowUserInteraction 
                     animations:^{
                         cell.contentView.backgroundColor = [UIColor redColor];
                         cell.contentView.layer.shadowOpacity = 0;
                     } 
                     completion:nil];
}

- (void)GMGridView:(GMGridView *)gridView didEnterFullSizeForCell:(UIView *)cell
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
    NSString *info = @"Long-press an item and its color will change; letting you know that you can now move it around. \n\nUsing two fingers, pinch/drag/rotate an item; zoom it enough and you will enter the fullsize mode";
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Info" 
                                                        message:info 
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK" 
                                              otherButtonTitles:nil];
    
    [alertView show];
}

- (void)presentOptions:(UIBarButtonItem *)barButton
{
    if (INTERFACE_IS_PHONE)
    {
        [self presentModalViewController:_optionsNav animated:YES];
    }
    else
    {
        if(![_optionsPopOver isPopoverVisible])
        {
            if (!_optionsPopOver)
            {
                _optionsPopOver = [[UIPopoverController alloc] initWithContentViewController:_optionsNav];
            }
            
            [_optionsPopOver presentPopoverFromBarButtonItem:barButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
        else
        {
            [self optionsDoneAction];
        }
    }
}

- (void)optionsDoneAction
{
    if (INTERFACE_IS_PHONE)
    {
        [self dismissModalViewControllerAnimated:YES];
    }
    else
    {
        [_optionsPopOver dismissPopoverAnimated:YES];
    }
}

@end
