//
//  SIImageSequenceView.h
//
//  Created by Kevin Cao on 12-6-25.
//  Copyright (c) 2012年 Sumi Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SIImageSequenceViewState) {
    SIImageSequenceViewStateIdling = 0,
	SIImageSequenceViewStateInteracting,
	SIImageSequenceViewStateDecelerating,
	SIImageSequenceViewStateSpinning,
	SIImageSequenceViewStateFreeSpinning
};

@protocol SIImageSequenceViewDelegate;

@interface SIImageSequenceView : UIImageView

@property (nonatomic, strong) NSBundle *bundle;
@property (nonatomic, copy) NSString   *pathFormat;									// required

@property (nonatomic, assign) NSUInteger               frameCount;					// default is 36
@property (nonatomic, assign) NSInteger                frameIndex;					// default is 0
@property (nonatomic, assign, getter = isLooping) BOOL looping;						// default is YES
@property (nonatomic, assign) float                    friction;					// default is 0.8

@property (nonatomic, readonly) SIImageSequenceViewState      state;				// default is SIImageSequenceViewStateIdling
@property (nonatomic, readonly, getter = isFreeSpinning) BOOL freeSpinning;

@property (nonatomic, weak) IBOutlet id <SIImageSequenceViewDelegate> delegate;

- (id)initWithPathFormat:(NSString *)pathFormat bundle:(NSBundle *)bundle;

- (void)spinToFrameIndex:(NSInteger)frameIndex speed:(NSInteger)speed completion:(void (^)(BOOL finished))completion;
- (void)startFreeSpinWithSpeed:(NSInteger)speed;
- (void)stopFreeSpin;

@end

@protocol SIImageSequenceViewDelegate <NSObject>

@optional
- (void)imageSequenceView:(SIImageSequenceView *)imageSequenceView didChangeState:(SIImageSequenceViewState)state;

@end
