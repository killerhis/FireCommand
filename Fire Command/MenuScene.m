//
//  MenuScene.m
//  Fire Command
//
//  Created by Hicham Chourak on 19/08/14.
//  Copyright (c) 2014 Hicham Chourak. All rights reserved.
//

#import "MenuScene.h"
#import "GameScene.h"
#import "GAIDictionaryBuilder.h"
#import "ViewController.h"
#import "GameCenterManager.h"

#define kIntroTrackFileName @"introv2_1.caf"
#define kLoopTrackFileName @"introv2_2.caf"

#define ARC4RANDOM_MAX 0x100000000

@interface MenuScene () //<GameCenterManagerDelegate>

@property(nonatomic, readwrite, retain) ALBuffer* introBuffer;
@property(nonatomic, readwrite, retain) ALSource* source;

@property(nonatomic, readwrite, retain) OALSimpleAudio *sourceSFX;
@property(nonatomic, readwrite, retain) ALBuffer* clickSFX;
@property(nonatomic, readwrite, retain) ALBuffer* nuclearExplosionSFX;

@end

@implementation MenuScene {
    
    ALDevice* device;
    ALContext* context;
    
    BOOL _gameMute;
    BOOL _startGame;
    BOOL showAsteroid;
    
    float _scale;
    
    NSUserDefaults *_defaults;
    
    SKScene *scene;
    
    SKSpriteNode *soundButton;
    SKSpriteNode *title;
    SKSpriteNode *_flashBackground;
    SKSpriteNode *_asteroid;
    
    NSArray *_textureNuclearExplosionFrames;
    
    CFTimeInterval nextAsteroidTime;
    
}

- (id)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor blackColor];
        
        [self initGroundExplosion];
        nextAsteroidTime = 0;
        showAsteroid = NO;
        [self setDeviceScale];
    }
    
    return self;
}

- (void)didMoveToView:(SKView *)view
{
    // GA
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"StartMenu"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    tracker.allowIDFACollection = NO;
    
    // Load notification for background states
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    // Mute audio
    _defaults = [NSUserDefaults standardUserDefaults];
    _gameMute = [_defaults boolForKey:@"gameMute"];
    
    // Music
    [self playBackgroundMusic:_gameMute];
    
    title = [SKSpriteNode spriteNodeWithImageNamed:@"title.png"];
    title.zPosition = 10;
    title.position = CGPointMake(self.size.width/2, -title.size.height/2);
    
    SKAction *wait = [SKAction waitForDuration:0.5];
    SKAction *move = [SKAction moveToY:self.size.height/2+title.size.height duration:1.0];
    
    [title runAction:[SKAction sequence:@[wait, move]] completion:^{
        [self animateTitleAsteroid];
    }];
    
    [self addChild:title];
    
    // Buttons
    
    SKSpriteNode *gameCenterButton = [SKSpriteNode spriteNodeWithImageNamed:@"gamecenterbutton.png"];
    gameCenterButton.zPosition = 10;
    gameCenterButton.alpha = 0.0;
    gameCenterButton.name = @"gamecenterbutton";
    gameCenterButton.position = CGPointMake(self.size.width/4, self.size.height/2 - gameCenterButton.size.height);
    
    SKAction *waitButton1 = [SKAction waitForDuration:2.0];
    SKAction *fade = [SKAction fadeAlphaTo:1.0 duration:0.5];
    
    [gameCenterButton runAction:[SKAction sequence:@[waitButton1, fade]]];
    
    [self addChild:gameCenterButton];
    
    
    SKSpriteNode *playButton = [SKSpriteNode spriteNodeWithImageNamed:@"playbutton.png"];
    playButton.zPosition = 10;
    playButton.alpha = 0.0;
    playButton.name = @"playbutton";
    playButton.position = CGPointMake(self.size.width/2, self.size.height/2 - playButton.size.height);
    
    SKAction *waitButton2 = [SKAction waitForDuration:2.3];
    
    [playButton runAction:[SKAction sequence:@[waitButton2, fade]]];
    [self addChild:playButton];
    
    // Sound Button
    SKTexture *soundTexture;
    
    if (_gameMute) {
        soundTexture = [SKTexture textureWithImageNamed:@"mutebutton.png"];
    } else {
        soundTexture = [SKTexture textureWithImageNamed:@"soundbutton.png"];
    }
    
    soundButton = [SKSpriteNode spriteNodeWithTexture:soundTexture];
    soundButton.zPosition = 10;
    soundButton.alpha = 0.0;
    soundButton.name = @"soundbutton";
    soundButton.position = CGPointMake((self.size.width/4)*3, self.size.height/2 - playButton.size.height);
    
    SKAction *waitButton3 = [SKAction waitForDuration:2.6];
    
    [soundButton runAction:[SKAction sequence:@[waitButton3, fade]] completion:^{
        showAsteroid = YES;
    }];
    
    [self addChild:soundButton];
    
    //Background image
    
    SKSpriteNode *backgroundImage = [SKSpriteNode spriteNodeWithImageNamed:@"background_menu.png"];
    backgroundImage.zPosition = -10;
    backgroundImage.alpha = 0.0;
    backgroundImage.position = CGPointMake(self.size.width/2, self.size.height/2);
    
    SKAction *waitBackground = [SKAction waitForDuration:2];
    SKAction *fadeBackground = [SKAction fadeAlphaTo:1.0 duration:5.0];
    [backgroundImage runAction:[SKAction sequence:@[waitBackground, fadeBackground]]];
    
    [self addChild:backgroundImage];
    
    // Flash background
    _flashBackground = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:self.size];
    _flashBackground.position = CGPointMake(self.size.width/2, self.size.height/2);
    [self addChild:_flashBackground];
    
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    if (showAsteroid) {
        
        if (currentTime > nextAsteroidTime || nextAsteroidTime - currentTime > 5) {
            nextAsteroidTime = ([self getRandomDouble] * 4) + currentTime;
            [self addAstroid];
        }
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        SKNode *node = [self nodeAtPoint:location];
        
        if ([node.name isEqualToString:@"soundbutton"]) {
            [self soundButtonPressed];
            if(!_gameMute) {
                [self.sourceSFX playBuffer:self.clickSFX volume:1.0 pitch:1.0 pan:0 loop:NO];
            }
            
        } else if ([node.name isEqualToString:@"gamecenterbutton"]) {
            [self showLeaderBoard];
            if(!_gameMute) {
                [self.sourceSFX playBuffer:self.clickSFX volume:1.0 pitch:1.0 pan:0 loop:NO];
            }
            
        } else if ([node.name isEqualToString:@"playbutton"]) {
            [self moveToSinglePlayerGame];
            if(!_gameMute) {
                [self.sourceSFX playBuffer:self.clickSFX volume:1.0 pitch:1.0 pan:0 loop:NO];
            }
        }
    }
}

