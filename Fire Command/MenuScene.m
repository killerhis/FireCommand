//
//  MenuScene.m
//  Fire Command
//
//  Created by Hicham Chourak on 19/08/14.
//  Copyright (c) 2014 Hicham Chourak. All rights reserved.
//

#import "MenuScene.h"
#import "GameScene.h"

@implementation MenuScene {
    UIButton *singlePlayerButton;
    UIButton *multiPlayerButton;
}

- (id)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor blackColor];
    }
    
    return self;
}

- (void)didMoveToView:(SKView *)view
{
    SKLabelNode *title = [SKLabelNode labelNodeWithFontNamed:@"HelveticaNeue-Bold"];
    title.fontColor = [SKColor whiteColor];
    title.fontSize = 30;
    title.text = @"Fire Command";
    title.zPosition = 2;
    //title.scale = 0.4;
    title.position = CGPointMake(self.size.width/2, self.size.height/2);
    [self addChild:title];
    
    UIImage *buttonImageNormal = [UIImage imageNamed:@"singleBtn.png"];
    singlePlayerButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    singlePlayerButton.frame = CGRectMake(self.size.height/8, self.size.width/2+250, buttonImageNormal.size.width, buttonImageNormal.size.height);
    singlePlayerButton.backgroundColor = [UIColor clearColor];
    [singlePlayerButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    UIImage *strechableButtonImageNormal = [buttonImageNormal stretchableImageWithLeftCapWidth:12 topCapHeight:0];
    [singlePlayerButton setBackgroundImage:strechableButtonImageNormal forState:UIControlStateNormal];
    [singlePlayerButton addTarget:self action:@selector(moveToSinglePlayerGame) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:singlePlayerButton];
    
}

- (void)moveToSinglePlayerGame
{
    SKScene *scene = [GameScene sceneWithSize:self.view.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    SKTransition *transition = [SKTransition revealWithDirection:SKTransitionDirectionUp duration:1];
    SKView *skView = (SKView *)self.view;
    [skView presentScene:scene transition:transition];
    
    [singlePlayerButton removeFromSuperview];
    [multiPlayerButton removeFromSuperview];
}

@end
