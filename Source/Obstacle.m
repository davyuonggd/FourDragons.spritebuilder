//
//  Obstacle.m
//  FourDragons
//
//  Created by DAVY UONG on 3/11/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Obstacle.h"

@implementation Obstacle

- (int)posOrNegOfOne
{
    int zeroOrOne = arc4random_uniform(2);
    switch (zeroOrOne)
    {
        case 0:
            return -1;
            break;
        case 1:
            return 1;
            break;
        default:
            return 1;
            break;
    }
}

- (id)initWithTypeName:(NSString *)typeName
{
    self = [super init];
    if (self)
    {
        self.typeName = typeName;
        self.typeNode = [CCBReader load:typeName];
        self.typeNode.physicsBody.type = CCPhysicsBodyTypeKinematic;
        self.typeNode.physicsBody.sensor = YES;
        
        self.timeToChangeUpOrDown = 2.f;
        self.speed = 1.f;
        self.sinceLastChangeUpOrDown = 0.f;
    }
    return self;
}

@end
