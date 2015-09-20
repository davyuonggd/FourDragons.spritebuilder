//
//  Coin.m
//  FourDragons
//
//  Created by DAVY UONG on 3/13/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Coin.h"

@implementation Coin

- (void)didLoadFromCCB
{
//    // generate a random number between 0.0 and 2.0
//    float delay = (arc4random() % 2000) / 1000.f;
//    // call method to start animation after random delay
//    [self performSelector:@selector(startCoinRotation) withObject:nil afterDelay:delay];
    self.physicsBody.type = CCPhysicsBodyTypeKinematic;
}

- (void)startCoinRotation
{
    // the animation manager of each node is stored in the 'animationManager' property
    CCAnimationManager* animationManager = self.animationManager;
    // timelines can be referenced and run by name
    [animationManager runAnimationsForSequenceNamed:@"CoinRotation"];
}

@end
