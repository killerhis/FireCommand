//
//  GameScene.m
//  Fire Command
//
//  Created by Hicham Chourak on 19/08/14.
//  Copyright (c) 2014 Hicham Chourak. All rights reserved.
//

#import "GameScene.h"
#import "MenuScene.h"

@implementation GameScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        
        self.backgroundColor = [SKColor colorWithRed:198.0/255.0 green:220.0/255.0 blue:54.0/255.0 alpha:1.0];
        
        position = size.width/3;
        sizeGlobal = size;
        [self addFlowerCommand];
        
        // Label informing mussles exploded
        labelMisslesExploded = [SKLabelNode labelNodeWithFontNamed:@"Hiragino-Kaku-Gothic-ProN"];
        labelMisslesExploded.text = [NSString stringWithFormat:@"Missles Exploded %d", missileExploded];
        labelMisslesExploded.fontSize = 30;
        labelMisslesExploded.position = CGPointMake(size.width/2, size.height-labelMisslesExploded.frame.size.height);
        labelMisslesExploded.zPosition = 3;
        [self addChild:labelMisslesExploded];
        
        flowerBullets1 = 1000;
        flowerBullets2 = 1000;
        flowerBullets3 = 1000;
        
        labelflowerBullets1 = [SKLabelNode labelNodeWithFontNamed:@"Hiragino-Kaku-Gothic-ProN"];
        labelflowerBullets1.text = [NSString stringWithFormat:@"%d",flowerBullets1];
        labelflowerBullets1.fontSize = 30;
        labelflowerBullets1.position = CGPointMake(position-position/2,labelflowerBullets1.frame.size.height/2);
        labelflowerBullets1.zPosition = 3;
        [self addChild:labelflowerBullets1];
        
        labelflowerBullets2 = [SKLabelNode labelNodeWithFontNamed:@"Hiragino-Kaku-Gothic-ProN"];
        labelflowerBullets2.text = [NSString stringWithFormat:@"%d",flowerBullets2];
        labelflowerBullets2.fontSize = 30;
        labelflowerBullets2.position = CGPointMake(position*2-position/2,labelflowerBullets2.frame.size.height/2);
        labelflowerBullets2.zPosition = 3;
        [self addChild:labelflowerBullets2];
        
        labelflowerBullets3 = [SKLabelNode labelNodeWithFontNamed:@"Hiragino-Kaku-Gothic-ProN"];
        labelflowerBullets3.text = [NSString stringWithFormat:@"%d",flowerBullets3];
        labelflowerBullets3.fontSize = 30;
        labelflowerBullets3.position = CGPointMake(position*3-position/2,labelflowerBullets3.frame.size.height/2);
        labelflowerBullets3.zPosition = 3;
        [self addChild:labelflowerBullets3];
        
        [self addMonstersBetweenSpace:1];
        [self addMonstersBetweenSpace:2];
        
        // Create missles
        
        SKAction *wait = [SKAction waitForDuration:2];
        SKAction *createMissiles = [SKAction runBlock:^{
            [self addMissilesFromSky:size];
        }];
        
        SKAction *updateMissiles = [SKAction sequence:@[wait, createMissiles]];
        [self runAction:[SKAction repeatActionForever:updateMissiles]];
        
        // Configure Physics
        
        self.physicsWorld.gravity = CGVectorMake(0, 0);
        self.physicsWorld.contactDelegate = self;
    }
    
    return self;

}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        
        // Return if User Taps Below a Flower
        if (location.y < 120) return;
        
        int bulletBeginning = 0;
        
        /*if (location.x >= 0 && location.x < position) {
            bulletBeginning = position-position/2;
            
            if (flowerBullets1 > 0)
                flowerBullets1--;
            else{
                if(flowerBullets1 == 0 && flowerBullets2 > 0){
                    flowerBullets2--;
                    [labelflowerBullets2 setText:[NSString stringWithFormat:@"%d",flowerBullets2]];
                    bulletBeginning = [self positionOfWhichFlowerShouldBegin:2];
                }
                else if(flowerBullets3 > 0){
                    flowerBullets3--;
                    [labelflowerBullets3 setText:[NSString stringWithFormat:@"%d",flowerBullets3]];
                    bulletBeginning =[self positionOfWhichFlowerShouldBegin:3];
                }
                else{
                    return;
                }
            }
            [labelflowerBullets1 setText:[NSString stringWithFormat:@"%d",flowerBullets1]];
        }
        else if((location.x >= position && location.x < position*2)){
            bulletBeginning = position*2-position/2;
            if(flowerBullets2 > 0)
                flowerBullets2--;
            else{
                if(location.x < sizeGlobal.width/2){
                    if(flowerBullets1 > 0){
                        flowerBullets1--;
                        [labelflowerBullets1 setText:[NSString stringWithFormat:@"%d",flowerBullets1]];
                        bulletBeginning =[self positionOfWhichFlowerShouldBegin:1];
                    }
                    else if (flowerBullets3 > 0){
                        flowerBullets3--;
                        [labelflowerBullets3 setText:[NSString stringWithFormat:@"%d",flowerBullets3]];
                        bulletBeginning =[self positionOfWhichFlowerShouldBegin:3];
                    }
                    else{
                        return;
                    }
                }
                else{
                    if(flowerBullets3 > 0){
                        flowerBullets3--;
                        [labelflowerBullets3 setText:[NSString stringWithFormat:@"%d",flowerBullets3]];
                        bulletBeginning =[self positionOfWhichFlowerShouldBegin:3];
                    }
                    else if (flowerBullets1 > 0){
                        flowerBullets1--;
                        [labelflowerBullets1 setText:[NSString stringWithFormat:@"%d",flowerBullets1]];
                        bulletBeginning =[self positionOfWhichFlowerShouldBegin:1];
                    }
                    else{
                        return;
                    }
                }
                
            }
            [labelflowerBullets2 setText:[NSString stringWithFormat:@"%d",flowerBullets2]];
        }
        else{
            bulletBeginning = position*3-position/2;
            if(flowerBullets3 > 0)
                flowerBullets3--;
            else{
                if(flowerBullets3 == 0 && flowerBullets2 > 0){
                    flowerBullets2--;
                    [labelflowerBullets2 setText:[NSString stringWithFormat:@"%d",flowerBullets2]];
                    bulletBeginning =[self positionOfWhichFlowerShouldBegin:2];
                }
                else if(flowerBullets1 > 0){
                    flowerBullets1--;
                    [labelflowerBullets1 setText:[NSString stringWithFormat:@"%d",flowerBullets1]];
                    bulletBeginning =[self positionOfWhichFlowerShouldBegin:1];
                }
                else{
                    return;
                }
            }
            [labelflowerBullets3 setText:[NSString stringWithFormat:@"%d",flowerBullets3]];
        }*/
        
        bulletBeginning = self.size.width/2;
        
        SKSpriteNode *bullet = [SKSpriteNode spriteNodeWithImageNamed:@"flowerBullet"];
        bullet.zPosition = 1;
        bullet.scale = 0.6;
        bullet.position = CGPointMake(bulletBeginning,110);
        bullet.color = [SKColor redColor];
        bullet.colorBlendFactor = 0.5;
        
        float duration = (2 * location.y)/sizeGlobal.width;
        SKAction *move =[SKAction moveTo:CGPointMake(location.x,location.y) duration:duration];
        SKAction *remove = [SKAction removeFromParent];
        
        // Explosion
        SKAction *callExplosion = [SKAction runBlock:^{
            SKSpriteNode *explosion = [SKSpriteNode spriteNodeWithImageNamed:@"explosion"];
            explosion.zPosition = 3;
            explosion.scale = 0.1;
            explosion.position = CGPointMake(location.x,location.y);
            explosion.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:explosion.size.height/2];
            explosion.physicsBody.dynamic = YES;
            explosion.physicsBody.categoryBitMask = ExplosionCategory;
            explosion.physicsBody.contactTestBitMask = MissileCategory;
            explosion.physicsBody.collisionBitMask = 1;
            SKAction *explosionAction = [SKAction scaleTo:0.8 duration:1.5];
            [explosion runAction:[SKAction sequence:@[explosionAction,remove]]];
            [self addChild:explosion];
        }];
        
        [bullet runAction:[SKAction sequence:@[move,callExplosion,remove]]];
        
        [self addChild:bullet];
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

