//
//  GameScene.m
//  Fire Command
//
//  Created by Hicham Chourak on 19/08/14.
//  Copyright (c) 2014 Hicham Chourak. All rights reserved.
//

#import "GameScene.h"
#import "ViewController.h"
#import "GAIDictionaryBuilder.h"
#import <ObjectAL/ObjectAL.h>
#import "GameCenterManager.h"

#define MainTrackFileName @"game-music.caf"
#define GameOverTrackFileName @"game-over-music.caf"

#define ARC4RANDOM_MAX 0x100000000


// Constants
static float rocketReloadTime = 0.4; //reload time next rocket
static float kExplosionRadius = 0.8;  //scale of explosion radius
static float kExplosionTime = 0.4; //duration time of explosion

//Varaible
static float kLevelMultiplier = 3.0; //time multiplier of next asteroid
static float kminAsteroidTime = 3.0; //min asteroid travel time
static float kmaxAsteroidTime = 6.0; //max asteroid travel time


typedef enum : NSUInteger {
    ExplosionCategory = (1 << 0),
    AsteroidCategory = (1 << 1),
    BuildingCategory = (1 << 2)
} NodeCategory;

@interface GameScene ()

@property (strong, nonatomic) SKSpriteNode *rocket;
@property (strong, nonatomic) SKNode *scoreBar;
@property (strong, nonatomic) SKNode *buildingNode;
@property (strong, nonatomic) SKSpriteNode *buildingFire;
@property (strong, nonatomic) SKSpriteNode *pauseButton;

@property(nonatomic, readwrite, retain) OALSimpleAudio* source;

@property(nonatomic, readwrite, retain) ALBuffer* nuclearSFX;

@property(nonatomic, readwrite, retain) OALAudioTrack* mainTrack;
@property(nonatomic, readwrite, retain) OALAudioTrack* gameOverTrack;

@property(nonatomic, readwrite, retain) ALBuffer* asteroidExplosionSFX;
@property(nonatomic, readwrite, retain) ALBuffer* rocketExplosionSFX;
@property(nonatomic, readwrite, retain) ALBuffer* fireRocketSFX;
@property(nonatomic, readwrite, retain) ALBuffer* clickSFX;

@end

@implementation GameScene {
    
    SKLabelNode *labelflowerBullets1;
    SKLabelNode *labelflowerBullets2;
    SKLabelNode *labelflowerBullets3;
    SKLabelNode *labelMisslesExploded;
    SKLabelNode *labelScore;
    
    UIImage *_imageToShare;
    
    int position;
    int _buildingDestroyed;
    int missileExploded;
    int score;
    int explosionZPosition;
    int buildingSet;
    
    int flowerBullets1;
    int flowerBullets2;
    int flowerBullets3;
    
    double nextAsteroidTime;
    float levelMultiplier;
    float minAsteroidTime;
    float maxAsteroidTime;
    
    float deviceScale;
    float _scale;
    
    CFTimeInterval currentTimeStamp;
    CFTimeInterval lastRocketTimeStamp;
    
    NSArray *_numbers;
    
    SKNode *_pauseScreen;
    SKNode *_gameOverScreen;
    
    SKSpriteNode *_asteroid;
    SKSpriteNode *_building;
    SKSpriteNode *_nuclearExplosion;
    SKSpriteNode *_explosion;
    SKSpriteNode *_flashBackground;
    SKSpriteNode *_pauseBackground;
    SKSpriteNode *_n0;
    SKSpriteNode *_n1;
    SKSpriteNode *_n2;
    SKSpriteNode *_n3;
    SKSpriteNode *_n4;
    SKSpriteNode *_n5;
    SKSpriteNode *_n6;
    SKSpriteNode *_muteButton;
    
    BOOL _gamePaused;
    BOOL _gameMute;
    BOOL _gameOver;
    BOOL _transition;
    
    NSUserDefaults *_defaults;
    
    ALDevice* device;
    ALContext* context;
    
    NSArray *_textureFrames;
    NSArray *_textureRocketExplosionFrames;
    NSArray *_textureNuclearExplosionFrames;
    NSArray *_rocketTextureFrames;
    
    int _value;
}

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        
        // GA
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker set:kGAIScreenName value:@"GameScene"];
        [tracker send:[[GAIDictionaryBuilder createAppView] build]];
        
        // Play Music
        [self initAudio];
        _defaults = [NSUserDefaults standardUserDefaults];
        _gameMute = [_defaults boolForKey:@"gameMute"];
        
        [self playMainMusic:_gameMute];
        
        _gameOver = NO;
        
        self.backgroundColor = [SKColor blackColor];
        self.scoreBar = [[SKSpriteNode alloc] init];
        
        // init first values
        _buildingDestroyed = 0;
        position = size.width/3;
        score = 0;
        explosionZPosition = 0;
        nextAsteroidTime = 0;
        lastRocketTimeStamp = 0;
        [self setDeviceScale];
        _gamePaused = NO;
        buildingSet = 0;
        
        // Game Mechanics
        levelMultiplier = kLevelMultiplier; //avg time for next asteroid in sec,
        minAsteroidTime = kminAsteroidTime;
        maxAsteroidTime = kmaxAsteroidTime;
        
        // load elements
        [self backgroundElement];
        [self generateNumbersArray];
        [self initBuildingFire];
        [self initrocketExplosion];
        [self initGroundExplosion];
        [self initRocketFire];
        
        // add Screen Elements
        [self addHud];
        [self updateScore:0];
        [self addLaunchPad];
        
        [self addBuildings:1];
        [self addBuildings:2];
        
        [self addBottomEdge];
        
        
        // setup physics
        self.physicsWorld.gravity = CGVectorMake(0, 0);
        self.physicsWorld.contactDelegate = self;
        
        [self addRocketFire];
    }
    
    return self;
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
    if (currentTime > nextAsteroidTime || nextAsteroidTime - currentTime > 5) {
        nextAsteroidTime = ([self getRandomDouble] * levelMultiplier) + currentTime;
        
        [self addAstroid];
    }
    
    currentTimeStamp = currentTime;
}

#pragma mark - UI Elements

