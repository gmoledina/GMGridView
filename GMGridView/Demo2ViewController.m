//
//  Demo2ViewController.m
//  GMGridView
//
//  Created by Gulam Moledina on 11-11-10.
//  Copyright (c) 2011 GMoledina.ca. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "Demo2ViewController.h"
#import "GMGridView.h"
#import "GMGridViewLayoutStrategies.h"
#import "OptionsViewController.h"
#import "OptionsViewController.h"

@interface Demo2ViewController () <GMGridViewDataSource, GMGridViewSortingDelegate, GMGridViewTransformationDelegate>
{
    __weak GMGridView *_gmGridView1;
    __weak GMGridView *_gmGridView2;
    
    __weak UIButton *_buttonOptionsGrid1;
    __weak UIButton *_buttonOptionsGrid2;
    
    UIPopoverController *_popOverController;
    UIViewController *_optionsController1;
    UIViewController *_optionsController2;
}

- (void)computeViewFrames;
- (void)showOptionsFromButton:(UIButton *)button;
- (void)optionsDoneAction;

@end


//////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark ViewController implementation
//////////////////////////////////////////////////////////////

@implementation Demo2ViewController


- (id)init
{
    if ((self = [super init])) 
    {
        self.title = @"Demo 2";
    }
    return self;
}

//////////////////////////////////////////////////////////////
#pragma mark View lifecycle
//////////////////////////////////////////////////////////////

- (void)loadView
{
    [super loadView];
    self.view.backgroundColor = [UIColor whiteColor];

    GMGridView *gmGridView = [[GMGridView alloc] initWithFrame:self.view.bounds];
    gmGridView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    gmGridView.style = GMGridViewStylePush;
    gmGridView.itemSpacing = 5;
    gmGridView.minEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    gmGridView.centerGrid = YES;
    gmGridView.layoutStrategy = [GMGridViewLayoutStrategyFactory strategyFromType:GMGridViewLayoutVertical];
    [self.view addSubview:gmGridView];
    _gmGridView1 = gmGridView;
    
    GMGridView *gmGridView2 = [[GMGridView alloc] initWithFrame:self.view.bounds];
    gmGridView2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    gmGridView2.style = GMGridViewStylePush;
    gmGridView2.itemSpacing = 5;
    gmGridView2.minEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    gmGridView2.centerGrid = YES;
    gmGridView2.layoutStrategy = [GMGridViewLayoutStrategyFactory strategyFromType:GMGridViewLayoutHorizontal];
    [self.view addSubview:gmGridView2];
    _gmGridView2 = gmGridView2;
    
    _buttonOptionsGrid1 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_buttonOptionsGrid1 setTitle:@"Options Grid1" forState:UIControlStateNormal];
    [_buttonOptionsGrid1 setReversesTitleShadowWhenHighlighted:YES];
    [_buttonOptionsGrid1 sizeToFit];
    _buttonOptionsGrid1.frame = CGRectMake(0, 0, _buttonOptionsGrid1.frame.size.width + 10, _buttonOptionsGrid1.frame.size.height + 10);
    [_buttonOptionsGrid1 addTarget:self action:@selector(showOptionsFromButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_buttonOptionsGrid1];
    
    _buttonOptionsGrid2 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_buttonOptionsGrid2 setTitle:@"Options Grid2" forState:UIControlStateNormal];
    [_buttonOptionsGrid2 setReversesTitleShadowWhenHighlighted:YES];
    [_buttonOptionsGrid2 sizeToFit];
    _buttonOptionsGrid2.frame = CGRectMake(0, 0, _buttonOptionsGrid2.frame.size.width + 10, _buttonOptionsGrid2.frame.size.height + 10);
    [_buttonOptionsGrid2 addTarget:self action:@selector(showOptionsFromButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_buttonOptionsGrid2];
    
    [self computeViewFrames];
}

- (void)viewDidLayoutSubviews
{
    [self computeViewFrames];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _gmGridView1.sortingDelegate   = self;
    _gmGridView1.transformDelegate = self;
    _gmGridView1.dataSource = self;
    
    _gmGridView2.sortingDelegate   = self;
    _gmGridView2.transformDelegate = self;
    _gmGridView2.dataSource = self;
    
    _gmGridView1.mainSuperView = self.navigationController.view;
    _gmGridView2.mainSuperView = self.navigationController.view;
    
    
    OptionsViewController *optionsController = [[OptionsViewController alloc] init];
    optionsController.gridView = _gmGridView1;
    optionsController.contentSizeForViewInPopover = CGSizeMake(400, 500);
    _optionsController1 = [[UINavigationController alloc] initWithRootViewController:optionsController];
    
    OptionsViewController *optionsController2 = [[OptionsViewController alloc] init];
    optionsController2.gridView = _gmGridView2;
    optionsController2.contentSizeForViewInPopover = CGSizeMake(400, 500);
    _optionsController2 = [[UINavigationController alloc] initWithRootViewController:optionsController2];
    
    if (INTERFACE_IS_PHONE)
    {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(optionsDoneAction)];
        optionsController.navigationItem.rightBarButtonItem = doneButton;
        
        UIBarButtonItem *doneButton2 = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(optionsDoneAction)];
        optionsController2.navigationItem.rightBarButtonItem = doneButton2;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

//////////////////////////////////////////////////////////////
#pragma mark Controller events
//////////////////////////////////////////////////////////////

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

