//
// Copyright 2011 Jeff Verkoeyen
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "NimbusCore.h"

/**
 * numberOfItems will be this value until reloadData is called.
 */
extern const NSInteger NIStripViewUnknownNumberOfItems;

/**
 * The default number of pixels on the side of each item.
 *
 * Value: 10
 */
extern const CGFloat NIScrollViewDefaultItemHorizontalMargin;

@protocol NIStripViewDataSource;
@protocol NIStripViewDelegate;
@protocol NIStripViewItem;
@class NIViewRecycler;

/**
 * An implementation of a scroll view that can do horizontal, shows a set of items in each item.
 *
 *      @ingroup NimbusStripView
 */
@interface NIStripView : UIView <UIScrollViewDelegate> {
@private
  // Views
  UIScrollView* _scrollView;

  // items
  NSMutableSet* _visibleItems;
  NIViewRecycler* _viewRecycler;

  // Configurable Properties
  CGFloat _pageHorizontalMargin;

  // State Information
  NSInteger _firstVisibleItemIndexBeforeRotation;
  CGFloat _percentScrolledIntoFirstVisibleItem;
  BOOL _isModifyingContentOffset;
  BOOL _isAnimatingToPage;
  NSInteger _lastItemIndex;

  // Cached Data Source Information
  NSInteger _numberOfItems;

  id<NIStripViewDataSource> _dataSource;
  id<NIStripViewDelegate> _delegate;
}

#pragma mark Data Source

- (void)reloadData;
@property (nonatomic, readwrite, assign) id<NIStripViewDataSource> dataSource;
@property (nonatomic, readwrite, assign) id<NIStripViewDelegate> delegate;

// It is highly recommended that you use this method to manage view recycling.
- (UIView<NIStripViewItem> *)dequeueReusableItemWithIdentifier:(NSString *)identifier;

#pragma mark State

@property (nonatomic, readwrite, assign) NSInteger lastItemIndex; // Use moveToItemAtIndex:animated: to animate to a given item.
- (void)setCenterItemIndex:(NSInteger)centerItemIndex animated:(BOOL)animated;

@property (nonatomic, readonly, assign) NSInteger numberOfItems;

#pragma mark Configuring Presentation
@property (nonatomic, readwrite, assign) BOOL horizontal;
@property (nonatomic, readonly, assign) NSUInteger itemsPerPage; 
@property (nonatomic, readwrite, assign) CGFloat itemViewXOffset;

#pragma mark Changing the Visible item

- (BOOL)hasNextPage;
- (BOOL)hasPreviousPage;

- (void)moveToNextAnimated:(BOOL)animated;
- (void)moveToPreviousAnimated:(BOOL)animated;
- (void)moveToItemAtIndex:(NSInteger)itemIndex animated:(BOOL)animated;

#pragma mark Rotating the Scroll View

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;

#pragma mark Subclassing

@property (nonatomic, readonly, retain) UIScrollView* scrollView;
@property (nonatomic, readonly, copy) NSMutableSet* visibleItems;

- (void)willDisplayItem:(UIView<NIStripViewItem> *)itemView;
- (void)didRecycleItem:(UIView<NIStripViewItem> *)itemView;

- (NSUInteger)numberOfVisiblePages;
- (NSInteger)calculateFirstVisibleItemIndex;
- (NSInteger)calculateLastVisibleItemIndex;

- (void)notifyDelegatePhotoDidLoadAtIndex:(NSInteger)photoIndex;

@end

/** @name Data Source */

/**
 * The data source for this page album view.
 *
 * This is the only means by which this paging view acquires any information about the
 * album to be displayed.
 *
 *      @fn NIScrollView::dataSource
 */

/**
 * Force the view to reload its data by asking the data source for information.
 *
 * This must be called at least once after dataSource has been set in order for the view
 * to gather any presentable information.
 *
 * This method is cheap because we only fetch new information about the currently displayed
 * items. If the number of items shrinks then the current center page index will be decreased
 * accordingly.
 *
 *      @fn NIScrollView::reloadData
 */

/**
 * Dequeues a reusable page from the set of recycled items.
 *
 * If no items have been recycled for the given identifier then this will return nil.
 * In this case it is your responsibility to create a new page.
 *
 *      @fn NIScrollView::dequeueReusablePageWithIdentifier:
 */

/**
 * The delegate for this paging view.
 *
 * Any user interactions or state changes are sent to the delegate through this property.
 *
 *      @fn NIScrollView::delegate
 */


/** @name Configuring Presentation */

/**
 * The number of pixels on either side of each page.
 *
 * The space between each page will be 2x this value.
 *
 * By default this is NIScrollViewDefaultItemHorizontalMargin.
 *
 *      @fn NIScrollView::pageHorizontalMargin
 */


/** @name State */

/**
 * The current center page index.
 *
 * This is a zero-based value. If you intend to use this in a label such as "page ## of n" be
 * sure to add one to this value.
 *
 * Setting this value directly will center the new page without any animation.
 *
 *      @fn NIScrollView::centerPageIndex
 */

/**
 * Change the center page index with optional animation.
 *
 * This method is deprecated in favor of
 * @link NIScrollView::moveToPageAtIndex:animated: moveToPageAtIndex:animated:@endlink
 *
 *      @fn NIScrollView::setCenterPageIndex:animated:
 */

/**
 * The total number of items in this paging view, as gathered from the data source.
 *
 * This value is cached after reloadData has been called.
 *
 * Until reloadData is called the first time, numberOfItems will be
 * NIScrollViewUnknownNumberOfItems.
 *
 *      @fn NIScrollView::numberOfItems
 */


/** @name Changing the Visible Page */

/**
 * Returns YES if there is a next page.
 *
 *      @fn NIScrollView::hasNextPage
 */

/**
 * Returns YES if there is a previous page.
 *
 *      @fn NIScrollView::hasPreviousPage
 */

/**
 * Move to the next page if there is one.
 *
 *      @fn NIScrollView::moveToNextAnimated:
 */

/**
 * Move to the previous page if there is one.
 *
 *      @fn NIScrollView::moveToPreviousAnimated:
 */

/**
 * Move to the given page index with optional animation.
 *
 *      @fn NIScrollView::moveToPageAtIndex:animated:
 */


/** @name Rotating the Scroll View */

/**
 * Stores the current state of the scroll view in preparation for rotation.
 *
 * This must be called in conjunction with willAnimateRotationToInterfaceOrientation:duration:
 * in the methods by the same name from the view controller containing this view.
 *
 *      @fn NIScrollView::willRotateToInterfaceOrientation:duration:
 */

/**
 * Updates the frame of the scroll view while maintaining the current visible page's state.
 *
 *      @fn NIScrollView::willAnimateRotationToInterfaceOrientation:duration:
 */


/** @name Subclassing */

/**
 * The internal scroll view.
 *
 * Meant to be used by subclasses only.
 *
 *      @fn NIScrollView::scrollView
 */

/**
 * The set of currently visible items.
 *
 * Meant to be used by subclasses only.
 *
 *      @fn NIScrollView::visibleItems
 */

/**
 * Called before the page is about to be shown and after its frame has been set.
 *
 * Meant to be subclassed. By default this method does nothing.
 *
 *      @fn NIScrollView::willDisplayItem:
 */

/**
 * Called immediately after the page is removed from the paging scroll view.
 *
 * Meant to be subclassed. By default this method does nothing.
 *
 *      @fn NIScrollView::didRecyclePage:
 */