#pragma mark - Menu Elements

- (void)animateTitleAsteroid
{
    SKSpriteNode *asteroid = [SKSpriteNode spriteNodeWithImageNamed:@"asteroid_1a"];
    asteroid.zPosition = 20;
    asteroid.position = CGPointMake(self.size.width + asteroid.size.width, self.size.height + asteroid.size.height);
    
    SKAction *rotate = [SKAction repeatActionForever:[SKAction rotateByAngle:M_PI*2 duration:3]];
    SKAction *move = [SKAction moveTo:CGPointMake(self.size.width/2 - title.size.width/4 + 10*_scale, self.size.height/2 + title.size.height - 15*_scale) duration:0.7];
    
    [asteroid runAction:rotate];
    [asteroid runAction:move completion:^{
        [self addGroundExplosion:CGPointMake(asteroid.position.x, asteroid.position.y - asteroid.size.height/2 + 15*_scale)];
        
        SKTexture *titleTexture = [SKTexture textureWithImageNamed:@"title_clean.png"];
        [title runAction:[SKAction setTexture:titleTexture]];
        
        if(!_gameMute) {
            [self.sourceSFX playBuffer:self.nuclearExplosionSFX volume:1.0 pitch:1.0 pan:0 loop:NO];
        }
    }];
    
    [self addChild:asteroid];
    
    
}

- (void)addAstroid
{
    int i = [self getRandomNumberBetween:1 to:4];
    
    if (i ==1) {
        _asteroid = [self asteroid1];
    } else if (i == 2) {
        _asteroid = [self asteroid2];
    } else if (i == 3) {
        _asteroid = [self asteroid3];
    } else {
        _asteroid = [self asteroid4];
    }
    
    _asteroid.zPosition = -10;
    
    int edge = [self getRandomNumberBetween:0 to:1];
    SKAction *move;
    
    if (edge == 0) {
        int startPoint = [self getRandomNumberBetween:0 to:self.size.height];
        _asteroid.position = CGPointMake(self.size.width + _asteroid.size.width, startPoint);
        
        int endPoint = [self getRandomNumberBetween:0 to:self.size.height];
        move =[SKAction moveTo:CGPointMake(0 - _asteroid.size.width, endPoint) duration:[self getRandomNumberBetween:5 to:15]];
    } else {
        int startPoint = [self getRandomNumberBetween:0 to:self.size.width];
        _asteroid.position = CGPointMake(startPoint, self.size.height+_asteroid.size.width);
        
        int endPoint = [self getRandomNumberBetween:0 to:self.size.width];
        move =[SKAction moveTo:CGPointMake(endPoint, 0 - _asteroid.size.width) duration:[self getRandomNumberBetween:5 to:15]];
    }
    
    SKAction *remove = [SKAction removeFromParent];
    [_asteroid runAction:[SKAction sequence:@[move,remove]]];
    
    // rotate asteroid
    float rotateDuration = [self getRandomDouble]*9+1;
    
    int rotateDirection;
    if ([self getRandomNumberBetween:-1 to:1] < 0) {
        rotateDirection = -1;
    } else {
        rotateDirection = 1;
    }
    
    SKAction *rotate = [SKAction repeatActionForever:[SKAction rotateByAngle:rotateDirection*M_PI*2 duration:rotateDuration]];
    [_asteroid runAction:rotate];
    [self addChild:_asteroid];
}