- (void)addHud
{
    self.scoreBar = [SKNode node];
    
    SKTexture *scoreTileText = _numbers[0];
    scoreTileText.filteringMode = SKTextureFilteringNearest;
    
    _n0 = [SKSpriteNode spriteNodeWithTexture:scoreTileText];
    _n0.zPosition = 3;
    _n0.position = CGPointMake( (22*0*_scale), self.size.height - scoreTileText.size.height/2 + 7*_scale);
    [self.scoreBar addChild:_n0];
    
    _n1 = [SKSpriteNode spriteNodeWithTexture:scoreTileText];
    _n1.zPosition = 3;
    _n1.position = CGPointMake((22*1*_scale), self.size.height - scoreTileText.size.height/2 + 7*_scale);
    [self.scoreBar addChild:_n1];
    
    _n2 = [SKSpriteNode spriteNodeWithTexture:scoreTileText];
    _n2.zPosition = 3;
    _n2.position = CGPointMake( (22*2*_scale), self.size.height - scoreTileText.size.height/2 + 7*_scale);
    [self.scoreBar addChild:_n2];
    
    _n3 = [SKSpriteNode spriteNodeWithTexture:scoreTileText];
    _n3.zPosition = 3;
    _n3.position = CGPointMake( (22*3*_scale), self.size.height - scoreTileText.size.height/2 + 7*_scale);
    [self.scoreBar addChild:_n3];
    
    _n4 = [SKSpriteNode spriteNodeWithTexture:scoreTileText];
    _n4.zPosition = 3;
    _n4.position = CGPointMake((22*4*_scale), self.size.height - scoreTileText.size.height/2 + 7*_scale);
    [self.scoreBar addChild:_n4];
    
    _n5 = [SKSpriteNode spriteNodeWithTexture:scoreTileText];
    _n5.zPosition = 3;
    _n5.position = CGPointMake( (22*5*_scale), self.size.height - scoreTileText.size.height/2+ 7*_scale);
    [self.scoreBar addChild:_n5];
    
    _n6 = [SKSpriteNode spriteNodeWithTexture:scoreTileText];
    _n6.zPosition = 3;
    _n6.position = CGPointMake( (22*6*_scale), self.size.height - scoreTileText.size.height/2+ 7*_scale);
    [self.scoreBar addChild:_n6];
    
    // Add Pause Button
    
    self.pauseButton = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:CGSizeMake(29*_scale, 29*_scale)];
    
    SKTexture *pauseButtonText = [SKTexture textureWithImageNamed:@"pausebutton.png"];
    pauseButtonText.filteringMode = SKTextureFilteringNearest;
    
    SKSpriteNode *pauseButtonTexture = [SKSpriteNode spriteNodeWithTexture:pauseButtonText];
    pauseButtonTexture.zPosition = 100;;
    pauseButtonTexture.name = @"pauseButton";
    [self.pauseButton addChild:pauseButtonTexture];
    
    self.pauseButton.position = CGPointMake((22*7*_scale)+15*_scale, self.size.height - self.pauseButton.size.height/2);
    self.pauseButton.zPosition = 100;
    [self.scoreBar addChild:self.pauseButton];
    
    // center scorebar
    
    self.scoreBar.zPosition = 100;
    self.scoreBar.position = CGPointMake(self.size.width/2 - ((22*7*_scale)+15*_scale)/2, 0);
    
    [self addChild:self.scoreBar];
}

- (void)updateScore:(int)addScore
{
    score = score + addScore;
    [self updateScoreHud:score];
    [self levelUpdate];
}

- (void)updateScoreHud:(int)value
{
    _value = value;
    
    for (int i = 0; i <= 6; i++) {
        
        int number = _value / pow(10,(6-i));
        _value = _value - (number*pow(10,(6-i)));
        
        SKTexture *scoreTileText = _numbers[number];
        scoreTileText.filteringMode = SKTextureFilteringNearest;
        
        SKAction *replace = [SKAction setTexture:scoreTileText];
        
        if (i == 0) {
            [_n0 runAction:replace];
        } else if (i == 1) {
            [_n1 runAction:replace];
        } else if (i == 2) {
            [_n2 runAction:replace];
        } else if (i == 3) {
            [_n3 runAction:replace];
        } else if (i == 4) {
            [_n4 runAction:replace];
        } else if (i == 5) {
            [_n5 runAction:replace];
        } else {
            [_n6 runAction:replace];
        }
    }
}

- (void)showPauseScreen:(BOOL)show
{
    _transition = YES;
    
    if (show) {
        _gamePaused = YES;
        _pauseScreen = [[SKNode alloc] init];
        _pauseScreen.zPosition = 100;
        _pauseScreen.name = @"pauseScreen";
        _pauseScreen.position = CGPointMake(self.size.width/2, self.size.height*1.5);
        
        SKSpriteNode *title = [SKSpriteNode spriteNodeWithImageNamed:@"pausedtitle.png"];
        title.position = CGPointMake(0, title.size.height*2);
        [_pauseScreen addChild:title];
        
        SKSpriteNode *resumeButton = [SKSpriteNode spriteNodeWithImageNamed:@"playbutton.png"];
        resumeButton.position = CGPointMake(self.size.width/4, -resumeButton.size.height);
        resumeButton.name = @"resumeButton";
        [_pauseScreen addChild:resumeButton];
        
        SKTexture *soundTexture;
        
        if (_gameMute) {
            soundTexture = [SKTexture textureWithImageNamed:@"mutebutton.png"];
        } else {
            soundTexture = [SKTexture textureWithImageNamed:@"soundbutton.png"];
        }
        
        _muteButton = [SKSpriteNode spriteNodeWithTexture:soundTexture];
        _muteButton.position = CGPointMake(-self.size.width/4, -_muteButton.size.height);
        _muteButton.name = @"muteButton";
        [_pauseScreen addChild:_muteButton];
        
        [_pauseBackground runAction:[SKAction fadeAlphaTo:0.75 duration:0.2]];
        
        [_pauseScreen runAction:[SKAction moveToY:self.size.height/2 duration:0.2] completion:^{
            _transition = NO;
            self.view.paused = YES;
        }];
        
        [self addChild:_pauseScreen];
        
    } else {
        _gamePaused = NO;
        self.view.paused = NO;
        SKAction *move = [SKAction moveToY:self.size.height*1.5 duration:0.5];
        SKAction *remove = [SKAction removeFromParent];
        
        [_pauseBackground runAction:[SKAction fadeAlphaTo:0.0 duration:0.2]];
        
        [_pauseScreen runAction:[SKAction sequence:@[move,remove]] completion:^{
            _transition = NO;
        }];
    }
}

