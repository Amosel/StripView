//
// Copyright 2012 Amos Elmaliah
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

#import "NIStripView.h"

#import "NIStripViewItem.h"
#import "NIStripViewDataSource.h"
#import "NIStripViewDelegate.h"
#import "NimbusCore.h"

const NSInteger NIStripViewUnknownNumberOfItems = -1;
const CGFloat NIScrollViewDefaultItemHorizontalMargin = 10;

@interface NIStripView()

@property (nonatomic, readwrite, retain) UIScrollView* scrollView;
@property (nonatomic, retain) NIViewRecycler* viewRecycler;
-(NSUInteger)itemIndexToCenterItemAtIndex:(NSUInteger)indexToCenter;
-(NSUInteger)numberOfVisiblePages;
@end

@implementation NIStripView

@synthesize visibleItems = _visibleItems;
@synthesize scrollView = _scrollView;
@synthesize itemViewXOffset = _itemViewXOffset;
@synthesize horizontal = _horizontal;
@synthesize itemsPerPage = _itemsPerPage;
@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;
@synthesize lastItemIndex = _lastItemIndex;
@synthesize numberOfItems = _numberOfItems;
@synthesize viewRecycler = _viewRecycler;

#pragma mark -
#pragma mark NSObject


- (void)dealloc {
    self.scrollView = nil;
    
    [_visibleItems release],_visibleItems = nil;
    self.viewRecycler = nil;
    
    [super dealloc];
}



- (void)commonInit {
    // Default state.
    _itemsPerPage = -1;
    _itemViewXOffset = NIScrollViewDefaultItemHorizontalMargin;
    _horizontal = NO;
    
    _firstVisibleItemIndexBeforeRotation = -1;
    _percentScrolledIntoFirstVisibleItem = -1;
    _lastItemIndex = -1;
    _numberOfItems = NIStripViewUnknownNumberOfItems;
    
    _viewRecycler = [[NIViewRecycler alloc] init];
    
    self.scrollView = [[[UIScrollView alloc] initWithFrame:self.bounds] autorelease];
    self.scrollView.pagingEnabled = YES;
    
    self.scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth
                                              | UIViewAutoresizingFlexibleHeight);
    
    self.scrollView.delegate = self;
    
    // Ensure that empty areas of the scroll view are draggable.
    self.scrollView.backgroundColor = [UIColor blackColor];
    
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    
    [self addSubview:self.scrollView];
    
    
}



- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self commonInit];
    }
    return self;
}



- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self commonInit];
    }
    return self;
}


#pragma mark -
#pragma mark UIView

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    
    self.scrollView.backgroundColor = backgroundColor;
}

-(void)layoutSubviews
{
    // This condition is to avoid the setFrame messages after on resizeWithOldSuperViewSize:
    // is called directly from the event loop when geomtry changes,
    // somehow we are getting frame with height = 0, although the autoResizeMask is flexible Height.
    BOOL wasModifyingContentOffset = _isModifyingContentOffset;
    _isModifyingContentOffset = YES;
    if (self.frame.size.height && self.frame.size.width) {
        self.scrollView.contentSize = [self contentSizeForScrollView];
        [self layoutVisibleItems];
    }
    _isModifyingContentOffset = wasModifyingContentOffset;
}



- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    
    self.scrollView.backgroundColor = self.superview.backgroundColor;
}




#pragma mark -
#pragma mark Item Layout


-(CGSize)itemFrameSize
{
    if (_horizontal) {
        int width = self.frame.size.width / _itemsPerPage;
        return CGSizeMake(width, MIN(width, self.frame.size.height));
    }
    else {
        int height = self.frame.size.height / _itemsPerPage;
        return CGSizeMake(MIN(height, self.frame.size.width),height);
    }
}

-(NSUInteger)numberOfVisiblePages
{
    if (_horizontal) {
        return ceilf(self.scrollView.bounds.size.width / [self itemFrameSize].width);
    }
    else {
        return ceilf(self.scrollView.bounds.size.height / [self itemFrameSize].height);
    }
}

// The following three methods are from Apple's ImageScrollView example application and have
// been used here because they are well-documented and concise.

- (CGRect)frameForScrollView {
    CGRect frame = self.bounds;
    
    // We make the scroll view a little bit wider on the side edges so that there
    // there is space between the items when flipping through them.
//    frame.origin.x -= self.itemViewXOffset;
//    frame.size.width += (2 * self.itemViewXOffset);
    
    return frame;
}

