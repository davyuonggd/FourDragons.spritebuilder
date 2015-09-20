//
//  PowerUp.m
//  FourDragons
//
//  Created by DAVY UONG on 3/23/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "PowerUp.h"

@implementation PowerUp

- (void)setupPowerUpAttributes
{
    self.typeNode.physicsBody.collisionType = self.typeName;
    
    self.upOrDown = [self posOrNegOfOne];
    self.changeInY = 0.4f;
}

@end