//////////////////////////////////////////////////////////////
#pragma mark Privates
//////////////////////////////////////////////////////////////

- (void)computeViewFrames
{
    CGSize itemSize = [self sizeForItemsInGMGridView:_gmGridView1];
    CGSize minSize  = CGSizeMake(itemSize.width  + _gmGridView1.minEdgeInsets.right + _gmGridView1.minEdgeInsets.left, 
                                 itemSize.height + _gmGridView1.minEdgeInsets.top   + _gmGridView1.minEdgeInsets.bottom);
    
    
    CGRect frame1 = CGRectMake(10, 10, minSize.width, self.view.bounds.size.height - minSize.height - 30);
    CGRect frame2 = CGRectMake(10, frame1.size.height + 20, self.view.bounds.size.width - 20 , minSize.height);
    
    _gmGridView1.frame = frame1;
    _gmGridView2.frame = frame2;
    
    _buttonOptionsGrid1.frame = CGRectMake(frame1.origin.x + frame1.size.width + 5, 
                                           frame1.origin.y, 
                                           _buttonOptionsGrid1.frame.size.width, 
                                           _buttonOptionsGrid1.frame.size.height);
    
    _buttonOptionsGrid2.frame = CGRectMake(frame2.origin.x + frame2.size.width - _buttonOptionsGrid2.frame.size.width, 
                                           frame2.origin.y - _buttonOptionsGrid2.frame.size.height - 5, 
                                           _buttonOptionsGrid2.frame.size.width, 
                                           _buttonOptionsGrid2.frame.size.height);
    
    
}

- (void)showOptionsFromButton:(UIButton *)button
{
    UIViewController *optionsControllerToShow = button == _buttonOptionsGrid1 ? _optionsController1 : _optionsController2;
    
    if (INTERFACE_IS_PHONE)
    {
        [self presentModalViewController:_optionsController1 animated:YES];
    }
    else
    {
        if(![_popOverController isPopoverVisible])
        {
            _popOverController = [[UIPopoverController alloc] initWithContentViewController:optionsControllerToShow];
            [_popOverController presentPopoverFromRect:button.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
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
        [_popOverController dismissPopoverAnimated:YES];
        _popOverController = nil;
    }
}

//////////////////////////////////////////////////////////////
#pragma mark GMGridViewDataSource
//////////////////////////////////////////////////////////////

- (NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView
{
    return 50;
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

- (UIView *)GMGridView:(GMGridView *)gridView viewForItemAtIndex:(NSInteger)index
{
    CGSize size = [self sizeForItemsInGMGridView:gridView];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    view.backgroundColor =  gridView == _gmGridView1 ? [UIColor purpleColor] : [UIColor greenColor];
    view.layer.masksToBounds = NO;
    view.layer.cornerRadius = 8;
    view.layer.shadowColor = [UIColor grayColor].CGColor;
    view.layer.shadowOffset = CGSizeMake(5, 5);
    view.layer.shadowPath = [UIBezierPath bezierPathWithRect:view.bounds].CGPath;
    view.layer.shadowRadius = 8;
    
    UILabel *label = [[UILabel alloc] initWithFrame:view.frame];
    label.text = [NSString stringWithFormat:@"%d", index];
    label.textAlignment = UITextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor blackColor];
    label.font = [UIFont boldSystemFontOfSize:20];
    [view addSubview:label];
    
    return view;
}


//////////////////////////////////////////////////////////////
#pragma mark GMGridViewSortingDelegate
//////////////////////////////////////////////////////////////

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
                         view.backgroundColor = (gridView == _gmGridView1) ? [UIColor purpleColor] : [UIColor greenColor];
                         view.layer.shadowOpacity = 0;
                     }
                     completion:nil
     ];
}

- (BOOL)GMGridView:(GMGridView *)gridView shouldAllowShakingBehaviorWhenMovingView:(UIView *)view atIndex:(NSInteger)index
{
    return YES;
}

- (void)GMGridView:(GMGridView *)gridView moveItemAtIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex
{
    // We dont care about this in this demo (see demo 1 for examples)
}

- (void)GMGridView:(GMGridView *)gridView exchangeItemAtIndex:(NSInteger)index1 withItemAtIndex:(NSInteger)index2
{
    // We dont care about this in this demo (see demo 1 for examples)
}


//////////////////////////////////////////////////////////////
#pragma mark DraggableGridViewTransformingDelegate
//////////////////////////////////////////////////////////////

- (CGSize)GMGridView:(GMGridView *)gridView sizeInFullSizeForView:(UIView *)view
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

- (UIView *)GMGridView:(GMGridView *)gridView fullSizeViewForView:(UIView *)view
{
    UIView *fullView = [[UIView alloc] init];
    fullView.backgroundColor = [UIColor yellowColor];
    fullView.layer.masksToBounds = NO;
    fullView.layer.cornerRadius = 8;
    
    CGSize size = [self GMGridView:gridView sizeInFullSizeForView:view];
    fullView.bounds = CGRectMake(0, 0, size.width, size.height);
    
    UILabel *label = [[UILabel alloc] initWithFrame:fullView.bounds];
    label.text = @"Fullscreen View";
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
                         view.backgroundColor = (gridView == _gmGridView1) ? [UIColor purpleColor] : [UIColor greenColor];
                         view.layer.shadowOpacity = 0;
                     } 
                     completion:nil];
}

- (void)GMGridView:(GMGridView *)gridView didEnterFullSizeForView:(UIView *)view
{
    
}


@end
