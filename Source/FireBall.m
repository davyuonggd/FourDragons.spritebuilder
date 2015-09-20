//
//  FireBall.m
//  FourDragons
//
//  Created by DAVY UONG on 5/20/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "FireBall.h"

@implementation FireBall

- (void)setupFireBallAttributes
{
    self.typeNode.physicsBody.collisionType = @"fireBall";
    self.speed = -480.f;
}

@end
