//
//  MainScene.swift
//  FourDragons
//
//  Created by DAVY UONG on 9/16/15.
//  Copyright © 2015 Apportable. All rights reserved.
//

import UIKit

enum DrawingOrder: Int {
    case DrawingOrderBackground = 0
    case DrawingOrderObstacle = 1
    case DrawingOrderGround = 2
    case DrawingOrderHero = 3
}

class MainScene: CCNode, CCPhysicsCollisionDelegate {
    
    //MARK: GAME ELEMENTS:
    var _currentHero: Hero?
    weak var _coinMagnetIndicator: CCSprite!
    weak var _invincibleIndicator: CCSprite!
    weak var _freezeTimeIndicator: CCSprite!
    
    weak var _physicsNode: CCPhysicsNode!
    weak var _ground1: CCSprite!
    weak var _ground2: CCSprite!
    weak var _roof1: CCSprite!
    weak var _roof2: CCSprite!
    var _grounds = [CCSprite]()
    
    weak var _gravityIndicator: CCNode!
    weak var _coinLable: CCLabelTTF!
    weak var _scoreLable: CCLabelTTF!
    weak var _transitionLable: CCLabelTTF!
    
    //MARK: SCORES:
    var _score: Int?
    var _timeSinceGameStart: NSTimeInterval?
    var _coins: Int?
    
    //MARK: OBSTACLES' VARS:
    var _obstacles = [CCNode]()
    var _obstacleXPositionBeforePhysicsNodeXIsNegative: CGFloat?
    var _sinceLastObstacleSpawn: NSTimeInterval?
    var _timeBetweenObstacles: NSTimeInterval?
    var _sinceLastPowerUpSpawn: NSTimeInterval?
    
    //MARK: MONSTERS' VARS:
    var _isGravityShift: Bool?
    
    //MARK: COIN'S VARS:
    var _coinArray = [CCNode]()
    var _coinLayoutArray = [CCNode]()
    var _sinceLastCoinLayoutSpawn: NSTimeInterval?
    var _timeBetweenCoinLayouts: NSTimeInterval?
    var coinBar: CCProgressNode?
    
    //MARK: BUTTONS:
    weak var _startHeroAbilityButton: CCButton!
    weak var _restartButton: CCButton!
    weak var _summonRandomHero: CCButton!
    weak var _breathFireButton: CCButton!
    
    //MARK: HERO'S VARS:
    var _heroAcceleration: CGFloat?
    var _heroShouldFlyUp: Bool?
    var _heroShouldDash: Bool?
    var _posOrNeg: Int?
    var _heroTimeSinceAbilityPerformed: NSTimeInterval?
    
    //MARK: GAME LOGIC VARS:
    var _scrollSpeed: CGFloat?
    
    func setupCoinBar() {
        let movableSprite = CCSprite.spriteWithImageNamed("coinBar.png") as! CCSprite
        coinBar = CCProgressNode.progressWithSprite(movableSprite)
        coinBar?.type = CCProgressNodeType.Bar
        coinBar?.midpoint = ccp(0,0); // starts from left
        coinBar?.barChangeRate = ccp(0,1); // grow only in the "y"-horizontal direction
        coinBar?.percentage = 99; // (0 - 100)
        coinBar?.anchorPoint = ccp(0,0);
        coinBar?.position = ccp(1, 1);
        
        self.addChild(coinBar!)
    }
    
    //MARK: TESTING FUNCS:
    func spawnRandomHero() {
        switch arc4random_uniform(4) {
        case 0:
            _currentHero = Hero.init(typeName: "AirDragon")
        case 1:
            _currentHero = Hero.init(typeName: "EarthDragon")
        case 2:
            _currentHero = Hero.init(typeName: "WaterDragon")
        case 3:
            _currentHero = Hero.init(typeName: "FireDragon")
        default:
            _currentHero = Hero.init(typeName: "AirDragon")
        }
    }
    
    func spawnSingleCoinAtPoint(point: CGPoint) {
        let coin = CCBReader.load("Coin")
        coin.physicsBody.type = CCPhysicsBodyType.Dynamic
        coin.position = point
        coin.zOrder = DrawingOrder.DrawingOrderObstacle.rawValue
        
        _physicsNode.addChild(coin)
        _coinArray.append(coin)
        
        coin.physicsBody.applyImpulse(ccp(randomBetweenNumbers(-25, secondNum: 50), randomBetweenNumbers(25, secondNum: 75)))
    }
    
