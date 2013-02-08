//
//  SIImageSequenceView.m
//
//  Created by Kevin Cao on 12-6-25.
//  Copyright (c) 2012年 Sumi Interactive. All rights reserved.
//

#import "SIImageSequenceView.h"
#import <QuartzCore/QuartzCore.h>

static float map(float value, float fromMin, float fromMax, float toMin, float toMax)
{
	return toMin + (value - fromMin) / (fromMax - fromMin) * (toMax - toMin);
}

@interface SIImageSequenceView ()
{
	NSInteger _originFrameIndex;
	NSInteger _targetFrameIndex;
	NSInteger _freeSpinSpeed;
	float _speed;
	CADisplayLink *_displayLink;
	BOOL _isDirty;
	BOOL _isRendering;
	void (^_completion)(BOOL finished);
}

@end

@implementation SIImageSequenceView

- (id)initWithPathFormat:(NSString *)pathFormat bundle:(NSBundle *)bundle
{
    self = [super initWithImage:nil];
    if (self) {
        self.bundle = bundle;
        self.pathFormat = pathFormat;
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self commonInit];
	}
	return self;
}

- (void)commonInit
{
    self.userInteractionEnabled = YES;
	UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panHandler:)];
	[self addGestureRecognizer:recognizer];
	
	_looping = YES;
	_friction = 0.8;
	_frameCount = 36;
	_state = SIImageSequenceViewStateIdling;
}

#pragma mark - Override

- (void)willMoveToSuperview:(UIView *)newSuperview
{
	if (nil == newSuperview) {
		if (_completion) {
			_completion(NO);
			_completion = nil;
		}
		[self setState:SIImageSequenceViewStateIdling];
		[self stopRendering];
	}
}

#pragma mark - Setters

- (void)setBundle:(NSBundle *)bundle
{
	_bundle = bundle;
	[self invalidate];
}

- (void)setPathFormat:(NSString *)pathFormat
{
	_pathFormat = pathFormat;
	[self invalidate];
}

- (void)setFrameIndex:(NSInteger)frameIndex
{
	[self setFrameIndex:frameIndex immediately:NO];
}

#pragma mark - Public

- (void)spinToFrameIndex:(NSInteger)frameIndex speed:(NSInteger)speed completion:(void (^)(BOOL))completion
{
	_targetFrameIndex = [self mappedFrameIndex:frameIndex];
	if (_targetFrameIndex == _frameIndex) {
		if (completion) {
			completion(YES);
		}
		return;
	}
	_speed = speed;
	_completion = [completion copy];
	[self setState:SIImageSequenceViewStateSpinning];
	[self startRendering];
}

- (void)startFreeSpinWithSpeed:(NSInteger)speed
{
	_freeSpinning = YES;
	_freeSpinSpeed = _speed = speed;
	[self setState:SIImageSequenceViewStateFreeSpinning];
	[self startRendering];
}

- (void)stopFreeSpin
{
	if (_state != SIImageSequenceViewStateFreeSpinning) {
		return;
	}
	_freeSpinning = NO;
	[self pauseRendering];
	[self setState:SIImageSequenceViewStateIdling];
}

#pragma mark - Private

- (void)panHandler:(UIPanGestureRecognizer *)recognizer
{
	CGPoint translation = [recognizer translationInView:self];
	
	switch (recognizer.state) {
		case UIGestureRecognizerStateBegan:
		{
			_originFrameIndex = _frameIndex;
			_speed = 0;
			if (_completion) {
				_completion(NO);
				_completion = nil;
			}
			[self pauseRendering];
			[self setState:SIImageSequenceViewStateInteracting];
			break;
		}
		case UIGestureRecognizerStateChanged:
		{
			NSInteger offsetFrameIndex = roundf(map(fabsf(translation.x), 0, self.bounds.size.width, 0, self.frameCount)) * (translation.x > 0 ? 1 : -1);
			[self setFrameIndex:_originFrameIndex + offsetFrameIndex immediately:YES];
			break;
		}
		case UIGestureRecognizerStateEnded:
		case UIGestureRecognizerStateCancelled:
		{
			_speed = [recognizer velocityInView:self].x * .001;
			[self setState:SIImageSequenceViewStateDecelerating];
			[self startRendering];
			break;
		}
		default:
			break;
	}
}

