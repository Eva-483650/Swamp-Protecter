//
//  ContentView.swift
//  Space Invaders
//
//  Created by A on 2025/2/19.
//

import SwiftUI
import Combine
import AVFoundation



// 数据模型
struct GameObject {
    var position: CGPoint
    var size: CGSize
}

// 游戏管理类
class GameManager: ObservableObject {
    
    private var bgmPlayer: AVAudioPlayer?
    // 添加公共控制方法
    func playBGM() {
           guard !isMuted else { return }
           bgmPlayer?.play()
    }
    
    func pauseBGM() {
        bgmPlayer?.pause()
    }
    
    func resumeBGM() {
        guard !isMuted else { return }
        bgmPlayer?.play()
    }
    
    func stopBGM() {
        bgmPlayer?.stop()
    }
    @Published var screenSize: CGSize = .zero
    
    // 玩家属性
    @Published var player = GameObject(position:CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.maxY - 90), size: CGSize(width: 40, height: 40))
    
    func updateScreenSize(_ size: CGSize) {
            screenSize = size
            repositionPlayer()
        }
        
    private func repositionPlayer() {
        player.position = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.maxY - 90)
    }
    
    //sound
    private func setupAudio() {
            guard let url = Bundle.main.url(forResource: "playSound", withExtension: ".mp3") else {
                print("BGM文件未找到")
                return
            }
            
            do {
                bgmPlayer = try AVAudioPlayer(contentsOf: url)
                bgmPlayer?.numberOfLoops = -1 // 无限循环
                bgmPlayer?.volume = 0.5 // 初始音量50%
                bgmPlayer?.prepareToPlay()
            } catch {
                print("音频播放器初始化失败: \(error.localizedDescription)")
            }
        }
    
    // 敌人管理
    @Published var enemies: [GameObject] = []
    private var enemyDirection: CGFloat = 1.0
    private let enemySpeed: CGFloat = 10
    
    // 子弹管理
    @Published var bullets: [GameObject] = []
    let bulletSpeed: CGFloat = 5.0
    
    // 游戏状态
    @Published var score = 0
    @Published var isGameOver = false
    private var timer: AnyCancellable?
    
    init() {
        setupAudio()
        resetGame()
    }
    
    // 公共方法：重置游戏
    func resetGame() {
        timer?.cancel()
        isGameOver = false
        score = 0
        player.position = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.maxY - 90)
        spawnEnemies()
        startGameLoop()
        
        // 开始播放音乐
        bgmPlayer?.play()
    }
    
    
    // 添加静音状态
    @Published var isMuted = false {
        didSet {
            bgmPlayer?.volume = isMuted ? 0 : 0.5
        }
    }

    // 静音切换方法
    func toggleMute() {
            isMuted.toggle()
            if isMuted {
                pauseBGM()
            } else {
                playBGM()
            }
       }

    
    // 生成敌人
    private func spawnEnemies() {
        let rows = 6
        let cols = 10
        let spacing: CGFloat = 8
        let enemySize = CGSize(width: 60, height: 50)
        
        enemies.removeAll()
        
        // 计算敌人方阵总宽度
        let totalWidth = CGFloat(cols) * (enemySize.width + spacing) - spacing
        // 计算水平起始位置（居中）
        let startX = (UIScreen.main.bounds.width - totalWidth) / 2
        
        for row in 0..<rows {
            for col in 0..<cols {
                let x = startX + CGFloat(col) * (enemySize.width + spacing)
                let y = CGFloat(row) * (enemySize.height + spacing) + 50
                enemies.append(GameObject(position: CGPoint(x: x, y: y), size: enemySize))
            }
        }
    }

    // 启动游戏循环
    private func startGameLoop() {
        timer = Timer.publish(every: 0.016, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateGameState()
            }
    }
    
    // 更新游戏状态
    private func updateGameState() {
        moveEnemies()
        moveBullets()
        checkCollisions()
        checkGameOver()
    }
    
    // 敌人移动逻辑
   private func moveEnemies() {
    let enemySize = CGSize(width: 60, height: 50) // 建议改为类属性
    let screenWidth = screenSize.width
    let edgeMargin: CGFloat = 20 // 边界安全距离
    // 所有敌人同步移动
    for i in 0..<enemies.count {
        enemies[i].position.x += enemySpeed * enemyDirection
    }
    // 边界检测（封装版）
    func checkBoundary() {
        guard let rightMost = enemies.max(by: { $0.position.x < $1.position.x }),
              let leftMost = enemies.min(by: { $0.position.x < $1.position.x })
        else { return }
        
        // 计算实际边缘位置（基于中心点坐标系）
        let rightEdge = rightMost.position.x + (enemySize.width/2)
        let leftEdge = leftMost.position.x - (enemySize.width/2)
        
        // 右边界检测
        if rightEdge > screenWidth - edgeMargin {
            enemyDirection = -1.0
            moveEnemiesDown()
        }
        // 左边界检测
        else if leftEdge < edgeMargin {
            enemyDirection = 1.0
            moveEnemiesDown()
        }
    }
    
    checkBoundary()
}
    
    // 敌人下移
    private func moveEnemiesDown() {
        let verticalDrop: CGFloat = 20   // 垂直下落距离
        let compensationX: CGFloat = 18   // 水平补偿量（根据实际效果调整）
        
        for i in 0..<enemies.count {
            // 垂直下落
            enemies[i].position.y += verticalDrop
            // 水平位置补偿（消除触边误差）
            enemies[i].position.x += compensationX * enemyDirection
        }
    }
    
    // 子弹移动
    private func moveBullets() {
        bullets = bullets.filter { $0.position.y > 0 }
        for i in 0..<bullets.count {
            bullets[i].position.y -= bulletSpeed
        }
    }
    
    // 碰撞检测
    private func checkCollisions() {
        var bulletsToRemove: [Int] = []
        var enemiesToRemove: [Int] = []
        
        for (bulletIndex, bullet) in bullets.enumerated() {
            for (enemyIndex, enemy) in enemies.enumerated() {
                if checkCollision(bullet: bullet, enemy: enemy) {
                    bulletsToRemove.append(bulletIndex)
                    enemiesToRemove.append(enemyIndex)
                    score += 10
                }
            }
        }
        
        // 移除碰撞对象
        enemiesToRemove.reversed().forEach { enemies.remove(at: $0) }
        bulletsToRemove.reversed().forEach { bullets.remove(at: $0) }
    }
    
    // 碰撞检测辅助方法
    private func checkCollision(bullet: GameObject, enemy: GameObject) -> Bool {
        return bullet.position.x > enemy.position.x - enemy.size.width/2 &&
        bullet.position.x < enemy.position.x + enemy.size.width/2 &&
        bullet.position.y > enemy.position.y - enemy.size.height/2 &&
        bullet.position.y < enemy.position.y + enemy.size.height/2
    }
    
    // 游戏结束检测
    private func checkGameOver() {
        // 敌人到达底部
        if let lowestEnemy = enemies.max(by: { $0.position.y < $1.position.y }) {
            if lowestEnemy.position.y > UIScreen.main.bounds.maxY - 160 {
                isGameOver = true
                timer?.cancel()
                stopBGM()
            }
        }
        
        // 所有敌人被消灭
        if enemies.isEmpty {
            isGameOver = true
            timer?.cancel()
            stopBGM()
        }
    }
    
    // 玩家移动
    func movePlayer(translation: CGSize) {
        let newX = player.position.x + translation.width
        let screenWidth = UIScreen.main.bounds.width
        player.position.x = min(max(newX, 30), screenWidth - 30)
    }
    
    // 发射子弹
    func fireBullet() {
        let bullet = GameObject(
            position: CGPoint(x: player.position.x, y: player.position.y - 50),
            size: CGSize(width: 5, height: 15)
        )
        bullets.append(bullet)
    }
}