    //MARK: SCENE'S SETUP
    func didLoadFromCCB() {
        //MARK: GAME'S SETTINGS:
        self.userInteractionEnabled = true
        _physicsNode.collisionDelegate = self
        
        //MARK: SCORES' SETTINGS:
        _score = 0
        _timeSinceGameStart = 0
        _coins = 0
        setupCoinBar()
        
        //MARK: OBSTACLES' SETTINGS:
        _obstacleXPositionBeforePhysicsNodeXIsNegative = CCDirector.sharedDirector().viewSizeInPixels().width
        _sinceLastObstacleSpawn = 0
        _timeBetweenObstacles = 2.5 //10
        
        //MARK: POWER_UP'S SETTINGS:
        _sinceLastPowerUpSpawn = 0
        
        //MARK: COIN'S SETTINGS:
        _sinceLastCoinLayoutSpawn = 0
        _timeBetweenCoinLayouts = 2.5
        
        //HERO'S SETTINGS:
        //initial hero
        spawnRandomHero()
        _currentHero?.setupHero()
        _currentHero?.typeNode.zOrder = DrawingOrder.DrawingOrderHero.rawValue
        _physicsNode.addChild(_currentHero?.typeNode!)
        _currentHero?.typeNode.position = ccp(HERO_X_POSITION, HERO_Y_POSITION)
        
        _heroAcceleration = 0
        _heroShouldFlyUp = false
        _heroShouldDash = false
        _posOrNeg = 1
        _heroTimeSinceAbilityPerformed = 0
        
        //MARK: GAME LOGIC'S SETTINGS:
        _scrollSpeed = NORMAL_SCROLLSPEED
        _score = 0
        
        //MARK: ENVIRONMENT'S SETTINGS:
        _grounds = [_ground1, _ground2, _roof1, _roof2]
        for ground in _grounds {
            ground.zOrder = DrawingOrder.DrawingOrderGround.rawValue
        }
        
        //MARK: TESTING'S SETTINGS:
        _physicsNode.debugDraw = false
        CCDirector.sharedDirector().displayStats = true
    }
    
    func setupObstacleYPosition(obstacle: Obstacle) {
        //randomize the y position of the obstacle
        let obstacleYPosition = randomBetweenNumbers(_ground1.contentSizeInPoints.height, secondNum: CCDirector.sharedDirector().viewSize().height - obstacle.typeNode.contentSizeInPoints.height)
        
        if (_physicsNode.position.x >= 0) //if _physicsNode.position.x is not negative yet
        {
            obstacle.typeNode.position = ccp(_obstacleXPositionBeforePhysicsNodeXIsNegative!, obstacleYPosition)
        }
        else {
            obstacle.typeNode.position = ccp(_obstacleXPositionBeforePhysicsNodeXIsNegative! - _physicsNode.position.x, obstacleYPosition)
        }
    }
    
    func setupObstacleSettingsForObstacle(obstacle: Obstacle) {
        //setup obstacle's position
        if (obstacle.typeName == "FireBall") {
            obstacle.typeNode.position = ccp(_currentHero!.typeNode.position.x, _currentHero!.typeNode.position.y);
        }
        else
        {
            setupObstacleYPosition(obstacle)
        }
        //obstacle's settings
        obstacle.typeNode.zOrder = DrawingOrder.DrawingOrderObstacle.rawValue
        //add the new obstacle into the moving _physicsNode
        _physicsNode.addChild(obstacle.typeNode)
        _obstacles.append(obstacle)
        
        if (obstacle is Monster) {
            startAbilityForMonster(obstacle as! Monster)
        }
    }
    
    func startAbilityForMonster(monster: Monster) {
        if (monster.abilityName == "GravityShift") {
//            _isGravityShift = true
//            _gravityIndicator.visible = true
//            if (_physicsNode.gravity.y < 0) {
//                _physicsNode.gravity = ccp(_physicsNode.gravity.x, -_physicsNode.gravity.y)
//            }
//            _transitionLable.string = "Gravity Shift"
//            stop()
//            carryOnAfterEvent()
        }
        else if (monster.abilityName == "Duplicate") {
            let duplicate = Monster.init(typeName: "RedCreature")
            duplicate
        }
    }
    
    func stopAbilityForMonster(monster: Monster) {
        if (monster.abilityName == "GravityShift") {
            _isGravityShift = false
            _gravityIndicator.visible = false
            if (_physicsNode.gravity.y > 0) {
                _physicsNode.gravity = ccp(_physicsNode.gravity.x, -_physicsNode.gravity.y)
            }
        }
    }
    
