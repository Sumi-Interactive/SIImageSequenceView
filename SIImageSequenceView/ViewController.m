//
//  ViewController.m
//  SIImageSequenceView
//
//  Created by Kevin Cao on 12-6-25.
//  Copyright (c) 2012年 Sumi Interactive. All rights reserved.
//

#import "ViewController.h"
#import "SIImageSequenceView.h"

@interface ViewController () <SIImageSequenceViewDelegate>

@property (weak, nonatomic) IBOutlet SIImageSequenceView *imageSequenceView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	_imageSequenceView.friction = 0.95;
    _imageSequenceView.pathFormat = @"sumi%d.jpg";
}

- (void)viewDidUnload
{
	[self setImageSequenceView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)buttonAction:(id)sender
{
	[_imageSequenceView spinToFrameIndex:-56 speed:-1 completion:^(BOOL finished) {
		NSLog(@"complete %d", finished);
	}];
}

- (IBAction)switchAction:(id)sender 
{
	if ([sender isOn]) {
		[_imageSequenceView startFreeSpinWithSpeed:1];
	} else {
		[_imageSequenceView stopFreeSpin];
	}
}

- (void)imageSequenceView:(SIImageSequenceView *)imageSequenceView didChangeState:(SIImageSequenceViewState)state
{
	NSLog(@"state=%d", state);
}

@end