- (void)tick:(CADisplayLink *)displayLink
{
	[self setFrameIndex:self.frameIndex + roundf(_speed) immediately:YES];
	
	switch (_state) {
		case SIImageSequenceViewStateDecelerating:
			_speed *= _friction;
			if (fabsf(_speed) < 1.0) {
				_speed = 0;
				[self pauseRendering];
				[self didEndDecelerating];
			}
			break;
		case SIImageSequenceViewStateSpinning:
			if (fabsf(_targetFrameIndex - _frameIndex) < fabsf(_speed)) {
				_speed = 0;
				[self setFrameIndex:_targetFrameIndex immediately:YES];
				[self pauseRendering];
				[self didEndSpinning];
			}
			break;
		default:
			break;
	}
}

- (void)invalidate
{
	if (!_isDirty) {
		_isDirty = YES;
		// schedule render in next runloop
		[self performSelector:@selector(validate) withObject:nil afterDelay:0];
	}
}

- (void)validate
{
	if (_isDirty) {
		[self render];
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(validate) object:nil]; 
		_isDirty = NO;
	}
}

- (void)setFrameIndex:(NSInteger)frameIndex immediately:(BOOL)immediately
{
	_frameIndex = [self mappedFrameIndex:frameIndex];
	if (immediately) {
		[self render];
	} else {
		[self invalidate];
	}
}

- (NSInteger)mappedFrameIndex:(NSInteger)frameIndex
{
	NSInteger resultFrameIndex = frameIndex;
	if (frameIndex < 0) {
		if (_looping) {
			resultFrameIndex = frameIndex % (NSInteger)(_frameCount) + _frameCount;
		} else {
			resultFrameIndex = 0;
		}
	} else if (frameIndex >= _frameCount) {
		if (_looping) {
			resultFrameIndex = frameIndex % _frameCount;
		} else {
			resultFrameIndex = _frameCount - 1;
		}
	}
	return resultFrameIndex;
}

- (void)startRendering
{
	if (_isRendering) {
		return;
	}
	if (!_displayLink) {
		_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
        _displayLink.frameInterval = 2; // 30fps
		[_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	}
	_displayLink.paused = NO;
	_isRendering = YES;
}

- (void)pauseRendering
{
	_displayLink.paused = YES;
	_isRendering = NO;
}

- (void)stopRendering
{
	[_displayLink invalidate];
	_displayLink = nil;
	_isRendering = NO;
}

- (void)render
{
	if (!_pathFormat) {
		return;
	}
	NSBundle *bundle = _bundle;
	if (!bundle) {
		bundle = [NSBundle mainBundle];
	}
	UIImage *image = [UIImage imageWithContentsOfFile:[bundle pathForResource:[NSString stringWithFormat:_pathFormat, _frameIndex] ofType:nil]];
	if (image) {
        self.image = image;
	}
}

- (void)didEndDecelerating
{
	[self restoreState];
}

- (void)didEndSpinning
{
	if (_completion) {
		_completion(YES);
		_completion = nil;
	}
	[self restoreState];
}

- (void)restoreState
{
	if (_freeSpinning) {
		[self startFreeSpinWithSpeed:_freeSpinSpeed];
	} else {
		[self setState:SIImageSequenceViewStateIdling];
	}
}

- (void)setState:(SIImageSequenceViewState)state
{
	if (_state == state) {
		return;
	}
	_state = state;
	if ([_delegate respondsToSelector:@selector(imageSequenceView:didChangeState:)]) {
		[_delegate imageSequenceView:self didChangeState:_state];
	}
}

@end