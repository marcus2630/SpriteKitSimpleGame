import SpriteKit

// MARK: - Vector math helper methods

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
        return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}


// MARK - Physics

// Setup Physics categories which is a 32 bit integer hence the spritekit physics can only hold 32 categories
struct PhysicsCategory {
    static let None         : UInt32 = 0
    static let All          : UInt32 = UInt32.max
    static let Monster      : UInt32 = 0b1 // 1
    static let Projectile   : UInt32 = 0b10 // 2
}



class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // 1
    let player = SKSpriteNode(imageNamed: "player")
    
    override func didMove(to view: SKView) {
        // 2
        backgroundColor = SKColor.white
        // 3
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        // 4
        addChild(player)
        
        physicsWorld.gravity = CGVector.zero
        physicsWorld.contactDelegate = self
        
       
        run(SKAction.repeatForever(
            SKAction.sequence( [SKAction.run(addMonster), SKAction.wait(forDuration: 1.0)] )
        ))
        
        let backgroundMusic = SKAudioNode(fileNamed: "background-music-aac.caf")
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
        
        
    }
    
    
    // MARK: - Add monsters at random positions
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func addMonster() {
        
        let monster = SKSpriteNode(imageNamed: "monster")
        
        
        monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size) // 1
        monster.physicsBody?.isDynamic = true // 2
        monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster // 3
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile // 4
        monster.physicsBody?.collisionBitMask = PhysicsCategory.None // 5
        
    
        let actualY = random(min: monster.size.height/2, max: size.height - monster.size.height/2)
        
        monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)
        
        addChild(monster)
        
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        let actionMove = SKAction.move(to: CGPoint(x: -monster.size.width/2, y: actualY), duration: TimeInterval(actualDuration))
        
        let actionMoveDone = SKAction.removeFromParent()
        
        monster.run(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // 1 - choose one of the touches to work with
        guard let touch = touches.first else { return }
        
        let touchLocation = touch.location(in: self)
        
        // 2 - set up initial location of projectile
        let projectile = SKSpriteNode(imageNamed: "projectile")
        projectile.position = player.position
        
        
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Monster
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.None
        projectile.physicsBody?.usesPreciseCollisionDetection = true
        
        
        // 3 - determine offset of location to projectile
        let offset = touchLocation - projectile.position
        
        // 4 - bail out if you are shooting down or backwards
        if (offset.x < 0) { return }
        
        // 5 - OK to add now - youve double checked position
        addChild(projectile)
        
        // 6 - Get the direction of where to shoot
        let direction = offset.normalized()
        
        // 7 - make it shoot far enough to be guaranteed off screen
        let shootAmount = direction * 1000
        
        // 8 - add the shoot amount to the current position
        let realDest = shootAmount + projectile.position
        
        // 9 - create the action
        let actionMove = SKAction.move(to: realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
        
        run(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
        
        
    }
    
    func projectileDidCollideWithMonster(projectile: SKSpriteNode, monster: SKSpriteNode) {
        print("Hit")
        projectile.removeFromParent()
        monster.removeFromParent()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        // 1
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // 2
        if ((firstBody.categoryBitMask & PhysicsCategory.Monster != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.Projectile != 0)) {
            if let monster = firstBody.node as? SKSpriteNode, let
                projectile = secondBody.node as? SKSpriteNode {
                projectileDidCollideWithMonster(projectile: projectile, monster: monster)
            }
        }
        
    }
    
}
