//
//  DFMoviePlayer.h
//  DFMovie
//
//  Created by fuxp on 16/3/8.
//  Copyright © 2016年 fuxp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DFMovieDefine.h"

@protocol DFMoviePlayerDelegate;

NS_CLASS_AVAILABLE_IOS(5_0) @interface DFMoviePlayer : UIView
/*!
 @brief The URL that references the media resource to be played.
 */
@property (nonatomic, strong) NSURL *URL;

/*!
 @brief How the video is displayed within the bounds rect. `DFMovieFillModeResizeAspect` is default.
 */
@property (nonatomic, assign) DFMovieFillMode fillMode;
/*!
 @brief Begins playback of the movie.
 */
- (void)play;
/*!
 @brief Pauses playback.
 */
- (void)pause;

@property (nonatomic, weak) id <DFMoviePlayerDelegate> movieDelegate;
/*!
 @brief Duration of the movie.
 @note  The duration of a movie can change dynamically during playback. Before the movie has been loaded, the value of this property is indefinite.
 */
@property (nonatomic, assign, readonly) DFMovieTime duration;
/*!
 @brief Current time of the movie.
 */
@property (nonatomic, assign, readonly) DFMovieTime currentTime;
/*!
 @brief Moves the playback cursor and invokes the specified block when the seek operation has either been completed or been interrupted. If the seek request completes without being interrupted (either by another seek request or by any other operation), the completion handler you provide is executed with the finished parameter set to YES. If another seek request is already in progress when you call this method, the completion handler for the in-progress seek request is executed immediately with the finished parameter set to NO.
 
 @param time              The time to which you would like to move the playback cursor.
 @param completionHandler The block to invoke when the seek operation has either been completed or been interrupted.
 */
- (void)seekToTime:(DFMovieTime)time completionHandler:(void(^)(BOOL finish))completionHandler;

@end


NS_AVAILABLE_IOS(5_0) @protocol DFMoviePlayerDelegate <NSObject>

@optional
- (void)moviePlayerDidStartLoading:(DFMoviePlayer *)player;

/*!
 @brief Invoked when the first video frame has been made ready for display for the movie. Before this, the player will not have any user-visible content.
 
 @param player The movie-player object informing the delegate of this event.
 */
- (void)moviePlayerIsReadyForDisplay:(DFMoviePlayer *)player;
- (void)moviePlayerIsReadyToPlay:(DFMoviePlayer *)player;
- (void)moviePlayerDidUpdateDuration:(DFMoviePlayer *)player;
- (void)moviePlayerDidUpdateCurrentTime:(DFMoviePlayer *)player;

/*!
 @brief Invoked when the movie has played to its end time.
 @note  After playback, the player’s head is set to the end of the item and further invocations of play have no effect. To position the playhead back at the beginning of the item, you can use @code - (void)seekToTime:(DFMovieTime)time completionHandler:(void(^)(BOOL finish))completionHandler @endcode with argument 0.
 
 @param player The movie-player object informing the delegate of this event.
 */
- (void)moviePlayerDidPlayToEndTime:(DFMoviePlayer *)player;
- (void)moviePlayer:(DFMoviePlayer *)player didFailPlayURL:(NSURL *)URL withError:(NSError *)error;

@end