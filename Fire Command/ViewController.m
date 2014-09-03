//
//  ViewController.m
//  Fire Command
//
//  Created by Hicham Chourak on 19/08/14.
//  Copyright (c) 2014 Hicham Chourak. All rights reserved.
//

#import "ViewController.h"
#import "MenuScene.h"
#import <SpriteKit/SpriteKit.h>

@implementation ViewController {
    NSString *_leaderboardIdentifier;
    BOOL _gameCenterEnabled;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Game Center
    [[GameCenterManager sharedManager] setDelegate:self];
    
    // Configure the view.
    self.skView = (SKView *)self.view;
    
    // Create and configure the scene.
    SKScene * scene = [MenuScene sceneWithSize:self.skView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [self.skView presentScene:scene];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - GameCenterManagerDelegate

- (void)gameCenterManager:(GameCenterManager *)manager authenticateUser:(UIViewController *)gameCenterLoginController {
    [self presentViewController:gameCenterLoginController animated:YES completion:^{
        NSLog(@"Done presenting gamecenter");
    }];
}


@end
