//
//  DFMoviePlayer.m
//  DFMovie
//
//  Created by fuxp on 16/3/8.
//  Copyright © 2016年 fuxp. All rights reserved.
//

#import "DFMoviePlayer.h"
#import <AVFoundation/AVFoundation.h>

static void *DFMoviePlayerKVOContext = &DFMoviePlayerKVOContext;

@interface DFMoviePlayer ()

@property (nonatomic, strong, readonly) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) id timeObserverToken;

@end

@implementation DFMoviePlayer

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self addObserver];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self addObserver];
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver];
}

- (void)didMoveToWindow
{
    if (!self.window)
    {
        [self pause];
    }
}

- (void)updatePlayer
{
    if ([self.movieDelegate respondsToSelector:@selector(moviePlayerDidStartLoading:)])
    {
        [self.movieDelegate moviePlayerDidStartLoading:self];
    }
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:_URL options:nil];
    NSArray *keys = @[@"playable", @"hasProtectedContent"];
    [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            for (NSString *key in keys)
            {
                NSError *error = nil;
                if ([asset statusOfValueForKey:key error:&error] == AVKeyValueStatusFailed)
                {
                    if ([self.movieDelegate respondsToSelector:@selector(moviePlayer:didFailPlayURL:withError:)])
                    {
                        [self.movieDelegate moviePlayer:self didFailPlayURL:_URL withError:error];
                    }
                    return;
                }
            }
            if (!asset.playable || asset.hasProtectedContent)
            {
                NSError *error = [[NSError alloc]initWithDomain:@"Can't play this video because it isn't playable or has protected content." code:AVErrorUnknown userInfo:nil];
                if ([self.movieDelegate respondsToSelector:@selector(moviePlayer:didFailPlayURL:withError:)])
                {
                    [self.movieDelegate moviePlayer:self didFailPlayURL:_URL withError:error];
                }
                return;
            }
            AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
            if (df_system_version() >= 9.0)
            {
#ifdef __IPHONE_9_0
                item.canUseNetworkResourcesForLiveStreamingWhilePaused = YES;
#endif
            }
            if (!self.player)
            {
                self.player = [[AVPlayer alloc]initWithPlayerItem:item];
            }
            else
            {
                [self.player replaceCurrentItemWithPlayerItem:item];
            }
        });
    }];
}

#pragma mark - getter && setter

- (AVPlayerLayer *)playerLayer
{
    return (AVPlayerLayer *)self.layer;
}

- (void)setPlayer:(AVPlayer *)player
{
    [self.playerLayer setPlayer:player];
}

- (AVPlayer *)player
{
    return self.playerLayer.player;
}

#pragma mark - KVO & notification
- (void)addObserver
{
    AVPlayer *player = [[AVPlayer alloc]init];
    self.player = player;
    
    [self addObserver:self forKeyPath:@"player.currentItem.duration" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:DFMoviePlayerKVOContext];
    [self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:DFMoviePlayerKVOContext];
    [self addObserver:self forKeyPath:@"player.currentItem.playbackBufferEmpty" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:DFMoviePlayerKVOContext];
    [self addObserver:self forKeyPath:@"layer.readyForDisplay" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:DFMoviePlayerKVOContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemFailedToPlayToEndTime:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    
    typeof(self) __weak weakSelf = self;
    _timeObserverToken = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        if ([weakSelf.movieDelegate respondsToSelector:@selector(moviePlayerDidUpdateCurrentTime:)])
        {
            [weakSelf.movieDelegate moviePlayerDidUpdateCurrentTime:weakSelf];
        }
    }];
}