//主视图
struct ContentView: View {
    @Binding var currentState: mainView.GameState
    @StateObject private var gameManager = GameManager()
    @GestureState private var dragOffset = CGSize.zero

    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 游戏背景
                Image("back")
                    .resizable()
                    .ignoresSafeArea() // 覆盖全屏
                    .opacity(0.4)    // 可选透明度（防止干扰前景元素）
                // 玩家
                PlayerView(position: gameManager.player.position)
                
                // 敌人
                ForEach(gameManager.enemies.indices, id: \.self) { index in
                    EnemyView(position: gameManager.enemies[index].position)
                }
                
                // 子弹
                ForEach(gameManager.bullets.indices, id: \.self) { index in
                    BulletView(position: gameManager.bullets[index].position)
                }
                
                // 游戏界面
                VStack(alignment: .center) {
                    ControlPanel(gameManager: gameManager)
                }
                
                // 游戏结束界面
                if gameManager.isGameOver {
                    GameOverView(
                        currentState: $currentState,  // 添加状态绑定
                        score: gameManager.score,
                        resetAction: {
                            gameManager.resetGame()
                            currentState = .playing  // 重置后保持游戏状态
                        }
                    )
                }
                
            }
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                        gameManager.movePlayer(translation: value.translation)
                    }
            )
            .navigationBarHidden(true)
            .onAppear {
                gameManager.updateScreenSize(geometry.size)}
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                gameManager.pauseBGM()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                if !gameManager.isGameOver {
                    gameManager.resumeBGM()
                }
            }
            .onChange(of: geometry.size) {
                            gameManager.updateScreenSize(geometry.size)
                        }
        }
    }
}

