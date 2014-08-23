//
//  GameScene.m
//  Fire Command
//
//  Created by Hicham Chourak on 19/08/14.
//  Copyright (c) 2014 Hicham Chourak. All rights reserved.
//

#import "GameScene.h"
#import "MenuScene.h"
#import "GameCenter.h"
#import "GAIDictionaryBuilder.h"

#define ARC4RANDOM_MAX 0x100000000

typedef enum : NSUInteger {
    ExplosionCategory = (1 << 0),
    MissileCategory = (1 << 1),
    MonsterCategory = (1 << 2),
    BaseCategory = (1 << 3)
} NodeCategory;

@implementation GameScene {
    
    
    SKLabelNode *labelflowerBullets1;
    SKLabelNode *labelflowerBullets2;
    SKLabelNode *labelflowerBullets3;
    SKLabelNode *labelMisslesExploded;
    SKLabelNode *labelScore;
    
    int position;
    int monstersDead;
    int missileExploded;
    int score;
    int explosionZPosition;
    
    int flowerBullets1;
    int flowerBullets2;
    int flowerBullets3;
    
    double nextAsteroidTime;
    float levelMultiplier;
    
    float deviceScale;
    
    CFTimeInterval currentTimeStamp;
    CFTimeInterval lastRocketTimeStamp;
    
    GameCenter *gameCenter;
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        
        // GA
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker set:kGAIScreenName value:@"GameScene"];
        [tracker send:[[GAIDictionaryBuilder createAppView] build]];
        
        self.backgroundColor = [SKColor blackColor];
        
        [self addGroundExplosion:1];
        [self addGroundExplosion:3];
        [self addGroundExplosion:5];
        [self addGroundExplosion:7];
        // enable GameCenter
        gameCenter = [[GameCenter alloc] init];
        [gameCenter authenticateLocalPlayer];
        
        // init first values
        position = size.width/3;
        score = 0;
        explosionZPosition = 0;
        nextAsteroidTime = 0;
        levelMultiplier = 5;
        lastRocketTimeStamp = 0;
        deviceScale = [self setDeviceScale];
        
        // add Screen Elements
        [self addHud];
  
        [self addFlowerCommand];
        
        [self addMonstersBetweenSpace:1];
        [self addMonstersBetweenSpace:2];
        
         // setup physics
        self.physicsWorld.gravity = CGVectorMake(0, 0);
        self.physicsWorld.contactDelegate = self;
    }
    
    return self;
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
    if (currentTime > nextAsteroidTime || nextAsteroidTime - currentTime > 5) {
        nextAsteroidTime = ([self getRandomDouble] * levelMultiplier) + currentTime;
        NSLog(@"%f", nextAsteroidTime);
        [self addAstroid];
    }
    
    currentTimeStamp = currentTime;
    
}

#pragma mark - UI Elements

- (void)addHud
{
    labelScore = [SKLabelNode labelNodeWithFontNamed:@"Hiragino-Kaku-Gothic-ProN"];
    labelScore.text = [NSString stringWithFormat:@"%d", score];
    labelScore.fontSize = 30;
    labelScore.position = CGPointMake(self.size.width/2, self.size.height-self.size.height/8);
    labelScore.zPosition = 3;
    [self addChild:labelScore];
}

