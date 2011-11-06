//
//  OptionsViewController.m
//  GMGridView
//
//  Created by Gulam Moledina on 11-11-01.
//  Copyright (c) 2011 GMoledina.ca. All rights reserved.
//

#import "OptionsViewController.h"
#import "GMGridViewLayoutStrategies.h"
#import "GMGridView.h"

// Sections
typedef enum {
    OptionSectionLayout = 0,
    OptionSectionSorting,
    OptionSectionDebug,
    
    OptionSectionsCount
} OptionsTypeSections;

// Options layout
typedef enum {
    OptionTypeLayoutStrategy = 0,
    OptionsTypeLayoutSpacing,
    OptionsTypeLayoutCenter,
    OptionsTypeLayoutMinInsets,
    
    OptionLayoutCount
} OptionsTypeLayout;

// Options sorting
typedef enum {
    OptionTypeSortingStyle = 0,
    
    OptionSortingCount
} OptionsTypeSorting;

// Options debug
typedef enum {
    OptionTypeDebugGridBackground = 0,
    OptionTypeDebugReload,
    
    OptionDebugCount
} OptionsTypeDebug;

@interface OptionsViewController () <UITableViewDelegate, UITableViewDataSource>
{
    __weak UITableView *_tableView;
}

- (void)sortStyleSegmentedControlChanged:(UISegmentedControl *)control;
- (void)layoutStrategySegmentedControlChanged:(UISegmentedControl *)control;
- (void)layoutCenterSwitchChanged:(UISwitch *)control;
- (void)layoutSpacingSliderChanged:(UISlider *)control;
- (void)layoutInsetsSliderChanged:(UISlider *)control;
- (void)debugGridBackgroundSwitchChanged:(UISwitch *)control;
- (void)debugReloadButtonPressed:(UIButton *)control;

@end

//////////////////////////////////////////////////////////////
#pragma mark - Implementation
//////////////////////////////////////////////////////////////

@implementation OptionsViewController

@synthesize gridView;

//////////////////////////////////////////////////////////////
#pragma mark Constructor
//////////////////////////////////////////////////////////////

- (id)init
{
    if ((self = [super init])) 
    {
        self.title = @"Options";
    }
    return self;
}

//////////////////////////////////////////////////////////////
#pragma mark View lifecycle
//////////////////////////////////////////////////////////////

- (void)loadView
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    tableView.dataSource = self;
    tableView.delegate   = self;
    self.view = tableView;
    _tableView = tableView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

//////////////////////////////////////////////////////////////
#pragma mark Controller events
//////////////////////////////////////////////////////////////

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


