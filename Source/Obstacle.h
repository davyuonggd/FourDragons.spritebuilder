//
//  Obstacle.h
//  FourDragons
//
//  Created by DAVY UONG on 3/11/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "CCNode.h"

@interface Obstacle : CCNode

@property (strong, nonatomic) NSString *typeName;
@property (strong, nonatomic) CCNode *typeNode;

//OBSTACLE'S GENERAL ATTRIBUTES:
@property int upOrDown; //to make the obstacle fly in zigzag
@property CGFloat changeInY;
@property NSTimeInterval sinceLastChangeUpOrDown; //to make the obstacle fly in zigzag
@property NSTimeInterval timeToChangeUpOrDown;
@property CGFloat speed;

- (int)posOrNegOfOne;
- (id)initWithTypeName:(NSString *)typeName;

@end
