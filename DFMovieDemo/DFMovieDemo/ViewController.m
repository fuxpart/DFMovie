//
//  ViewController.m
//  DFMovieDemo
//
//  Created by fuxp on 16/3/13.
//  Copyright © 2016年 fuxp. All rights reserved.
//

#import "ViewController.h"
#import "MoviePlayerViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    MoviePlayerViewController *mvc = segue.destinationViewController;
    mvc.title = segue.identifier;
    if ([segue.identifier isEqualToString:@"Local File"])
    {
        NSString *path = @"your file path";
        NSURL *URL = [NSURL fileURLWithPath:path];
        mvc.URL = URL;
    }
    else
    {
        NSURL *URL = [NSURL URLWithString:@"your http string"];
        mvc.URL = URL;
    }
}

@end