- (void)gameOverScreen
{
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"GameOverScene"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    
    [self stopBackgroundMusic];
    [self playGameOverMusic:_gameMute];
    int bestScore = [self saveScore];
    
    // Hide scorebar
    [self.scoreBar runAction:[SKAction fadeAlphaTo:0.0 duration:0.2]];
    
    
    // mute SFX
    _gameOverScreen = [[SKNode alloc] init];
    _gameOverScreen.zPosition = 100;
    _gameOverScreen.name = @"gameOverScreen";
    _gameOverScreen.position = CGPointMake(self.size.width/2, self.size.height*1.5);
    
    SKSpriteNode *title = [SKSpriteNode spriteNodeWithImageNamed:@"gameovertitle.png"];
    title.position = CGPointMake(0, self.size.height/2 - self.size.height/6);
    [_gameOverScreen addChild:title];
    
    // Buttons
    
    SKSpriteNode *resumeButton = [SKSpriteNode spriteNodeWithImageNamed:@"playbutton.png"];
    resumeButton.position = CGPointMake(0, -self.size.height/2 + 2*self.size.height/7);
    resumeButton.name = @"replayButton";
    [_gameOverScreen addChild:resumeButton];
    
    _muteButton = [SKSpriteNode spriteNodeWithImageNamed:@"soundbutton.png"];
    _muteButton.position = CGPointMake(self.size.width/4, -self.size.height/2 + 2*self.size.height/7);
    _muteButton.name = @"gameOverMuteButton";
    [_gameOverScreen addChild:_muteButton];
    
    SKSpriteNode *gameCenterButton = [SKSpriteNode spriteNodeWithImageNamed:@"gamecenterbutton.png"];
    gameCenterButton.name = @"gamecenterbutton";
    gameCenterButton.position = CGPointMake(-self.size.width/4, -self.size.height/2 + 2* self.size.height/7);
    [_gameOverScreen addChild:gameCenterButton];
    
    SKSpriteNode *rateButton = [SKSpriteNode spriteNodeWithImageNamed:@"rate.png"];
    rateButton.name = @"ratebutton";
    rateButton.position = CGPointMake(-self.size.width/4, -self.size.height/2 + self.size.height/7);
    [_gameOverScreen addChild:rateButton];
    
    SKSpriteNode *facebookButton = [SKSpriteNode spriteNodeWithImageNamed:@"facebook.png"];
    facebookButton.position = CGPointMake(0, -self.size.height/2 + self.size.height/7);
    facebookButton.name = @"facebookButton";
    [_gameOverScreen addChild:facebookButton];
    
    SKSpriteNode *twitterButton = [SKSpriteNode spriteNodeWithImageNamed:@"twitter.png"];
    twitterButton.position = CGPointMake(self.size.width/4, -self.size.height/2 + self.size.height/7);
    twitterButton.name = @"twitterButton";
    [_gameOverScreen addChild:twitterButton];
    
    // best score label
    
    SKSpriteNode *bestScoreTextLabel = [SKSpriteNode spriteNodeWithImageNamed:@"bestscore.png"];
    bestScoreTextLabel.position = CGPointMake(0, 0);
    [_gameOverScreen addChild:bestScoreTextLabel];
    
    SKSpriteNode *bestScoreLabel = [self showScore:bestScore];
    int bestScoreLength = (int)[NSString stringWithFormat:@"%d", bestScore].length;
    bestScoreLabel.position = CGPointMake(-11*(bestScoreLength-1)*_scale, -bestScoreTextLabel.size.height/2 - 22*_scale);
    [_gameOverScreen addChild:bestScoreLabel];
    
    // score label
    
    SKSpriteNode *scoreTextLabel = [SKSpriteNode spriteNodeWithImageNamed:@"scorelabel.png"];
    scoreTextLabel.position = CGPointMake(0, bestScoreTextLabel.size.height/2 + 22*_scale + scoreTextLabel.size.height);
    [_gameOverScreen addChild:scoreTextLabel];
    
    SKSpriteNode *scoreLabel = [self showScore:score];
    int scoreLenght = (int)[NSString stringWithFormat:@"%d", score].length;
    scoreLabel.position = CGPointMake(-11*(scoreLenght-1)*_scale, bestScoreTextLabel.size.height/2 + 22*_scale);
    [_gameOverScreen addChild:scoreLabel];
    
    
    [_gameOverScreen runAction:[SKAction moveToY:self.size.height/2 duration:0.2]];
    
    [self addChild:_gameOverScreen];
    
    [_pauseBackground runAction:[SKAction fadeAlphaTo:0.75 duration:0.2] completion:^{
        [self createScreenShot];
        _transition = NO;
    }];
}


