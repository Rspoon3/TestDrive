import SpriteKit

class GameScene: SKScene {
    
    private let obstacleSpeed: TimeInterval = 1.5  // Lower = faster, Higher = slower
    private let obstacleSpawnInterval: TimeInterval = 2.0  // Lower = more frequent, Higher = less frequent
    
    private var player: SKShapeNode!
    private var ground: SKShapeNode!
    private var scoreLabel: SKLabelNode!
    private var score = 0
    private var lastUpdateTime: TimeInterval = 0
    private var isJumping = false
    private var gameOver = false
    private var obstacleTimer: TimeInterval = 0
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.15, green: 0.15, blue: 0.3, alpha: 1.0)
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -19.8)
        physicsWorld.contactDelegate = self
        
        setupGround()
        setupPlayer()
        setupScore()
        setupBackground()
    }
    
    func setupGround() {
        ground = SKShapeNode(rectOf: CGSize(width: size.width, height: 50))
        ground.fillColor = .gray
        ground.strokeColor = .gray
        ground.position = CGPoint(x: size.width / 2, y: 25)
        
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width, height: 50))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = PhysicsCategory.ground
        
        addChild(ground)
    }
    
    func setupPlayer() {
        player = SKShapeNode(rectOf: CGSize(width: 30, height: 30))
        player.fillColor = .white
        player.strokeColor = .white
        player.position = CGPoint(x: 100, y: 100)
        
        player.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 30, height: 30))
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.obstacle
        player.physicsBody?.contactTestBitMask = PhysicsCategory.obstacle
        player.physicsBody?.allowsRotation = false
        
        addChild(player)
    }
    
    func setupScore() {
        scoreLabel = SKLabelNode(fontNamed: "Arial")
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: size.width - 100, y: size.height - 50)
        scoreLabel.text = "Score: 0"
        addChild(scoreLabel)
    }
    
    func setupBackground() {
        for i in 0..<25 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...3))
            star.fillColor = .white
            star.strokeColor = .white
            
            // Distribute stars across and beyond the screen width
            let xPosition = CGFloat.random(in: -50...size.width * 1.5)
            star.position = CGPoint(
                x: xPosition,
                y: CGFloat.random(in: 100...size.height)
            )
            star.alpha = CGFloat.random(in: 0.3...1.0)
            star.name = "star"
            addChild(star)
            
            // Slow movement for stars
            let duration = TimeInterval.random(in: 30...50)
            let moveLeft = SKAction.moveBy(x: -(size.width + 100), y: 0, duration: duration)
            let resetPosition = SKAction.moveTo(x: size.width + 50, duration: 0)
            let sequence = SKAction.sequence([moveLeft, resetPosition])
            star.run(SKAction.repeatForever(sequence))
        }
        
        for i in 0..<7 {
            let cloud = createCloud()
            
            // Distribute clouds across and beyond the screen width
            let xPosition = CGFloat.random(in: -100...size.width * 1.5)
            cloud.position = CGPoint(
                x: xPosition,
                y: CGFloat.random(in: size.height * 0.6...size.height * 0.9)
            )
            cloud.name = "cloud"
            addChild(cloud)
            
            // Clouds move slightly faster than stars
            let duration = TimeInterval.random(in: 20...35)
            let moveLeft = SKAction.moveBy(x: -(size.width + 200), y: 0, duration: duration)
            let resetPosition = SKAction.moveTo(x: size.width + 100, duration: 0)
            let sequence = SKAction.sequence([moveLeft, resetPosition])
            cloud.run(SKAction.repeatForever(sequence))
        }
    }
    
    func createCloud() -> SKNode {
        let cloud = SKNode()
        
        for i in 0..<3 {
            let circle = SKShapeNode(circleOfRadius: CGFloat.random(in: 20...30))
            circle.fillColor = SKColor(white: 1.0, alpha: 0.3)
            circle.strokeColor = .clear
            circle.position = CGPoint(x: CGFloat(i * 25), y: 0)
            cloud.addChild(circle)
        }
        
        return cloud
    }
    
    func createObstacle() {
        let obstacle = SKShapeNode(rectOf: CGSize(width: 20, height: 40))
        obstacle.fillColor = .red
        obstacle.strokeColor = .red
        obstacle.position = CGPoint(x: size.width + 20, y: 70)
        
        obstacle.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: 40))
        obstacle.physicsBody?.isDynamic = false
        obstacle.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        obstacle.physicsBody?.contactTestBitMask = PhysicsCategory.player
        
        addChild(obstacle)
        
        let moveAction = SKAction.moveBy(x: -size.width - 40, y: 0, duration: obstacleSpeed)
        let removeAction = SKAction.removeFromParent()
        obstacle.run(SKAction.sequence([moveAction, removeAction]))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameOver {
            resetGame()
            return
        }
        
        if !isJumping {
            player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 30))
            isJumping = true
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if gameOver { return }
        
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        score += 1
        scoreLabel.text = "Score: \(score)"
        
        obstacleTimer += deltaTime
        if obstacleTimer > obstacleSpawnInterval {
            createObstacle()
            obstacleTimer = 0
        }
        
        if let playerPhysicsBody = player.physicsBody {
            if abs(playerPhysicsBody.velocity.dy) < 10 && player.position.y <= 66 {
                isJumping = false
            }
        }
    }
    
    func gameOverSequence() {
        gameOver = true
        
        let gameOverLabel = SKLabelNode(fontNamed: "Arial")
        gameOverLabel.fontSize = 48
        gameOverLabel.fontColor = .white
        gameOverLabel.text = "Game Over"
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(gameOverLabel)
        
        let tapLabel = SKLabelNode(fontNamed: "Arial")
        tapLabel.fontSize = 24
        tapLabel.fontColor = .white
        tapLabel.text = "Tap to restart"
        tapLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 50)
        addChild(tapLabel)
    }
    
    func resetGame() {
        removeAllChildren()
        score = 0
        gameOver = false
        isJumping = false
        obstacleTimer = 0
        lastUpdateTime = 0
        
        setupGround()
        setupPlayer()
        setupScore()
        setupBackground()
    }
}

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if collision == PhysicsCategory.player | PhysicsCategory.obstacle {
            gameOverSequence()
        }
    }
}

struct PhysicsCategory {
    static let player: UInt32 = 0x1 << 0
    static let ground: UInt32 = 0x1 << 1
    static let obstacle: UInt32 = 0x1 << 2
}