    func setupObstacleSettingsForDuplicateFromOriginal(monsters: [Monster]) {
        let duplicate = monsters.first
        let original = monsters.last
        duplicate?.upOrDown = (original?.upOrDown)! * -1
        duplicate?.sinceLastChangeUpOrDown = (original?.sinceLastChangeUpOrDown)!
        duplicate?.typeNode.position = ccp((original?.typeNode.position.x)!, (original?.typeNode.position.y)!)
        duplicate?.typeNode.zOrder = DrawingOrder.DrawingOrderObstacle.rawValue
        _physicsNode.addChild(duplicate?.typeNode!)
        _obstacles.append(duplicate!)
        startAbilityForMonster(duplicate!)
    }
    
    //MARK: SPAWNING FUNCS:
    func spawnNewMonster() {
        var monster: Monster!
        
        switch (arc4random_uniform(NUMBER_OF_OBSTACLE_TYPES))
        {
        case 0:
            if _isGravityShift == true {}
            else {
                monster = Monster.init(typeName: "PinkCreature")
                break
            }
        case 1:
            monster = Monster.init(typeName: "BrownCreature")
            break
        case 2:
            monster = Monster.init(typeName: "Laser")
            break
        case 3:
            monster = Monster.init(typeName: "RedCreature")
            break
        default:
            monster = Monster.init(typeName: "BrownCreature")
            break
        }
        monster.setupMonsterAttributes()
        setupObstacleSettingsForObstacle(monster)
    }
    
    func spawnTower() {
        let monster = Monster.init(typeName: "Tower")
        monster.setupMonsterAttributes()
        setupObstacleSettingsForObstacle(monster)
    }
    
    func spawnNewPowerUp() {
        _sinceLastPowerUpSpawn = 0
        var powerUp: PowerUp!
        switch (arc4random_uniform(NUMBER_OF_POWER_UP_TYPES)) {
        case 0:
            powerUp = PowerUp.init(typeName: "EarthDragonEgg")
            break
        case 1:
            powerUp = PowerUp.init(typeName: "AirDragonEgg")
            break
        case 2:
            powerUp = PowerUp.init(typeName: "WaterDragonEgg")
            break
        case 3:
            powerUp = PowerUp.init(typeName: "FireDragonEgg")
            break
        case 4:
            powerUp = PowerUp.init(typeName: "DashPowerUp")
            break
        default:
            break
        }
        powerUp.setupPowerUpAttributes()
        setupObstacleSettingsForObstacle(powerUp)
    }
    
    func spawnObstacleOrPowerUp() {
        switch (arc4random_uniform(2)) {
        case 0:
            spawnNewMonster()
            break;
        case 1:
            spawnNewPowerUp()
            break;
        default:
            spawnNewMonster()
            break;
        }
    }
    
    func spawnCoinLayout() {
        _sinceLastCoinLayoutSpawn = 0
        let coinLayout = CCBReader.load("CoinLayouts/LayoutHi")
        //randomize the y position of the coinLayout
        let obstacleYPosition = randomBetweenNumbers(_ground1.contentSizeInPoints.height, secondNum: CCDirector.sharedDirector().viewSize().height - coinLayout.contentSizeInPoints.height)
        if (_physicsNode.position.x >= 0) {
            coinLayout.position = ccp(_obstacleXPositionBeforePhysicsNodeXIsNegative!, obstacleYPosition)
        }
        else {
            coinLayout.position = ccp(_obstacleXPositionBeforePhysicsNodeXIsNegative! - _physicsNode.position.x, obstacleYPosition);
        }
        _coinLayoutArray.append(coinLayout)
        _physicsNode.addChild(coinLayout)
    }
    
    func spawnSomething() {
        //TESTING spawnSingleCoin:
        spawnSingleCoinAtPoint(CGPointMake((_currentHero?.typeNode.position.x)!, (_currentHero?.typeNode.position.y)!))
        //reset time _sinceLastObstacleSpawn
        _sinceLastObstacleSpawn = 0;
        switch (arc4random_uniform(4)) {
        case 0:
            spawnTower()
            break;
        case 1:
            spawnTower()
            break;
        case 2:
            spawnObstacleOrPowerUp()
            break;
        case 3:
            spawnCoinLayout()
            break;
        default:
            //[self spawnObstacleOrPowerUp];
            break;
        }
    }
    
    //MARK: SCORE and COINS
    func calculateCoin() {
        var multiplier = 1
        if (_currentHero?.isMagnet == true) {
            multiplier = 2
        }
        _coins = _coins! + multiplier
        if (coinBar?.percentage != 100) {
            coinBar?.percentage = (coinBar?.percentage)! + Float(multiplier)
        }
        else {
            _startHeroAbilityButton.visible = true
        }
    }
    func calculateScore(delta: CCTime) {
        if (_scrollSpeed != 0) {
            _timeSinceGameStart = _timeSinceGameStart! + delta
            let distance = _scrollSpeed! * CGFloat(_timeSinceGameStart!)
            _score = Int(distance/100)
        }
    }
    
