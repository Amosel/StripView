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

#import <Foundation/Foundation.h>
#import "NIStripView.h"

/**
 * The delegate for NIStripView.
 *
 *      @ingroup NimbusStripView
 */
@protocol NIStripViewDelegate <UIScrollViewDelegate>

/**
 * Fetches the number of items shown at each page in the scroll view.
 *
 * The value returned in this method will be cached by the scroll view until reloadData
 * is called again.
 */
- (NSUInteger)numberOfItemsPerPageOnStripView:(NIStripView *)stripView;

@optional

#pragma mark Scrolling and Zooming /** @name [NIPhotoAlbumStripViewDelegate] Scrolling and Zooming */

/**
 * The user is scrolling between two photos.
 */
- (void)stripViewDidScroll:(NIStripView *)stripView;

#pragma mark Changing Pages /** @name [NIStripViewDelegate] Changing Pages */

/**
 * The current page has changed.
 *
 * stripView.centerPageIndex will reflect the changed page index.
 */
- (void)stripViewDidChangeItems:(NIStripView *)stripView;



- (void)stripView:(NIStripView*)stripView willDisplayItem:(UIView<NIStripViewItem> *)viewItem;


- (void)stripView:(NIStripView*)stripView didRecycleItem:(UIView<NIStripViewItem> *)item;

/**
 * The next photo in the album has been loaded and is ready to be displayed.
 */
- (void)stripViewDidLoadNextView:(NIStripView *)photoAlbumStripView;

/**
 * The previous photo in the album has been loaded and is ready to be displayed.
 */
- (void)stripViewDidLoadPreviousView:(NIStripView *)photoAlbumStripView;

@end
