##SIImageSequenceView

An UIImageView subclass for interating with a sequence of images.
Typically used for a product 360° span.

##FEATURES

- tweak able inertial simulation
- spin to a specific frame of image sequence
- auto spin mode
- delegate for monitoring state change

##HOW TO USE

1. Add all files under `SIImageSequenceView/SIImageSequenceView` to your project
2. Add `QuartzCore.framework` to your project
3. Add `#import "SIImageSequenceView.h"` before using it

##EXAMPLES

**Code:**

	SIImageSequenceView *imageSequenceView = [[SIImageSequenceView alloc] initWithPathFormat:@"%d.jpg" bundle:nil];
	imageSequenceView.frame = self.view.bounds;
	[self.view addSubView:imageSequenceView];

**Storyboard:**

Using SIImageSequenceView with storyboard is inclued in the demo project.

##LICENSE

SIImageSequenceView is available under the MIT license. See the LICENSE file for more info.