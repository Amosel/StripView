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

/**
 * @defgroup NimbusStripView Nimbus Paging Strip View
 * @{
 *
 * A paging Strip view is a UIStripView that Strips horizontally and shows a series of
 * pages that are efficiently recycled.
 *
 * The Nimbus paging Strip view is powered by a datasource that allows you to separate the
 * data from the view. This makes it easy to efficiently recycle pages and only create as many
 * pages of content as may be visible at any given point in time. Nimbus' implementation also
 * provides helpful features such as keeping the center page centered when the device changes
 * orientation.
 *
 * Paging Strip views are commonly used in many iOS applications. For example, Nimbus' Photos
 * feature uses a paging Strip view to power its NIStripView.
 *
 * <h2>Building a Component with NIStripView</h2>
 *
 * NIStripView works much like a UITableView in that you must implement a data source
 * and optionally a delegate. The data source fetches information about the contents of the
 * paging Strip view, such as the total number of pages and the view for a given page when it
 * is required. The views that you return for pages must conform to the NIStripViewItem
 * protocol. This is similar to UITableViewCell, but rather than subclass a view you can simply
 * implement a protocol. If you would prefer not to implement the protocol, you can subclass
 * NIPageView which implements the required methods of NIStripViewItem.
 */

/**@}*/

#import "NIStripView.h"
#import "NIStripViewDataSource.h"
#import "NIStripViewDelegate.h"
#import "NIStripViewItem.h"

#import "NimbusCore.h"