// MARK: - 组件部分

// 控制面板
struct ControlPanel: View {
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        VStack{
            // 分数与静音组合
           HStack(spacing: 20) {
               // 分数显示
               ScoreView(score: gameManager.score)
                   .padding(.horizontal, 28)
               // 静音按钮
               Button(action: {
                   gameManager.toggleMute()
               }) {
                   Image(systemName: gameManager.isMuted ? "speaker.slash" : "speaker.wave.2")
                       .font(.system(size: 22))
                       .frame(width: 50, height: 50)
                       .background(gameManager.isMuted ? Color.secondary : .accentColor)
                       .foregroundColor(.white)
                       .clipShape(Circle())
               }
           }
  
            
            Spacer()
            
            HStack(spacing: 15){
                ControlButton(systemName: "arrow.left") {
                    gameManager.movePlayer(translation: CGSize(width: -40, height: 0))
                }
                Spacer()
                
                ControlButton(systemName: "flame") {
                    gameManager.fireBullet()
                }
                
                Spacer()
                
                ControlButton(systemName: "arrow.right") {
                    gameManager.movePlayer(translation: CGSize(width: 40, height: 0))
                }
                
                
            }
            .padding(.horizontal, 100)
            .padding(.bottom, 60)
        }
       
    }
}

struct ScoreView: View {
    let score: Int
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "star.circle")
                .foregroundColor(.accentColor)
                .font(.system(size: 38))
            
            Text("\(score)")
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)
                .shadow(color: .black, radius: 2, x: 1, y: 1)
        }
        .frame(width: 150, height: 60)
        .background(
         RoundedRectangle(cornerRadius:30).fill(Material.ultraThinMaterial))
        .shadow(radius:5)
    }
}

// 控制按钮
struct ControlButton: View {
    let systemName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 32))
                .frame(width: 80, height: 80)
                .background(LinearGradient(colors: [.green, .pink],startPoint: .top,endPoint: .bottom)).opacity(0.5)// 渐变背景
                .foregroundColor(.white) // 图标颜色
                .clipShape(Circle())
        }
    }
}

// 玩家视图
struct PlayerView: View {
    let position: CGPoint
    
    var body: some View {
        Image("flower")
            .resizable()
            .rotationEffect(.degrees(180))
            .foregroundColor(.mint)
            .frame(width: 90, height: 90)
            .position(position)
        
    }
}

// 敌人视图
struct EnemyView: View {
    let position: CGPoint
    
    var body: some View {
        Image("python")
            .resizable()
            .foregroundColor(.red)
            .frame(width: 60, height: 60)
            .position(position)
    }
}
// 子弹视图
struct BulletView: View {
    let position: CGPoint
    var body: some View {
        Image("petal")
            .resizable()
            .frame(width: 40, height: 60)
            .position(position)
    }
}

// 游戏结束视图
struct GameOverView: View {
    @Binding var currentState: mainView.GameState
    let score: Int
    let resetAction: () -> Void

    var body: some View {
            ZStack {
                Color.black.opacity(0.8)
                
                VStack(spacing: 20) {
                    if(score >= 500)
                    {
                        Text("Excellent!")
                            .font(.system(size: 48,weight:.semibold))
                            .textCase(.uppercase)
                            .kerning(2) // 字间距
                            .foregroundColor(Color("AccentColor"))
                    }
                    else{
                        Text("Keep it up!")
                            .font(.system(size: 48,weight:.semibold))
                            .textCase(.uppercase)
                            .kerning(2) // 字间距
                            .foregroundColor(Color("AccentColor"))
                        
                    }
                    Text("Score: \(score)")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.white)
                    
                    Button {
                        resetAction()
                        SoundManager.instance.playSound(sound: .bubbleSound)
                    } label: {
                        PrimaryButton(text:"continue")
                            .font(.system(size: 26))
                    }


                    Button {
                        currentState = .start
                        SoundManager.instance.playSound(sound: .bubbleSound)
                    } label: {
                        PrimaryButton(text: "Quit")
                            .font(.system(size: 26))
                            .padding(.bottom, -15.0)
                    }
                    
                }
            }
            .ignoresSafeArea()
    }
}

#Preview("初始状态") {
    ContentView(currentState: .constant(.start))
}

#Preview("进行中状态") {
    ContentView(currentState: .constant(.playing))
}


