//
//  MoviePlayerViewController.m
//  DFMovieDemo
//
//  Created by fuxp on 16/3/13.
//  Copyright © 2016年 fuxp. All rights reserved.
//

#import "MoviePlayerViewController.h"
#import "DFMoviePlayer.h"

@interface MoviePlayerViewController ()<DFMoviePlayerDelegate>
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (weak, nonatomic) IBOutlet UISlider *timeSlider;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;

@end

@implementation MoviePlayerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *play = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(play)];
    self.navigationItem.rightBarButtonItem = play;
    
    [[self player] setMovieDelegate:self];
    [[self player] setURL:_URL];
    [self play];
}

- (void)play
{
    [[self player] play];
    UIBarButtonItem *pause = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(pause)];
    self.navigationItem.rightBarButtonItem = pause;
}

- (void)pause
{
    [[self player] pause];
    UIBarButtonItem *play = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(play)];
    self.navigationItem.rightBarButtonItem = play;
}

- (IBAction)seekToTime:(UISlider *)sender
{
    [self.loadingIndicator startAnimating];
    [[self player] seekToTime:sender.value completionHandler:^(BOOL finish) {
        if (finish)
        {
            [self.loadingIndicator stopAnimating];
        }
    }];
}

- (DFMoviePlayer *)player
{
    return (DFMoviePlayer *)self.view;
}

- (NSString *)stringForTime:(DFMovieTime)time
{
    NSDateComponentsFormatter *formatter = [[NSDateComponentsFormatter alloc] init];
    formatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
    formatter.allowedUnits = NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.second = (NSInteger)fmax(0.0, time);
    return [formatter stringFromDateComponents:components];
}

#pragma mark - DFMoviePlayerDelegate

- (void)moviePlayerDidStartLoading:(DFMoviePlayer *)player
{
    [self.loadingIndicator startAnimating];
}

- (void)moviePlayerIsReadyForDisplay:(DFMoviePlayer *)player
{

}

- (void)moviePlayerIsReadyToPlay:(DFMoviePlayer *)player
{
    [self.loadingIndicator stopAnimating];
    self.timeSlider.enabled = YES;
}

- (void)moviePlayerDidUpdateDuration:(DFMoviePlayer *)player
{
    self.durationLabel.text = [self stringForTime:player.duration];
    self.timeSlider.maximumValue = player.duration;
}

- (void)moviePlayerDidUpdateCurrentTime:(DFMoviePlayer *)player
{
    self.currentTimeLabel.text = [self stringForTime:player.currentTime];
    if (!self.timeSlider.isTracking)
    {
        self.timeSlider.value = player.currentTime;
    }
}

- (void)moviePlayerDidPlayToEndTime:(DFMoviePlayer *)player
{
    [player seekToTime:0 completionHandler:^(BOOL finish) {
        if (finish)
        {
            UIBarButtonItem *play = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(play)];
            self.navigationItem.rightBarButtonItem = play;
        }
    }];
}

- (void)moviePlayer:(DFMoviePlayer *)player didFailPlayURL:(NSURL *)URL withError:(NSError *)error
{
    [self.loadingIndicator stopAnimating];
    NSLog(@"%@",error);
}

#pragma mark -

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