    //MARK: HERO'S FUNCS
    func breathFire() {
        if (_currentHero?.typeName == "FireDragon") {
            _currentHero?.breathFire() //this is a func that belongs to Hero's model
            let fireBall = FireBall.init(typeName: "FireBall")
            fireBall.setupFireBallAttributes()
            setupObstacleSettingsForObstacle(fireBall)
        }
    }
    
    func showAbilityIndicatorForHero(hero: Hero) {
        if (hero.abilityName == "coinMagnet")
        {
            _coinMagnetIndicator.visible = true;
        }
        else if (hero.abilityName == "invincible")
        {
            _invincibleIndicator.visible = true;
        }
        else if (hero.abilityName == "freezeTime")
        {
            _freezeTimeIndicator.visible = true;
        }
    }
    
    func hideHeroAbilityIndicator() {
        _coinMagnetIndicator.visible = false;
        _invincibleIndicator.visible = false;
        _freezeTimeIndicator.visible = false;
    }
    
    func cancelHeroFlyUp() {
        _currentHero?.acceleration = 0
        _heroShouldFlyUp = false
    }
    
    func startAbilityForHero(hero: Hero) {
        _heroTimeSinceAbilityPerformed = 0
        if (hero.abilityName == "freezeTime") {
            let scale = CCActionScaleTo.actionWithDuration(0.5, scale: 0.75)
            let callBlock = CCActionCallBlock.actionWithBlock({ [unowned self] () -> Void in
                self._currentHero?.typeNode.scale = 0.75
                hero.isFreezeTime = true
                hero.changeShape()
            })
            let sequence = CCActionSequence.actionWithArray([scale, callBlock]) as! CCAction
            _currentHero?.typeNode.runAction(sequence)
        }
        else if (hero.abilityName == "invincible") {
            let scale = CCActionScaleTo.actionWithDuration(0.5, scale: 2.0)
            let callBlock = CCActionCallBlock.actionWithBlock({ [unowned self] () -> Void in
                self._currentHero?.typeNode.scale = 2.0
                hero.isInvincible = true
                hero.changeShape()
            })
            let sequence = CCActionSequence.actionWithArray([scale, callBlock]) as! CCAction
            _currentHero?.typeNode.runAction(sequence)
        }
        else if (hero.abilityName == "coinMagnet") {
            hero.isMagnet = true
        }
        else if (hero.abilityName == "breathFire") {
            hero.isBreathingFire = true
            _breathFireButton.visible = true
        }
        showAbilityIndicatorForHero(hero)
    }
    
    func stopAbilityForHero(hero: Hero) {
        if (hero.abilityName == "freezeTime") {
            let scale = CCActionScaleTo .actionWithDuration(0.5, scale: 1.0)
            let callBlock = CCActionCallBlock.actionWithBlock({ [unowned self] () -> Void in
                self._currentHero?.typeNode.scale = 1.0
                hero.isFreezeTime = false
                hero.changeShape()
            })
            let sequence = CCActionSequence.actionWithArray([scale, callBlock]) as! CCAction
            _currentHero?.typeNode.runAction(sequence)
        }
        else if (hero.abilityName == "invincible") {
            let scale = CCActionScaleTo .actionWithDuration(0.5, scale: 1.0)
            let callBlock = CCActionCallBlock.actionWithBlock({ [unowned self] () -> Void in
                self._currentHero?.typeNode.scale = 1.0
                hero.isInvincible = false
                hero.changeShape()
                })
            let sequence = CCActionSequence.actionWithArray([scale, callBlock]) as! CCAction
            _currentHero?.typeNode.runAction(sequence)
        }
        else if (hero.abilityName == "coinMagnet") {
            hero.isMagnet = false
        }
        else if (hero.abilityName == "breathFire") {
            hero.isBreathingFire = false
            _breathFireButton.visible = false
        }
        hideHeroAbilityIndicator()
    }
    
    func summonDragonWithEggName(eggName: String) {
        //before changing hero's type, stop current hero's ability first
        stopAbilityForHero(_currentHero!)
        
        //change hero's type
        if (eggName == "EarthDragonEgg") {
            _currentHero?.changeTypeWithTypeName("EarthDragon")
        }
        else if (eggName == "AirDragonEgg") {
            _currentHero?.changeTypeWithTypeName("AirDragon")
        }
        else if (eggName == "WaterDragonEgg") {
            _currentHero?.changeTypeWithTypeName("WaterDragon")
        }
        else if (eggName == "FireDragonEgg") {
            _currentHero?.changeTypeWithTypeName("FireDragon")
        }
    }
    
