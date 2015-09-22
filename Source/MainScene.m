/*
 Note:
 -----
 Flappy fly settings:
    gravity = -700;
 Steady fly settings:
    gravity = -350;
 
 */

#import "MainScene.h"
#import "Hero.h"
#import "Monster.h"
#import "PowerUp.h"
#import "FireBall.h"

#import "CCPhysics+ObjectiveChipmunk.h" //to access advanced chipmunk properties

@implementation MainScene
{
    //GAME ELEMENTS:
    Hero *_currentHero;
    CCNode *_coinMagnetIndicator;
    CCNode *_invincibleIndicator;
    CCNode *_freezeTimeIndicator;
    
    CCPhysicsNode *_physicsNode;
    CCNode *_ground1;
    CCNode *_ground2;
    CCNode *_roof1;
    CCNode *_roof2;
    NSArray *_grounds;
    
    CCNode *_gravityIndicator;
    CCLabelTTF *_coinLable;
    CCLabelTTF *_scoreLable;
    CCLabelTTF *_transitionLable;
    
    //SCORES:
    int _score;
    NSTimeInterval _timeSinceGameStart;
    int _coins;
    
    //OBSTACLES' VARS:
    NSMutableArray *_obstacles;
    CGFloat _obstacleXPositionBeforePhysicsNodeXIsNegative;
    NSTimeInterval _sinceLastObstacleSpawn;
    NSTimeInterval _timeBetweenObstacles;
    NSTimeInterval _sinceLastPowerUpSpawn;
    
    //MONSTERS' VAR:
    BOOL _isGravityShift;
    
    //COIN'S VARS:
    NSMutableArray *_coinArray;
    NSMutableArray *_coinLayoutArray;
    NSTimeInterval _sinceLastCoinLayoutSpawn;
    NSTimeInterval _timeBetweenCoinLayouts;
    CCProgressNode *coinBar;
    
    //BUTTONS:
    CCButton *_startHeroAbilityButton;
    CCButton *_restartButton;
    CCButton *_summonRandomHero;
    CCButton *_breathFireButton;
    
    //HERO'S VARS:
    CGFloat _heroAcceleration;
    BOOL _heroShouldFlyUp;
    BOOL _heroShouldDash;
    int _posOrNeg;
    NSTimeInterval _heroTimeSinceAbilityPerformed;
    
    //GAME LOGIC VARS:
    CGFloat _scrollSpeed;
}

typedef NS_ENUM(NSInteger, DrawingOrder)
{
    DrawingOrderBackground,
    DrawingOrderObstacle,
    DrawingOrderGround,
    DrawingOrderHero,
};

static const CGFloat NORMAL_SCROLLSPEED = 240.f;
//static const CGFloat DEFAULT_GRAVITY = -400.f;
static const CGFloat HERO_X_POSITION = 100.f;

static const NSTimeInterval HERO_ABILITY_DURATION = 10.f;

- (void)setupCoinBar
{
    CCSprite *movableSprite = [CCSprite spriteWithImageNamed:@"coinBar.png"];
    coinBar = [CCProgressNode progressWithSprite:movableSprite];
    coinBar.type = CCProgressNodeTypeBar;
    coinBar.midpoint = ccp(0,0); // starts from left
    coinBar.barChangeRate = ccp(0,1); // grow only in the "y"-horizontal direction
    coinBar.percentage = 99.f; // (0 - 100)
    coinBar.anchorPoint = ccp(0,0);
    coinBar.position = ccp(1, 1);
    [self addChild:coinBar];
}

- (void)didLoadFromCCB
{
    //GAME'S SETTINGS:
    self.userInteractionEnabled = YES;
    _physicsNode.collisionDelegate = self;
    
    //SCORES' SETTINGS:
    _score = 0;
    _timeSinceGameStart = 0.f;
    _coins = 0;
    [self setupCoinBar];
    
    //OBSTACLES' VARS:
    _obstacles = [NSMutableArray array];
    _obstacleXPositionBeforePhysicsNodeXIsNegative = [CCDirector sharedDirector].viewSizeInPixels.width;
    _sinceLastObstacleSpawn = 0.f;
    _timeBetweenObstacles = 2.5f; //10.f
    
    //POWER_UP'S VARS:
    _sinceLastPowerUpSpawn = 0.f;
    
    //COIN'S VARS:
    _coinArray = [NSMutableArray array];
    _coinLayoutArray = [NSMutableArray array];
    _sinceLastCoinLayoutSpawn = 0.f;
    _timeBetweenCoinLayouts = 2.5f;
    
    //HERO'S SETTINGS:
    //Initial hero
    [self spawnRandomHero];
    [_currentHero setupHero];
    _currentHero.typeNode.zOrder = DrawingOrderHero;
    [_physicsNode addChild:_currentHero.typeNode];
    _currentHero.typeNode.position = ccp(HERO_X_POSITION, 200.f);
    
    //HERO'S VARS:
    _heroAcceleration = 0.f;
    _heroShouldFlyUp = NO;
    _heroShouldDash = NO;
    _posOrNeg = 1;
    
    //GAME LOGIC VARS:
    _scrollSpeed = NORMAL_SCROLLSPEED;
    _score = 0;
    
    //ENVIRONMENT'S SETTINGS:
    _grounds = @[_ground1, _ground2, _roof1, _roof2];
    for (CCNode *ground in _grounds)
    {
        ground.zOrder = DrawingOrderGround;
    }
    
    //TESTING
    _physicsNode.debugDraw = NO;
    [[CCDirector sharedDirector] displayStats];
}