- (void)removeObserver
{
    [self removeObserver:self forKeyPath:@"player.currentItem.duration" context:DFMoviePlayerKVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem.status" context:DFMoviePlayerKVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem.playbackBufferEmpty" context:DFMoviePlayerKVOContext];
    [self removeObserver:self forKeyPath:@"layer.readyForDisplay" context:DFMoviePlayerKVOContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.player removeTimeObserver:_timeObserverToken];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context != DFMoviePlayerKVOContext)
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if ([keyPath isEqualToString:@"player.currentItem.duration"])
    {
        NSValue *newDurationValue = change[NSKeyValueChangeNewKey];
        CMTime newDuration = [newDurationValue isKindOfClass:[NSValue class]] ? newDurationValue.CMTimeValue : kCMTimeZero;
        BOOL hasValidDuration = CMTIME_IS_NUMERIC(newDuration) && newDuration.value != 0;
        if (hasValidDuration)
        {
            if ([self.movieDelegate respondsToSelector:@selector(moviePlayerDidUpdateDuration:)])
            {
                [self.movieDelegate moviePlayerDidUpdateDuration:self];
            }
        }
    }
    else if ([keyPath isEqualToString:@"player.currentItem.status"])
    {
        NSNumber *newStatusNumber = change[NSKeyValueChangeNewKey];
        AVPlayerItemStatus newStatus = [newStatusNumber isKindOfClass:[NSNumber class]] ? newStatusNumber.integerValue : AVPlayerItemStatusUnknown;
        if (newStatus == AVPlayerItemStatusFailed)
        {
            if ([self.movieDelegate respondsToSelector:@selector(moviePlayer:didFailPlayURL:withError:)])
            {
                [self.movieDelegate moviePlayer:self didFailPlayURL:_URL withError:self.player.currentItem.error];
            }
        }
        else if (newStatus == AVPlayerItemStatusReadyToPlay)
        {
            if ([self.movieDelegate respondsToSelector:@selector(moviePlayerIsReadyToPlay:)])
            {
                [self.movieDelegate moviePlayerIsReadyToPlay:self];
            }
        }
    }
    else if ([keyPath isEqualToString:@"layer.readyForDisplay"])
    {
        NSNumber *newReadyForDisplayNumber = change[NSKeyValueChangeNewKey];
        BOOL newReadyForDisplay = [newReadyForDisplayNumber isKindOfClass:[NSNumber class]] ? newReadyForDisplayNumber.boolValue : NO;
        if (newReadyForDisplay)
        {
            if ([self.movieDelegate respondsToSelector:@selector(moviePlayerIsReadyForDisplay:)])
            {
                [self.movieDelegate moviePlayerIsReadyForDisplay:self];
            }
        }
    }
    else if ([keyPath isEqualToString:@"player.currentItem.playbackBufferEmpty"])
    {
        NSNumber *newBufferEmptyNumber = change[NSKeyValueChangeNewKey];
        BOOL newBufferEmpty = [newBufferEmptyNumber isKindOfClass:[NSNumber class]] ? newBufferEmptyNumber.boolValue : YES;
        if (newBufferEmpty)
        {
            if ([self.movieDelegate respondsToSelector:@selector(moviePlayerDidStartLoading:)])
            {
                [self.movieDelegate moviePlayerDidStartLoading:self];
            }
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)itemDidPlayToEndTime:(NSNotification *)notification
{
    if ([self.movieDelegate respondsToSelector:@selector(moviePlayerDidPlayToEndTime:)])
    {
        [self.movieDelegate moviePlayerDidPlayToEndTime:self];
    }
}

- (void)itemFailedToPlayToEndTime:(NSNotification *)notification
{
    if ([self.movieDelegate respondsToSelector:@selector(moviePlayer:didFailPlayURL:withError:)])
    {
        NSError *error = notification.userInfo[AVPlayerItemFailedToPlayToEndTimeErrorKey];
        [self.movieDelegate moviePlayer:self didFailPlayURL:_URL withError:error];
    }
}

#pragma mark - API
- (void)setURL:(NSURL *)URL
{
    _URL = URL;
    [self updatePlayer];
}

- (void)play
{
    [self.player play];
}

- (void)pause
{
    [self.player pause];
}

- (void)setFillMode:(DFMovieFillMode)fillMode
{
    if (fillMode == _fillMode)
    {
        return;
    }
    _fillMode = fillMode;
    switch (fillMode)
    {
        case DFMovieFillModeResizeAspect:
            [self.playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
            break;
        case DFMovieFillModeResizeAspectFill:
            [self.playerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
            break;
        case DFMovieFillModeResize:
            [self.playerLayer setVideoGravity:AVLayerVideoGravityResize];
            break;
        default:
            break;
    }
}

- (DFMovieTime)duration
{
    return CMTimeGetSeconds(self.player.currentItem.duration);
}

- (DFMovieTime)currentTime
{
    return CMTimeGetSeconds(self.player.currentTime);
}

- (void)seekToTime:(DFMovieTime)time completionHandler:(void(^)(BOOL finish))completionHandler
{
    [self.player seekToTime:CMTimeMake(time, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:completionHandler];
}

@end