#pragma mark - Touch Methods

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        
        // Return if User Taps Below a Flower
        if (location.y < 120) return;

        if (fabsf(currentTimeStamp - lastRocketTimeStamp) > 0.3) {
            [self addRocket:location];
            [self addParticleExplosion:location];
            lastRocketTimeStamp = currentTimeStamp;
        }
    }
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    if ((contact.bodyA.categoryBitMask & ExplosionCategory) != 0 || (contact.bodyB.categoryBitMask & ExplosionCategory) != 0) {
        // Collision Between Explosion and Missile
        SKNode *missile = (contact.bodyA.categoryBitMask & ExplosionCategory) ? contact.bodyB.node : contact.bodyA.node;
        [missile runAction:[SKAction removeFromParent]];
        
        //the explosion continues, because can kill more than one missile
        NSLog(@"Missile destroyed");
    
        
        score = score + 10;
        [labelScore setText:[NSString stringWithFormat:@"%d", score]];
        
        if(missileExploded == 20){
            SKLabelNode *ganhou = [SKLabelNode labelNodeWithFontNamed:@"Hiragino-Kaku-Gothic-ProN"];
            ganhou.text = @"You win!";
            ganhou.fontSize = 60;
            ganhou.position = CGPointMake(self.size.width/2,self.size.height/2);
            ganhou.zPosition = 3;
            [self addChild:ganhou];
        }
    } else {
        // Collision Between Missile and Monster
        SKNode *monster = (contact.bodyA.categoryBitMask & MonsterCategory) ? contact.bodyA.node : contact.bodyB.node;
        SKNode *missile = (contact.bodyA.categoryBitMask & MonsterCategory) ? contact.bodyB.node : contact.bodyA.node;
        [missile runAction:[SKAction removeFromParent]];
        [monster runAction:[SKAction removeFromParent]];
        
        NSLog(@"Monster killed");
        monstersDead++;
        if(monstersDead == 6){
            SKLabelNode *perdeu = [SKLabelNode labelNodeWithFontNamed:@"Hiragino-Kaku-Gothic-ProN"];
            perdeu.text = @"You Lose!";
            perdeu.fontSize = 60;
            perdeu.position = CGPointMake(self.size.width/2,self.size.height/2);
            perdeu.zPosition = 3;
            [self addChild:perdeu];
            [self moveToMenu];
        }
    }
}

#pragma mark - Game Elements

- (void)addFlowerCommand
{
    SKSpriteNode *flower = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(50, 100)];
    flower.zPosition = 2;
    flower.scale = deviceScale;
    
    flower.position = CGPointMake(self.size.width/2, flower.size.height/2);
    [self addChild:flower];
}

- (void)addRocket:(CGPoint)location
{
    SKSpriteNode *rocket = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(10, 10)];
    rocket.zPosition = 1;
    rocket.scale = deviceScale;
    rocket.position = CGPointMake(self.size.width/2,110);
    
    float duration = location.y *0.001;
    SKAction *move =[SKAction moveTo:CGPointMake(location.x,location.y) duration:duration];
    SKAction *remove = [SKAction removeFromParent];
    
    // Explosion
    SKAction *callExplosion = [SKAction runBlock:^{
        SKSpriteNode *explosion = [SKSpriteNode spriteNodeWithImageNamed:@"explosion"];
        explosion.zPosition = 0;
        explosion.scale = 0.2 * deviceScale;
        explosion.position = CGPointMake(location.x,location.y);
        explosion.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:explosion.size.height/2];
        explosion.physicsBody.dynamic = YES;
        explosion.physicsBody.categoryBitMask = ExplosionCategory;
        explosion.physicsBody.contactTestBitMask = MissileCategory;
        explosion.physicsBody.collisionBitMask = 0;
        SKAction *explosionAction = [SKAction scaleTo:0.5 * deviceScale duration:.6];
        [explosion runAction:[SKAction sequence:@[explosionAction,remove]]];
        [self addChild:explosion];
    }];
    
    [rocket runAction:[SKAction sequence:@[move,callExplosion,remove]]];
    
    [self addChild:rocket];
}

- (void)addMonstersBetweenSpace:(int)spaceOrder
{
    for (int i = 0; i< 4; i++) {
        
        SKSpriteNode *monster;
        monster = [SKSpriteNode spriteNodeWithColor:[SKColor grayColor] size:CGSizeMake(50, 50)];
        monster.scale = deviceScale;
        monster.zPosition = 2;
    
        if (i < 2) {
            monster.position = CGPointMake((self.size.width/4) * i, monster.size.height/2);
        } else {
            monster.position = CGPointMake((self.size.width/4) * (i+1), monster.size.height/2);
        }
    
        // Add Physics
        monster.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:monster.size];
        monster.physicsBody.dynamic = YES;
        monster.physicsBody.categoryBitMask = MonsterCategory;
        monster.physicsBody.contactTestBitMask = MissileCategory;
        monster.physicsBody.collisionBitMask = 1;
        
        [self addChild:monster];
    }
}

