//
//  Tower.m
//  FourDragons
//
//  Created by DAVY UONG on 5/29/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Tower.h"

@implementation Tower

{
    CCNode *_bottomTower;
    CCNode *_topTower;
    
    CGFloat _maximumYPositionBottomTower;
    CGFloat _maximumYPositionTopTower;
}

#define ARC4RANDOM_MAX 0x100000000
static const CGFloat minimumYPositionTopTower = 10.f;
// distance between top and bottom pipe
static const CGFloat pipeDistance = 80.f;

- (void)didLoadFromCCB
{
    _maximumYPositionTopTower = [CCDirector sharedDirector].viewSize.height - 80.f - minimumYPositionTopTower;
    //CCLOG(@"_maximumYPositionBottomTower = %f", _maximumYPositionTopTower);
    [self setupRandomTowerPosition];
}

- (void)setupRandomTowerPosition
{
    // value between 0.f and 1.f
    CGFloat random = ((double)arc4random() / ARC4RANDOM_MAX);
    CGFloat range = _maximumYPositionTopTower - minimumYPositionTopTower;
    //CCLOG(@"range = %f", range);
    CGFloat randomRange = (random * range);
    //CCLOG(@"randomRange = %f", randomRange);
    _topTower.position = ccp(_topTower.position.x, minimumYPositionTopTower + (random * range));
    _bottomTower.position = ccp(_bottomTower.position.x, - _topTower.position.y - pipeDistance);
}


@end


