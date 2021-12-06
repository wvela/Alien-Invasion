//
//  EnemyLevelTwo.swift
//  FinalProject
//
//  Created by Walker Vela on 4/29/21.
//

import Foundation
import SpriteKit

class EnemyLevelTwo: SKSpriteNode {
    var health: Int = 2
    
    init() {
        let enemyNode: SKTexture!
        enemyNode = SKTexture(imageNamed: "enemyLevelTwo")
        super.init(texture: enemyNode, color: .white, size: enemyNode.size())
        name = "enemyLevelTwo"
        physicsBody = SKPhysicsBody(texture: enemyNode, size: enemyNode.size())
        physicsBody?.affectedByGravity = false
        physicsBody?.linearDamping = 0
        physicsBody?.restitution = 1
        physicsBody?.allowsRotation = false
        physicsBody?.categoryBitMask = 0b1000
        physicsBody?.collisionBitMask = 0b0100
        physicsBody?.contactTestBitMask = 0b0110
        
        
        
        let x = Int.random(in: -325...325)
        position = CGPoint(x: x, y: 632)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("EnemyLevelTwo Broken.... :(")
    }
}