- (void)addAstroid
{
    SKSpriteNode *missile = [SKSpriteNode spriteNodeWithColor:[SKColor greenColor] size:CGSizeMake(20, 20)];
        missile.scale = deviceScale;
        missile.zPosition = 1;
        
        int startPoint = [self getRandomNumberBetween:0 to:self.size.width];
        missile.position = CGPointMake(startPoint, self.size.height);
        
        missile.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:missile.size.height/2];
        missile.physicsBody.dynamic = NO;
        missile.physicsBody.categoryBitMask = MissileCategory;
        missile.physicsBody.contactTestBitMask = ExplosionCategory | MonsterCategory;
        missile.physicsBody.collisionBitMask = 1;
        
        int endPoint = [self getRandomNumberBetween:0 to:self.size.width];
        
        SKAction *move =[SKAction moveTo:CGPointMake(endPoint, 0) duration:15];
        SKAction *remove = [SKAction removeFromParent];
        [missile runAction:[SKAction sequence:@[move,remove]]];
        
        [self addChild:missile];
}

- (void)addGroundExplosion:(int)ExplosionPosition
{
    NSMutableArray *frames = [NSMutableArray array];
    SKTextureAtlas *nuclearExplosionAtlas = [SKTextureAtlas atlasNamed:@"nuclear_explosion"];
    
    int framesCount = nuclearExplosionAtlas.textureNames.count;
    for (int i=0; i < framesCount; i++) {
        NSString *textureName = [NSString stringWithFormat:@"nuclear_explosion_%d", i];
        SKTexture *texture = [nuclearExplosionAtlas textureNamed:textureName];
        [frames addObject:texture];
    }
    
    NSArray *textureFrames = frames;

    SKSpriteNode *nuclearExplosion = [SKSpriteNode spriteNodeWithTexture:textureFrames[0]];
    nuclearExplosion.scale = 2.0;
    nuclearExplosion.position = CGPointMake((self.size.width/8)*ExplosionPosition, nuclearExplosion.size.height/2);
    nuclearExplosion.zPosition = 20;
    
    [nuclearExplosion runAction:[SKAction repeatActionForever:
                      [SKAction animateWithTextures:textureFrames
                                       timePerFrame:0.07f
                                             resize:NO
                                            restore:YES]]];
    
    [self addChild:nuclearExplosion];
}

#pragma mark - Particles

- (void)addParticleExplosion:(CGPoint)location
{
    
    SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"SparkParticles" ofType:@"sks"]];
    
    explosion.particlePosition = location;
    
    [explosion setParticleColor:[UIColor whiteColor]];
    [explosion setNumParticlesToEmit:5*deviceScale];
    [explosion setParticleBirthRate:450];
    [explosion setParticleLifetime:2];
    [explosion setEmissionAngleRange:360];
    [explosion setParticleSpeed:200*deviceScale];
    [explosion setParticleSpeedRange:1000*deviceScale];
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
    
    [self addChild:explosion];
}

#pragma mark - Transition Methods

- (void)moveToMenu
{
    [gameCenter reportScore:score];
    
    SKTransition *transition = [SKTransition fadeWithDuration:2];
    MenuScene *myscene = [[MenuScene alloc] initWithSize:CGSizeMake(CGRectGetMaxX(self.frame), CGRectGetMaxY(self.frame))];
    [self.scene.view presentScene:myscene transition:transition];
}

#pragma mark - Helper Methods

- (double)getRandomDouble
{
    return ((double)arc4random() / ARC4RANDOM_MAX);
}


- (int)getRandomNumberBetween:(int)from to:(int)to
{
    return (int)from + arc4random() % (to - from + 1);
}

- (int)positionOfWhichFlowerShouldBegin:(int)number
{
    return position * number - position / 2;
}

- (float)setDeviceScale
{
    float scaleTextures;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        scaleTextures = 2.0;
    } else {
        scaleTextures = 1.0;
    }
    
    return scaleTextures;
}

@end