- (void)addFlowerCommand
{
    //for (int i = 1; i <= 3; i++) {
        SKSpriteNode *flower = [SKSpriteNode spriteNodeWithImageNamed:@"flower.png"];
        flower.zPosition = 2;
        //flower.position = CGPointMake(position * i - position / 2, flower.size.height / 2);
    flower.position = CGPointMake(self.size.width/2, flower.size.height/2);
        [self addChild:flower];
    //}
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    if ((contact.bodyA.categoryBitMask & ExplosionCategory) != 0 || (contact.bodyB.categoryBitMask & ExplosionCategory) != 0) {
        // Collision Between Explosion and Missile
        SKNode *missile = (contact.bodyA.categoryBitMask & ExplosionCategory) ? contact.bodyB.node : contact.bodyA.node;
        [missile runAction:[SKAction removeFromParent]];
        
        //the explosion continues, because can kill more than one missile
        NSLog(@"Missile destroyed");
        
        // Update Missile Exploded
        missileExploded++;
        [labelMisslesExploded setText:[NSString stringWithFormat:@"Missiles Exploded: %d",missileExploded]];
        
        if(missileExploded == 20){
            SKLabelNode *ganhou = [SKLabelNode labelNodeWithFontNamed:@"Hiragino-Kaku-Gothic-ProN"];
            ganhou.text = @"You win!";
            ganhou.fontSize = 60;
            ganhou.position = CGPointMake(sizeGlobal.width/2,sizeGlobal.height/2);
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
            perdeu.position = CGPointMake(sizeGlobal.width/2,sizeGlobal.height/2);
            perdeu.zPosition = 3;
            [self addChild:perdeu];
            [self moveToMenu];
        }
    }
}