#pragma mark - Touch Methods

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        SKNode *node = [self nodeAtPoint:location];
        
        
        if (!_transition) {
            
            if (location.y < 60) return;
            
            if ([node.name isEqualToString:@"pauseButton"] && !_gameOver) {
                [self pauseGame];
            } else if ([node.name isEqualToString:@"resumeButton"] && !_gameOver) {
                [self pauseGame];
            } else if (_gameOver){
                if ([node.name isEqualToString:@"replayButton"]) {
                    [self replayGame];
                    [self.source playBuffer:self.clickSFX volume:1.0 pitch:1.0 pan:0 loop:NO];
                } else if ([node.name isEqualToString:@"gamecenterbutton"]) {
                    [self showLeaderBoard];
                    [self.source playBuffer:self.clickSFX volume:1.0 pitch:1.0 pan:0 loop:NO];
                } else if ([node.name isEqualToString:@"gameOverMuteButton"]) {
                    if (!_gameMute) {
                        [self muteSound:YES forScreen:2];
                    } else {
                        [self muteSound:NO forScreen:2];
                    }
                    
                    [self.source playBuffer:self.clickSFX volume:1.0 pitch:1.0 pan:0 loop:NO];
                } else if ([node.name isEqualToString:@"ratebutton"]) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"itms-apps://itunes.apple.com/app/id911839238"]];
                    [self.source playBuffer:self.clickSFX volume:1.0 pitch:1.0 pan:0 loop:NO];
                } else if ([node.name isEqualToString:@"facebookButton"] || [node.name isEqualToString:@"twitterButton"]) {
                    [self shareScore];
                    [self.source playBuffer:self.clickSFX volume:1.0 pitch:1.0 pan:0 loop:NO];
                    
                }
                
            } else if ([node.name isEqualToString:@"muteButton"]) {
                if (!_gameMute) {
                    [self muteSound:YES forScreen:1];
                } else {
                    [self muteSound:NO forScreen:1];
                }
            } else if (fabsf(currentTimeStamp - lastRocketTimeStamp) > rocketReloadTime && !_gameOver && !_gamePaused) {
                [self fireRocket:location];
                lastRocketTimeStamp = currentTimeStamp;
            }
        }
    }
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    if ((contact.bodyA.categoryBitMask & ExplosionCategory) != 0 || (contact.bodyB.categoryBitMask & ExplosionCategory) != 0) {
        // Collision Between Explosion and Asteroid
        SKNode *asteroid = (contact.bodyA.categoryBitMask & ExplosionCategory) ? contact.bodyB.node : contact.bodyA.node;
        [asteroid runAction:[SKAction removeFromParent]];
        
        [self addAsteroidParticles:asteroid.name onLocation:asteroid.position];
        
        // update score
        [self updateScore:10];
        [labelScore setText:[NSString stringWithFormat:@"%d", score]];
        
    } else {
        // Collision Between Asteroid & Building/Ground
        SKNode *building = (contact.bodyA.categoryBitMask & BuildingCategory) ? contact.bodyA.node : contact.bodyB.node;
        SKNode *asteroid = (contact.bodyA.categoryBitMask & BuildingCategory) ? contact.bodyB.node : contact.bodyA.node;
        
        NSString *groundName = @"ground";
        
        if (building.name != groundName) {
            //NSLog(@"%@", building.name);
            //[building runAction:[SKAction removeFromParent]];
            //[building removeFromParent];
            //building = nil;
            //[super removeFromParent];
            
            //for (SKNode *building in self.buildingNode) {
                [building removeFromParent];
            //}
            [self removeFromParent];
        }
        
        if (asteroid.name != groundName) {
            [asteroid runAction:[SKAction removeFromParent]];
        }
        
        NSString *launchPadName = @"launchPad";
        NSString *asteroidName = @"asteroid";
        NSString *buildingName = @"building";
        
        if (asteroid.name == buildingName) {
            [self addBurningBuilding:asteroid.position];
            _buildingDestroyed++;
        } else if (building.name == buildingName) {
            [self addBurningBuilding:building.position];
            _buildingDestroyed++;
        }
        
        if ([building.name rangeOfString:asteroidName].location != NSNotFound) {
            [self addGroundExplosion:building.position];
        } else {
            [self addGroundExplosion:asteroid.position];
        }
        
        if (building.name == launchPadName || asteroid.name == launchPadName) {
            [self.rocket removeFromParent];
        }
        
        if((_buildingDestroyed >= 8 || asteroid.name == launchPadName || building.name == launchPadName) && !_gameOver){
            [self gameOverScreen];
            _gameOver = YES;
            _transition = YES;
        }

        
    }
}

#pragma mark - Game Elements

- (void)backgroundElement
{
    SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"background"];
    background.zPosition = -100;
    background.position = CGPointMake(self.size.width/2, self.size.height/2);
    [self addChild:background];
    
    _flashBackground = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:self.size];
    _flashBackground.position = CGPointMake(self.size.width/2, self.size.height/2);
    _flashBackground.zPosition = 10;
    
    [self addChild:_flashBackground];
    
    _pauseBackground = [SKSpriteNode spriteNodeWithColor:[SKColor blackColor] size:self.size];
    _pauseBackground.position = CGPointMake(self.size.width/2, self.size.height/2);
    _pauseBackground.alpha = 0.0;
    _pauseBackground.zPosition = 90;
    
    [self addChild:_pauseBackground];
}

- (void)addLaunchPad
{
    SKSpriteNode *launchPad = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:CGSizeMake(38*_scale, 2)];
    
    SKSpriteNode *launchPadTexture = [SKSpriteNode spriteNodeWithImageNamed:@"launchpad.png"];
    launchPadTexture.zPosition = 3;
    launchPadTexture.position = CGPointMake(0, launchPadTexture.size.height/2);
    [launchPad addChild:launchPadTexture];
    
    launchPad.zPosition = 10;
    launchPad.name = @"launchPad";
    
    launchPad.position = CGPointMake(self.size.width/2, launchPad.size.height/2-1);
    
    // Add Physics
    launchPad.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:launchPad.size];
    launchPad.physicsBody.dynamic = YES;
    launchPad.physicsBody.categoryBitMask = BuildingCategory;
    launchPad.physicsBody.contactTestBitMask = AsteroidCategory;
    launchPad.physicsBody.collisionBitMask = 1;
    
    [self addChild:launchPad];
    [self addRocket];
}

- (void)addRocket
{
    self.rocket = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:CGSizeMake(20*_scale, 29*_scale)];
    
    SKSpriteNode *rocketTexture = [SKSpriteNode spriteNodeWithImageNamed:@"rocket.png"];
    rocketTexture.zPosition = 2;
    [self.rocket addChild:rocketTexture];
    
    self.rocket.zPosition = 1;
    self.rocket.position = CGPointMake(self.size.width/2,-rocketTexture.size.height/2);
    
    SKAction *move =[SKAction moveTo:CGPointMake(self.size.width/2,self.rocket.size.height/2 + 18*_scale) duration:rocketReloadTime];
    
    [self.rocket runAction:move];
    [self addChild:self.rocket];
}

- (void)fireRocket:(CGPoint)location
{
    float angle = atanf((location.y-18*_scale)/(location.x - self.size.width/2));
    
    if (angle < 0) {
        angle = angle + M_PI/2;
    } else {
        angle = angle - M_PI/2;
    }
    
    self.rocket.zRotation = angle;
    
    float duration = (location.y *0.001)/_scale;
    SKAction *move =[SKAction moveTo:CGPointMake(location.x,location.y) duration:duration];
    SKAction *remove = [SKAction removeFromParent];
    
    // Explosion
    SKAction *callExplosion = [SKAction runBlock:^{
        _explosion = [SKSpriteNode spriteNodeWithImageNamed:@"explosion"];
        _explosion.zPosition = 0;
        _explosion.scale = 0.2;
        _explosion.position = CGPointMake(location.x,location.y);
        _explosion.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:_explosion.size.height/2];
        _explosion.physicsBody.dynamic = YES;
        _explosion.physicsBody.categoryBitMask = ExplosionCategory;
        _explosion.physicsBody.contactTestBitMask = AsteroidCategory;
        _explosion.physicsBody.collisionBitMask = 0;
        SKAction *explosionAction = [SKAction scaleTo:kExplosionRadius duration:kExplosionTime];
        [_explosion runAction:[SKAction sequence:@[explosionAction,remove]]];
        [self addChild:_explosion];
        [self addChild:[self addRocketExplosion:location]];
        [self addRocketParticles:location];
        if (!_gameOver) {
            [self.source playBuffer:self.rocketExplosionSFX volume:1.0 pitch:1.0 pan:0 loop:NO];
        }
    }];
    
    [self.rocket addChild:[self addRocketFire]];
    
    
    [self.rocket runAction:[SKAction sequence:@[move,callExplosion,remove]]];
    [self addRocket];
    if (!_gameOver) {
        [self.source playBuffer:self.fireRocketSFX volume:1.0 pitch:1.0 pan:0 loop:NO];
    }
}