#pragma mark - Testing funcs:

- (void)spawnRandomHero  {
    switch (arc4random_uniform(4)) {
        case 0:
            _currentHero = [[Hero alloc] initWithTypeName:@"AirDragon"];
            break;
        case 1:
            _currentHero = [[Hero alloc] initWithTypeName:@"EarthDragon"];
            break;
        case 2:
            _currentHero = [[Hero alloc] initWithTypeName:@"WaterDragon"];
            break;
        case 3:
            _currentHero = [[Hero alloc] initWithTypeName:@"FireDragon"];
            break;
            
        default:
            _currentHero = [[Hero alloc] initWithTypeName:@"AirDragon"];
            break;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Obstacle's Helper Methods:

//Take a low and a high, return a value between high - low
- (CGFloat)randomFloatBetween:(CGFloat)smallNumber and:(CGFloat)bigNumber {
    CGFloat diff = bigNumber - smallNumber;
    return (((CGFloat) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + smallNumber;
}

- (void)setupObstacleYPosition:(Obstacle *)obstacle
{
    //randomize the y position of the obstacle
    CGFloat obstacleYPosition = [self randomFloatBetween: _ground1.contentSizeInPoints.height and:[CCDirector sharedDirector].viewSize.height - obstacle.typeNode.contentSizeInPoints.height];
    if (_physicsNode.position.x >= 0) //if _physicsNode.position.x is not negative yet
    {
        obstacle.typeNode.position = ccp(_obstacleXPositionBeforePhysicsNodeXIsNegative, obstacleYPosition);
    }
    else
    {
        obstacle.typeNode.position = ccp(_obstacleXPositionBeforePhysicsNodeXIsNegative - _physicsNode.position.x, obstacleYPosition);
    }
}

- (void)setupObstacleSettingsForDuplicateFromOriginal:(NSArray *)monsters
{
    Monster *duplicate = [monsters firstObject];
    Monster *original = [monsters lastObject];
    duplicate.upOrDown = - original.upOrDown;
    duplicate.sinceLastChangeUpOrDown = original.sinceLastChangeUpOrDown;
    duplicate.typeNode.position = ccp(original.typeNode.position.x, original.typeNode.position.y);
    duplicate.typeNode.zOrder = DrawingOrderObstacle;
    [_physicsNode addChild:duplicate.typeNode];
    [_obstacles addObject:duplicate];
    if ([duplicate isKindOfClass:[Monster class]])
    {
        [self startAbilityForMonster:(Monster *)duplicate];
    }
}

- (void)setupObstacleSettingsForObstacle:(Obstacle *)obstacle
{
    //setup Obstacle's position
    if ([obstacle.typeName isEqualToString:@"FireBall"])
    {
        obstacle.typeNode.position = ccp(_currentHero.typeNode.position.x, _currentHero.typeNode.position.y);
    }
    else
    {
        //randomize the y position of the obstacle
        [self setupObstacleYPosition:obstacle];
    }
    
    //obstacle's settings
    obstacle.typeNode.zOrder = DrawingOrderObstacle;
    //add the new obstacle into the moving _physicsNode
    [_physicsNode addChild:obstacle.typeNode];
    [_obstacles addObject:obstacle];
    
    if ([obstacle isKindOfClass:[Monster class]])
    {
        [self startAbilityForMonster:(Monster *)obstacle];
    }
}

- (void)startAbilityForMonster:(Monster *)monster
{
    if ([monster.abilityName isEqualToString:@"GravityShift"])
    {
        _isGravityShift = YES;
        _gravityIndicator.visible = YES;
        if (_physicsNode.gravity.y < 0.f)
        {
            _physicsNode.gravity = ccp(_physicsNode.gravity.x, - _physicsNode.gravity.y);            
        }
        _transitionLable.string = @"Gravity Shift";
        [self stop];
        [self carryOnAfterEvent];
    }
    else if ([monster.abilityName isEqualToString:@"Duplicate"])
    {
        Monster *duplicate = [[Monster alloc] initWithTypeName:@"RedCreature"];
        [duplicate setupMonsterAttributes];
        //[duplicate duplicateFromOriginalMonster:monster];
        //NSArray *parameters = @[duplicate, monster];
        NSArray *parameters = [NSArray arrayWithObjects:duplicate, monster, nil];
        [self performSelector:@selector(setupObstacleSettingsForDuplicateFromOriginal:) withObject:parameters afterDelay:3.0f];
    }
}

- (void)stopAbilityForMonster:(Monster *)monster
{
    if ([monster.abilityName isEqualToString:@"GravityShift"])
    {
        _isGravityShift = NO;
        _gravityIndicator.visible = NO;
        if (_physicsNode.gravity.y > 0.f)
        {
            _physicsNode.gravity = ccp(_physicsNode.gravity.x, - _physicsNode.gravity.y);
        }
    }
}

- (void)spawnSingleCoinAtPoint:(CGPoint)point
{
    CCNode *coin = [CCBReader load:@"Coin"];
    coin.physicsBody.type = CCPhysicsBodyTypeDynamic;
    coin.position = point;
    coin.zOrder = DrawingOrderObstacle;
    
    [_physicsNode addChild:coin];
    [_coinArray addObject:coin];
    
    [coin.physicsBody applyImpulse:ccp([self randomFloatBetween:-25.f and:50.f], [self randomFloatBetween:25.f and:75.f])];
}

static const int NUMBER_OF_OBSTACLE_TYPES = 4;

- (void)spawnNewMonster
{
    Monster *monster;
    switch (arc4random_uniform(NUMBER_OF_OBSTACLE_TYPES))
    {
        case 0:
            if (_isGravityShift == YES)
            {
            }
            else
            {
                monster = [[Monster alloc] initWithTypeName:@"PinkCreature"];
                break;
            }
        case 1:
            monster = [[Monster alloc] initWithTypeName:@"BrownCreature"];
            break;
        case 2:
            monster = [[Monster alloc] initWithTypeName:@"Laser"];
            break;
        case 3:
            monster = [[Monster alloc] initWithTypeName:@"RedCreature"];
            break;
        default:
            monster = [[Monster alloc] initWithTypeName:@"BrownCreature"];
            //monster = [[Monster alloc] initWithTypeName:@"PinkCreature"];
            //monster = [[Monster alloc] initWithTypeName:@"Laser"];
            //monster = [[Monster alloc] initWithTypeName:@"RedCreature"];
            break;
    }
    [monster setupMonsterAttributes];
    [self setupObstacleSettingsForObstacle:monster];
}

- (void)spawnTower
{
    Monster *monster;
    monster = [[Monster alloc] initWithTypeName:@"Tower"];
    [monster setupMonsterAttributes];
    [self setupObstacleSettingsForObstacle:monster];
}

- (void)spawnObstacleOrPowerUp
{
    switch (arc4random_uniform(2)) {
        case 0:
            [self spawnNewMonster];
            break;
        case 1:
            [self spawnNewPowerUp];
            break;
        default:
            [self spawnNewMonster];
            break;
    }
}

- (void)spawnSomething
{
    //TESTING spawnSingleCoin:
    //[self spawnSingleCoinAtPoint:CGPointMake(_currentHero.typeNode.position.x + 350.f, _currentHero.typeNode.position.y)];
    
    //reset time _sinceLastObstacleSpawn
    _sinceLastObstacleSpawn = 0.f;
    switch (arc4random_uniform(4)) {
        case 0:
            [self spawnTower];
            break;
        case 1:
            [self spawnTower];
            break;
        case 2:
            [self spawnObstacleOrPowerUp];
            break;
        case 3:
            [self spawnCoinLayout];
            break;
        default:
            //[self spawnObstacleOrPowerUp];
            break;
    }
}

#pragma mark - PowerUp's Helper Methods:

static const int NUMBER_OF_POWER_UP_TYPES = 5;

- (void)spawnNewPowerUp
{
    _sinceLastPowerUpSpawn = 0.f;
    PowerUp *powerUp;
    switch (arc4random_uniform(NUMBER_OF_POWER_UP_TYPES))
    {
        case 0:
            powerUp = [[PowerUp alloc] initWithTypeName:@"EarthDragonEgg"];
            break;
        case 1:
            powerUp = [[PowerUp alloc] initWithTypeName:@"AirDragonEgg"];
            break;
        case 2:
            powerUp = [[PowerUp alloc] initWithTypeName:@"WaterDragonEgg"];
            break;
        case 3:
            powerUp = [[PowerUp alloc] initWithTypeName:@"FireDragonEgg"];
            break;
        case 4:
            powerUp = [[PowerUp alloc] initWithTypeName:@"DashPowerUp"];
            break;
        default:
            //powerUp = [[PowerUp alloc] initWithTypeName:@"DashPowerUp"];
            break;
    }
    [powerUp setupPowerUpAttributes];
    [self setupObstacleSettingsForObstacle:powerUp];
}

#pragma mark - CoinLayout's Helper Methods:

- (void)spawnCoinLayout
{
    _sinceLastCoinLayoutSpawn = 0.f;
    CCNode *coinLayout = [CCBReader load:@"CoinLayouts/LayoutHi"];
    //randomize the y position of the obstacle
    CGFloat obstacleYPosition = [self randomFloatBetween: _ground1.contentSizeInPoints.height and:[CCDirector sharedDirector].viewSize.height - coinLayout.contentSizeInPoints.height];
    if (_physicsNode.position.x >= 0) //if _physicsNode.position.x is not negative yet
    {
        coinLayout.position = ccp(_obstacleXPositionBeforePhysicsNodeXIsNegative, obstacleYPosition);
    }
    else
    {
        coinLayout.position = ccp(_obstacleXPositionBeforePhysicsNodeXIsNegative - _physicsNode.position.x, obstacleYPosition);
    }
    [_coinLayoutArray addObject:coinLayout];
    [_physicsNode addChild:coinLayout];
}

- (void)calculateCoin
{
    int multiplier = 1;
    if (_currentHero.isMagnet == YES)
    {
        multiplier = 2;
    }
    _coins = _coins + (1 * multiplier);
    if (coinBar.percentage != 100.f)
    {
        coinBar.percentage = coinBar.percentage + (1.f * multiplier);
        
    }
    else if (coinBar.percentage == 100.f)
    {
        _startHeroAbilityButton.visible = YES;
    }
}

#pragma mark - Score's Helper Methods:

- (void)calculateScore:(CCTime)delta
{
    if (_scrollSpeed != 0)
    {
        _timeSinceGameStart = _timeSinceGameStart + delta;
        int distance = _scrollSpeed * _timeSinceGameStart;
        _score = distance/100;
    }
}

#pragma mark - Hero's Helper Methods:

- (void)breathFire
{
    if ([_currentHero.typeName isEqualToString:@"FireDragon"])
    {
        [_currentHero breathFire];
        FireBall *fireBall = [[FireBall alloc] initWithTypeName:@"FireBall"];
        [fireBall setupFireBallAttributes];
        [self setupObstacleSettingsForObstacle:fireBall];
    }
}

- (void)showAbilityIndicatorForHero:(Hero *)hero
{
    if ([hero.abilityName isEqualToString:@"coinMagnet"])
    {
        _coinMagnetIndicator.visible = YES;
    }
    else if ([hero.abilityName isEqualToString:@"invincible"])
    {
        _invincibleIndicator.visible = YES;
    }
    else if ([hero.abilityName isEqualToString:@"freezeTime"])
    {
        _freezeTimeIndicator.visible = YES;
    }
}

- (void)hideHeroAbilityIndicator
{
    _coinMagnetIndicator.visible = NO;
    _invincibleIndicator.visible = NO;
    _freezeTimeIndicator.visible = NO;
}

- (void)cancelHeroFlyUp
{
    _currentHero.acceleration = 0.f;
    _heroShouldFlyUp = NO;
}

- (void)startAbilityForHero:(Hero *)hero
{
    _heroTimeSinceAbilityPerformed = 0.f;
    
    if ([hero.abilityName isEqualToString:@"freezeTime"])
    {
        id scale = [CCActionScaleTo actionWithDuration:0.5f scale:0.75f];
        __unsafe_unretained Hero *weakHero = hero;
        id callBlock = [CCActionCallBlock actionWithBlock:^{
            weakHero.typeNode.scale = 0.75f;
            weakHero.isFreezeTime = YES;
            [weakHero changeShape];
        }];
        [_currentHero.typeNode runAction:[CCActionSequence actions:scale, callBlock, nil]];        
    }
    else if ([hero.abilityName isEqualToString:@"invincible"])
    {
        /*
         + invincible: hero's scale increase and become invincible for a short time
         change scale
         ...
         */
        id scale = [CCActionScaleTo actionWithDuration:0.5f scale:2.0f];
        __unsafe_unretained Hero *weakHero = hero;
        id callBlock = [CCActionCallBlock actionWithBlock:^{
            weakHero.typeNode.scale = 2.0f;
            weakHero.isInvincible = YES;
            [weakHero changeShape];
        }];
        [_currentHero.typeNode runAction:[CCActionSequence actions:scale, callBlock, nil]];
    }
    else if ([hero.abilityName isEqualToString:@"coinMagnet"])
    {
        hero.isMagnet = YES;
    }
    else if ([hero.abilityName isEqualToString:@"breathFire"])
    {
        hero.isBreathingFire = YES;
        _breathFireButton.visible = YES;
    }
    [self showAbilityIndicatorForHero:hero];
}

- (void)stopAbilityForHero:(Hero *)hero
{
    if ([hero.abilityName isEqualToString:@"freezeTime"])
    {
        id scale = [CCActionScaleTo actionWithDuration:0.5f scale:1.0f];
        __unsafe_unretained Hero *weakHero = hero;
        id callBlock = [CCActionCallBlock actionWithBlock:^{
            weakHero.typeNode.scale = 1.0f;
            weakHero.isFreezeTime = NO;
            [weakHero changeShape];
        }];
        [_currentHero.typeNode runAction:[CCActionSequence actions:scale, callBlock, nil]];
    }
    else if ([hero.abilityName isEqualToString:@"invincible"])
    {
        id scale = [CCActionScaleTo actionWithDuration:0.5f scale:1.0f];
        __unsafe_unretained Hero *weakHero = hero;
        id callBlock = [CCActionCallBlock actionWithBlock:^{
            weakHero.typeNode.scale = 1.0f;
            weakHero.isInvincible = NO;
            [weakHero changeShape];
        }];
        [_currentHero.typeNode runAction:[CCActionSequence actions:scale, callBlock, nil]];
    }
    else if ([hero.abilityName isEqualToString:@"coinMagnet"])
    {
        hero.isMagnet = NO;
    }
    else if ([hero.abilityName isEqualToString:@"breathFire"])
    {
        hero.isBreathingFire = NO;
        _breathFireButton.visible = NO;
    }
    [self hideHeroAbilityIndicator];
}

//TESTING
- (void)summonRandomHero
{
    
}

- (void)summonDragonWithEggName:(NSString *)eggName
{
    //before changing hero's type, stop current hero's ability first
    [self stopAbilityForHero:_currentHero];
    
    //change hero's type
    if ([eggName isEqualToString:@"EarthDragonEgg"])
    {
        [_currentHero changeTypeWithTypeName:@"EarthDragon"];
    }
    else if ([eggName isEqualToString:@"AirDragonEgg"])
    {
        [_currentHero changeTypeWithTypeName:@"AirDragon"];
    }
    else if ([eggName isEqualToString:@"WaterDragonEgg"])
    {
        [_currentHero changeTypeWithTypeName:@"WaterDragon"];
    }
    else
    {
        [_currentHero changeTypeWithTypeName:@"FireDragon"];
    }
}

- (void)testHeroAbility
{
    [self startAbilityForHero:_currentHero];
    coinBar.percentage = 0.f;
    _startHeroAbilityButton.visible = NO;
}

- (void)heroStartDashing
{
    //get the name of the dashing animation timeline
    NSString *timelineName = [NSString stringWithFormat:@"%@%@", _currentHero.typeName, @"Dashing"];
    
    //play the dashing animation on the hero
    _heroShouldDash = YES;
    id fadeOut = [CCActionFadeOut actionWithDuration:1.f];
    id fadeIn = [CCActionFadeIn actionWithDuration:1.f];
    __unsafe_unretained Hero *weakCurrentHero = _currentHero;
    id callBlock = [CCActionCallBlock actionWithBlock:^{
        weakCurrentHero.typeNode.scale = 0.38f;
        CCAnimationManager *animationManager = weakCurrentHero.typeNode.animationManager;
        [animationManager runAnimationsForSequenceNamed:timelineName];
    }];
    id scaleBack = [CCActionScaleTo actionWithDuration:1.f scale:1.f];
    [_currentHero.typeNode runAction:[CCActionSequence actions:fadeOut, callBlock, fadeIn, scaleBack, nil]];
    [self shakeScreen];
}

- (void)heroStopDashing
{
    //stop the screen from shaking
    [self stopAllActions];
    
    _heroShouldDash = NO;
    _scrollSpeed = NORMAL_SCROLLSPEED;
    _posOrNeg = 1;
    id fadeOut = [CCActionFadeOut actionWithDuration:1.f];
    id fadeIn = [CCActionFadeIn actionWithDuration:1.f];
    id scaleSmall = [CCActionScaleTo actionWithDuration:1.f scale:0.38f];
    __unsafe_unretained Hero *weakCurrentHero = _currentHero;
    id callBlock = [CCActionCallBlock actionWithBlock:^{
        CCAnimationManager *animationManager = weakCurrentHero.typeNode.animationManager;
        [animationManager runAnimationsForSequenceNamed:weakCurrentHero.typeName];
    }];
    id scaleBack = [CCActionScaleTo actionWithDuration:1.f scale:1.f];
    [_currentHero.typeNode runAction:[CCActionSequence actions:scaleSmall, fadeOut, callBlock, fadeIn, scaleBack, nil]];
}

#pragma mark - Gameplay effects:
- (void)shakeScreen
{
    //shake the screen
    CCActionMoveBy *moveBy = [CCActionMoveBy actionWithDuration:0.2f position:ccp(-10, 10)];
    CCActionInterval *reverseMovement = [moveBy reverse];
    CCActionSequence *shakeSequence = [CCActionSequence actionWithArray:@[moveBy, reverseMovement]];
    id repeatForeverAction = [CCActionRepeatForever actionWithAction:shakeSequence];
    [self runAction:repeatForeverAction]; //shake the screen forever
}

#pragma mark - Touch:

- (void)touchEnded:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    [self cancelHeroFlyUp];
}
- (void)touchCancelled:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    [self cancelHeroFlyUp];
}

- (void)touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    if (_isGravityShift == NO)
    {
        _heroShouldFlyUp = YES;
    }
    else if (_isGravityShift == YES)
    {
        if (_physicsNode.gravity.y < 0.f)
        {
            _physicsNode.gravity = ccp(_physicsNode.gravity.x, - _physicsNode.gravity.y);
            for (CCNode *node in _gravityIndicator.children)
            {
                id flipY = [CCActionFlipY actionWithFlipY:NO];
                [node runAction:flipY];
            }
        }
        else if (_physicsNode.gravity.y > 0.f)
        {
            _physicsNode.gravity = ccp(_physicsNode.gravity.x, - _physicsNode.gravity.y);
            for (CCNode *node in _gravityIndicator.children)
            {
                id flipY = [CCActionFlipY actionWithFlipY:YES];
                [node runAction:flipY];
            }
            
        }
        [_currentHero.typeNode.physicsBody setVelocity:ccp(0, 0)];
    }
    //[audio playEffect:@"touch.mp3"];
//    if (_isGravityShift)
//    {
//        [_currentHero.typeNode.physicsBody applyImpulse:ccp(0, -1 * _currentHero.impulseInY)];
//    }
//    else
//    {
//        [_currentHero.typeNode.physicsBody applyImpulse:ccp(0, _currentHero.impulseInY)];
//    }
}

#pragma mark - Settings, Pause and Resume, Gameover and Restart:

- (void)stop
{
    self.userInteractionEnabled = NO;
    _scrollSpeed = 0;
    //_currentHero.typeNode.physicsBody.affectedByGravity = NO;
    //[_currentHero.typeNode.physicsBody setVelocity:ccp(0, 0)];
    _physicsNode.paused = YES; //pause the physics world
    _transitionLable.visible = YES;
}

- (void)start
{
    self.userInteractionEnabled = YES;
    _scrollSpeed = NORMAL_SCROLLSPEED;
    //_currentHero.typeNode.physicsBody.affectedByGravity = YES;
    _physicsNode.paused = NO;
    _transitionLable.visible = NO;
}

- (void)carryOnAfterEvent
{
    [self performSelector:@selector(start) withObject:nil afterDelay:1.5f];
}

- (void)pause
{
    self.paused = TRUE;
    self.userInteractionEnabled = NO; //no user's touch input when paused
}

- (void)unpause
{
    self.paused = FALSE;
    self.userInteractionEnabled = YES;
}

- (void)restart
{
    CCScene *scene = [CCBReader loadAsScene:@"MainScene"];
    [[CCDirector sharedDirector] replaceScene:scene withTransition:[CCTransition transitionCrossFadeWithDuration:0.5f]];
}

#pragma mark - Collision Detection:

static const CGFloat EXPLOSION_X_OFFSET = 40.f + 20.f;

//fireBall vs monster
- (BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair fireBall:(CCNode *)fireBall monster:(CCNode *)monster
{
    Obstacle *obstacle = [[Obstacle alloc] initWithTypeName:@"Explosion"];
    
    obstacle.typeNode.position = ccp(fireBall.position.x + EXPLOSION_X_OFFSET, fireBall.position.y);
    //obstacle's settings
    obstacle.typeNode.zOrder = DrawingOrderObstacle;
    //add the new obstacle into the moving _physicsNode
    [_physicsNode addChild:obstacle.typeNode];
    [_obstacles addObject:obstacle];
    
    monster.physicsBody.collisionType = @"removed";
    [monster removeFromParentAndCleanup:YES];
    
    return NO;
}

- (BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair fireBall:(CCNode *)fireBall laser:(CCNode *)laser
{
    Obstacle *obstacle = [[Obstacle alloc] initWithTypeName:@"Explosion"];
    
    obstacle.typeNode.position = ccp(fireBall.position.x + EXPLOSION_X_OFFSET, fireBall.position.y);
    //obstacle's settings
    obstacle.typeNode.zOrder = DrawingOrderObstacle;
    //add the new obstacle into the moving _physicsNode
    [_physicsNode addChild:obstacle.typeNode];
    [_obstacles addObject:obstacle];
    
    laser.physicsBody.collisionType = @"removed";
    [laser removeFromParentAndCleanup:YES];
    
    return NO;
}

//fireBall vs coin
- (BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair fireBall:(CCNode *)fireBall coin:(CCNode *)coin
{
    [coin removeFromParentAndCleanup:YES];
    [self calculateCoin];
    return NO;
}


//hero vs coin
- (BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair hero:(CCNode *)hero coin:(CCNode *)coin
{
    //coin.physicsBody.sensor = YES;
    coin.physicsBody.collisionType = @"removed";
    [coin removeFromParentAndCleanup:YES];
    [self calculateCoin];
    return NO;
}

//hero vs powerUps
- (BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair hero:(CCNode *)hero DashPowerUp:(CCNode *)powerUp
{
    powerUp.physicsBody.collisionType = @"removed";
    [powerUp removeFromParentAndCleanup:YES];
    
    [self heroStartDashing];
    return NO;
}

- (void)summonDragonAndStartAbilityWithDragonEgg:(CCNode *)egg
{
    [self summonDragonWithEggName:egg.physicsBody.collisionType];
    egg.physicsBody.collisionType = @"removed";
    [egg removeFromParentAndCleanup:YES];
    
    [self startAbilityForHero:_currentHero];
}

- (BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair hero:(CCNode *)hero EarthDragonEgg:(CCNode *)powerUp
{
    [self summonDragonAndStartAbilityWithDragonEgg:powerUp];
    return NO;
}

- (BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair hero:(CCNode *)hero AirDragonEgg:(CCNode *)powerUp
{
    [self summonDragonAndStartAbilityWithDragonEgg:powerUp];
    return NO;
}

- (BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair hero:(CCNode *)hero WaterDragonEgg:(CCNode *)powerUp
{
    [self summonDragonAndStartAbilityWithDragonEgg:powerUp];
    return NO;
}

- (BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair hero:(CCNode *)hero FireDragonEgg:(CCNode *)powerUp
{
    [self summonDragonAndStartAbilityWithDragonEgg:powerUp];
    return NO;
}

//hero vs enemies
- (BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair hero:(CCNode *)hero laser:(CCNode *)laser
{
    CCLOG(@"hero hit laser!");
    return YES;
}

#pragma mark - Update:

- (void)update:(CCTime)delta
{
    //SCORES:
    _coinLable.string = [NSString stringWithFormat:@"%i", _coins];
    [self calculateScore:delta];
    _scoreLable.string = [NSString stringWithFormat:@"%i", _score];
    
    //stop the hero's ability after HERO_ABILITY_DURATION second
    _heroTimeSinceAbilityPerformed += delta;
    if (_heroTimeSinceAbilityPerformed >= HERO_ABILITY_DURATION)
    {
        [self stopAbilityForHero:_currentHero];
    }
    
    //spawn a new obstacle for every _timeBetweenObstacles sec
    _sinceLastObstacleSpawn += delta;
    if (_sinceLastObstacleSpawn > _timeBetweenObstacles)
    {
        //CCLOG(@"spawned! _sinceLastObstacleSpawn = %f", _sinceLastObstacleSpawn);
        [self spawnSomething];
    }
    
//    //spawn a new coin layout
//    _sinceLastCoinLayoutSpawn += delta;
//    if (_sinceLastCoinLayoutSpawn > _timeBetweenCoinLayouts)
//    {
//        CCLOG(@"_isGravityShift = %i", _isGravityShift);
//        [self spawnCoinLayout];
//    }
    
//    //spawn a new powerUp
//    _sinceLastPowerUpSpawn += delta;
//    if (_sinceLastPowerUpSpawn > _timeBetweenObstacles * 2.5f)
//    {
//        [self spawnNewPowerUp];
//        //CCLOG(@"\n%@\n%@\n%@\n%@",_currentHero.smallShape.collisionType, _currentHero.normalShape.collisionType, _currentHero.largeShape.collisionType, _currentHero.invincibleShape.collisionType);
//    }
    
    //MOVE THE HERO
    _currentHero.typeNode.position = ccp(_currentHero.typeNode.position.x + _scrollSpeed * delta, _currentHero.typeNode.position.y);
    
    
//    if (_isGravityShift)
//    {
//        //clamp velocity of the hero
//        float yVelocity = clampf(_currentHero.typeNode.physicsBody.velocity.y, -1 * MAXFLOAT, _currentHero.yVelocityClamp); //-1 * MAXFLOAT means there is no limit on the falling speed of the hero, and 200.f mean the max velocity of the hero is 200.f
//        _currentHero.typeNode.physicsBody.velocity = ccp(0, - 1 * yVelocity);
//    }
//    else
//    {
//        //clamp velocity of the hero
//        float yVelocity = clampf(_currentHero.typeNode.physicsBody.velocity.y, -1 * MAXFLOAT, _currentHero.yVelocityClamp); //-1 * MAXFLOAT means there is no limit on the falling speed of the hero, and 200.f mean the max velocity of the hero is 200.f
//        _currentHero.typeNode.physicsBody.velocity = ccp(0, yVelocity);
//    }
    
    //clamp velocity of the hero
    float yVelocity = clampf(_currentHero.typeNode.physicsBody.velocity.y, -1 * MAXFLOAT, _currentHero.yVelocityClamp); //-1 * MAXFLOAT means there is no limit on the falling speed of the hero, and 200.f mean the max velocity of the hero is 200.f
    _currentHero.typeNode.physicsBody.velocity = ccp(0, yVelocity);
    
    //make the hero fly up
    if (_heroShouldFlyUp)
    {
//        if (_isGravityShift)
//        {
//            [_currentHero.typeNode.physicsBody applyImpulse:ccp(0, - 1 * _currentHero.acceleration)];
//        }
//        else
//        {
//            [_currentHero.typeNode.physicsBody applyImpulse:ccp(0, _currentHero.acceleration)];
//        }
        [_currentHero.typeNode.physicsBody applyImpulse:ccp(0, _currentHero.acceleration)];
        _currentHero.acceleration += _currentHero.accelerationRate;
        if (_currentHero.acceleration > _currentHero.accelerationMax)
        {
            _currentHero.acceleration = _currentHero.accelerationMax;
        }
    }

    _physicsNode.position = ccp(_physicsNode.position.x - _scrollSpeed * delta, _physicsNode.position.y);
    
    //HERO IS DASHING
    if (_heroShouldDash)
    {
        _scrollSpeed += _posOrNeg * 10.f;
        if (_scrollSpeed > _currentHero.maxSpeed)
        {
            _posOrNeg = -1;
        }
        if (_scrollSpeed < NORMAL_SCROLLSPEED)
        {
            [self heroStopDashing];
        }
    }
    
    //Remove obstacle that leaves the screen
    NSMutableArray *offScreenObstacles = nil;
    if ([_obstacles count])
    {
        for (Obstacle *obstacle in _obstacles)
        {
            if ([obstacle.typeNode.physicsBody.collisionType isEqualToString:@"removed"])
            {
                if (!offScreenObstacles)
                {
                    offScreenObstacles = [NSMutableArray array];
                }
                //stop monster's ability if it's removed from _physicsNode
                if ([obstacle isKindOfClass:[Monster class]])
                {
                    [self stopAbilityForMonster:(Monster *)obstacle];
                }
                [offScreenObstacles addObject:obstacle];
            }
            //make the obstacles that have _upOrDown set fly in a zigzag
            else
            {
                obstacle.sinceLastChangeUpOrDown += delta;
                if (obstacle.sinceLastChangeUpOrDown >= obstacle.timeToChangeUpOrDown)
                {
                    obstacle.upOrDown = obstacle.upOrDown * -1;
                    obstacle.sinceLastChangeUpOrDown = 0.f;
                }
                //stop the obstacle from going under the screen or over the screen
                if ((obstacle.typeNode.position.y < _ground1.contentSizeInPoints.height) || (obstacle.typeNode.position.y > [CCDirector sharedDirector].viewSize.height - obstacle.typeNode.contentSizeInPoints.height))
                {
                    obstacle.upOrDown = obstacle.upOrDown * -1;
                }
                
                if (_currentHero.isFreezeTime == YES)
                {
                    obstacle.typeNode.position = ccp(obstacle.typeNode.position.x - obstacle.speed * delta, obstacle.typeNode.position.y);
                }
                else
                {
                    obstacle.typeNode.position = ccp(obstacle.typeNode.position.x - obstacle.speed * delta, obstacle.typeNode.position.y + obstacle.upOrDown * obstacle.changeInY);
                }
                
                CGPoint obstacleWorldPosition = [_physicsNode convertToWorldSpace:obstacle.typeNode.position];
                CGPoint obstacleScreenPosition = [self convertToNodeSpace:obstacleWorldPosition];
                if ([obstacle.typeName isEqualToString:@"FireBall"])
                {
                    if (obstacleScreenPosition.x >= _physicsNode.contentSizeInPoints.width + obstacle.typeNode.contentSizeInPoints.width)
                    {
                        if (!offScreenObstacles)
                        {
                            offScreenObstacles = [NSMutableArray array];
                        }
                        [offScreenObstacles addObject:obstacle];
                        //CCLOG(@"FireBall removed");
                    }
                }
                else
                {
                    if (obstacleScreenPosition.x < - obstacle.typeNode.contentSize.width)
                    {
                        if (!offScreenObstacles)
                        {
                            offScreenObstacles = [NSMutableArray array];
                        }
                        //stop monster's ability if it's offscreen
                        if ([obstacle isKindOfClass:[Monster class]])
                        {
                            [self stopAbilityForMonster:(Monster *)obstacle];
                        }
                        [offScreenObstacles addObject:obstacle];
                    }
                }
            }
        }
        for (Obstacle *obstacleToRemove in offScreenObstacles)
        {
            [obstacleToRemove.typeNode removeFromParentAndCleanup:YES];//remove the CCNode *
            [_obstacles removeObject:obstacleToRemove];//remove the Obstacle *
            //CCLOG(@"_obstacles cound is: %lu", [_obstacles count]);
            //CCLOG(@"offscreened obstacle removed.");
        }
    }
    
    //Remove coinLayout that leaves the screen:
    NSMutableArray *offScreenCoinLayouts = nil;
    if ([_coinLayoutArray count])
    {
        for (CCNode *coinLayout in _coinLayoutArray)
        {
            //Moving coins to the hero if hero's magnet ability is active
            if (_currentHero.isMagnet == YES)
            {
                CGPoint currentHeroWorldPosition = [_physicsNode convertToWorldSpace:_currentHero.typeNode.position];
                for (CCNode *coin in coinLayout.children)
                {
                    CGPoint coinWorldPosition = [coinLayout convertToWorldSpace:coin.position];
                    if ((coinWorldPosition.x - currentHeroWorldPosition.x <= 250.f) && (currentHeroWorldPosition.x <= coinWorldPosition.x)) //check if the coin is within hero's magnet's range
                    {
                        id move = [CCActionMoveBy actionWithDuration:1.0f position:ccp(currentHeroWorldPosition.x - coinWorldPosition.x ,currentHeroWorldPosition.y - coinWorldPosition.y)];
                        
                        [coin runAction:move];
                        
                        if (fabs(currentHeroWorldPosition.x - coinWorldPosition.x) <= 30.f)
                        {
                            __unsafe_unretained CCNode *weakCoin = coin;
                            id removeCoin = [CCActionCallBlock actionWithBlock:^{
                                [weakCoin removeFromParentAndCleanup:YES];
                                _coins++;
                            }];
                            [coin runAction:removeCoin];
                        }
                    }
                }
            }

            CGPoint coinLayoutWorldPosition = [_physicsNode convertToWorldSpace:coinLayout.position];
            CGPoint coinLayoutScreenPosition = [self convertToNodeSpace:coinLayoutWorldPosition];
            if (coinLayoutScreenPosition.x < - coinLayout.contentSize.width)
            {
                if (!offScreenCoinLayouts)
                {
                    offScreenCoinLayouts = [NSMutableArray array];
                }
                [offScreenCoinLayouts addObject:coinLayout];
            }
        }
        for (CCNode *coinLayout in offScreenCoinLayouts)
        {
            [coinLayout removeFromParentAndCleanup:YES];
            [_coinLayoutArray removeObject:coinLayout];
            //CCLOG(@"offscreened coinLayout removed.");
        }
    }
    
    //Remove coin that leaves the screen:
    NSMutableArray *offScreenCoins = nil;
    if ([_coinArray count])
    {
        for (CCNode *coin in _coinArray)
        {
            if ([coin.physicsBody.collisionType isEqualToString:@"removed"])
            {
                if (!offScreenCoins)
                {
                    offScreenCoins = [NSMutableArray array];
                }
                [offScreenCoins addObject:coin];
            }
            //Moving coins to the hero if hero's magnet ability is active
            CGPoint coinWorldPosition = [_physicsNode convertToWorldSpace:coin.position];
            if (_currentHero.isMagnet == YES)
            {
                CGPoint currentHeroWorldPosition = [_physicsNode convertToWorldSpace:_currentHero.typeNode.position];
                if ((coinWorldPosition.x - currentHeroWorldPosition.x <= 250.f) && (currentHeroWorldPosition.x <= coinWorldPosition.x)) //check if the coin is within hero's magnet's range
                {
                    id move = [CCActionMoveBy actionWithDuration:1.0f position:ccp(currentHeroWorldPosition.x - coinWorldPosition.x ,currentHeroWorldPosition.y - coinWorldPosition.y)];
                    
                    [coin runAction:move];
                    
                    if (fabs(currentHeroWorldPosition.x - coinWorldPosition.x) <= 30.f)
                    {
                        __unsafe_unretained CCNode *weakCoin = coin;
                        id removeCoin = [CCActionCallBlock actionWithBlock:^{
                            [weakCoin removeFromParentAndCleanup:YES];
                            _coins++;
                        }];
                        [coin runAction:removeCoin];
                    }
                }
            }
            CGPoint coinScreenPosition = [self convertToNodeSpace:coinWorldPosition];
            if (coinScreenPosition.x < - coin.contentSize.width)
            {
                if (!offScreenCoins)
                {
                    offScreenCoins = [NSMutableArray array];
                }
                [offScreenCoins addObject:coin];
            }
        }
        for (CCNode *coin in offScreenCoins)
        {
            [coin removeFromParentAndCleanup:YES];
            [_coinArray removeObject:coin];
            //CCLOG(@"offscreen coin removed");
        }
    }
    
    //loop the ground
    for (CCNode *ground in _grounds)
    {
        //get the world position of the ground
        CGPoint groundWorldPosition = [_physicsNode convertToWorldSpace:ground.position];
        //get the screen position of the ground
        CGPoint groundScreenPosition = [self convertToNodeSpace:groundWorldPosition];
        //if left corner of the ground is 1 complete width off screen, move it to the right of the next ground
        if (groundScreenPosition.x <= -1 * ground.contentSizeInPoints.width)
        {
            ground.position = ccp(ground.position.x + (2 * ground.contentSizeInPoints.width) - 2, ground.position.y);
        }
    }
}

@end
