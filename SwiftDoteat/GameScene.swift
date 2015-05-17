//
//  GameScene.swift
//  SwiftDoteat
//
//  Created by katoy on 2015/05/05.
//  Copyright (c) 2015年 Youichi Kato. All rights reserved.
//
// See  http://www.shuwasystem.co.jp/support/7980html/4055.html
//      > 書籍： Sprite Kit iPhone 2Dゲームプログラミング 7 章
//

import SpriteKit

// 一枚絵を表示するシーン
class TouchScene: SKScene {
    // 画面タッチ時
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        // フリップトランジション
        let transition = SKTransition.flipVerticalWithDuration(1.0)

        // GameScene を初期化する
        let scene = GameScene()
        scene.scaleMode = .AspectFill
        scene.size = self.size

        // トランジションを適用しながら GameScene に遷移する
        self.view?.presentScene(scene, transition: transition)
    }
}

class GameScene: SKScene, SPCharacterDelegate {

    var tileMap = [[Tile]]()                          // すべてのタイルを保持する配列
    var flowerMap = [Int : SKSpriteNode]()             // 花のタイルを保持する辞書
    var tileSize = CGSize(width: 10.0, height: 10.0)  // タイルの表示上のサイズ
    var mapWidth = 0                                  // マップの横方向のタイル数
    var mapHeight = 0                                 // マップの縦方向のタイル数

    var player: Player?              // プレイヤー
    var enemies = [Enemy]()          // 敵

    var scoreLabel: SKLabelNode?     // スコア用ラベル
    var score = 0                    // スコア

