//
//  Hero.h
//  FourDragons
//
//  Created by DAVY UONG on 3/5/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "CCNode.h"

@interface Hero : CCNode

@property (strong, nonatomic) NSString *typeName;
@property (strong, nonatomic) NSString *previousTypeName;
@property (strong, nonatomic) CCNode *typeNode;

//HERO'S GENERAL ATTRIBUTES:
@property (strong, nonatomic) CCPhysicsShape *normalShape;
@property (strong, nonatomic) CCPhysicsShape *smallShape;
@property (strong, nonatomic) CCPhysicsShape *largeShape;
@property (strong, nonatomic) CCPhysicsShape *invincibleShape;

@property CGFloat normalShapeRadius;

@property CGFloat acceleration;
@property CGFloat accelerationRate;
@property CGFloat accelerationMax;
@property CGFloat impulseInY;
@property CGFloat yVelocityClamp;
@property CGFloat maxSpeed;

@property BOOL isNormal;
@property BOOL isSmall;
@property BOOL isLarge;

//HERO'S UNIQUE ATTRIBUTES:
@property (strong, nonatomic) NSString *abilityName;

//Air Dragon's:
@property BOOL isFreezeTime;

//Earth Dragon's:
@property BOOL isInvincible;

//Water Dragon's:
@property BOOL isMagnet;

//Fire Dragon's:
@property BOOL isBreathingFire;
- (void)breathFire;

//HERO'S GENERAL METHODS:
- (void)setupHero;
- (void)changeTypeWithTypeName:(NSString *)typeName;
- (void)changeShape;
- (id)initWithTypeName:(NSString *)typeName;

@end