//////////////////////////////////////////////////////////////
#pragma mark UITableView datasource & delegates
//////////////////////////////////////////////////////////////

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 35;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return OptionSectionsCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = @"Unknown";
    
    switch (section) 
    {
        case OptionSectionLayout:
            title = @"Layout";
            break;
        case OptionSectionSorting:
            title = @"Sorting";
            break;
        case OptionSectionDebug:
            title = @"Debug";
            break;
    }
    
    return title;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    switch (section) 
    {
        case OptionSectionLayout:
            count = OptionLayoutCount;
            break;
        case OptionSectionSorting:
            count = OptionSortingCount;
            break;
        case OptionSectionDebug:
            count = OptionDebugCount;
            break;
    }
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) 
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    if ([indexPath section] == OptionSectionLayout) 
    {
        switch ([indexPath row]) 
        {
            case OptionTypeLayoutStrategy:
            {
                cell.detailTextLabel.text = @"Strategy";
                
                UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Vertical", @"Horizontal", nil]];
                segmentedControl.frame = CGRectMake(0, 0, 200, 30);
                [segmentedControl addTarget:self action:@selector(layoutStrategySegmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
                segmentedControl.selectedSegmentIndex = [self.gridView.layoutStrategy type] == GMGridViewLayoutVertical ? 0 : 1;
                
                cell.accessoryView = segmentedControl;
                break;
            }
            case OptionsTypeLayoutCenter:
            {
                cell.detailTextLabel.text = @"Center";
                
                UISwitch *centerSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
                [centerSwitch addTarget:self action:@selector(layoutCenterSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                centerSwitch.on = self.gridView.centerGrid;
                
                cell.accessoryView = centerSwitch;
                
                break;
            }
            case OptionsTypeLayoutSpacing:
            {
                cell.detailTextLabel.text = @"Spacing";
                
                UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
                [slider setMinimumValue:0];
                [slider setMaximumValue:20];
                [slider setValue:self.gridView.itemSpacing];
                [slider setContinuous:NO];
                [slider addTarget:self action:@selector(layoutSpacingSliderChanged:) forControlEvents:UIControlEventValueChanged];
                
                cell.accessoryView = slider;
                
                break;
            }
            case OptionsTypeLayoutMinInsets:
            {
                cell.detailTextLabel.text = @"Edge insets";
                
                UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
                [slider setMinimumValue:0];
                [slider setMaximumValue:50];
                [slider setValue:self.gridView.minEdgeInsets.top];
                [slider setContinuous:NO];
                [slider addTarget:self action:@selector(layoutInsetsSliderChanged:) forControlEvents:UIControlEventValueChanged];
                
                cell.accessoryView = slider;
                break;
            }
        }
    }
    else if ([indexPath section] == OptionSectionSorting)
    {
        switch ([indexPath row]) 
        {
            case OptionTypeSortingStyle:
            {
                cell.detailTextLabel.text = @"Style";
                
                UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Swap", @"Push", nil]];
                segmentedControl.frame = CGRectMake(0, 0, 150, 30);
                [segmentedControl addTarget:self action:@selector(sortStyleSegmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
                segmentedControl.selectedSegmentIndex = (self.gridView.style == GMGridViewStylePush) ? 1 : 0;
                
                cell.accessoryView = segmentedControl;
                
                break;
            }
        }
    }
    else if ([indexPath section] == OptionSectionDebug)
    {
        switch ([indexPath row]) 
        {
            case OptionTypeDebugGridBackground:
            {
                cell.detailTextLabel.text = @"Grid background color";
                
                UISwitch *backgroundSwitch = [[UISwitch alloc] init];
                [backgroundSwitch addTarget:self action:@selector(debugGridBackgroundSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                backgroundSwitch.on = (self.gridView.backgroundColor != [UIColor clearColor]);
                [backgroundSwitch sizeToFit];
                
                cell.accessoryView = backgroundSwitch;
                
                break;
            }
            case OptionTypeDebugReload:
            {
                cell.detailTextLabel.text = @"Reload from Datasource";
                
                UIButton *reloadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                [reloadButton setReversesTitleShadowWhenHighlighted:YES];
                [reloadButton setTitleColor:[UIColor redColor] forState:UIControlEventTouchUpInside];
                [reloadButton setTitle:@"Reload" forState:UIControlStateNormal];
                [reloadButton addTarget:self action:@selector(debugReloadButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                [reloadButton sizeToFit];
                
                cell.accessoryView = reloadButton;
                
                break;
            }
        }
    }

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}


//////////////////////////////////////////////////////////////
#pragma mark Control callbacks
//////////////////////////////////////////////////////////////

- (void)sortStyleSegmentedControlChanged:(UISegmentedControl *)control
{
    switch (control.selectedSegmentIndex) 
    {
        case 1:
            self.gridView.style = GMGridViewStylePush;
            break;
        case 0:
        default:
            self.gridView.style = GMGridViewStyleSwap;
            break;
    }
}

- (void)layoutStrategySegmentedControlChanged:(UISegmentedControl *)control
{
    switch (control.selectedSegmentIndex) 
    {
        case 1:
            self.gridView.layoutStrategy = [GMGridViewLayoutStrategyFactory strategyFromType:GMGridViewLayoutHorizontal];
            break;
        case 0:
        default:
            self.gridView.layoutStrategy = [GMGridViewLayoutStrategyFactory strategyFromType:GMGridViewLayoutVertical];
            break;
    }
}

- (void)layoutCenterSwitchChanged:(UISwitch *)control
{
    self.gridView.centerGrid = control.on;
}

- (void)layoutSpacingSliderChanged:(UISlider *)control
{
    self.gridView.itemSpacing = control.value;
}

- (void)layoutInsetsSliderChanged:(UISlider *)control
{
    self.gridView.minEdgeInsets = UIEdgeInsetsMake(control.value, control.value, control.value, control.value);
}

- (void)debugGridBackgroundSwitchChanged:(UISwitch *)control
{
    self.gridView.backgroundColor = control.on ? [UIColor lightGrayColor] : [UIColor clearColor];
}

- (void)debugReloadButtonPressed:(UIButton *)control
{
    [self.gridView reloadData];
}

@end
