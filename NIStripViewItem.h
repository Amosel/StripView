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

#import "NimbusCore.h"

#import <Foundation/Foundation.h>

/**
 * The protocol that a paging scroll view item should implement.
 *
 * By providing a protocol instead of a UIView base class we allow more flexibility when
 * building Items.
 *
 *      @ingroup NimbusPagingScrollView
 */
@protocol NIStripViewItem <NIRecyclableView>
@required

/**
 * The index of this Item view.
 */
@property (nonatomic, readwrite, assign) NSInteger itemIndex;

@optional

/**
 * Called after the Item has gone off-screen.
 *
 * This method should be used to reset any state information after a Item goes off-screen.
 * For example, in the Nimbus photo viewer we reset the zoom scale so that if the photo
 * was zoomed in it will fit on the screen again when the user flips back and forth between
 * two Items.
 */
- (void)itemDidDisappear;

/**
 * Called when the frame of the item is going to change.
 *
 * Use this method to maintain any state that may be affected by the frame changing.
 * The Nimbus photo viewer uses this method to save and restore the zoom and center
 * point. This makes the photo always appear to rotate around the center point of the screen
 * rather than the center of the photo.
 */
- (void)setFrameAndMaintainState:(CGRect)frame;

@end
