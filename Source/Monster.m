//
//  Monster.m
//  FourDragons
//
//  Created by DAVY UONG on 3/23/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Monster.h"

@implementation Monster

//Take a low and a high, return a value between high - low
- (CGFloat)randomFloatBetween:(CGFloat)smallNumber and:(CGFloat)bigNumber {
    CGFloat diff = bigNumber - smallNumber;
    return (((CGFloat) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + smallNumber;
}

- (void)setupMonsterAttributes
{
    self.typeNode.physicsBody.collisionType = @"monster";
    if ([self.typeName isEqualToString:@"PinkCreature"])
    {
        self.abilityName = @"GravityShift";
        self.changeInY = self.changeInY = [self randomFloatBetween:0.4f and:1.f];
        self.speed = - [self randomFloatBetween:50.f and:100.f];
    }
    else if ([self.typeName isEqualToString:@"RedCreature"])
    {
        self.abilityName = @"Duplicate";
        self.changeInY = [self randomFloatBetween:0.4f and:1.f];
        self.speed = - [self randomFloatBetween:50.f and:200.f];
    }
    else if ([self.typeName isEqualToString:@"BrownCreature"])
    {
        
    }
    self.upOrDown = [self posOrNegOfOne];
}

@end