- (SKSpriteNode *)asteroid1
{
    int i = [self getRandomNumberBetween:1 to:3];
    SKSpriteNode *sprite;
    
    if (i ==1) {
        sprite = [SKSpriteNode spriteNodeWithImageNamed:@"asteroid_1a.png"];
        sprite.name = [NSString stringWithFormat:@"asteroid_1a"];
    } else if (i ==2) {
        sprite = [SKSpriteNode spriteNodeWithImageNamed:@"asteroid_1b.png"];
        sprite.name = [NSString stringWithFormat:@"asteroid_1b"];
    } else {
        sprite = [SKSpriteNode spriteNodeWithImageNamed:@"asteroid_1c.png"];
        sprite.name = [NSString stringWithFormat:@"asteroid_1c"];
    }
    
    return sprite;
}

- (SKSpriteNode *)asteroid2
{
    int i = [self getRandomNumberBetween:1 to:3];
    SKSpriteNode *sprite;
    
    if (i ==1) {
        sprite = [SKSpriteNode spriteNodeWithImageNamed:@"asteroid_2a.png"];
        sprite.name = [NSString stringWithFormat:@"asteroid_2a"];
    } else if (i ==2) {
        sprite = [SKSpriteNode spriteNodeWithImageNamed:@"asteroid_2b.png"];
        sprite.name = [NSString stringWithFormat:@"asteroid_2b"];
    } else {
        sprite = [SKSpriteNode spriteNodeWithImageNamed:@"asteroid_2c.png"];
        sprite.name = [NSString stringWithFormat:@"asteroid_2c"];
    }
    
    return sprite;
}

- (SKSpriteNode *)asteroid3
{
    int i = [self getRandomNumberBetween:1 to:3];
    SKSpriteNode *sprite;
    
    if (i ==1) {
        sprite = [SKSpriteNode spriteNodeWithImageNamed:@"asteroid_3a.png"];
        sprite.name = [NSString stringWithFormat:@"asteroid_3a"];
    } else if (i ==2) {
        sprite = [SKSpriteNode spriteNodeWithImageNamed:@"asteroid_3b.png"];
        sprite.name = [NSString stringWithFormat:@"asteroid_3b"];
    } else {
        sprite = [SKSpriteNode spriteNodeWithImageNamed:@"asteroid_3c.png"];
        sprite.name = [NSString stringWithFormat:@"asteroid_3c"];
    }
    
    return sprite;
}

- (SKSpriteNode *)asteroid4
{
    int i = [self getRandomNumberBetween:1 to:3];
    SKSpriteNode *sprite;
    
    if (i ==1) {
        sprite = [SKSpriteNode spriteNodeWithImageNamed:@"asteroid_4a.png"];
        sprite.name = [NSString stringWithFormat:@"asteroid_4a"];
    } else if (i ==2) {
        sprite = [SKSpriteNode spriteNodeWithImageNamed:@"asteroid_4b.png"];
        sprite.name = [NSString stringWithFormat:@"asteroid_4b"];
    } else {
        sprite = [SKSpriteNode spriteNodeWithImageNamed:@"asteroid_4c.png"];
        sprite.name = [NSString stringWithFormat:@"asteroid_4c"];
    }
    
    return sprite;
}


- (void)initGroundExplosion
{
    NSMutableArray *frames = [NSMutableArray array];
    
    for (int i=0; i <= 20; i++) {
        NSString *textureName = [NSString stringWithFormat:@"nuclear_explosion_%d", i];
        SKTexture *texture = [SKTexture textureWithImageNamed:textureName];
        [frames addObject:texture];
    }
    
    _textureNuclearExplosionFrames = frames;
    
    [SKTexture preloadTextures:_textureNuclearExplosionFrames withCompletionHandler:^{}];
}

