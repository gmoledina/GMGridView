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
    OptionSectionGeneral = 0,
    OptionSectionLayout,
    OptionSectionSorting,
    OptionSectionGestures,
    OptionSectionDebug,
    
    OptionSectionsCount
} OptionsTypeSections;

// General
typedef enum {
    OptionTypeGeneralEditing = 0,
    
    OptionGeneralCount
} OptionsTypeGeneral;

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

// Options Gestures
typedef enum {
    OptionTypeGesturesEditOnTap = 0,
    OptionTypeGesturesDisableEditOnEmptySpaceTap,
    
    OptionTypeGesturesCount
} OptionsTypeGestures;

// Options debug
typedef enum {
    OptionTypeDebugGridBackground = 0,
    OptionTypeDebugReload,
    
    OptionDebugCount
} OptionsTypeDebug;

@interface OptionsViewController () <UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource>
{
    __gm_weak UITableView *_tableView;
}

- (void)editingSwitchChanged:(UISwitch *)control;
- (void)sortStyleSegmentedControlChanged:(UISegmentedControl *)control;
- (void)layoutCenterSwitchChanged:(UISwitch *)control;
- (void)layoutSpacingSliderChanged:(UISlider *)control;
- (void)layoutInsetsSliderChanged:(UISlider *)control;
- (void)editOnTapSwitchChanged:(UISwitch *)control;
- (void)disableEditOnEmptySpaceTapSwitchChanged:(UISwitch *)control;
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 45;
    
    if ([indexPath section] == OptionSectionLayout) 
    {
        switch ([indexPath row]) 
        {
            case OptionTypeLayoutStrategy:
                height = 160;
                break;
        }
    }
    
    return height;
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
        case OptionSectionGeneral:
            title = @"General";
            break;
        case OptionSectionLayout:
            title = @"Layout";
            break;
        case OptionSectionSorting:
            title = @"Sorting";
            break;
        case OptionSectionGestures:
            title = @"Gestures";
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
        case OptionSectionGeneral:
            count = OptionGeneralCount;
            break;
        case OptionSectionLayout:
            count = OptionLayoutCount;
            break;
        case OptionSectionSorting:
            count = OptionSortingCount;
            break;
        case OptionSectionGestures:
            count = OptionTypeGesturesCount;
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
    else 
    {
        for (UIView* subview in cell.contentView.subviews) {
            if ([subview isKindOfClass:[UIPickerView class]]) {
                [subview removeFromSuperview];
            }
        }
    }
    
    if ([indexPath section] == OptionSectionGeneral)
    {
        switch ([indexPath row]) 
        {
            case OptionTypeGeneralEditing:
            {
                cell.detailTextLabel.text = @"Editing";
                
                UISwitch *editingSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
                [editingSwitch addTarget:self action:@selector(editingSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                editingSwitch.on = self.gridView.isEditing;
                
                cell.accessoryView = editingSwitch;
            }
        }
    }
    else if ([indexPath section] == OptionSectionLayout) 
    {
        switch ([indexPath row]) 
        {
            case OptionTypeLayoutStrategy:
            {
                cell.detailTextLabel.text = @"";
                
                UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:cell.contentView.bounds];
                pickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                pickerView.showsSelectionIndicator = YES;
                pickerView.delegate = self;
                pickerView.dataSource = self;
                
                switch ([self.gridView.layoutStrategy type]) 
                {
                    case GMGridViewLayoutHorizontalPagedTTB:
                        [pickerView selectRow:3 inComponent:0 animated:YES];
                        break;
                    case GMGridViewLayoutHorizontalPagedLTR:
                        [pickerView selectRow:2 inComponent:0 animated:YES];
                        break;
                    case GMGridViewLayoutHorizontal:
                        [pickerView selectRow:1 inComponent:0 animated:YES];
                        break;
                    case GMGridViewLayoutVertical:
                    default:
                        [pickerView selectRow:0 inComponent:0 animated:YES];
                        break;
                }

                cell.contentView.clipsToBounds = YES;
                [cell.contentView addSubview:pickerView];
                
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
    else if ([indexPath section] == OptionSectionGestures)
    {
        switch ([indexPath row]) 
        {
            case OptionTypeGesturesEditOnTap:
            {
                cell.detailTextLabel.text = @"Edit on Long Tap";
                
				UISwitch *editOnTapSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
                [editOnTapSwitch addTarget:self action:@selector(editOnTapSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                editOnTapSwitch.on = self.gridView.enableEditOnLongPress;
                
                cell.accessoryView = editOnTapSwitch;
                
                break;
            }
            case OptionTypeGesturesDisableEditOnEmptySpaceTap:
            {
                cell.detailTextLabel.text = @"Disable edit on empty tap";
                
				UISwitch *disableEditOnEmptyTapSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
                [disableEditOnEmptyTapSwitch addTarget:self action:@selector(disableEditOnEmptySpaceTapSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                disableEditOnEmptyTapSwitch.on = self.gridView.enableEditOnLongPress;
                
                cell.accessoryView = disableEditOnEmptyTapSwitch;
                
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
#pragma mark UIPickerView delegate and datasource
//////////////////////////////////////////////////////////////


- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    switch (row) 
    {
        case 1:
            self.gridView.layoutStrategy = [GMGridViewLayoutStrategyFactory strategyFromType:GMGridViewLayoutHorizontal];
            break;
        case 2:
            self.gridView.layoutStrategy = [GMGridViewLayoutStrategyFactory strategyFromType:GMGridViewLayoutHorizontalPagedLTR];
            break;
        case 3:
            self.gridView.layoutStrategy = [GMGridViewLayoutStrategyFactory strategyFromType:GMGridViewLayoutHorizontalPagedTTB];
            break;
        case 0:
        default:
            self.gridView.layoutStrategy = [GMGridViewLayoutStrategyFactory strategyFromType:GMGridViewLayoutVertical];
            break;
    }
    [self.gridView layoutSubviewsWithAnimation:GMGridViewItemAnimationFade];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 4;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *title = nil;
    
    switch (row) {
        case 0:
            title = @"Vertical strategy";
            break;
        case 1:
            title = @"Horizontal strategy";
            break;
        case 2:
            title = @"Horizontal paged LTR strategy";
            break;
        case 3:
            title = @"Horizontal paged TTB strategy";
            break;
        default:
            title = @"Unknown";
            break;
    }
    
    return title;
}

//////////////////////////////////////////////////////////////
#pragma mark Control callbacks
//////////////////////////////////////////////////////////////

- (void)editingSwitchChanged:(UISwitch *)control
{
    self.gridView.editing = control.on;
    control.on = self.gridView.isEditing;
    [self.gridView layoutSubviewsWithAnimation:GMGridViewItemAnimationFade];
}

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

- (void)layoutCenterSwitchChanged:(UISwitch *)control
{
    self.gridView.centerGrid = control.on;
    [self.gridView layoutSubviewsWithAnimation:GMGridViewItemAnimationFade];
}

- (void)layoutSpacingSliderChanged:(UISlider *)control
{
    self.gridView.itemSpacing = control.value;
    [self.gridView layoutSubviewsWithAnimation:GMGridViewItemAnimationFade];
}

- (void)layoutInsetsSliderChanged:(UISlider *)control
{
    self.gridView.minEdgeInsets = UIEdgeInsetsMake(control.value, control.value, control.value, control.value);
    [self.gridView layoutSubviewsWithAnimation:GMGridViewItemAnimationFade];
}

- (void)editOnTapSwitchChanged:(UISwitch *)control
{
    self.gridView.enableEditOnLongPress = control.on;
}

- (void)disableEditOnEmptySpaceTapSwitchChanged:(UISwitch *)control;
{
    self.gridView.disableEditOnEmptySpaceTap = control.on;
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
