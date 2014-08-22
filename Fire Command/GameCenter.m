//
//  GameCenter.m
//  Fire Command
//
//  Created by Hicham Chourak on 22/08/14.
//  Copyright (c) 2014 Hicham Chourak. All rights reserved.
//

#import "GameCenter.h"

@implementation GameCenter {
    NSString *_leaderboardIdentifier;
    BOOL _gameCenterEnabled;
}

- (void)authenticateLocalPlayer
{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    
    localPlayer.authenticateHandler = ^(UIViewController * viewController, NSError *error) {
        if (viewController != nil) {
            [self presentViewController:viewController animated:YES completion:nil];
        } else {
            if ([GKLocalPlayer localPlayer].authenticated) {
                _gameCenterEnabled = YES;
                
                [[GKLocalPlayer localPlayer] loadDefaultLeaderboardIdentifierWithCompletionHandler:^(NSString *leaderboardIdentifier, NSError *error) {
                    
                    if (error !=nil) {
                        NSLog(@"%@", [error localizedDescription]);
                    } else {
                        _leaderboardIdentifier = leaderboardIdentifier;
                    }
                }];
            } else {
                _gameCenterEnabled = NO;
            }
        }
        
    };
}

- (void)reportScore:(NSInteger)finalScore
{
    if (_leaderboardIdentifier != NULL) {
        
        GKScore *score = [[GKScore alloc] initWithLeaderboardIdentifier:_leaderboardIdentifier];
        score.value = finalScore;
        
        [GKScore reportScores:@[score] withCompletionHandler:^(NSError *error) {
            if (error != nil) {
                NSLog(@"%@", [error localizedDescription]);
            }
        }];
    }
    
}

- (void)showLeaderboard
{
    if (_leaderboardIdentifier != NULL) {
        GKGameCenterViewController *gcViewController = [[GKGameCenterViewController alloc] init];
        
        gcViewController.gameCenterDelegate = self;
        
        gcViewController.viewState = GKGameCenterViewControllerStateLeaderboards;
        gcViewController.leaderboardIdentifier = _leaderboardIdentifier;
        
        [self presentViewController:gcViewController animated:YES completion:nil];
    }
}

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController
{
    [gameCenterViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