    override func didMoveToView(view: SKView) {
        self.setup()
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        // タッチしたときのシーン上の位置を求める
        let touch = touches.first as! UITouch
        let touchLocation = touch.locationInNode(self)

        // プレイヤーの現在位置を取得
        if let playerLocation = self.player?.sprite?.position {
            // タッチ位置とプレイヤーの位置との差を求める
            let dx = touchLocation.x - playerLocation.x
            let dy = touchLocation.y - playerLocation.y
            let sprite_width = self.player!.sprite!.size.width * 0.7
            var nextDirection: Direction = .None

            if abs(dx) < sprite_width && abs(dy) < sprite_width {
                // 移動停止する
                player!.nextDirection = .None
                return
            }

            // 絶対値が大きい方向を求める
            if abs(dx) > abs(dy) {
                nextDirection = dx > 0 ? .Right : .Left
            } else {
                nextDirection = dy > 0 ? .Up : .Down
            }
            if let player = self.player {
                // プレイヤーが方向転換可能であれば
                if player.canRotate(nextDirection) {
                    // 次回の方向として反映する
                    player.nextDirection = nextDirection
                    // プレイヤーの動きが止まっていれば動かす
                    player.startMoving()
                }
            }
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }

    func xy2index(x : Int, y : Int) -> Int {
        return y * self.mapWidth + x
    }
    func index2Position(index : Int) -> TilePosition {
        return TilePosition(x: index / self.mapHeight, y: index % self.mapWidth)
    }

    // タイルの位置からシーン上での位置を返すメソッド
    func getScenePointByTilePosition(position:TilePosition) -> CGPoint {
        let x = CGFloat(position.x + 1) * self.tileSize.width
        let y = self.frame.size.height - CGFloat(position.y + 1) * self.tileSize.height
        return CGPoint(x: x, y: y)
    }

     // マップを描画するメソッド
    func drawMap() {
        // CSVファイルのパスを求める
        if let fileName = NSBundle.mainBundle().pathForResource("map_ascii", ofType: "txt") {
            // マップを読み込む
            self.loadMapData(fileName)
        }

        // タイルのスプライトをシーンに貼り付ける
        for rowTiles in self.tileMap {
            for tile in rowTiles {
                self.addChild(tile)
            }
        }

        // 花のスプライトをシーンに貼り付ける
        for (index, flowerSprite) in self.flowerMap {
            self.addChild(flowerSprite)
        }
    }

    // ゲームの初期化処理を行うメソッド
    func setup() {
        // 背景画像のスプライトを貼り付ける
        let backgroundSprite = SKSpriteNode(imageNamed: "background")
        backgroundSprite.size = self.size
        backgroundSprite.position = CGPoint(x: self.size.width * 0.5, y: self.size.height * 0.5)
        self.addChild(backgroundSprite)

        drawMap()                              // マップを描画する
        createPlayer(TilePosition(x: 0, y: 0)) // プレイヤーを作成する
        for i in 0...1 {
            createEnemy(TilePosition(x: mapWidth - 2, y: mapHeight - 2))  // 敵を作成する
        }
        // スコアボードを設置する
        let houseSprite = SKSpriteNode(imageNamed: "house")
        houseSprite.size = CGSize(width: 143, height: 91)
        houseSprite.position = CGPoint(x: self.size.width-71, y: 45)
        houseSprite.zPosition = 1   // 他のノードより手前に表示する
        self.addChild(houseSprite)

        // スコアのラベルを設置する
        let scoreLabel = SKLabelNode(fontNamed: "Helvetica")
        scoreLabel.text = "0"
        scoreLabel.fontSize = 32
        scoreLabel.position = CGPoint(x: self.size.width-60, y: 40)
        scoreLabel.fontColor = UIColor.blackColor()
        scoreLabel.zPosition = 1
        self.addChild(scoreLabel)
        self.scoreLabel = scoreLabel

        // "points" ラベルを設置する
        let pointsLabel = SKLabelNode(fontNamed: "Helvetica")
        pointsLabel.text = "points"
        pointsLabel.fontSize = 18
        pointsLabel.position = CGPoint(x: self.size.width-60, y: 20)
        pointsLabel.fontColor = UIColor.blackColor()
        pointsLabel.zPosition = 1
        self.addChild(pointsLabel)
    }

    // 一枚絵を表示するシーンを作成するメソッド
    func createImageScene(imageName: String) -> SKScene {
        // シーンのサイズはGameSceneに合わせる
        let scene = TouchScene(size: self.size)

        // スプライトをシーン中央に貼り付ける
        let sprite = SKSpriteNode(imageNamed: imageName)
        sprite.size = scene.size
        sprite.position = CGPoint(x: scene.size.width * 0.5, y: scene.size.height * 0.5)
        scene.addChild(sprite)

        return scene
    }

    // プレイヤー(赤ずきん)を作成するメソッド
    func createPlayer(firstPosition:TilePosition) {
        // テクスチャを二枚用意する
        let akazukin1 = SKTexture(imageNamed: "akazukin01")
        let akazukin2 = SKTexture(imageNamed: "akazukin02")

        // 一枚目のテクスチャでスプライトを作成する
        var sprite = SKSpriteNode(texture: akazukin1)
        sprite.size = CGSize(width: self.tileSize.width, height: self.tileSize.height)
        sprite.position = self.getScenePointByTilePosition(firstPosition)
        self.addChild(sprite)

        // 二枚のテクスチャでアニメーションを行う
        let animation = SKAction.animateWithTextures([akazukin1, akazukin2], timePerFrame: 0.5)
        let repeat = SKAction.repeatActionForever(animation)
        sprite.runAction(repeat)

        // Playerクラスのオブジェクトを作成する
        var player = Player()
        player.delegate = self            // デリゲートにGameSceneを指定する
        player.position = firstPosition
        player.sprite = sprite
        player.startMoving()              // 移動を開始する
        self.player = player
    }

    // 敵(オオカミ)を作成するメソッド
    func createEnemy(firstPosition:TilePosition) {
        // テクスチャを二枚用意する
        let wolf1 = SKTexture(imageNamed: "wolf01")
        let wolf2 = SKTexture(imageNamed: "wolf02")

        // 一枚目のテクスチャでスプライトを作成する
        var sprite = SKSpriteNode(texture: wolf1)
        // タイルから少しはみ出るくらい横幅を確保する
        sprite.size = CGSize(width: self.tileSize.width * 1.5, height: self.tileSize.height)
        sprite.position = self.getScenePointByTilePosition(firstPosition)
        self.addChild(sprite)

        // 二枚のテクスチャでアニメーションを行う
        let animation = SKAction.animateWithTextures([wolf1, wolf2], timePerFrame: 0.5)
        let repeat = SKAction.repeatActionForever(animation)
        sprite.runAction(repeat)

        // Enemy クラスのオブジェクトを作成する
        var enemy = Enemy()
        enemy.delegate = self             // デリゲートに GameScene を指定する
        enemy.position = firstPosition
        enemy.sprite = sprite
        enemy.startMoving()               // 移動を開始する

        self.enemies.append(enemy)
    }

    // キャラクターが移動したときに呼ばれるメソッド
    func moveCharacter(character: SPCharacter) {
        // スプライトに移動アニメーションを適用する
        if let sprite = character.sprite {
            let moveAction = SKAction.moveTo(self.getScenePointByTilePosition(character.position), duration: 0.6)
            sprite.runAction(moveAction)
        }

        if let player = self.player {
            // 全ての敵に対して処理を行う
            for enemy in self.enemies {
                // プレイヤーと敵が同じ位置にいたら
                if player.position.isEqual(enemy.position) {
                    doGameOver(false)
                    break
                }
            }
        }
    }

    // 指定位置のタイルを返すメソッド
    func tileByPosition(position: TilePosition) -> Tile? {
        // タイルの位置からインデックスを求める
        let index = position.y * self.mapWidth + position.x
        // インデックスがマップの範囲外なら nil を返す
        if position.x < 0 || position.y < 0 || position.x >= self.mapWidth || position.y >= self.mapHeight {
            return nil
        }
        // インデックスからタイルを返却する
        return self.tileMap[position.y][position.x]
    }

    // 花を摘むときに呼ばれるメソッド
    func removeFlower(position: TilePosition) {
        // タイルの位置からインデックスを求める
        let index = xy2index(position.x, y: position.y)
        // インデックスから花のスプライトを求める
        if let flowerSprite = self.flowerMap[index] {
            // スプライトをシーンから削除する
            flowerSprite.removeFromParent()
            // 辞書からも削除する
            self.flowerMap.removeValueForKey(index)

            // スコアを加算する
            self.score++
            // スコアラベルを更新する
            self.scoreLabel?.text = "\(self.score)"

            // 全ての花を摘み終えたら
            if self.flowerMap.count == 0 {
                doGameOver(true)
            }
        }
    }

    func doGameOver(clear : Bool) {
        // ゲームクリア画面のシーンを作成する
        let scene = clear ? self.createImageScene("gameclear") : self.createImageScene("gameover")

        // クロスフェードトランジションを適用しながらシーンを移動する
        let transition = SKTransition.crossFadeWithDuration(1.0)
        self.view?.presentScene(scene, transition: transition)


        // プレイヤーの動きを止める
        self.player?.stopMoving()
        // 全ての敵の動きを止める
        for enemy in self.enemies {
            enemy.stopMoving()
        }
    }

    typealias CSVType = (Int, Int, Array<Array<String>>)
    // MAP を読み込む
    func readCSV(fileName: String) -> CSVType {
        var error = NSErrorPointer()

        var dimx = 0
        var dimy = 0

        // ファイルをUTF-8エンコードの文字列として読み込む
        let fileString = String(contentsOfFile: fileName, encoding: NSUTF8StringEncoding, error: error)
        // 改行で区切って配列にする
        let lineList = fileString!.componentsSeparatedByString("\n")
        dimy = lineList.count
        for line in lineList {
            dimx = max(count(line), dimx)
        }

        var ary = [[String]](count: dimy, repeatedValue: [String](count: dimx, repeatedValue: "0"))
        var work2 = [[String]](count: dimy + 2, repeatedValue: [String](count: dimx + 2, repeatedValue: " "))

        var y = 0
        for line in lineList {
            var x = 0
            for c in line {
                work2[y + 1][x + 1] = String(c)
                x++
            }
            y++
        }

        for y in 0..<dimy {
            for x in 0..<dimx {
                ary[y][x] = block2int([
                    " ",             work2[y][x + 1],     " ",
                    work2[y + 1][x], work2[y + 1][x + 1], work2[y + 1][x + 2],
                    " ",             work2[y + 2][x + 1], " "
                ])
            }
        }
        return (dimx, dimy, ary)
    }
    let PATTERNS = [
        "   ***   ": "1",
        "   **    ": "1",
        "    **   ": "1",
        " *  *  * ": "2",
        "    *  * ": "2",
        " *  *    ": "2",
        "    ** * ": "3",
        "   **  * ": "4",
        " * **    ": "5",
        " *  **   ": "6",
        "   *** * ": "7",
        " * **  * ": "8",
        " * ***   ": "9",
        " *  ** * ": "10",
        " * *** * ": "11",
        "    *    ": "x",
        " ": "0",
        "A": "A",
        "B": "B",
        "C": "C",
    ]

    func block2int(neigh: [String]) -> String {
        if neigh[4] != "*" {
            return PATTERNS[neigh[4]]!
        }
        var block = ""
        for c in neigh {
            block += (c == "*" || c == " ") ? c : " "
        }
        if let ans = PATTERNS[block] {
            return ans
        }
        return "0"
    }

    // マップデータを読み込んで タイル, 花の sprite を生成する
    func loadMapData(fileName:String) {
        // csv を読み込む
        let csv = readCSV(fileName) // tuple (列の数、行の数 Int の 2 次元配列 が返る
        self.mapWidth = csv.0       // 列の数
        self.mapHeight = csv.1      // 行の数
         // タイルの大きさを設定する (正方形)
        let tileWidth = min(
                Double(self.frame.width) * 0.9 / Double(csv.0),
                Double(self.frame.height) * 0.9 / Double(csv.1)
        )

        self.tileSize = CGSize(width: tileWidth, height: tileWidth)

        var y = 0
        // 行中の要素毎に処理を行う
        for row in csv.2 {
            var rowTiles = Array<Tile>()
            var x = 0
            for value in row {
                let tileName = "\(value)"
                // String から TileType型 に変換する
                if let type = TileType(name: value) {
                    // (列、行) の位置からタイルの位置を求める
                    let position = TilePosition(x: x, y: y)

                    // タイルを作成してタイルの配列に追加する
                    let tile = Tile(imageNamed: tileName)
                    tile.position = self.getScenePointByTilePosition(position)
                    tile.size = self.tileSize
                    tile.type = type
                    rowTiles.append(tile)

                    // タイルが花を置く条件にあてはまる場合
                    if type == .Road1 || type == .Road2 {
                        // 花のスプライトを花の配列に追加する
                        let flowerSprite = SKSpriteNode(imageNamed: "flower")
                        flowerSprite.size = tile.size
                        flowerSprite.position = tile.position
                        flowerSprite.anchorPoint = tile.anchorPoint
                        self.flowerMap[xy2index(x, y: y)] = flowerSprite // 一次元配列
                    }
                }
                x++
            }
            self.tileMap.append(rowTiles)
            y++
        }
    }
}
