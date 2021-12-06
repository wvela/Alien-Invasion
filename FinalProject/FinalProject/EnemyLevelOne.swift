//
//  EnemyLevelOne.swift
//  FinalProject
//
//  Created by Walker Vela on 4/29/21.
//

import Foundation
import SpriteKit

class EnemyLevelOne: SKSpriteNode {
    var health: Int = 1
    
    init() {
        let enemyNode: SKTexture!
        enemyNode = SKTexture(imageNamed: "enemyLevelOne")
        super.init(texture: enemyNode, color: .white, size: enemyNode.size())
        name = "enemyLevelOne"
        physicsBody = SKPhysicsBody(texture: enemyNode, size: enemyNode.size())
        physicsBody?.affectedByGravity = false
        physicsBody?.linearDamping = 0
        physicsBody?.restitution = 1
        physicsBody?.allowsRotation = false
        physicsBody?.categoryBitMask = 0b1000
        physicsBody?.collisionBitMask = 0b0100
        physicsBody?.contactTestBitMask = 0b0110
        
        
        
        let x = Int.random(in: -330...330)
        position = CGPoint(x: x, y: 635)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("EnemyLevelOne Broken.... :(")
    }
}