    func summonDragonAndStartAbilityWithDragonEgg(egg: CCNode) {
        summonDragonWithEggName(egg.physicsBody.collisionType)
        egg.physicsBody.collisionType = "removed"
        egg.removeFromParentAndCleanup(true)
        startAbilityForHero(_currentHero!)
    }
    
    func testHeroAbility() {
        
    }
    
    func heroStartDashing() {
        //get the name of the dashing animation timeline
        let timelineName = (_currentHero?.typeName)! + "Dashing"
        //play the dashing animation on the hero
        _heroShouldDash = true
        let fadeOut = CCActionFadeOut.actionWithDuration(1)
        let fadeIn = CCActionFadeIn.actionWithDuration(1)
        let callBlock = CCActionCallBlock.actionWithBlock { [unowned self] () -> Void in
            self._currentHero?.typeNode.scale = 0.38
            let animationManager = self._currentHero?.typeNode.animationManager
            animationManager?.runAnimationsForSequenceNamed(timelineName)
        }
        let scaleBack = CCActionScaleTo.actionWithDuration(1, scale: 1)
        let sequence = CCActionSequence.actionWithArray([fadeOut, callBlock, fadeIn, scaleBack]) as! CCAction
        _currentHero?.typeNode.runAction(sequence)
        shakeScreen()
    }
    
    func heroStopDashing() {
        //stop the screen from shaking
        self.stopAllActions()
        _heroShouldDash = false
        _scrollSpeed = NORMAL_SCROLLSPEED
        _posOrNeg = 1
        let fadeOut = CCActionFadeOut.actionWithDuration(1)
        let fadeIn = CCActionFadeIn.actionWithDuration(1)
        let scaleSmall = CCActionScaleTo.actionWithDuration(1, scale: 0.38)
        let callBlock = CCActionCallBlock.actionWithBlock { [unowned self] () -> Void in
            let animationManager = self._currentHero?.typeNode.animationManager
            animationManager?.runAnimationsForSequenceNamed(self._currentHero?.typeName)
        }
        let scaleBack = CCActionScaleTo.actionWithDuration(1, scale: 1)
        let sequence = CCActionSequence.actionWithArray([scaleSmall, fadeOut, callBlock, fadeIn, scaleBack])
        self._currentHero?.runAction(sequence as! CCAction)
    }
    
    //MARK: GAMEPLAY EFFECTS:
    func shakeScreen() {
        let moveBy = CCActionMoveBy.actionWithDuration(0.2, position: ccp(-10, 10))
        let reverseMovement = (moveBy as! CCActionInterval).reverse()
        let sequence = CCActionSequence.actionWithArray([moveBy, reverseMovement])
        let repeatForeverAction = CCActionRepeatForever.actionWithAction(sequence as! CCActionInterval)
        self.runAction(repeatForeverAction as! CCAction)
    }
    
    //MARK: TOUCH:
    override func touchEnded(touch: CCTouch!, withEvent event: CCTouchEvent!) {
        cancelHeroFlyUp()
    }
    
    override func touchCancelled(touch: CCTouch!, withEvent event: CCTouchEvent!) {
        cancelHeroFlyUp()
    }
    
    override func touchBegan(touch: CCTouch!, withEvent event: CCTouchEvent!) {
        if (_isGravityShift == false) {
            _heroShouldFlyUp = true
        }
        else if (_isGravityShift == true) {
            if (_physicsNode.gravity.y < 0) {
                _physicsNode.gravity = ccp(_physicsNode.gravity.x, _physicsNode.gravity.y * -1)
                for node in _gravityIndicator.children {
                    let flipY = CCActionFlipY.actionWithFlipY(false)
                    (node as! CCNode).runAction(flipY as! CCAction)
                }
            }
            else {
                _physicsNode.gravity = ccp(_physicsNode.gravity.x, _physicsNode.gravity.y * -1)
                for node in _gravityIndicator.children {
                    let flipY = CCActionFlipY.actionWithFlipY(true)
                    (node as! CCNode).runAction(flipY as! CCAction)
                }
            }
            _currentHero?.typeNode.physicsBody.velocity = ccp(0,0)
        }
    }
    