- (void)addMonstersBetweenSpace:(int)spaceOrder
{
    for (int i = 0; i< 3; i++) {
        int giveDistanceToMonsters = 60 * i -60;
        int randomMonster = [self getRandomNumberBetween:0 to:1];
        
        SKSpriteNode *monster;
        CGMutablePathRef path = CGPathCreateMutable();
        
        if (randomMonster == 0) {
            monster = [SKSpriteNode spriteNodeWithImageNamed:@"protectCreature4"];
            
            CGFloat offsetX = monster.frame.size.width * monster.anchorPoint.x;
            CGFloat offsetY = monster.frame.size.height * monster.anchorPoint.y;
            CGPathMoveToPoint(path, NULL, 10 - offsetX, 1 - offsetY);
            CGPathAddLineToPoint(path, NULL, 42 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 49 - offsetX, 13 - offsetY);
            CGPathAddLineToPoint(path, NULL, 51 - offsetX, 29 - offsetY);
            CGPathAddLineToPoint(path, NULL, 50 - offsetX, 42 - offsetY);
            CGPathAddLineToPoint(path, NULL, 42 - offsetX, 59 - offsetY);
            CGPathAddLineToPoint(path, NULL, 29 - offsetX, 67 - offsetY);
            CGPathAddLineToPoint(path, NULL, 19 - offsetX, 67 - offsetY);
            CGPathAddLineToPoint(path, NULL, 5 - offsetX, 53 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 34 - offsetY);
            CGPathAddLineToPoint(path, NULL, 1 - offsetX, 15 - offsetY);
            CGPathCloseSubpath(path);
        } else {
            monster = [SKSpriteNode spriteNodeWithImageNamed:@"protectCreature2"];
            
            CGFloat offsetX = monster.frame.size.width * monster.anchorPoint.x;
            CGFloat offsetY = monster.frame.size.height * monster.anchorPoint.y;
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 1 - offsetY);
            CGPathAddLineToPoint(path, NULL, 47 - offsetX, 1 - offsetY);
            CGPathAddLineToPoint(path, NULL, 47 - offsetX, 24 - offsetY);
            CGPathAddLineToPoint(path, NULL, 40 - offsetX, 43 - offsetY);
            CGPathAddLineToPoint(path, NULL, 28 - offsetX, 53 - offsetY);
            CGPathAddLineToPoint(path, NULL, 19 - offsetX, 53 - offsetY);
            CGPathAddLineToPoint(path, NULL, 8 - offsetX, 44 - offsetY);
            CGPathAddLineToPoint(path, NULL, 1 - offsetX, 26 - offsetY);
            CGPathCloseSubpath(path);
        }
        
        monster.zPosition = 2;
        monster.position = CGPointMake(position * spaceOrder - giveDistanceToMonsters, monster.size.height / 2);
        
        // Add Physics
        monster.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:path];
        monster.physicsBody.dynamic = YES;
        monster.physicsBody.categoryBitMask = MonsterCategory;
        monster.physicsBody.contactTestBitMask = MissileCategory;
        monster.physicsBody.collisionBitMask = 1;
        monster.zPosition = 2;
        monster.position = CGPointMake(position * spaceOrder - giveDistanceToMonsters, monster.size.height / 2);
        
        [self addChild:monster];
    }
}

- (void)moveToMenu
{
    SKTransition *transition = [SKTransition fadeWithDuration:2];
    MenuScene *myscene = [[MenuScene alloc] initWithSize:CGSizeMake(CGRectGetMaxX(self.frame), CGRectGetMaxY(self.frame))];
    [self.scene.view presentScene:myscene transition:transition];
}

- (int)getRandomNumberBetween:(int)from to:(int)to
{
    return (int)from + arc4random() % (to - from + 1);
}

- (void)addMissilesFromSky:(CGSize)size
{
    int numberMissiles = [self getRandomNumberBetween:0 to:3];
    
    for (int i = 0; i < numberMissiles; i++) {
        SKSpriteNode *missile;
        missile = [SKSpriteNode spriteNodeWithImageNamed:@"enemyMissile"];
        missile.scale = 0.6;
        missile.zPosition = 1;
        
        int startPoint = [self getRandomNumberBetween:0 to:size.width];
        missile.position = CGPointMake(startPoint, size.height);
        
        missile.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:missile.size.height/2];
        missile.physicsBody.dynamic = NO;
        missile.physicsBody.categoryBitMask = MissileCategory;
        missile.physicsBody.contactTestBitMask = ExplosionCategory | MonsterCategory;
        missile.physicsBody.collisionBitMask = 1;
        
        int endPoint = [self getRandomNumberBetween:0 to:size.width];
        
        SKAction *move =[SKAction moveTo:CGPointMake(endPoint, 0) duration:15];
        SKAction *remove = [SKAction removeFromParent];
        [missile runAction:[SKAction sequence:@[move,remove]]];
        
        [self addChild:missile];
    }
}

- (int)positionOfWhichFlowerShouldBegin:(int)number
{
    return position * number - position / 2;
}

@end
