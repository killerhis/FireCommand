//
//  GameCenter.h
//  Fire Command
//
//  Created by Hicham Chourak on 22/08/14.
//  Copyright (c) 2014 Hicham Chourak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@interface GameCenter : UIViewController <GKGameCenterControllerDelegate>

- (void)authenticateLocalPlayer;
- (void)reportScore:(NSInteger)finalScore;

@end
