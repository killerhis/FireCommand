//
//  MenuScene.m
//  Fire Command
//
//  Created by Hicham Chourak on 19/08/14.
//  Copyright (c) 2014 Hicham Chourak. All rights reserved.
//

#import "MenuScene.h"
#import "GameScene.h"
//#import "GAIDictionaryBuilder.h"
#import "ViewController.h"
#import <ObjectAL/ObjectAL.h>
#import "GameCenterManager.h"

#define kIntroTrackFileName @"game-menu-music-1.caf"
#define kLoopTrackFileName @"game-menu-music-2.caf"

@interface MenuScene () //<GameCenterManagerDelegate>

@property(nonatomic, readwrite, retain) ALBuffer* introBuffer;
//@property(nonatomic, readwrite, retain) ALBuffer* mainBuffer;
@property(nonatomic, readwrite, retain) ALSource* source;

@property(nonatomic, readwrite, retain) OALAudioTrack* mainTrack;
//@property(nonatomic, readwrite, retain) OALAudioTrack* introTrack;

@end

@implementation MenuScene {
    
    UIButton *singlePlayerButton;
    UIButton *singlePlayerButton2;
    UIButton *multiPlayerButton;
    
    ALDevice* device;
    ALContext* context;
    
    BOOL _gameMute;
    
    NSUserDefaults *_defaults;
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
    // GA
    //id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    //[tracker set:kGAIScreenName value:@"StartMenu"];
    //[tracker send:[[GAIDictionaryBuilder createAppView] build]];
    
    // Mute audio
    _defaults = [NSUserDefaults standardUserDefaults];
    _gameMute = [_defaults boolForKey:@"gameMute"];
    
    
    
    
    // Music
    [self playBackgroundMusic:_gameMute];

    SKLabelNode *title = [SKLabelNode labelNodeWithFontNamed:@"HelveticaNeue-Bold"];
    title.fontColor = [SKColor whiteColor];
    title.fontSize = 30 * [self DeviceScale];
    
    title.text = @"Fire Command";
    title.zPosition = 2;
    //title.scale = 0.4;
    title.position = CGPointMake(self.size.width/2, self.size.height/2);
    [self addChild:title];
    
    
    
    UIImage *buttonImageNormal = [UIImage imageNamed:@"singleBtn.png"];
    singlePlayerButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    singlePlayerButton.frame = CGRectMake(self.size.height/16, (self.size.width/4)*3, buttonImageNormal.size.width/(3-[self DeviceScale]), buttonImageNormal.size.height/(3-[self DeviceScale]));
    singlePlayerButton.backgroundColor = [UIColor clearColor];
    [singlePlayerButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    UIImage *strechableButtonImageNormal = [buttonImageNormal stretchableImageWithLeftCapWidth:12 topCapHeight:0];
    [singlePlayerButton setBackgroundImage:strechableButtonImageNormal forState:UIControlStateNormal];
    [singlePlayerButton addTarget:self action:@selector(moveToSinglePlayerGame) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:singlePlayerButton];
    
    UIImage *buttonImageNormal2 = [UIImage imageNamed:@"singleBtn.png"];
    singlePlayerButton2 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    singlePlayerButton2.frame = CGRectMake(self.size.height/16, (self.size.width/4)*2, buttonImageNormal.size.width/(3-[self DeviceScale]), buttonImageNormal2.size.height/(3-[self DeviceScale]));
    singlePlayerButton2.backgroundColor = [UIColor clearColor];
    [singlePlayerButton2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    UIImage *strechableButtonImageNormal2 = [buttonImageNormal stretchableImageWithLeftCapWidth:12 topCapHeight:0];
    [singlePlayerButton2 setBackgroundImage:strechableButtonImageNormal2 forState:UIControlStateNormal];
    [singlePlayerButton2 addTarget:self action:@selector(showLeaderBoard) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:singlePlayerButton2];
    
}

- (void)showLeaderBoard
{
    BOOL isGameCenterAvailable = [[GameCenterManager sharedManager] checkGameCenterAvailability];
    
    if (isGameCenterAvailable) {
        [[GameCenterManager sharedManager] presentLeaderboardsOnViewController:(ViewController *)self.view.window.rootViewController];
    }
}

- (void)moveToSinglePlayerGame
{
    [self stopBackgroundMusic];
    SKScene *scene = [GameScene sceneWithSize:self.view.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    //SKTransition *transition = [SKTransition revealWithDirection:SKTransitionDirectionUp duration:1];
    SKTransition *transition = [SKTransition fadeWithDuration:0.5];
    SKView *skView = (SKView *)self.view;
    
    [skView presentScene:scene transition:transition];
    
    [singlePlayerButton removeFromSuperview];
    [singlePlayerButton2 removeFromSuperview];
}

#pragma mark - Helper Methods

- (float)DeviceScale
{
    float scaleTextures;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        scaleTextures = 2.0;
    } else {
        scaleTextures = 1.0;
    }
    
    return scaleTextures;
}

#pragma mark - Play Audio

- (void)playBackgroundMusic:(BOOL)mute
{
    if (!mute) {
        
        // Create the device and context.
        // Note that it's easier to just let OALSimpleAudio handle
        // these rather than make and manage them yourself.
        //device = [ALDevice deviceWithDeviceSpecifier:nil];
        //context = [ALContext contextOnDevice:device attributes:nil];
        //[OpenALManager sharedInstance].currentContext = context;
        
        // Deal with interruptions for me!
        //[OALAudioSession sharedInstance].handleInterruptions = YES;
        
        // Mute all audio if the silent switch is turned on.
        //[OALAudioSession sharedInstance].honorSilentSwitch = YES;
        //[OALSimpleAudio sharedInstance].reservedSources = 0;
        [OALSimpleAudio sharedInstance];
        self.source = [ALSource source];
        self.introBuffer = [[OpenALManager sharedInstance] bufferFromFile:kIntroTrackFileName];
        //self.mainBuffer = [[OpenALManager sharedInstance] bufferFromFile:kLoopTrackFileName];
        
        //self.introTrack = [OALAudioTrack track];
        //[self.introTrack preloadFile:kIntroTrackFileName];
        
        self.mainTrack = [OALAudioTrack track];
        [self.mainTrack preloadFile:kLoopTrackFileName];
        // Main music track will loop on itself
        self.mainTrack.numberOfLoops = -1;
        
        //NSLog(@"%f", self.introBuffer.duration);
        
        [self onOpenALHybrid];
    }

}

- (void)onOpenALHybrid
{
    // Uses OpenAL for the intro and an audio track for the main loop.
    // Playback on the main track is delayed by the duration of the intro.
    
    // This sidesteps the software channel issue, but requires you to load
    // the entire decoded intro track (not the main track) into memory.
    // However, there are problems because of differences in how OpenAL and
    // AVAudioPlayer keep time (AVAudioPlayer is somewhat delayed).
    // You'll need to do some fudging of the playAt value to get it right.
    // I've left it as-is so you can hear the issue.
    
    //[self stop];
    //[self turnOnLamp:self.openALButton];
    
    [self.source play:self.introBuffer];
    
    // Have the main track start again after the intro buffer's duration elapses.
    NSTimeInterval playAt = self.mainTrack.deviceCurrentTime + self.introBuffer.duration;
    [self.mainTrack playAtTime:playAt];
    self.mainTrack.volume = 1;
}

- (void)stopBackgroundMusic
{
    //[self.source unregisterAllNotifications];
    [self.source stop];
    //[self.introTrack stop];
    [self.mainTrack stop];
    //self.introTrack.currentTime = 0;
    self.mainTrack.currentTime = 0;
}


/*- (void)gameCenterManager:(GameCenterManager *)manager authenticateUser:(UIViewController *)gameCenterLoginController {
    // Do something with the login controller, either present it now (shown below) or store it to present later
    NSLog(@"present gamecenter login");
    [(ViewController *)self.view.window.rootViewController presentViewController:gameCenterLoginController animated:YES completion:nil];
    //[self presentViewController:gameCenterLoginController animated:YES completion:nil];
}*/







@end
