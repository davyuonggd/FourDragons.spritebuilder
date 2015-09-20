//
//  Hero.m
//  FourDragons
//
//  Created by DAVY UONG on 3/5/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Hero.h"

@implementation Hero

#pragma mark - Hero's ability

- (void)breathFire
{
    CCAnimationManager *animationManager = self.typeNode.animationManager;
    NSString *shootingAnimation = [NSString stringWithFormat:@"%@Shooting", self.typeName];
    [animationManager runAnimationsForSequenceNamed:shootingAnimation];
    [self performSelector:@selector(changeTypeWithTypeName:) withObject:self.typeName afterDelay:0.25f];
}

#pragma mark - Applying Hero's Attributes

- (void)createHeroPhysicsBody
{
    self.normalShapeRadius = 15.f;
    //Get the hero's center with a little offset
    CGPoint heroCenter = ccp(self.typeNode.anchorPointInPoints.x + 7.f, self.typeNode.anchorPointInPoints.y);
    
    //this is the normal shape of the hero's physicsBody
    self.normalShape = [CCPhysicsShape circleShapeWithRadius:self.normalShapeRadius center:heroCenter];
    //this is the tiny shape of the hero's physicsBody
    self.smallShape = [CCPhysicsShape circleShapeWithRadius:self.normalShapeRadius * 0.75f center:ccp(heroCenter.x - 7.f, heroCenter.y - 3.5f)];
    //this is the invincible shape of the hero's physicsBody
    self.largeShape = [CCPhysicsShape circleShapeWithRadius:self.normalShapeRadius * 1.5f center:ccp(heroCenter.x + 12.f, heroCenter.y + 6.f)];
    
    self.invincibleShape = [CCPhysicsShape circleShapeWithRadius:self.normalShapeRadius * 2.f center:ccp(heroCenter.x + 24.f, heroCenter.y + 12.f)];
    
//    self.smallShape.mass = 0.f;
//    //self.normalShape.mass = 0.f;
//    self.largeShape.mass = 0.f;
//    self.invincibleShape.mass = 0.f;
//    
//    self.normalShape.density = 0.20f;
//    self.normalShape.friction = 1.0f;
//    self.normalShape.elasticity = 0.30f;
    
    NSArray *herophysicsShapes = @[self.normalShape, self.smallShape, self.largeShape, self.invincibleShape];
    self.typeNode.physicsBody = [CCPhysicsBody bodyWithShapes:herophysicsShapes];
    
    //create the hero's physicsBody with these 4 shapes overlapping each other. Only 1 shape is set for collision at a time.
    self.typeNode.physicsBody.type = CCPhysicsBodyTypeDynamic;
    self.typeNode.physicsBody.allowsRotation = FALSE;
    self.typeNode.physicsBody.density = 0.20f;
    self.typeNode.physicsBody.friction = 1.0f;
    self.typeNode.physicsBody.elasticity = 0.30f;
    
    //start out with normal shape
    self.normalShape.collisionType = @"hero";
    self.smallShape.collisionType = @"inactive";
    self.largeShape.collisionType = @"inactive";
    self.invincibleShape.collisionType = @"inactive";
    
    //prevent the bigger shapes from physically hit the ground
    self.smallShape.sensor = TRUE;
    self.largeShape.sensor = TRUE;
    self.invincibleShape.sensor = TRUE;
}

- (void)applyHeroAttributes
{
    //general attributes
    self.impulseInY = 1000.f;
    self.yVelocityClamp = 300.f;
    self.accelerationRate = 2.f; //1.0f
    self.accelerationMax = 15.0f;
    self.maxSpeed = 2400.f;
    
    if ([self.typeName isEqualToString:@"AirDragon"])
    {
        //hero's unique attributes
        self.abilityName = @"freezeTime";        
    }
    else if ([self.typeName isEqualToString:@"EarthDragon"])
    {
        //hero's unique attributes
        self.abilityName = @"invincible";
    }
    else if ([self.typeName isEqualToString:@"WaterDragon"])
    {
        self.abilityName = @"coinMagnet";
    }
    else if ([self.typeName isEqualToString:@"FireDragon"])
    {
        self.abilityName = @"breathFire";
    }
    self.acceleration = 0.0f;
}

- (void)setupHero
{
    //set hero's animation
    CCAnimationManager *animationManager = self.typeNode.animationManager;
    [animationManager runAnimationsForSequenceNamed:self.typeName];
    //create hero's physicsBody
    [self createHeroPhysicsBody];
    //set hero's attributes
    [self applyHeroAttributes];
}

- (void)changeShape
{
    //invinsible
    if (self.typeNode.scale == 2.0f)
    {
        self.smallShape.collisionType = @"inactive";
        self.normalShape.collisionType = @"inactive";
        self.largeShape.collisionType = @"inactive";
        self.invincibleShape.collisionType = @"hero";
        //prevent the bigger shapes from physically hit the ground
        self.smallShape.sensor = TRUE;
        self.normalShape.sensor = TRUE;
        self.largeShape.sensor = TRUE;
        self.invincibleShape.sensor = FALSE;
    }
    //small
    else if (self.typeNode.scale == 0.75f)
    {
        self.smallShape.collisionType = @"hero";
        self.normalShape.collisionType = @"inactive";
        self.largeShape.collisionType = @"inactive";
        self.invincibleShape.collisionType = @"inactive";
        //prevent the bigger shapes from physically hit the ground
        self.smallShape.sensor = FALSE;
        self.normalShape.sensor = TRUE;
        self.largeShape.sensor = TRUE;
        self.invincibleShape.sensor = TRUE;
    }
    //normal
    else if (self.typeNode.scale == 1.f)
    {
        self.smallShape.collisionType = @"inactive";
        self.normalShape.collisionType = @"hero";
        self.largeShape.collisionType = @"inactive";
        self.invincibleShape.collisionType = @"inactive";
        //prevent the bigger shapes from physically hit the ground
        self.smallShape.sensor = TRUE;
        self.normalShape.sensor = FALSE;
        self.largeShape.sensor = TRUE;
        self.invincibleShape.sensor = TRUE;
    }
    //large
    else if (self.typeNode.scale == 1.5f)
    {
        self.smallShape.collisionType = @"inactive";
        self.normalShape.collisionType = @"inactive";
        self.largeShape.collisionType = @"hero";
        self.invincibleShape.collisionType = @"inactive";
        //prevent the bigger shapes from physically hit the ground
        self.smallShape.sensor = TRUE;
        self.normalShape.sensor = TRUE;
        self.largeShape.sensor = FALSE;
        self.invincibleShape.sensor = TRUE;
    }
}

- (void)changeTypeWithTypeName:(NSString *)typeName
{
    self.previousTypeName = self.typeName;
    self.typeName = typeName;
    CCAnimationManager *animationManager = self.typeNode.animationManager;
    [animationManager runAnimationsForSequenceNamed:self.typeName];
    //set hero's attributes
    [self applyHeroAttributes];
}

#pragma mark - Initialization

- (id)initWithTypeName:(NSString *)typeName
{
    self = [super init];
    if (self)
    {
        self.typeNode = [CCBReader load:@"Dragon"];
        self.typeName = typeName;
    }
    return self;
}

@end