- (CGRect)frameForItemViewAtIndex:(NSInteger)itemIndex {
    // We have to use our scroll view's bounds, not frame, to calculate the page
    // placement. When the device is in landscape orientation, the frame will still be in
    // portrait because the scrollView is the root view controller's view, so its
    // frame is in window coordinate space, which is never rotated. Its bounds, however,
    // will be in landscape because it has a rotation transform applied.
    CGSize itemFrameSize = [self itemFrameSize];
    CGRect pageFrame = CGRectMake(0, 0, itemFrameSize.width, itemFrameSize.height);
    
    // We need to counter the extra spacing added to the scroll view in
    // frameForScrollView:
    if (_horizontal) {
        pageFrame.size.width -= self.itemViewXOffset * 2;
        pageFrame.origin.x = (itemFrameSize.width * itemIndex);
        pageFrame.origin.x += self.itemViewXOffset;
    }
    else
    {
        pageFrame.size.width -= self.itemViewXOffset * 2;
        pageFrame.origin.x += self.itemViewXOffset;
        pageFrame.origin.y = (itemFrameSize.height * itemIndex);
    }
    
    return pageFrame;
}



- (CGSize)contentSizeForScrollView {
    // We have to use the scroll view's bounds to calculate the contentSize, for the
    // same reason outlined above.    
    
    CGSize itemFrameSize = [self frameForScrollView].size;
    int numberOfPages = ceilf((float)_numberOfItems/_itemsPerPage);
    if (_horizontal) {
        return CGSizeMake(itemFrameSize.width * numberOfPages, itemFrameSize.height);
    }
    else {
        return CGSizeMake(itemFrameSize.width, itemFrameSize.height * numberOfPages);
    }
}




#pragma mark -
#pragma mark Visible Page Management



- (BOOL)isDisplayingPageForIndex:(NSInteger)itemIndex {
    BOOL foundPage = NO;
    
    // There will be more than 3 visible items in this array, so this lookup is
    // not O(C) constant time.
    for (id<NIStripViewItem> item in _visibleItems) {
        if (item.itemIndex == itemIndex) {
            foundPage = YES;
            break;
        }
    }
    
    return foundPage;
}



- (NSInteger)calculateLastVisibleItemIndex {
    CGPoint contentOffset = self.scrollView.contentOffset;
    CGSize itemFrameSize = [self itemFrameSize];
    
    if (_horizontal) {
        // Whatever item view is currently at the top right point of the screen
        return boundi((NSInteger)(floorf(contentOffset.x / itemFrameSize.width)
                                  + 0.5f),
                      0, self.numberOfItems - 1);
    }
    else {
        // Whatever item view is currently at the top right point of the screen
        return boundi((NSInteger)(floorf(contentOffset.y / itemFrameSize.height)
                                  + 0.5f),
                      0, self.numberOfItems - 1);
    }
}

- (NSInteger)calculateFirstVisibleItemIndex {
    CGPoint contentOffset = self.scrollView.contentOffset;
    CGSize scroolViewSize = self.scrollView.bounds.size;
    CGSize itemFrameSize = [self itemFrameSize];
    
    if (_horizontal) {
        // Whatever page view is currently displayed at the top right point of the screen
        return boundi((NSInteger)(floorf((contentOffset.x + scroolViewSize.width) / itemFrameSize.width)
                                  + 0.5f),
                      0, self.numberOfItems - 1);
    }
    else {
        // Whatever page view is currently displayed at the top right point of the screen
        return boundi((NSInteger)(floorf((contentOffset.y + scroolViewSize.height) / itemFrameSize.height)
                                  + 0.5f),
                      0, self.numberOfItems - 1);

    }
}



- (NSRange)calculateVisibleItemRange {
    if (0 >= _numberOfItems) {
        return NSMakeRange(0, 0);
    }
    
    NSInteger leftmostVisibleItemIndex = [self calculateLastVisibleItemIndex];
    NSInteger rightmostVisibleItemIndex = [self calculateFirstVisibleItemIndex];
    
    int firstVisibleItemIndex = boundi(leftmostVisibleItemIndex - 1, 0, _numberOfItems - 1);
    int lastVisibleItemIndex  = boundi(rightmostVisibleItemIndex + 1, 0, _numberOfItems - 1);
    
    return NSMakeRange(firstVisibleItemIndex, lastVisibleItemIndex - firstVisibleItemIndex + 1);
}



- (void)willDisplayItem:(UIView<NIStripViewItem> *)itemView atIndex:(NSInteger)itemIndex {
    itemView.itemIndex = itemIndex;
    [itemView setFrame:[self frameForItemViewAtIndex:itemIndex]];
    

    [self willDisplayItem:itemView];
    if ([self.delegate respondsToSelector:@selector(stripView:willDisplayItem:)]) {
        [self.delegate stripView:self willDisplayItem:itemView];
    }

}