- (void)initRocketFire
{
    NSMutableArray *frames = [NSMutableArray array];
    
    for (int i=22; i <= 55; i++) {
        NSString *textureName = [NSString stringWithFormat:@"rocket_fire_%d", i];
        SKTexture *texture = [SKTexture textureWithImageNamed:textureName];
        [frames addObject:texture];
    }
    
    _rocketTextureFrames = frames;
    [SKTexture preloadTextures:_rocketTextureFrames withCompletionHandler:^{}];
    
}

- (SKSpriteNode *)addRocketFire
{
    SKTexture *textureSize = _rocketTextureFrames[0];
    
    SKSpriteNode *rocketFire = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:textureSize.size];
    rocketFire.position = CGPointMake(0, -30*_scale);
    rocketFire.zRotation = M_PI;
    rocketFire.zPosition = -10;
    
    [rocketFire runAction:[SKAction repeatActionForever:[SKAction animateWithTextures:_rocketTextureFrames timePerFrame:0.02f resize:NO restore:YES]]];
    
    return rocketFire;
}


- (void)addBuildings:(int)spaceOrder
{
    self.buildingNode = [[SKNode alloc] init];
    
    for (int i = 1; i <= 4; i++) {
        
        float buildingWidth = (self.size.width-38*_scale)/4;
        
        _building = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:CGSizeMake(buildingWidth, 2)];
        
        NSString *textureName = [NSString stringWithFormat:@"buildings_%i.png", i];
        SKTexture *buildingText = [SKTexture textureWithImageNamed:textureName];
        buildingText.filteringMode = SKTextureFilteringNearest;
        
        SKSpriteNode *buildingTexture = [SKSpriteNode spriteNodeWithTexture:buildingText];
        
        if (i == 1) {
            buildingTexture.position = CGPointMake(0, buildingTexture.size.height/2);
            buildingTexture.zPosition = 2;
            _building.position = CGPointMake(buildingTexture.size.width/2 - 11*_scale, 0);
        } else if (i == 2) {
            
            buildingTexture.position = CGPointMake(0, buildingTexture.size.height/2);
            buildingTexture.zPosition = 3;
            
            _building.position = CGPointMake((self.size.width/2) - buildingTexture.size.width/2 - 16*_scale, 0);
        } else if (i == 3) {
            buildingTexture.position = CGPointMake(0, buildingTexture.size.height/2);
            buildingTexture.zPosition = 3;
            _building.position = CGPointMake((self.size.width/2) + buildingTexture.size.width/2 + 16*_scale, 0);
        } else if (i == 4) {
            buildingTexture.position = CGPointMake(0, buildingTexture.size.height/2);
            buildingTexture.zPosition = 2;
            _building.position = CGPointMake(self.size.width - buildingTexture.size.width/2 + 11*_scale, 0);
        }
        
        _building.name = @"building";
        
        [_building addChild:buildingTexture];
        _building.zPosition = 1;
        
        // Add Physics
        _building.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_building.size];
        _building.physicsBody.dynamic = YES;
        _building.physicsBody.categoryBitMask = BuildingCategory;
        _building.physicsBody.contactTestBitMask = AsteroidCategory;
        _building.physicsBody.collisionBitMask = 0;
        
        [self.buildingNode addChild:_building];
    }
    
    [self addChild:self.buildingNode];
}

- (void)addBurningBuilding:(CGPoint)location
{
    SKSpriteNode *burnedBuilding = [SKSpriteNode spriteNodeWithImageNamed:@"burned_buildings_1"];
    burnedBuilding.position = CGPointMake(location.x, location.y + burnedBuilding.size.height/2);
    burnedBuilding.zPosition = 2;
    [burnedBuilding addChild:[self addBuildingFire]];
    [self addChild:burnedBuilding];
}

- (void)initBuildingFire
{
    NSMutableArray *frames = [NSMutableArray array];
    
    for (int i=0; i <= 247; i++) {
        NSString *textureName = [NSString stringWithFormat:@"buidling_fire_%d", i];
        SKTexture *texture = [SKTexture textureWithImageNamed:textureName];
        [frames addObject:texture];
    }
    
    _textureFrames = frames;
    [SKTexture preloadTextures:_textureFrames withCompletionHandler:^{}];
    
}

- (SKSpriteNode *)addBuildingFire
{
    SKSpriteNode *buildingFire = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:CGSizeMake(111*_scale, 60*_scale)];
    
    buildingFire.zPosition = -10;
    
    [buildingFire runAction:[SKAction repeatActionForever:[SKAction animateWithTextures:_textureFrames timePerFrame:0.04f resize:NO restore:YES]]];
    
    return buildingFire;
}

- (void)initrocketExplosion
{
    NSMutableArray *frames = [NSMutableArray array];
    
    for (int i=0; i <= 24; i++) {
        NSString *textureName = [NSString stringWithFormat:@"rocket_explosion_%d", i];
        SKTexture *texture = [SKTexture textureWithImageNamed:textureName];
        [frames addObject:texture];
    }
    
    _textureRocketExplosionFrames = frames;
    [SKTexture preloadTextures:_textureRocketExplosionFrames withCompletionHandler:^{}];
    
}