- (void)addGroundExplosion:(CGPoint)location
{
    SKSpriteNode *nuclearExplosion = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:CGSizeMake(110*_scale, 80*_scale)];
    nuclearExplosion.position = CGPointMake(location.x, location.y + nuclearExplosion.size.height/2);
    nuclearExplosion.zPosition = 30;
    
    [nuclearExplosion runAction:[SKAction animateWithTextures:_textureNuclearExplosionFrames
                                                 timePerFrame:0.1f
                                                       resize:NO
                                                      restore:YES]];
    
    [self addChild:nuclearExplosion];
    [self flashBackground];
}

- (void)flashBackground
{
    [self runAction:[SKAction sequence:@[[SKAction repeatAction:[SKAction sequence:@[[SKAction runBlock:^{
        _flashBackground.color = [SKColor colorWithRed:1.0 green:1.0 blue:220.0/255.0 alpha:1.0];
    }], [SKAction waitForDuration:0.05], [SKAction runBlock:^{
        _flashBackground.color = [SKColor clearColor];
    }], [SKAction waitForDuration:0.05]]] count:1]]] withKey:@"flash"];
}


#pragma mark - Helper Methods

- (void)setDeviceScale
{
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _scale = 2.0;
    } else {
        _scale = 1.0;
    }
}

- (void)soundButtonPressed
{
    SKTexture *changeTexture;
    
    if (_gameMute) {
        _gameMute = NO;
        [self playBackgroundMusic:NO];
        changeTexture = [SKTexture textureWithImageNamed:@"soundbutton.png"];
    } else {
        _gameMute = YES;
        [self stopBackgroundMusic];
        changeTexture = [SKTexture textureWithImageNamed:@"mutebutton.png"];
    }
    
    [soundButton runAction:[SKAction setTexture:changeTexture]];
    [_defaults setBool:_gameMute forKey:@"gameMute"];
    [_defaults synchronize];
}

- (void)showLeaderBoard
{
    BOOL isGameCenterAvailable = [[GameCenterManager sharedManager] checkGameCenterAvailability];
    
    if (isGameCenterAvailable) {
        [[GameCenterManager sharedManager] presentLeaderboardsOnViewController:(ViewController *)self.view.window.rootViewController];
    } else {
        // popup user nog logedin
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Game Center Unavailable" message:@"Player is not signed in" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil ];
        
        [alertView show];
    }
}

- (void)moveToSinglePlayerGame
{
    [self stopBackgroundMusic];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        scene = [GameScene sceneWithSize:self.view.bounds.size];
        scene.scaleMode = SKSceneScaleModeAspectFill;
        SKTransition *transition = [SKTransition fadeWithDuration:0.5];
        SKView *skView = (SKView *)self.view;
        [skView presentScene:scene transition:transition];
    });
}

- (int)getRandomNumberBetween:(int)from to:(int)to
{
    return (int)from + arc4random() % (to - from + 1);
}

- (double)getRandomDouble
{
    return ((double)arc4random() / ARC4RANDOM_MAX);
}

#pragma mark - Play Audio

- (void)playBackgroundMusic:(BOOL)mute
{
    if (!mute) {

        [OALSimpleAudio sharedInstance];
        self.source = [ALSource source];
        self.introBuffer = [[OpenALManager sharedInstance] bufferFromFile:kIntroTrackFileName];
        
        self.mainTrack = [OALAudioTrack track];
        [self.mainTrack preloadFile:kLoopTrackFileName];
        self.mainTrack.numberOfLoops = -1;
        
        // BUffer SFX
        self.sourceSFX = [OALSimpleAudio sharedInstance];
        
        self.nuclearExplosionSFX = [[OpenALManager sharedInstance] bufferFromFile:@"nuclear.caf"];
        self.clickSFX = [[OpenALManager sharedInstance] bufferFromFile:@"click.caf"];
        
        [self onOpenALHybrid];
    }

}

- (void)onOpenALHybrid
{
   
    [self.source play:self.introBuffer];
    
    // Have the main track start again after the intro buffer's duration elapses.
    NSTimeInterval playAt = self.mainTrack.deviceCurrentTime + self.introBuffer.duration;
    [self.mainTrack playAtTime:playAt];
    self.mainTrack.volume = 1;
    
}

- (void)stopBackgroundMusic
{
    [self.source stop];
    [self.mainTrack stop];
    self.mainTrack.currentTime = 0;
    self.source.muted = _gameMute;
}

-(void) appWillResignActive:(NSNotification*)note{
    [self.source setPaused:YES];
    [self.mainTrack setPaused:YES];
}

-(void) appWillEnterForeground:(NSNotification*)note{
    [self.source setPaused:NO];
    [self.mainTrack setPaused:NO];
}


@end
