//
//  GameScene.swift
//  FinalProject
//
//  Created by Walker Vela on 4/22/21.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var playerNode = SKSpriteNode(imageNamed: "space-ship.png")
    var playerLives: Int = 3
    var isPlayerAlive: Bool = true
    var playerLivesNode: SKLabelNode!
    var scoreNode: SKLabelNode!
    var highScoreNode: SKLabelNode!
    var gameOverNode: SKLabelNode!
    var replayNode: SKLabelNode!
    var isFiring: Bool = false
    var currentFireRate: Double = 0.70
    var updateTime: Double = 0
    var damageBoost: Bool = false
    var score: Int = 0
    var highScore: Int = 0
    var storage = UserDefaults.standard
    
    
    override func didMove(to view: SKView) {
        // Create labels for Score, Highscore, Game Over, Replay, and lives
        self.createGameLabels()
        
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = .zero
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.name = "wall"
        self.physicsBody?.categoryBitMask = 0b0100
        self.physicsBody?.collisionBitMask = 0b1001
        self.physicsBody?.contactTestBitMask = 0b1001
        
        // Sets background
        if let stars = SKEmitterNode(fileNamed: "background") {
            stars.position = CGPoint(x: 0, y: 700)
            stars.advanceSimulationTime(60)
            stars.zPosition = -1
            addChild(stars)
        }
        
        // Set player attributes
        playerNode.position = CGPoint(x: 0, y: (self.size.height * -0.4))
        playerNode.physicsBody = SKPhysicsBody(rectangleOf: playerNode.size)
        playerNode.physicsBody?.allowsRotation = false
        playerNode.physicsBody?.isDynamic = true
        playerNode.physicsBody?.usesPreciseCollisionDetection = true
        playerNode.physicsBody?.angularVelocity = 0
        playerNode.physicsBody?.affectedByGravity = false
        playerNode.physicsBody?.linearDamping = 0
        playerNode.physicsBody?.restitution = 0
        playerNode.physicsBody?.categoryBitMask = 0b0001
        // TODO: Set these value later!!!!!!   ******** IMPORTANT ********
        playerNode.physicsBody?.collisionBitMask = 0b0100
        playerNode.physicsBody?.contactTestBitMask = 0b1100
        playerNode.name = "player"
        self.addChild(playerNode)
        
        // Spawn damage boost
        let waitDamage = SKAction.wait(forDuration: Double.random(in: 20...75))
        let spawnDamage = SKAction.run {
            self.spawnDamageBoost()
        }
        let damageSequence = SKAction.sequence([waitDamage, spawnDamage])
        self.run(SKAction.repeatForever(damageSequence))
        
        // Spawn rate of fire power up
        let waitSpeed = SKAction.wait(forDuration: Double.random(in: 20...75))
        let spawnSpeed = SKAction.run {
            self.spawnFireRateBoost()
        }
        let speedSequence = SKAction.sequence([waitSpeed, spawnSpeed])
        self.run(SKAction.repeatForever(speedSequence))
        
        // Spawn extra life
        let waitLife = SKAction.wait(forDuration: Double.random(in: 20...75))
        let spawnLife = SKAction.run {
            self.spawnExtraLife()
        }
        let extraLifeSequence = SKAction.sequence([waitLife, spawnLife])
        self.run(SKAction.repeatForever(extraLifeSequence))
        
        // Spawn random debuff
        let waitDebuff = SKAction.wait(forDuration: Double.random(in: 20...55))
        let spawnDebuff = SKAction.run {
            self.spawnBadPowerUp()
        }
        let debuffSequence = SKAction.sequence([waitDebuff, spawnDebuff])
        self.run(debuffSequence)
        
        // Start level one. Long spawn time, only one enemy type
        let waitLevelOne = SKAction.wait(forDuration: 3.5)
        let spawnLevelOne = SKAction.run {
            self.spawnLevelOneEnemy()
        }
        let easyGamePlay = SKAction.sequence([waitLevelOne, spawnLevelOne])
        self.run(SKAction.repeatForever(easyGamePlay), withKey: "easy")
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else {return}
        guard let nodeB = contact.bodyB.node else {return}
        
        let sortedNodes = [nodeA, nodeB].sorted {$0.name ?? "" < $1.name ?? ""}
        let firstNode = sortedNodes[0]
        let secondNode = sortedNodes[1]
        
        print("Contact: \(firstNode.name ?? "?") with \(secondNode.name ?? "?")")
        
        let action1 = SKAction.removeFromParent()
        let remove = SKAction.sequence([action1])
        
        // Player missiles do 2 damage per shot for ~10 seconds
        if firstNode.name == "damageBoost" && secondNode.name == "player" {
            let damageDuration = SKAction.wait(forDuration: 10)
            let activateDamage = SKAction.run {
                self.damageBoost = true
            }
            let deactivateDamage = SKAction.run {
                self.damageBoost = false
            }
            let activateBoost = SKAction.sequence([activateDamage, damageDuration, deactivateDamage])
            secondNode.run(activateBoost)
            firstNode.run(remove)
        }
        
        // Player firerate increases for ~10 seconds
        if firstNode.name == "player" && secondNode.name == "speedBoost" {
            let speedDuration = SKAction.wait(forDuration: 10)
            let activateSpeed = SKAction.run {
                self.currentFireRate = 0.4
            }
            let deactivateSpeed = SKAction.run {
                self.currentFireRate = 0.70
            }
            let activateSpeedBoost = SKAction.sequence([activateSpeed, speedDuration, deactivateSpeed])
            firstNode.run(activateSpeedBoost)
            secondNode.run(remove)
        }
        
        // Player gains an extra life
        if firstNode.name == "extraLife" && secondNode.name == "player" {
            playerLives += 1
            playerLivesNode.text = "Lives: \(playerLives)"
            firstNode.run(remove)
        }
        
        // Player firerate decreases for ~7 seconds
        if firstNode.name == "player" && secondNode.name == "slow" {
            let slowDuration = SKAction.wait(forDuration: 7)
            let activateSlow = SKAction.run {
                self.currentFireRate = 0.95
            }
            let deactivateSpeed = SKAction.run {
                self.currentFireRate = 0.70
            }
            let activateSpeedBoost = SKAction.sequence([activateSlow, slowDuration, deactivateSpeed])
            firstNode.run(activateSpeedBoost)
            secondNode.run(remove)
        }
        
        // Player sprite increases in size by 1.4x for ~7 seconds
        if firstNode.name == "big" && secondNode.name == "player" {
            let bigDuration = SKAction.wait(forDuration: 7)
            let bigActivate = SKAction.run {
                secondNode.setScale(1.4)
            }
            let bigDeactivate = SKAction.run {
                secondNode.setScale(1.0)
            }
            let activateBigMode = SKAction.sequence([bigActivate, bigDuration, bigDeactivate])
            secondNode.run(activateBigMode)
            firstNode.run(remove)
        }
        
        if firstNode.name == "enemyLevelOne" && (secondNode.name == "missile" || secondNode.name == "missileHeavy") {
            nodeA.run(remove)
            nodeB.run(remove)
            score += 1
            scoreNode.text = "Score: \(score)"
        }
        
        if firstNode.name == "enemyLevelTwo" && (secondNode.name == "missile" || secondNode.name == "missileHeavy") {
            let node = firstNode as! EnemyLevelTwo
            
            if secondNode.name == "missile"{
                node.health -= 1
            }
            if secondNode.name == "missileHeavy"{
                node.health -= 2
            }
            
            if node.health <= 0 {
                nodeA.run(remove)
                nodeB.run(remove)
                score += 2
                scoreNode.text = "Score: \(score)"
            }
            secondNode.run(remove)
        }
        
        if firstNode.name == "enemyLevelThree" && (secondNode.name == "missile" || secondNode.name == "missileHeavy") {
            let node = firstNode as! EnemyLevelThree
            
            if secondNode.name == "missile"{
                node.health -= 1
            }
            if secondNode.name == "missileHeavy"{
                node.health -= 2
            }
            
            if node.health <= 0 {
                nodeA.run(remove)
                nodeB.run(remove)
                score += 3
                scoreNode.text = "Score: \(score)"
            }
            secondNode.run(remove)
        }
        
        // Player loses 1 life when hit by any enemy
        if (firstNode.name == "enemyLevelOne" || firstNode.name == "enemyLevelTwo" || firstNode.name == "enemyLevelThree") && secondNode.name == "player"{
            let flashOff = SKAction.colorize(with: UIColor.clear, colorBlendFactor: 1, duration: 0.15)
            let flashOn = SKAction.colorize(with: UIColor.white, colorBlendFactor: 0, duration: 0.25)
            let flash = SKAction.sequence([flashOff, flashOn, flashOff, flashOn])
            secondNode.run(flash)
            firstNode.run(remove)
            playerLives -= 1
            playerLivesNode.text = "Lives: \(playerLives)"
            
            // Start game over when player loses all lives
            if playerLives <= 0 {
                isPlayerAlive = false
                self.gameOver()
            }
            
        }
        
        if score > highScore {
            highScore = score
            highScoreNode.text = "Highscore: \(highScore)"
            storage.setValue(highScore, forKey: "highScore")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isFiring = true
        
        // Look for touch on replay label
        for touch in touches {
            let point = touch.location(in: self)
            let nodeArray = nodes(at: point)
            for node in nodeArray {
                print("Tapped: \(node.name ?? "")")
                print("X: \(point.x), Y: \(point.y)")
                if node.name == "replayLabel" {
                    self.restartGame()
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            
            let point = touch.location(in: self)
            let previousTouch = touch.previousLocation(in: self)
            
//******************************************************************************************
//            This code was to move the player only when your finger was on the ship.
//            Overall I found this to not be as smooth because my finger would slip off
//            the ship every now and again. I decided to have the ship follow the movement
//            of the players finger whenever it was on the screen.
//******************************************************************************************
//            //let nodeArray = nodes(at: point)
//
//            // Use this to only move ship when the users finger is on the ship
//            for node in nodeArray {
//                if node.name == "player" {
//                    let distanceMovedX = point.x - previousTouch.x
//                    let distanceMovedY = point.y - previousTouch.y
//
//                    playerNode.position.x += distanceMovedX
//                    playerNode.position.y += distanceMovedY
//                }
//            }
//
            // May uncomment this later
            // Move ship when the users finger is on the screen and not only on the ship
            let distanceMovedX = point.x - previousTouch.x
            let distanceMovedY = point.y - previousTouch.y

            playerNode.position.x += distanceMovedX
            playerNode.position.y += distanceMovedY
            
            
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isFiring = false
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        // Once score hits five, transition to level 2
        if score == 5 || score == 6 {
            self.startLevelTwo()
            score += 1
        }
        // Once score gets between 19 - 21 transition to level 3
        if score == 20 || score == 21 || score == 19 {
            self.startLevelThree()
            score += 1
        }
        
        // Sets the fire rate of the player
        if isFiring == true {
            if damageBoost == false {
                if updateTime == 0 {
                    updateTime = currentTime
                }
                if (currentTime - updateTime) > currentFireRate {
                    self.fireNormalBullet()
                    updateTime = currentTime
                }
            } else {
                if updateTime == 0 {
                    updateTime = currentTime
                }
                if (currentTime - updateTime) > currentFireRate {
                    self.fireHeavyBullet()
                    updateTime = currentTime
                }
            }
        }
    }
    
    // Level 2, enemies spawn every 2 seconds and can be level 1 or level 2 enemies
    func startLevelTwo() {
        self.removeAction(forKey: "easy")
        
        let waitLevelTwo = SKAction.wait(forDuration: 2)
        let spawnEnemy = SKAction.run {
            let x = Int.random(in: 1...2)
            if x == 1 {
                self.spawnLevelOneEnemy()
            }
            else {
                self.spawnLevelTwoEnemy()
            }
        }
        let mediumGamePlay = SKAction.sequence([waitLevelTwo, spawnEnemy])
        self.run(SKAction.repeatForever(mediumGamePlay), withKey: "medium")
    }
    
    // Level 3, enemies spawn every second and can be level 1, level 2, or level 3 enemies
    func startLevelThree() {
        self.removeAction(forKey: "medium")
        
        let waitLevelThree = SKAction.wait(forDuration: 1)
        let spawnEnemy = SKAction.run {
            let x = Int.random(in: 1...3)
            if x == 1 {
                self.spawnLevelOneEnemy()
            }
            else if x == 2 {
                self.spawnLevelTwoEnemy()
            }
            else {
                self.spawnLevelThreeEnemy()
            }
        }
        let hardGamePlay = SKAction.sequence([waitLevelThree, spawnEnemy])
        self.run(SKAction.repeatForever(hardGamePlay), withKey: "hard")
    }
    
    // Spawn a normal bullet
    func fireNormalBullet() {
        guard isPlayerAlive else {return}
        let bulletNode: SKSpriteNode!
        bulletNode = SKSpriteNode(imageNamed: "bomb.png")
        
        bulletNode.name = "missile"
        bulletNode.physicsBody = SKPhysicsBody(rectangleOf: bulletNode.size)
        bulletNode.physicsBody?.affectedByGravity = false
        bulletNode.physicsBody?.linearDamping = 0
        bulletNode.physicsBody?.restitution = 1
        bulletNode.physicsBody?.allowsRotation = false
        bulletNode.physicsBody?.isDynamic = false
        bulletNode.physicsBody?.velocity = CGVector(dx:0, dy:350)
        bulletNode.physicsBody?.categoryBitMask = 0b0010
        // TODO: Set these value later!!!!!!   ******** IMPORTANT ********
        bulletNode.physicsBody?.collisionBitMask = 0b0000
        bulletNode.physicsBody?.contactTestBitMask = 0b1000
        bulletNode.position = CGPoint(x: playerNode.position.x, y: (playerNode.position.y + playerNode.size.height))
        self.addChild(bulletNode)
        
        let moveBulletNode = SKAction.moveTo(y: 700, duration: 1.75)
        let deleteBulletNode = SKAction.removeFromParent()
        let fireSequence = SKAction.sequence([moveBulletNode, deleteBulletNode])
        
        bulletNode.run(fireSequence)
    }
    
    // Spawn a heavy bullet ie. Does 2 damage to enemies
    func fireHeavyBullet() {
        guard isPlayerAlive else {return}
        let bulletNode: SKSpriteNode!
        bulletNode = SKSpriteNode(imageNamed: "missile.png")
        
        bulletNode.name = "missileHeavy"
        bulletNode.physicsBody = SKPhysicsBody(rectangleOf: bulletNode.size)
        bulletNode.physicsBody?.affectedByGravity = false
        bulletNode.setScale(1.3)
        bulletNode.physicsBody?.linearDamping = 0
        bulletNode.physicsBody?.restitution = 1
        bulletNode.physicsBody?.allowsRotation = false
        bulletNode.physicsBody?.isDynamic = false
        bulletNode.physicsBody?.velocity = CGVector(dx:0, dy:350)
        bulletNode.physicsBody?.categoryBitMask = 0b0010
        // TODO: Set these value later!!!!!!   ******** IMPORTANT ********
        bulletNode.physicsBody?.collisionBitMask = 0b0000
        bulletNode.physicsBody?.contactTestBitMask = 0b1000
        bulletNode.position = CGPoint(x: playerNode.position.x, y: (playerNode.position.y + playerNode.size.height))
        self.addChild(bulletNode)
        let color = SKAction.colorize(with: UIColor.red, colorBlendFactor: 0.55, duration: 0)
        
        let moveBulletNode = SKAction.moveTo(y: 700, duration: 1.75)
        let deleteBulletNode = SKAction.removeFromParent()
        let fireSequence = SKAction.sequence([color, moveBulletNode, deleteBulletNode])
        
        bulletNode.run(fireSequence)
    }
    
    // Spawn level 1 enemy, Only 1 health, slower impulse
    func spawnLevelOneEnemy() {
        guard isPlayerAlive else {return}
        let enemyNode = EnemyLevelOne()
        self.addChild(enemyNode)
        
        let dx = Int.random(in: -50...50)
        let dy = Int.random(in: -100...(-20))
        
        enemyNode.physicsBody?.applyImpulse(CGVector(dx:dx, dy:dy))
    }
    
    // Spawn level 2 enemy, 2 health and larger impulse
    func spawnLevelTwoEnemy() {
        guard isPlayerAlive else {return}
        let enemyNode = EnemyLevelTwo()
        self.addChild(enemyNode)
        
        let dx = Int.random(in: -50...50)
        let dy = Int.random(in: -175...(-60))
        
        enemyNode.physicsBody?.applyImpulse(CGVector(dx: dx, dy:dy))
    }
    
    // Spawn level 3 enemy, 3 health and largest impulse
    func spawnLevelThreeEnemy() {
        guard isPlayerAlive else {return}
        let enemyNode = EnemyLevelThree()
        self.addChild(enemyNode)
        
        let dx = Int.random(in: -75...75)
        let dy = Int.random(in: -220...(-80))
        
        enemyNode.physicsBody?.applyImpulse(CGVector(dx: dx, dy: dy))
    }
    
    // Spawns damage power up
    func spawnDamageBoost() {
        guard isPlayerAlive else {return}
        let powerNode: SKSpriteNode!
        powerNode = SKSpriteNode(imageNamed: "ray.png")
        powerNode.name = "damageBoost"
        powerNode.physicsBody = SKPhysicsBody(circleOfRadius: powerNode.frame.size.width / 2)
        powerNode.physicsBody?.affectedByGravity = true
        powerNode.physicsBody?.linearDamping = 0
        powerNode.physicsBody?.restitution = 1
        powerNode.physicsBody?.categoryBitMask = 0b10000
        powerNode.physicsBody?.collisionBitMask = 0b0000
        powerNode.physicsBody?.contactTestBitMask = 0b0101
        
        let x = Int.random(in: -350...350)
        powerNode.position = CGPoint(x: x, y: 700)
        powerNode.physicsBody?.velocity = CGVector(dx: 0, dy: -135)
        self.addChild(powerNode)
    }
    
    // Spawns fire rate power up
    func spawnFireRateBoost() {
        guard isPlayerAlive else {return}
        let speedNode: SKSpriteNode!
        speedNode = SKSpriteNode(imageNamed: "lightning.png")
        speedNode.name = "speedBoost"
        
        speedNode.physicsBody = SKPhysicsBody(rectangleOf: speedNode.size)
        speedNode.physicsBody?.affectedByGravity = true
        speedNode.physicsBody?.linearDamping = 0
        speedNode.physicsBody?.restitution = 1
        speedNode.physicsBody?.categoryBitMask = 0b10000
        speedNode.physicsBody?.collisionBitMask = 0b0000
        speedNode.physicsBody?.contactTestBitMask = 0b0101
        
        let x = Int.random(in: -350...350)
        speedNode.position = CGPoint(x: x, y: 700)
        speedNode.physicsBody?.velocity = CGVector(dx: 0, dy: -135)
        self.addChild(speedNode)
    }
    
    // Spawns an extra life
    func spawnExtraLife() {
        guard isPlayerAlive else {return}
        let lifeNode: SKSpriteNode!
        lifeNode = SKSpriteNode(imageNamed: "heart.png")
        lifeNode.name = "extraLife"
        
        lifeNode.physicsBody = SKPhysicsBody(circleOfRadius: lifeNode.frame.size.width / 2)
        lifeNode.physicsBody?.affectedByGravity = true
        lifeNode.physicsBody?.linearDamping = 0
        lifeNode.physicsBody?.restitution = 1
        lifeNode.physicsBody?.categoryBitMask = 0b10000
        lifeNode.physicsBody?.collisionBitMask = 0b0000
        lifeNode.physicsBody?.contactTestBitMask = 0b0101
        
        let x = Int.random(in: -350...350)
        lifeNode.position = CGPoint(x: x, y: 700)
        lifeNode.physicsBody?.velocity = CGVector(dx: 0, dy: -600)
        self.addChild(lifeNode)
    }
    
    // Spawns a random debuff, choices are either bigger ship or slower fire rate. I couldnt figure out an icon for larger ship so I decided to make them the same icon and have it be a random debuff
    func spawnBadPowerUp() {
        guard isPlayerAlive else {return}
        let slowNode: SKSpriteNode!
        slowNode = SKSpriteNode(imageNamed: "warning.png")
        let i = Int.random(in: 1...2)
        if i == 1 {
            slowNode.name = "slow"
        }
        else {
            slowNode.name = "big"
        }

        slowNode.physicsBody = SKPhysicsBody(circleOfRadius: slowNode.frame.size.width / 2)
        slowNode.physicsBody?.affectedByGravity = true
        slowNode.physicsBody?.linearDamping = 0
        slowNode.physicsBody?.restitution = 1
        slowNode.physicsBody?.categoryBitMask = 0b10000
        slowNode.physicsBody?.collisionBitMask = 0b0000
        slowNode.physicsBody?.contactTestBitMask = 0b0101

        let x = Int.random(in: -350...350)
        slowNode.position = CGPoint(x: x, y: 700)
        slowNode.physicsBody?.velocity = CGVector(dx: 0, dy: -135)
        self.addChild(slowNode)
    }
    
    // Removes all children nodes and displays game over and replay label
    func gameOver() {
        self.removeAllChildren()
        self.addChild(gameOverNode)
        self.addChild(replayNode)
        self.addChild(scoreNode)
        gameOverNode.text = "GAME OVER"
        replayNode.text = "Replay"
        scoreNode.text = "Score: \(score)"
    }
    
    // Creates a new scene and restarts game
    func restartGame() {
        let newScene = GameScene(size: self.size)
        newScene.scaleMode = self.scaleMode
        newScene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let animation = SKTransition.fade(withDuration: 1.0)
        self.view?.presentScene(newScene, transition: animation)
    }
    
    // Creates all labels for the game
    func createGameLabels() {
        let labelGameOver = SKLabelNode(fontNamed: "Helvetica Neue UltraLight")
        labelGameOver.fontSize = 125
        labelGameOver.name = "gameOverLabel"
        labelGameOver.text = ""
        gameOverNode = labelGameOver
        self.addChild(gameOverNode)
        gameOverNode.position = CGPoint(x: 0, y: 0)
        
        let labelReplay = SKLabelNode(fontNamed: "Helvetica Neue UltraLight")
        labelReplay.fontSize = 72
        labelReplay.name = "replayLabel"
        labelReplay.text = ""
        replayNode = labelReplay
        self.addChild(replayNode)
        replayNode.position = CGPoint(x: 0, y: -260)
        
        let scoreLabel = SKLabelNode(fontNamed: "Helvetica Neue UltraLight")
        scoreLabel.fontSize = 48
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.name = "scoreLabel"
        scoreLabel.text = "Score: 0"
        scoreNode = scoreLabel
        self.addChild(scoreNode)
        scoreNode.position = CGPoint(x: -360, y: 615)
        
        let highScoreLabel = SKLabelNode(fontNamed: "Helvetica Neue UltraLight")
        highScoreLabel.fontSize = 48
        highScoreLabel.horizontalAlignmentMode = .left
        highScoreLabel.name = "highScoreLabel"
        highScoreLabel.text = "Highscore: \(storage.integer(forKey: "highScore"))"
        highScoreNode = highScoreLabel
        self.addChild(highScoreNode)
        highScoreNode.position = CGPoint(x: -360, y: 560)
        highScore = storage.integer(forKey: "highScore")
        
        
        let livesLabel = SKLabelNode(fontNamed: "Helvetica Neue UltraLight")
        livesLabel.fontSize = 48
        livesLabel.name = "playerLivesLabel"
        livesLabel.text = "Lives: \(playerLives)"
        playerLivesNode = livesLabel
        self.addChild(playerLivesNode)
        playerLivesNode.position = CGPoint(x: 274, y: 615)
    }
}