- (SKSpriteNode *)addRocketExplosion:(CGPoint)location
{
    SKTexture *textureSize = _textureRocketExplosionFrames[0];
    
    SKSpriteNode *rocketExplosion = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:textureSize.size];
    
    rocketExplosion.zPosition = 10;
    rocketExplosion.position = location;
    
    [rocketExplosion runAction:[SKAction animateWithTextures:_textureRocketExplosionFrames timePerFrame:0.05f resize:NO restore:YES]];
    
    return rocketExplosion;
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
    
    _asteroid.zPosition = 10;
    
    int startPoint = [self getRandomNumberBetween:0 to:self.size.width];
    _asteroid.position = CGPointMake(startPoint, self.size.height+_asteroid.size.width);
    
    _asteroid.physicsBody.dynamic = NO;
    _asteroid.physicsBody.categoryBitMask = AsteroidCategory;
    _asteroid.physicsBody.contactTestBitMask = ExplosionCategory | BuildingCategory;
    _asteroid.physicsBody.collisionBitMask = 1;
    
    int endPoint = [self getRandomNumberBetween:0 to:self.size.width];
    
    SKAction *move =[SKAction moveTo:CGPointMake(endPoint, 0) duration:[self getRandomNumberBetween:minAsteroidTime to:maxAsteroidTime]];
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
    
    CGFloat offsetX = sprite.frame.size.width * sprite.anchorPoint.x;
    CGFloat offsetY = sprite.frame.size.height * sprite.anchorPoint.y;
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, 18*_scale - offsetX, 46*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 35*_scale - offsetX, 46*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 48*_scale - offsetX, 28*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 39*_scale - offsetX, 10*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 29*_scale - offsetX, 7*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 15*_scale - offsetX, 10*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 9*_scale - offsetX, 19*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 12*_scale - offsetX, 34*_scale - offsetY);
    
    CGPathCloseSubpath(path);
    
    sprite.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:path];
    
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
    
    CGFloat offsetX = sprite.frame.size.width * sprite.anchorPoint.x;
    CGFloat offsetY = sprite.frame.size.height * sprite.anchorPoint.y;
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, 24*_scale - offsetX, 35*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 32*_scale - offsetX, 35*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 38*_scale - offsetX, 33*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 44*_scale - offsetX, 24*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 38*_scale - offsetX, 15*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 23*_scale - offsetX, 15*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 12*_scale - offsetX, 18*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 9*_scale - offsetX, 24*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 13*_scale - offsetX, 29*_scale - offsetY);
    
    CGPathCloseSubpath(path);
    
    sprite.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:path];
    
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
    
    CGFloat offsetX = sprite.frame.size.width * sprite.anchorPoint.x;
    CGFloat offsetY = sprite.frame.size.height * sprite.anchorPoint.y;
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, 28*_scale - offsetX, 36*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 37*_scale - offsetX, 30*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 37*_scale - offsetX, 22*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 26*_scale - offsetX, 13*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 14*_scale - offsetX, 19*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 14*_scale - offsetX, 30*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 20*_scale - offsetX, 36*_scale - offsetY);
    
    CGPathCloseSubpath(path);
    
    sprite.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:path];
    
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
    
    CGFloat offsetX = sprite.frame.size.width * sprite.anchorPoint.x;
    CGFloat offsetY = sprite.frame.size.height * sprite.anchorPoint.y;
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, 13*_scale - offsetX, 21*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 20*_scale - offsetX, 18*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 23*_scale - offsetX, 14*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 16*_scale - offsetX, 7*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 9*_scale - offsetX, 14*_scale - offsetY);
    CGPathAddLineToPoint(path, NULL, 9*_scale - offsetX, 18*_scale - offsetY);
    
    CGPathCloseSubpath(path);
    
    sprite.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:path];
    
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
    _nuclearExplosion = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:CGSizeMake(110*_scale, 80*_scale)];
    _nuclearExplosion.position = CGPointMake(location.x, _nuclearExplosion.size.height/2);
    _nuclearExplosion.zPosition = 10;
    
    if (!_gameOver) {
        [self.source playBuffer:self.nuclearSFX volume:1.0 pitch:1.0 pan:0 loop:NO];
    }
    [_nuclearExplosion runAction:[SKAction animateWithTextures:_textureNuclearExplosionFrames
                                                  timePerFrame:0.1f
                                                        resize:NO
                                                       restore:YES]];
    
    [self addChild:_nuclearExplosion];
    [self flashBackground];
}

- (void)flashBackground
{
    [self removeActionForKey:@"flash"];
    [self runAction:[SKAction sequence:@[[SKAction repeatAction:[SKAction sequence:@[[SKAction runBlock:^{
        _flashBackground.color = [SKColor colorWithRed:1.0 green:1.0 blue:220.0/255.0 alpha:1.0];
    }], [SKAction waitForDuration:0.05], [SKAction runBlock:^{
        _flashBackground.color = [SKColor clearColor];
    }], [SKAction waitForDuration:0.05]]] count:1]]] withKey:@"flash"];
}

- (void)addBottomEdge
{
    SKSpriteNode *bottemEdge = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:CGSizeMake(self.size.width, 2)];
    bottemEdge.name = @"ground";
    bottemEdge.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:bottemEdge.size];
    bottemEdge.position = CGPointMake(self.size.width/2, 0);
    bottemEdge.physicsBody.dynamic = YES;
    bottemEdge.physicsBody.categoryBitMask = BuildingCategory;
    bottemEdge.physicsBody.contactTestBitMask = AsteroidCategory;
    bottemEdge.physicsBody.collisionBitMask = 1;
    [self addChild:bottemEdge];
}

- (SKSpriteNode *)showScore:(int)value
{
    SKSpriteNode *scoreNode = [SKSpriteNode node];
    
    int scoreLenght = (int)[NSString stringWithFormat:@"%i", value].length;
    
    for (int i = 0; i < scoreLenght; i++) {
        
        int number = value / pow(10,((scoreLenght - 1)-i));
        value = value - (number*pow(10,((scoreLenght - 1)-i)));
        
        SKTexture *scoreTileText = _numbers[number];
        scoreTileText.filteringMode = SKTextureFilteringNearest;
        
        SKSpriteNode *scoreTile = [SKSpriteNode spriteNodeWithTexture:scoreTileText];
        scoreTile.position = CGPointMake(22*i*_scale, 0);
        
        [scoreNode addChild:scoreTile];
    }
    
    return scoreNode;
}

#pragma mark - Particles

