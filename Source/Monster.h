//
//  Monster.h
//  FourDragons
//
//  Created by DAVY UONG on 3/23/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Obstacle.h"

@interface Monster : Obstacle

@property (strong, nonatomic)NSString *abilityName;

//MONSTER'S GENERAL ATTRIBUTES:

//MONSTER'S UNIQUE ATTRIBUTES:
//Red Creature's

- (void)setupMonsterAttributes;

@end