    //MARK: SETTIGNS, PAUSE and RESUME, GAMEOVER and RESTART:
    func stop() {
        userInteractionEnabled = false
        _scrollSpeed = 0
        _physicsNode.paused = true
        _transitionLable.visible = true
    }
    func start() {
        userInteractionEnabled = true
        _scrollSpeed = NORMAL_SCROLLSPEED
        _physicsNode.paused = false
        _transitionLable.visible = false
    }
    func carryOnAfterEvent() {
        self.performSelector(Selector(start()), withObject: nil, afterDelay: 1.5)
    }
    func pause() {
        self.paused = true
        userInteractionEnabled = false
    }
    func unpause(){
        self.paused = false
        userInteractionEnabled = true
    }
    func restart() {
        let scene = CCBReader.loadAsScene("MainScene")
        CCDirector.sharedDirector().replaceScene(scene, withTransition: CCTransition(crossFadeWithDuration: 0.5))
    }
    
    //MARK: COLLISION DETECTION:
    //fireBall vs monster
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, fireBall: CCNode!, monster: CCNode!) -> Bool {
        let obstacle = Obstacle.init(typeName: "Explosion")
        obstacle.typeNode.position = ccp(fireBall.position.x + EXPLOSION_X_OFFSET, fireBall.position.y)
        obstacle.typeNode.zOrder = DrawingOrder.DrawingOrderObstacle.rawValue
        _physicsNode.addChild(obstacle.typeNode)
        _obstacles.append(obstacle)
        
        monster.physicsBody.collisionType = "removed"
        monster.removeFromParentAndCleanup(true)
        
        return false
    }
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, fireBall: CCNode!, laser: CCNode!) -> Bool {
        let obstacle = Obstacle.init(typeName: "Explosion")
        obstacle.typeNode.position = ccp(fireBall.position.x + EXPLOSION_X_OFFSET, fireBall.position.y)
        obstacle.typeNode.zOrder = DrawingOrder.DrawingOrderObstacle.rawValue
        _physicsNode.addChild(obstacle.typeNode)
        _obstacles.append(obstacle)
        
        laser.physicsBody.collisionType = "removed"
        laser.removeFromParentAndCleanup(true)
        
        return false
    }
    
    //fireBall vs coin
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, fireBall: CCNode!, coin: CCNode!) -> Bool {
        coin.physicsBody.collisionType = "removed"
        coin.removeFromParentAndCleanup(true)
        calculateCoin()
        return false
    }
    
    //hero vs coin
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero: CCNode!, coin: CCNode!) -> Bool {
        coin.physicsBody.collisionType = "removed"
        coin.removeFromParentAndCleanup(true)
        calculateCoin()
        return false
    }
    //hero vs powerUps
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero: CCNode!, DashPowerUp: CCNode!) -> Bool {
        DashPowerUp.physicsBody.collisionType = "removed"
        DashPowerUp.removeFromParentAndCleanup(true)
        heroStartDashing()
        return false
    }
    //hero vs eggs
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero: CCNode!, EarthDragonEgg: CCNode!) -> Bool {
        summonDragonAndStartAbilityWithDragonEgg(EarthDragonEgg)
        return false
    }
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero: CCNode!, AirDragonEgg: CCNode!) -> Bool {
        summonDragonAndStartAbilityWithDragonEgg(AirDragonEgg)
        return false
    }
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero: CCNode!, WaterDragonEgg: CCNode!) -> Bool {
        summonDragonAndStartAbilityWithDragonEgg(WaterDragonEgg)
        return false
    }
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero: CCNode!, FireDragonEgg: CCNode!) -> Bool {
        summonDragonAndStartAbilityWithDragonEgg(FireDragonEgg)
        return false
    }
    //hero vs enemies
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero: CCNode!, laser: CCNode!) -> Bool {
        print("\nhero hit laser!")
        return false
    }
    
    //MARK: UPDATE:
    override func update(delta: CCTime) {
        //SCORES:
        _coinLable.string = "\(_coins)"
        calculateScore(delta)
        _scoreLable.string = "\(_score)"
        
        //stop the hero's ability after HERO_ABILITY_DURATION second
        _heroTimeSinceAbilityPerformed! += NSTimeInterval(delta)
        if (_heroTimeSinceAbilityPerformed >= HERO_ABILITY_DURATION) {
            stopAbilityForHero(_currentHero!)
        }
        
        //spawn a new obstacle for every _timeBetweenObstacles sec
        _sinceLastObstacleSpawn! += NSTimeInterval(delta)
        if (_sinceLastObstacleSpawn > _timeBetweenObstacles) {
            spawnSomething()
        }
        
        //MOVE THE HERO
        _currentHero?.typeNode.position = ccp((_currentHero?.typeNode.position.x)! + _scrollSpeed! * CGFloat(delta), (_currentHero?.typeNode.position.y)!)
        
        //clamp velocity of the hero
        let yVelocity = clampf(Float((_currentHero?.typeNode.physicsBody.velocity.y)!), -1 * MAXFLOAT, Float((_currentHero?.yVelocityClamp)!)) //-1 * MAXFLOAT means there is no limit on the falling speed of the hero, and 200.f mean the max velocity of the hero is 200.f
        _currentHero?.typeNode.physicsBody.velocity = ccp(0, CGFloat(yVelocity))
        
        //make the hero fly up
        if (_heroShouldFlyUp == true) {
            _currentHero?.typeNode.physicsBody.applyImpulse(ccp(0, (_currentHero?.acceleration)!))
            _currentHero?.acceleration += (_currentHero?.accelerationRate)!
            if (_currentHero?.acceleration > _currentHero?.accelerationMax) {
                _currentHero?.acceleration = (_currentHero?.accelerationMax)!
            }
        }
        
        _physicsNode.position = ccp(_physicsNode.position.x - _scrollSpeed! * CGFloat(delta), _physicsNode.position.y)
        
        //HERO IS DASHING
        if (_heroShouldDash == true) {
            _scrollSpeed! += CGFloat(_posOrNeg!) * 10
            if (_scrollSpeed > _currentHero?.maxSpeed) {
                _posOrNeg = -1
            }
            if (_scrollSpeed < NORMAL_SCROLLSPEED) {
                heroStopDashing()
            }
        }
        
        //remove obstacle that leaves the screen
        var offScreenObstacles: [Obstacle]? = nil
        if (_obstacles.count != 0) {
            for obstacle in _obstacles as! [Obstacle] {
                if obstacle.typeNode.physicsBody.collisionType == "removed" {
                    if (offScreenObstacles == nil) {
                        offScreenObstacles = [Obstacle]()
                    }
                    //stop monster's ability if it's removed from _physicsNode
                    if (obstacle is Monster) {
                        stopAbilityForMonster(obstacle as! Monster)
                    }
                    offScreenObstacles?.append(obstacle)
                }
                //make the obstacles that have _upOrDown set fly in a zigzag
                else {
                    obstacle.sinceLastChangeUpOrDown += delta
                    if (obstacle.sinceLastChangeUpOrDown >= obstacle.timeToChangeUpOrDown) {
                        obstacle.upOrDown = obstacle.upOrDown * -1
                        obstacle.sinceLastChangeUpOrDown = 0
                    }
                    //stop the obstacle from going under the screen or over the screen
                    if (obstacle.typeNode.position.y < _ground1.contentSizeInPoints.height || obstacle.typeNode.position.y > CCDirector.sharedDirector().viewSize().height - obstacle.typeNode.contentSizeInPoints.height) {
                        obstacle.upOrDown = obstacle.upOrDown * -1
                    }
                    if (_currentHero?.isFreezeTime == true) {
                        obstacle.typeNode.position = ccp(obstacle.typeNode.position.x - obstacle.speed * CGFloat(delta), obstacle.typeNode.position.y)
                    }
                    else {
                        obstacle.typeNode.position = ccp(obstacle.typeNode.position.x - obstacle.speed * CGFloat(delta), obstacle.typeNode.position.y + CGFloat(obstacle.upOrDown) * obstacle.changeInY);
                    }
                    let obstacleWorldPosition = _physicsNode.convertToWorldSpace(obstacle.typeNode.position)
                    let obstacleScreenPosition = self.convertToNodeSpace(obstacleWorldPosition)
                    if (obstacle.typeName == "FireBall") {
                        if (obstacleScreenPosition.x >= _physicsNode.contentSizeInPoints.width + obstacle.typeNode.contentSizeInPoints.width) {
                            if (offScreenObstacles == nil) {
                                offScreenObstacles = [Obstacle]()
                            }
                            offScreenObstacles?.append(obstacle)
                        }
                    }
                    else {
                        if (obstacleScreenPosition.x < obstacle.typeNode.contentSize.width * -1) {
                            if (offScreenObstacles == nil) {
                                offScreenObstacles = [Obstacle]()
                            }
                            //stop monster's ability if it's offscreen
                            if (obstacle is Monster) {
                                stopAbilityForMonster(obstacle as! Monster)
                            }
                            offScreenObstacles?.append(obstacle)
                        }
                    }
                }
            }
            for obstacleToRemove in offScreenObstacles! {
                obstacleToRemove.typeNode.removeFromParentAndCleanup(true)
                _obstacles.removeAtIndex(_obstacles.indexOf(obstacleToRemove as CCNode)!)
            }
        }
        var offScreenCoinLayouts: [CCNode]? = nil
        if (_coinLayoutArray.count != 0) {
            for coinLayout in _coinLayoutArray {
                //Moving coins to the hero if hero's magnet ability is active
                if (_currentHero?.isMagnet == true) {
                    let currentHeroWorldPosition = _physicsNode.convertToWorldSpace((_currentHero?.typeNode.position)!)
                    for coin in coinLayout.children {
                        let coinWorldPosition = coinLayout.convertToWorldSpace(coin.position)
                        //check if the coin is within hero's magnet's range
                        if (coinWorldPosition.x - currentHeroWorldPosition.x <= 250 && currentHeroWorldPosition.x <= coinWorldPosition.x) {
                            let move = CCActionMoveBy.actionWithDuration(1, position: ccp(currentHeroWorldPosition.x - coinWorldPosition.x, currentHeroWorldPosition.y - coinWorldPosition.y))
                            coin.runAction(move as! CCAction)
                            if (fabs(currentHeroWorldPosition.x - coinWorldPosition.x) <= 30) {
                                let removeCoin = CCActionCallBlock.actionWithBlock({ [unowned coin, unowned self] () -> Void in
                                    coin.removeFromParentAndCleanup(true)
                                    self._coins!++
                                })
                                coin.runAction(removeCoin as! CCAction)
                            }
                        }
                    }
                }
                let coinLayoutWorldPosition = _physicsNode.convertToWorldSpace(coinLayout.position)
                let coinLayoutScreenPosition = self.convertToNodeSpaceAR(coinLayoutWorldPosition)
                if (coinLayoutScreenPosition.x < coinLayout.contentSize.width * -1) {
                    if (offScreenCoinLayouts == nil) {
                        offScreenCoinLayouts = [CCNode]()
                    }
                    offScreenCoinLayouts?.append(coinLayout)
                }
            }
            for coinLayoutToRemove in offScreenCoinLayouts! {
                coinLayoutToRemove.removeFromParentAndCleanup(true)
                _coinLayoutArray.removeAtIndex(_coinLayoutArray.indexOf(coinLayoutToRemove)!)
            }
        }
        var offScreenCoins: [CCNode]? = nil
        if _coinArray.count != 0 {
            for coin in _coinArray {
                if coin.physicsBody.collisionType == "removed" {
                    if offScreenCoins == nil {
                        offScreenCoins = [CCNode]()
                    }
                    offScreenCoins?.append(coin)
                }
                //Moving coins to the hero if hero's magnet ability is active
                let coinWorldPosition = _physicsNode.convertToWorldSpace(coin.position)
                if _currentHero?.isMagnet == true {
                    let currentHeroWorldPosition = _physicsNode.convertToWorldSpace((_currentHero?.typeNode.position)!)
                    if (coinWorldPosition.x - currentHeroWorldPosition.x <= 250 && currentHeroWorldPosition.x <= coinWorldPosition.x) {
                        let move = CCActionMoveBy.actionWithDuration(1, position: ccp(currentHeroWorldPosition.x - coinWorldPosition.x, currentHeroWorldPosition.y - coinWorldPosition.y))
                        coin.runAction(move as! CCAction)
                        if (fabs(currentHeroWorldPosition.x - coinWorldPosition.x) <= 30) {
                            let removeCoin = CCActionCallBlock.actionWithBlock({ [unowned coin, unowned self] () -> Void in
                                coin.removeFromParentAndCleanup(true)
                                self._coins!++
                                })
                            coin.runAction(removeCoin as! CCAction)
                        }
                    }
                }
                let coinScreenPosition = self.convertToNodeSpace(coinWorldPosition)
                if coinScreenPosition.x < coin.contentSize.width * -1 {
                    if offScreenCoins == nil {
                        offScreenCoins = [CCNode]()
                    }
                    offScreenCoins?.append(coin)
                }
            }
            for coinToRemove in offScreenCoins! {
                coinToRemove.removeFromParentAndCleanup(true)
                _coinArray.removeAtIndex(_coinArray.indexOf(coinToRemove)!)
            }
        }
        //loop the ground
        for ground in _grounds {
            //get the world position of the ground
            let groundWorldPosition = _physicsNode.convertToWorldSpace(ground.position)
            //get the screen position of the ground
            let groundScreenPosition = self.convertToNodeSpace(groundWorldPosition)
            //if left corner of the ground is 1 complete width off screen, move it to the right of the next ground
            if groundScreenPosition.x <= -1 * ground.contentSizeInPoints.width {
                ground.position = ccp(ground.position.x + (2 * ground.contentSizeInPoints.width) - 2, ground.position.y)
            }
        }
    }
}