- (void)resetItem:(id<NIStripViewItem>)item {
    if ([item respondsToSelector:@selector(itemDidDisappear)]) {
        [item itemDidDisappear];
    }
}



- (void)resetSurroundingItems {
    for (id<NIStripViewItem> item in _visibleItems) {
        if (!NSLocationInRange(item.itemIndex, [self calculateVisibleItemRange])) {
            [self resetItem:item];
        }
    }
}



- (UIView<NIStripViewItem> *)dequeueReusableItemWithIdentifier:(NSString *)identifier {
    NIDASSERT(nil != identifier);
    if (nil == identifier) {
        return nil;
    }
    
    return (UIView<NIStripViewItem> *)[_viewRecycler dequeueReusableViewWithIdentifier:identifier];
}



- (void)displayItemAtIndex:(NSInteger)itemIndex {
    UIView<NIStripViewItem>* item = [self.dataSource stripView:self itemViewForIndex:itemIndex];
    NIDASSERT([item isKindOfClass:[UIView class]]);
    NIDASSERT([item conformsToProtocol:@protocol(NIStripViewItem)]);
    if (nil == item || ![item isKindOfClass:[UIView class]]
        || ![item conformsToProtocol:@protocol(NIStripViewItem)]) {
        // Bail out! This page is malformed.
        return;
    }
    
    // This will only be called once before the page is shown.
    [self willDisplayItem:item atIndex:itemIndex];
    
    [self.scrollView addSubview:(UIView *)item];
    [_visibleItems addObject:item];
}



- (void)updateVisibleItems {
    NSRange visiblePageRange = [self calculateVisibleItemRange];
    
    // Recycle no-longer-visible items. We copy _visibleItems because we may modify it while we're
    // iterating over it.
    for (UIView<NIStripViewItem>* item in [[_visibleItems copy] autorelease]) {
        if (!NSLocationInRange(item.itemIndex, visiblePageRange)) {
            [_viewRecycler recycleView:item];
            [item removeFromSuperview];
            
            [self didRecycleItem:item];
            if ([self.delegate respondsToSelector:@selector(stripView:didRecycleItem:)]) {
                [self.delegate stripView:self didRecycleItem:item];
            }
            [_visibleItems removeObject:item];
        }
    }
    
    NSInteger oldLastItemIndex = _lastItemIndex;
    
    if (_numberOfItems > 0) {
        _lastItemIndex = [self calculateLastVisibleItemIndex];
        
        // Prioritize displaying the currently visible page.
        if (![self isDisplayingPageForIndex:_lastItemIndex]) {
            [self displayItemAtIndex:_lastItemIndex];
        }
        
        // Add missing pages.
        for (int itemIndex = visiblePageRange.location;
             itemIndex < NSMaxRange(visiblePageRange); ++itemIndex) {
            if (![self isDisplayingPageForIndex:itemIndex]) {
                [self displayItemAtIndex:itemIndex];
            }
        }
    } else {
        _lastItemIndex = -1;
    }
    
    if (oldLastItemIndex != _lastItemIndex
        && [self.delegate respondsToSelector:@selector(stripViewDidChangeItems:)]) {
        [self.delegate stripViewDidChangeItems:self];
    }
}




- (void)layoutVisibleItems {
    for (UIView<NIStripViewItem>* item in _visibleItems) {
        CGRect itemFrame = [self frameForItemViewAtIndex:item.itemIndex];
        if ([item respondsToSelector:@selector(setFrameAndMaintainState:)]) {
            [item setFrameAndMaintainState:itemFrame];
            
        } else {
            [item setFrame:itemFrame];
        }
    }
}



#pragma mark -
#pragma mark UIScrollViewDelegate



- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!_isModifyingContentOffset) {
        // This method is called repeatedly as the user scrolls so updateVisibleItems must be
        // light-weight enough not to noticeably impact performance.
        [self updateVisibleItems];
        
        if ([self.delegate respondsToSelector:@selector(stripViewDidScroll:)]) {
            [self.delegate stripViewDidScroll:self];
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [self.delegate scrollViewDidScroll:scrollView];
    }
}



- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self resetSurroundingItems];
    }
    
    if ([self.delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [self.delegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}



- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self resetSurroundingItems];
    
    if ([self.delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [self.delegate scrollViewDidEndDecelerating:scrollView];
    }
}




#pragma mark -
#pragma mark Subclassing



- (void)willDisplayItem:(UIView<NIStripViewItem> *)itemView {
    // No-op.
}



- (void)didRecycleItem:(UIView<NIStripViewItem> *)itemView {
    // No-op
}




#pragma mark -
#pragma mark Public Methods

- (void)reloadData {
    NIDASSERT(nil != _dataSource);
    
    // Remove any visible items from the view before we release the sets.
    for (UIView<NIStripViewItem>* item in _visibleItems) {
        [_viewRecycler recycleView:item];
        [(UIView *)item removeFromSuperview];
    }
    
    NI_RELEASE_SAFELY(_visibleItems);
    
    // If there is no data source then we can't do anything particularly interesting.
    if (nil == _dataSource) {
        _isModifyingContentOffset = YES;
        self.scrollView.contentSize = self.bounds.size;
        self.scrollView.contentOffset = CGPointZero;
        _isModifyingContentOffset = NO;
        
        // May as well just get rid of all the views then.
        [_viewRecycler removeAllViews];
        
        return;
    }
    
    _visibleItems = [[NSMutableSet alloc] init];
    
    // Cache items per page
    _itemsPerPage = [_delegate numberOfItemsPerPageOnStripView:self];
    
    // Cache the number of items
    _numberOfItems = [_dataSource numberOfItemsInStripView:self];
    self.scrollView.frame = [self frameForScrollView];
    self.scrollView.contentSize = [self contentSizeForScrollView];
    
    NSInteger oldLastItemIndex = _lastItemIndex;
    if (oldLastItemIndex >= 0) {
        _lastItemIndex = boundi(_lastItemIndex, 0, _numberOfItems - 1);
        
        // The content size is calculated based on the number of items and the scroll view frame.
        _isModifyingContentOffset = YES;
        CGPoint offset = [self frameForItemViewAtIndex:_lastItemIndex].origin;
        offset.x -= self.itemViewXOffset;
        self.scrollView.contentOffset = offset;
        _isModifyingContentOffset = NO;
    }
    
    // Begin requesting the item information from the data source.
    [self updateVisibleItems];
    
    /*
    // test providing 5 is the number of visible page views:
    NSUInteger maxIndex = [self numberOfItems]-1;
    NSLog(@"result %d should be %d", [self itemIndexToCenterItemAtIndex:0], 2);
    NSLog(@"result %d should be %d", [self itemIndexToCenterItemAtIndex:1], 2);
    NSLog(@"result %d should be %d", [self itemIndexToCenterItemAtIndex:2], 2);
    NSLog(@"result %d should be %d", [self itemIndexToCenterItemAtIndex:maxIndex-2], maxIndex - 2);
    NSLog(@"result %d should be %d", [self itemIndexToCenterItemAtIndex:maxIndex-1], maxIndex - 2);
    NSLog(@"result %d should be %d", [self itemIndexToCenterItemAtIndex:maxIndex], maxIndex - 2);
     */
}

- (void)willRotateToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation
                                duration: (NSTimeInterval)duration {
    // Here, our scrollView bounds have not yet been updated for the new interface
    // orientation. This is a good place to calculate the content offset that we will
    // need in the new orientation.
    CGFloat offset = self.scrollView.contentOffset.x;
    CGFloat pageWidth = self.scrollView.bounds.size.width;
    
    if (offset >= 0) {
        _firstVisibleItemIndexBeforeRotation = floorf(offset / pageWidth);
        _percentScrolledIntoFirstVisibleItem = ((offset
                                                 - (_firstVisibleItemIndexBeforeRotation * pageWidth))
                                                / pageWidth);
        
    } else {
        _firstVisibleItemIndexBeforeRotation = 0;
        _percentScrolledIntoFirstVisibleItem = offset / pageWidth;
    }
}



- (void)willAnimateRotationToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation
                                         duration: (NSTimeInterval)duration {
    BOOL wasModifyingContentOffset = _isModifyingContentOffset;
    
    // Recalculate contentSize based on current orientation.
    _isModifyingContentOffset = YES;
    self.scrollView.contentSize = [self contentSizeForScrollView];
    _isModifyingContentOffset = wasModifyingContentOffset;
    
    [self layoutVisibleItems];
    
    // Adjust contentOffset to preserve page location based on values collected prior to location.
    CGFloat pageWidth = self.scrollView.bounds.size.width;
    CGFloat newOffset = ((_firstVisibleItemIndexBeforeRotation * pageWidth)
                         + (_percentScrolledIntoFirstVisibleItem * pageWidth));
    _isModifyingContentOffset = YES;
    self.scrollView.contentOffset = CGPointMake(newOffset, 0);
    _isModifyingContentOffset = wasModifyingContentOffset;
}

- (void)notifyDelegatePhotoDidLoadAtIndex:(NSInteger)photoIndex {
    if (photoIndex == (self.lastItemIndex + 1)
        && [self.delegate respondsToSelector:@selector(stripViewDidLoadNextView:)]) {
        [self.delegate stripViewDidLoadNextView:self];
        
    } else if (photoIndex == (self.lastItemIndex - 1)
               && [self.delegate respondsToSelector:@selector(stripViewDidLoadPreviousView:)]) {
        [self.delegate stripViewDidLoadPreviousView:self];
    }
}

#pragma mark -
#pragma mark Changing the Visible item



- (BOOL)hasNextPage {
    return (([self calculateFirstVisibleItemIndex] + [self numberOfVisiblePages]) < self.numberOfItems - 1);
}



- (BOOL)hasPreviousPage {
    return ([self calculateLastVisibleItemIndex] - [self numberOfVisiblePages]) > 0;
}


- (void)didAnimateToPage:(NSNumber *)itemIndex {
    _isAnimatingToPage = NO;
    
    // Reset the content offset once the animation completes, just to be sure that the
    // viewer sits on a page bounds even if we rotate the device while animating.
    CGPoint offset = [self frameForItemViewAtIndex:[itemIndex intValue]].origin;
    offset.x -= 2*self.itemViewXOffset;
    
    _isModifyingContentOffset = YES;
    self.scrollView.contentOffset = offset;
    _isModifyingContentOffset = NO;
    
    [self updateVisibleItems];
}


- (void)moveToItemAtIndex:(NSInteger)itemIndex animated:(BOOL)animated {
    if (_isAnimatingToPage) {
        // Don't allow re-entry for sliding animations.
        return;
    }
    
    CGPoint offset = [self frameForItemViewAtIndex:itemIndex].origin;
    offset.x -= 2*self.itemViewXOffset;
    
    _isModifyingContentOffset = YES;
    [self.scrollView setContentOffset:offset animated:animated];
    
    NSNumber* itemIndexNumber = [NSNumber numberWithInt:floorf(itemIndex / [self numberOfVisiblePages])];
    if (animated) {
        _isAnimatingToPage = YES;
        SEL selector = @selector(didAnimateToPage:);
        [NSObject cancelPreviousPerformRequestsWithTarget: self];
        
        // When the animation is finished we reset the content offset just in case the frame
        // changes while we're animating (like when rotating the device). To do this we need
        // to know the destination index for the animation.
        [self performSelector: selector
                   withObject: itemIndexNumber
                   afterDelay: 0.4];
        
    } else {
        [self didAnimateToPage:itemIndexNumber];
    }
}

- (void)moveToNextAnimated:(BOOL)animated {
    if ([self hasNextPage]) {
        NSInteger itemIndex = self.lastItemIndex + [self numberOfVisiblePages] + 1;
        
        [self moveToItemAtIndex:itemIndex animated:animated];
    }
}

- (void)moveToPreviousAnimated:(BOOL)animated {
    if ([self hasPreviousPage]) {
        NSInteger itemIndex = self.lastItemIndex - [self numberOfVisiblePages] - 1;
        
        [self moveToItemAtIndex:itemIndex animated:animated];
    }
}

-(NSUInteger)itemIndexToCenterItemAtIndex:(NSUInteger)indexToCenter
{
#define leanToRight YES
    NSUInteger result = indexToCenter;
    int leftmostIndex = floorf([self numberOfVisiblePages] *.5);
    int rightmostIndex = [self numberOfItems] -1 - ceilf([self numberOfVisiblePages] *.5);
    
    if (indexToCenter < leftmostIndex ||
        indexToCenter > rightmostIndex
        ) 
    {
        int distanceFromLeft = abs(indexToCenter - leftmostIndex);
        int distanceFromRight = abs(rightmostIndex - indexToCenter);
        result =  distanceFromLeft == distanceFromRight 
        ? (leanToRight ? rightmostIndex : leftmostIndex)
        : distanceFromLeft < distanceFromRight 
        ? leftmostIndex 
        : rightmostIndex;
    }
    return result;
}

- (void)setCenterItemIndex:(NSInteger)centerItemIndex {
    [self moveToItemAtIndex:[self itemIndexToCenterItemAtIndex:centerItemIndex]
                   animated:NO];
}

- (void)setCenterItemIndex:(NSInteger)centerItemIndex animated:(BOOL)animated {
    [self moveToItemAtIndex:[self itemIndexToCenterItemAtIndex:centerItemIndex]
                   animated:animated];
}

@end
