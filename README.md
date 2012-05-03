#[GM-GRID-VIEW](http://www.gmoledina.ca/projects/gmgridview/)
<a target="_blank" href="http://www.gmoledina.ca/projects/gmgridview/">
<img style="position: relative; width: 768px; margin: 0;" src="http://www.gmoledina.ca/wp-content/uploads/2012/04/GMGridView_iPad_promo1.png" alt="GMGridView"/>
</a>

"**Definitely looks like one to watch**" [ManiacDev.com]

"**Looks like the best 3rd party implementation I have seen so far**" [iosDevWeekly.com]

---

An iOS Grid-View allowing the user to sort the views in the scrollView and also to see the views in full-size by pinching them. 
This view is inspired by the UITableView and uses a datasource and delegates in order to get the data and interact with it.

The cells are reusable and are not loaded until required (only the ones visible on the scrollview are loaded). 
It is important to use the dequeue method to reuse the cell.

The best sorting style (swap or push) depends on personal taste and the frame of the grid; you can choose the one that suits you best.
Same applies to the layout strategy (vertical, horizontal, paged,... and more to come).

Many working examples provided in the demo app.

Let us know how this component works out for you!
New feature requests are welcome. (ping [@gmoledina](http://twitter.com/gmoledina) or [@steipete](http://twitter.com/steipete))

---

**Fresh from the baking oven**:

*  The component is now shipped as a static library
*  The component now inherits from UIScrollView and changing the scroll delegate is now allowed!
*  Support for different item sizes per interface orientation

**Coming soon**:

*  Changing the zoom scale dynamically (when pinching to go fullscreen)
*  Better performance of items scalling on pinch
*  More customization options


---

**Consider making a small donation to [support future developement](http://www.gmoledina.ca/projects/gmgridview/) of this component.**

---


**Requirements**:

* iOS 4 and up
* Xcode 4.2 (GMGridView uses ARC)
* Frameworks: Foundation, UIKit, CoreGraphics and QuartzCore

**Features - General**:

*  Works on both the iPhone and iPad (best suited for iPad)
*  Works on both portrait and landscape orientation
*  Inherits from UIScrollView - you can override the UIScrollViewDelegate if you wish
*  Reusable cells
*  Edit mode to delete cells
*  Gestures work great inside of the scrollView
*  4 different layout strategies (Vertical, Horizontal, Horizontal Paged LTR/TTB)
*  Possibility to provide your own layout strategy
*  Paging!! 2 horizontally paged layout strategies added
*  shaking animation on items when in edit mode
*  Changing the scrollview delegate is allowed!
*  Demo app provided, with options panel

**Features - Sorting**:

* Perform a long-touch on a view to be able to move it
* Two different animation styles ("Swap" or "Push")
* Sorted view has a shake animation (can be disabled)
* Only one UIPanGestureRecognizer and one UILongTouchGestureRecognizer used to track ALL views

**Features - Fullsize**:

* Pinch, rotate and drag views using 2 fingers
* Switch to fullsize mode on the view at the end of these gestures if the view scaled enough
* Provide a different fullsize view (detailed view) for the view via the delegate
* Every view doesn't have it's own gesture recognizers, the main view handles a set of gestures for ALL views