- (void)addAsteroidParticles:(NSString *)name onLocation:(CGPoint)location
{
    if ([name isEqualToString:@"asteroid_1a"]) {
        [self addParticleExplosion:location withColor:[UIColor colorWithRed:186.0/255.0 green:0.0/255.0 blue:255.0/255.0 alpha:1.0] andNumberOfParticles:100];
    }
    
    if ([name isEqualToString:@"asteroid_1b"]) {
        [self addParticleExplosion:location withColor:[UIColor colorWithRed:162.0/255.0 green:255.0/255.0 blue:0.0/255.0 alpha:1.0] andNumberOfParticles:100];
    }
    
    if ([name isEqualToString:@"asteroid_1c"]) {
        [self addParticleExplosion:location withColor:[UIColor colorWithRed:255.0/255.0 green:0.0/255.0 blue:138.0/255.0 alpha:1.0] andNumberOfParticles:100];
    }
    
    if ([name isEqualToString:@"asteroid_2a"]) {
        [self addParticleExplosion:location withColor:[UIColor colorWithRed:255.0/255.0 green:216.0/255.0 blue:0.0/255.0 alpha:1.0] andNumberOfParticles:100];
    }
    
    if ([name isEqualToString:@"asteroid_2b"]) {
        [self addParticleExplosion:location withColor:[UIColor colorWithRed:255.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0] andNumberOfParticles:100];
    }
    
    if ([name isEqualToString:@"asteroid_2c"]) {
        [self addParticleExplosion:location withColor:[UIColor colorWithRed:207.0/255.0 green:207.0/255.0 blue:207.0/255.0 alpha:1.0] andNumberOfParticles:100];
    }
    if ([name isEqualToString:@"asteroid_3a"]) {
        [self addParticleExplosion:location withColor:[UIColor colorWithRed:8.0/255.0 green:229.0/255.0 blue:255.0/255.0 alpha:1.0] andNumberOfParticles:100];
    }
    
    if ([name isEqualToString:@"asteroid_3b"]) {
        [self addParticleExplosion:location withColor:[UIColor colorWithRed:255.0/255.0 green:130.0/255.0 blue:8.0/255.0 alpha:1.0] andNumberOfParticles:100];
    }
    
    if ([name isEqualToString:@"asteroid_3c"]) {
        [self addParticleExplosion:location withColor:[UIColor colorWithRed:8.0/255.0 green:255.0/255.0 blue:107.0/255.0 alpha:1.0] andNumberOfParticles:100];
    }
    if ([name isEqualToString:@"asteroid_4a"]) {
        [self addParticleExplosion:location withColor:[UIColor colorWithRed:0.0/255.0 green:255.0/255.0 blue:216.0/255.0 alpha:1.0] andNumberOfParticles:100];
    }
    
    if ([name isEqualToString:@"asteroid_4b"]) {
        [self addParticleExplosion:location withColor:[UIColor colorWithRed:0.0/255.0 green:90.0/255.0 blue:255.0/255.0 alpha:1.0] andNumberOfParticles:100];
    }
    
    if ([name isEqualToString:@"asteroid_4c"]) {
        [self addParticleExplosion:location withColor:[UIColor colorWithRed:231.0/255.0 green:212.0/255.0 blue:162.0/255.0 alpha:1.0] andNumberOfParticles:100];
    }
    
    if (!_gameOver) {
        [self.source playBuffer:self.asteroidExplosionSFX volume:1.0 pitch:1.0 pan:0 loop:NO];
    }
}

- (void)addRocketParticles:(CGPoint)location
{
    [self addParticleExplosion:location withColor:[UIColor whiteColor] andNumberOfParticles:10];
    [self addParticleExplosion:location withColor:[UIColor redColor] andNumberOfParticles:10];
}

- (void)addParticleExplosion:(CGPoint)location withColor:(UIColor *)color andNumberOfParticles:(int)particles
{
    
    SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"SparkParticles" ofType:@"sks"]];
    explosion.particleColorSequence = nil;
    explosion.particlePosition = location;
    
    [explosion setParticleColor:color];
    [explosion setNumParticlesToEmit:particles*_scale];
    [explosion setParticleBirthRate:450];
    [explosion setParticleLifetime:4];
    [explosion setEmissionAngleRange:360];
    [explosion setParticleSpeed:300*_scale];
    [explosion setParticleSpeedRange:1200*_scale];
    [explosion setXAcceleration:0];
    [explosion setYAcceleration:0];
    [explosion setParticleAlpha:0.8];
    [explosion setParticleAlphaRange:0.2];
    [explosion setParticleAlphaSpeed:-0.5];
    
    [explosion setParticleScale:1];
    [explosion setParticleScaleRange:0.5];
    [explosion setParticleScaleSpeed:-0.5];
    
    [explosion setParticleRotation:0];
    [explosion setParticleRotationRange:0];
    [explosion setParticleRotationSpeed:0];
    
    [explosion setParticleColorBlendFactor:1];
    [explosion setParticleColorBlendFactorRange:0];
    [explosion setParticleColorBlendFactorSpeed:0];
    [explosion setParticleBlendMode:SKBlendModeAdd];
    
    [self addChild:explosion];
}

- (SKEmitterNode *)particles:(UIColor *)color andNumberOfParticles:(int)particles
{
    SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"SparkParticles" ofType:@"sks"]];
    explosion.particleColorSequence = nil;
    explosion.particlePosition = CGPointMake(0,0);
    
    [explosion setParticleColor:color];
    [explosion setNumParticlesToEmit:particles*deviceScale];
    [explosion setParticleBirthRate:450];
    [explosion setParticleLifetime:2];
    [explosion setEmissionAngleRange:360];
    [explosion setParticleSpeed:300*deviceScale];
    [explosion setParticleSpeedRange:1200*deviceScale];
    [explosion setXAcceleration:0];
    [explosion setYAcceleration:0];
    [explosion setParticleAlpha:0.8];
    [explosion setParticleAlphaRange:0.2];
    [explosion setParticleAlphaSpeed:-0.5];
    
    [explosion setParticleScale:1*deviceScale];
    [explosion setParticleScaleRange:0];
    [explosion setParticleScaleSpeed:-0.5];
    
    [explosion setParticleRotation:0];
    [explosion setParticleRotationRange:0];
    [explosion setParticleRotationSpeed:0];
    
    [explosion setParticleColorBlendFactor:1];
    [explosion setParticleColorBlendFactorRange:0];
    [explosion setParticleColorBlendFactorSpeed:0];
    [explosion setParticleBlendMode:SKBlendModeAdd];
    
    return explosion;
}

#pragma mark - Action Methods

- (void)moveToMenu
{
    [self stopBackgroundMusic];
    [self playGameOverMusic:_gameMute];
}

- (void)replayGame
{
    [self stopBackgroundMusic];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        self.view.paused = NO;
        SKScene *scene = [GameScene sceneWithSize:self.view.bounds.size];
        scene.scaleMode = SKSceneScaleModeAspectFill;
        SKTransition *transition = [SKTransition fadeWithDuration:0.5];
        SKView *skView = (SKView *)self.view;
        
        [skView presentScene:scene transition:transition];
    });
}

- (void)pauseGame
{
    if (!_gamePaused) {
        [self showPauseScreen:YES];
    } else {
        [self showPauseScreen:NO];
    }
    
    [self.source playBuffer:self.clickSFX volume:1.0 pitch:1.0 pan:0 loop:NO];
    
}

