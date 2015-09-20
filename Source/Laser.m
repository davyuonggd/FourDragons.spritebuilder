//
//  Laser.m
//  FourDragons
//
//  Created by DAVY UONG on 3/25/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Laser.h"
#import "CCPhysics+ObjectiveChipmunk.h" //to access advanced chipmunk properties

@implementation Laser

{
    CCNode *_top;
    CCSprite *_middle;
    CCPhysicsShape *_middleShape;
    CCNode *_bottom;
}

- (CGFloat)randomFloatBetween:(CGFloat)smallNumber and:(CGFloat)bigNumber {
    CGFloat diff = bigNumber - smallNumber;
    return (((CGFloat) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + smallNumber;
}

- (void)didLoadFromCCB
{
    _top.physicsBody.sensor = YES;
    _middle.physicsBody.sensor = YES;
    _bottom.physicsBody.sensor = YES;
    _top.physicsBody.collisionType = @"monster";
    _middle.physicsBody.collisionType = @"laser";
    _bottom.physicsBody.collisionType = @"monster";
    
    CGFloat tanA;
    CGFloat angle;
    int oneOrTwo = arc4random_uniform(2);
    switch (oneOrTwo)
    {
        case 0:
            _top.position = ccp([self randomFloatBetween:0.f and:self.contentSizeInPoints.width], _top.position.y);
            _bottom.position = ccp(0.f, _top.position.y);
            tanA = _top.position.x / self.contentSizeInPoints.height;
            angle = atan(tanA) * 180 / M_PI;
            //CCLOG(@"angle = %f", angle);
            _middle.rotation = angle;
            break;
        case 1:
//            _top.position = ccp(self.contentSizeInPoints.width, _top.position.y);
//            _bottom.position = ccp([self randomFloatBetween:0.f and:self.contentSizeInPoints.width], _bottom.position.y);
//            _middle.anchorPoint = ccp(0.5f, 1.f);
//            _middle.position = ccp(self.contentSizeInPoints.width, self.contentSizeInPoints.height - 8.f);
            _top.position = ccp([self randomFloatBetween:0.f and:self.contentSizeInPoints.width], _top.position.y);
            _bottom.position = ccp(self.contentSizeInPoints.width, _bottom.position.y);
            _middle.position = ccp(self.contentSizeInPoints.width, _middle.position.y);
            tanA = (self.contentSizeInPoints.width - _top.position.x) / self.contentSizeInPoints.height;
            angle = atan(tanA) * 180 / M_PI;
            _middle.rotation = - angle;
            break;
            
        default:
            break;
    }
}

@end
