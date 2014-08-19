//
//  GameScene.h
//  Fire Command
//

//  Copyright (c) 2014 Hicham Chourak. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

typedef enum : NSUInteger {
    ExplosionCategory = (1 << 0),
    MissileCategory = (1 << 1),
    MonsterCategory = (1 << 2)
} NodeCategory;

@interface GameScene : SKScene <SKPhysicsContactDelegate> {
    CGSize sizeGlobal;
    
    SKLabelNode *labelflowerBullets1;
    SKLabelNode *labelflowerBullets2;
    SKLabelNode *labelflowerBullets3;
    SKLabelNode *labelMisslesExploded;
    
    int position;
    int monstersDead;
    int missileExploded;
    
    int flowerBullets1;
    int flowerBullets2;
    int flowerBullets3;
}



@end