#pragma mark - Helper Methods

- (void)levelUpdate
{
    int level = (score/100);
    
    levelMultiplier = 3 - 0.15*level;
    minAsteroidTime = 3 - 0.15*level;
    maxAsteroidTime = 6 - 0.3*level;
    
    if (levelMultiplier < 0.4) {
        levelMultiplier = 0.4;
    }
    
    if (minAsteroidTime < 1) {
        minAsteroidTime = 1;
    }
    
    if (maxAsteroidTime < 1.5) {
        maxAsteroidTime = 1.5;
    }
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

- (int)saveScore
{
    // Get GameCenter Score
    BOOL isAvailable = [[GameCenterManager sharedManager] checkGameCenterAvailability];
    
    int gameCenterScore = 0;
    int highScore = 0;
    
    if (isAvailable) {
        gameCenterScore = [[GameCenterManager sharedManager] highScoreForLeaderboard:@"leader_board_score"];
    }
    
    NSInteger localScore = [_defaults integerForKey:@"highScore"];
    
    if (localScore > gameCenterScore) {
        highScore = (int)localScore;
    } else {
        highScore = gameCenterScore;
    }
    
    if (score > highScore) {
        highScore = score;
    }
    
    // save highscore
    [_defaults setInteger:highScore forKey:@"highScore"];
    [_defaults synchronize];
    
    if (isAvailable) {
        
        [[GameCenterManager sharedManager] saveAndReportScore:highScore leaderboard:@"leader_board_score" sortOrder:GameCenterSortOrderHighToLow];
    }
    
    return highScore;
}

- (void)saveMute
{
    [_defaults setBool:_gameMute forKey:@"gameMute"];
    [_defaults synchronize];
}

- (void)pauseView:(BOOL)state
{
    if (state) {
        self.rocket.paused = YES;
        _asteroid.paused = YES;
        _nuclearExplosion.paused = YES;
        _explosion.paused = YES;
        _gamePaused = YES;
    } else {
        self.rocket.paused = NO;
        _asteroid.paused = NO;
        _nuclearExplosion.paused = NO;
        _explosion.paused = NO;
        _gamePaused = NO;
    }
}

- (double)getRandomDouble
{
    return ((double)arc4random() / ARC4RANDOM_MAX);
}

- (int)getRandomNumberBetween:(int)from to:(int)to
{
    return (int)from + arc4random() % (to - from + 1);
}

- (void)setDeviceScale
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _scale = 2.0;
    } else {
        _scale = 1.0;
    }
}

- (void)generateNumbersArray
{
    NSMutableArray *numbers = [NSMutableArray array];
    
    for (int i=0; i <= 9; i++) {
        NSString *textureName = [NSString stringWithFormat:@"%d", i];
        SKTexture *texture = [SKTexture textureWithImageNamed:textureName];
        [numbers addObject:texture];
    }
    
    _numbers = numbers;
    [SKTexture preloadTextures:_numbers withCompletionHandler:^{}];
}

#pragma mark - Play Audio

- (void)initAudio
{
    [OALSimpleAudio sharedInstance];
}

- (void)playMainMusic:(BOOL)mute
{
    self.source = [OALSimpleAudio sharedInstance];
    self.source.muted = _gameMute;
    self.mainTrack = [OALAudioTrack track];
    [self.mainTrack preloadFile:MainTrackFileName];
    
    self.asteroidExplosionSFX = [[OpenALManager sharedInstance] bufferFromFile:@"Explosion_asteroid.caf"];
    self.rocketExplosionSFX = [[OpenALManager sharedInstance] bufferFromFile:@"Explosion_rocket.caf"];
    self.nuclearSFX = [[OpenALManager sharedInstance] bufferFromFile:@"nuclear.caf"];
    self.clickSFX = [[OpenALManager sharedInstance] bufferFromFile:@"click.caf"];
    self.fireRocketSFX = [[OpenALManager sharedInstance] bufferFromFile:@"rocket1.caf"];
    
    self.mainTrack.numberOfLoops = -1;
    
    if (!mute) {
        [self.mainTrack play];
        self.mainTrack.volume = 1;
    }
}

- (void)playGameOverMusic:(BOOL)mute
{
    self.gameOverTrack = [OALAudioTrack track];
    [self.gameOverTrack preloadFile:GameOverTrackFileName];
    
    // Main music track will loop on itself
    self.gameOverTrack.numberOfLoops = -1;
    
    if (!mute) {
        [self.gameOverTrack play];
        self.gameOverTrack.volume = 1;
    }
    
}

- (void)muteSound:(BOOL)state forScreen:(int)screen
{
    if (state) {
        [self.gameOverTrack stop];
        [self.mainTrack stop];
        self.gameOverTrack.currentTime = 0;
        self.mainTrack.currentTime = 0;
        [self muteSFX:0];
        _gameMute = YES;
    } else {
        if (screen == 1) {
            [self playMainMusic:NO];
            [self muteSFX:1];
            _gameMute = NO;
        } else {
            [self playGameOverMusic:NO];
            _gameMute = NO;
            [self muteSFX:1];
        }
    }
    
    [self saveMute];
    [self.source playBuffer:self.clickSFX volume:1.0 pitch:1.0 pan:0 loop:NO];
    
    SKTexture *soundTexture;
    if (_gameMute) {
        soundTexture = [SKTexture textureWithImageNamed:@"mutebutton.png"];
    } else {
        soundTexture = [SKTexture textureWithImageNamed:@"soundbutton.png"];
    }
    [_muteButton runAction:[SKAction setTexture:soundTexture]];
}

- (void)stopBackgroundMusic
{
    [self.gameOverTrack stop];
    [self.mainTrack stop];
    self.gameOverTrack.currentTime = 0;
    self.mainTrack.currentTime = 0;
}

- (void)muteSFX:(int)value
{
    if (value == 1) {
        self.source.muted = NO;
    } else {
        self.source.muted = YES;
    }
}

#pragma mark - Share

- (void)shareScore
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        NSString *textToShare = [NSString stringWithFormat:@"OMG! I got %d points in Fire Command! @hieshimi http://itunes.apple.com/app/id910010318", score];
        
        NSArray *itemsToShare = @[textToShare, _imageToShare];
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
        [(ViewController *)self.view.window.rootViewController presentViewController:activityVC animated:YES completion:^{}];
    });
}

- (void)createScreenShot
{
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, YES, 0.5);
    [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];
    _imageToShare = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

@end
