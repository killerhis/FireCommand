//
//  ViewController.h
//  Fire Command
//

//  Copyright (c) 2014 Hicham Chourak. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import "GameCenterManager.h"

@interface ViewController : UIViewController <GameCenterManagerDelegate>

@property (nonatomic, strong) SKView *skView;

@end
