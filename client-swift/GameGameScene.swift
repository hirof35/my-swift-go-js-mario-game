import SpriteKit
import GameplayKit

// MARK: - モデル定義
struct Block: Decodable {
    let type: String
    let x: Double
    let y: Double
}

struct EnemyData: Decodable {
    let type: String
    let x: Double
    let y: Double
}

struct StageData: Decodable {
    let stageId: Int
    let blocks: [Block]
    let enemies: [EnemyData]
}

// MARK: - タイトルシーン
class TitleScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = .black
        let title = SKLabelNode(text: "GO & SWIFT MARIO")
        title.position = CGPoint(x: size.width/2, y: size.height/2 + 30)
        addChild(title)
        
        let start = SKLabelNode(text: "TAP TO START")
        start.fontSize = 20
        start.position = CGPoint(x: size.width/2, y: size.height/2 - 50)
        start.run(SKAction.repeatForever(SKAction.sequence([SKAction.fadeOut(withDuration: 0.5), SKAction.fadeIn(withDuration: 0.5)])))
        addChild(start)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let gameScene = GameScene(size: self.size)
        gameScene.scaleMode = .aspectFill
        view?.presentScene(gameScene, transition: .doorsOpenHorizontal(withDuration: 0.5))
    }
}

// MARK: - ゲームメインシーン
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    struct PhysicsCategory {
        static let none: UInt32   = 0
        static let player: UInt32 = 0b1
        static let enemy: UInt32  = 0b10
        static let block: UInt32  = 0b100
    }
    
    let enemyName = "enemy"
    let bossName = "boss"
    var bossHP = 3
    var isBossAngry = false
    var playerNode: SKSpriteNode!
    
    override func didMove(to view: SKView) {
        backgroundColor = .init(red: 0.39, green: 0.58, blue: 0.93, alpha: 1.0) // コーンフラワーブルー
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self
        fetchStageData()
    }
    
    func fetchStageData() {
        guard let url = URL(string: "http://localhost:8080/api/stage") else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data else { return }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            if let stageData = try? decoder.decode(StageData.self, from: data) {
                DispatchQueue.main.async { self?.generateStage(with: stageData) }
            }
        }.resume()
    }
    
    func generateStage(with data: StageData) {
        // ブロック配置
        for b in data.blocks {
            let block = SKSpriteNode(color: b.type == "ground" ? .green : .orange, size: CGSize(width: 40, height: 40))
            block.position = CGPoint(x: b.x, y: b.y)
            block.physicsBody = SKPhysicsBody(rectangleOf: block.size)
            block.physicsBody?.isDynamic = false
            block.physicsBody?.categoryBitMask = PhysicsCategory.block
            addChild(block)
        }
        // 敵配置
        for e in data.enemies { spawnEnemy(type: e.type, position: CGPoint(x: e.x, y: e.y)) }
        // プレイヤー配置
        spawnPlayer()
    }
    
    func spawnPlayer() {
        playerNode = SKSpriteNode(color: .red, size: CGSize(width: 30, height: 40))
        playerNode.position = CGPoint(x: 80, y: 200)
        playerNode.physicsBody = SKPhysicsBody(rectangleOf: playerNode.size)
        playerNode.physicsBody?.allowsRotation = false
        playerNode.physicsBody?.categoryBitMask = PhysicsCategory.player
        playerNode.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        playerNode.physicsBody?.collisionBitMask = PhysicsCategory.block | PhysicsCategory.enemy
        addChild(playerNode)
    }
    
    func spawnEnemy(type: String, position: CGPoint) {
        let node = SKSpriteNode()
        node.position = position
        
        switch type {
        case "goomba":
            node.color = .brown
            node.size = CGSize(width: 30, height: 30)
            node.name = enemyName
            node.run(SKAction.moveBy(x: -600, y: 0, duration: 12))
        case "turtle":
            node.color = .darkGray
            node.size = CGSize(width: 30, height: 30)
            node.name = enemyName
            let seq = SKAction.sequence([SKAction.moveBy(x: 80, y: 0, duration: 2), SKAction.moveBy(x: -80, y: 0, duration: 2)])
            node.run(SKAction.repeatForever(seq))
        case "jumper":
            node.color = .purple
            node.size = CGSize(width: 30, height: 30)
            node.name = enemyName
            let jump = SKAction.run { node.physicsBody?.applyImpulse(CGVector(dx: -1, dy: 10)) }
            node.run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 2), jump])))
        case "boss":
            node.color = .orange
            node.size = CGSize(width: 60, height: 80)
            node.name = bossName
            node.position.x = 450 // ★確実に床（Ground）がある位置に上書きする
            startBossMovement(bossNode: node, duration: 2.0)
        default: return
        }
        
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.allowsRotation = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        node.physicsBody?.collisionBitMask = PhysicsCategory.block | PhysicsCategory.player
        addChild(node)
    }
    
    func startBossMovement(bossNode: SKSpriteNode, duration: TimeInterval) {
        let seq = SKAction.sequence([SKAction.moveBy(x: -100, y: 0, duration: duration), SKAction.moveBy(x: 100, y: 0, duration: duration)])
        bossNode.run(SKAction.repeatForever(seq), withKey: "boss_move")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let velocityY = playerNode.physicsBody?.velocity.dy, abs(velocityY) < 0.1 {
            playerNode.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 14))
        }
    }
    
    // 💥 接触イベント検知
    func didBegin(_ contact: SKPhysicsContact) {
        let masks = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if masks == (PhysicsCategory.player | PhysicsCategory.enemy) {
            guard let player = (contact.bodyA.categoryBitMask == PhysicsCategory.player ? contact.bodyA.node : contact.bodyB.node) as? SKSpriteNode,
                  let enemy = (contact.bodyA.categoryBitMask == PhysicsCategory.enemy ? contact.bodyA.node : contact.bodyB.node) as? SKSpriteNode else { return }
            
            let pBottom = player.position.y - (player.size.height / 2)
            let eTop = enemy.position.y + (enemy.size.height / 2)
            
            if pBottom >= eTop - 5 { // 踏んだ判定
                player.physicsBody?.velocity.dy = 0
                player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 10)) // 跳ね返り
                
                if enemy.name == bossName { damageBoss(bossNode: enemy) }
                else { enemy.run(SKAction.sequence([SKAction.scaleY(to: 0.1, duration: 0.1), .removeFromParent()])) }
            } else { // ぶつかった判定
                playerLose(playerNode: player)
            }
        }
    }
    
    func damageBoss(bossNode: SKSpriteNode) {
        bossHP -= 1
        bossNode.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 10))
        
        if bossHP <= 0 {
            bossNode.removeFromParent()
            view?.presentScene(ClearScene(size: size), transition: .fade(withDuration: 1.0))
        } else if bossHP == 1 && !isBossAngry {
            isBossAngry = true
            bossNode.removeAction(forKey: "boss_move")
            let red = SKAction.colorize(with: .red, colorBlendFactor: 1.0, duration: 0.1)
            let norm = SKAction.colorize(with: .orange, colorBlendFactor: 1.0, duration: 0.1)
            let angrySetup = SKAction.run { [weak self] in
                self?.startBossMovement(bossNode: bossNode, duration: 1.0) // スピード2倍
                let jump = SKAction.run { bossNode.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 18)) }
                bossNode.run(SKAction.repeatForever(SKAction.sequence([.wait(forDuration: 1.5), jump])))
            }
            bossNode.run(SKAction.sequence([red, norm, red, norm, angrySetup]))
        }
    }
    
    func playerLose(playerNode: SKSpriteNode) {
        playerNode.physicsBody?.collisionBitMask = 0
        let seq = SKAction.sequence([.moveBy(x: 0, y: 120, duration: 0.25), .moveBy(x: 0, y: -500, duration: 0.5), .removeFromParent()])
        playerNode.run(seq) { [weak self] in
            guard let self = self else { return }
            self.view?.presentScene(GameOverScene(size: self.size), transition: .crossFade(withDuration: 0.5))
        }
    }
}

// MARK: - ゲームオーバーシーン
class GameOverScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = .darkGray
        let label = SKLabelNode(text: "GAME OVER")
        label.fontColor = .red
        label.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(label)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view?.presentScene(TitleScene(size: size), transition: .fade(withDuration: 0.5))
    }
}

// MARK: - クリアシーン
class ClearScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = .blue
        let label = SKLabelNode(text: "STAGE CLEAR!")
        label.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(label)
        sendScore()
    }
    func sendScore() {
        guard let url = URL(string: "http://localhost:8080/api/clear") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["player_name": "Swift_Mario", "score": 1500])
        URLSession.shared.dataTask(with: req).resume()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view?.presentScene(TitleScene(size: size), transition: .doorsCloseHorizontal(withDuration: 0.5))
    }
}