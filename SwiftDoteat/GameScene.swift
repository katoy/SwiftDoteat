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

        // GameSceneを初期化する
        let scene = GameScene()
        scene.scaleMode = .AspectFill
        scene.size = self.size

        // トランジションを適用しながらGameSceneに遷移する
        self.view?.presentScene(scene, transition: transition)
    }
}

class GameScene: SKScene, CharacterDelegate {

    var tileMap = [Tile]()                            // すべてのタイルを保持する配列
    var flowerMap = [Int: SKSpriteNode]()             // 花のタイルを保持する辞書
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
            let x = touchLocation.x - playerLocation.x
            let y = touchLocation.y - playerLocation.y

            // 絶対値が大きい方向を求める
            var nextDirection: Direction
            if abs(x) > abs(y) {
                nextDirection = x > 0 ? .Right : .Left
            } else {
                nextDirection = y > 0 ? .Up : .Down
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

    // タイルの位置からシーン上での位置を返すメソッド
    func getScenePointByTilePosition(position:TilePosition) -> CGPoint {
        let x = CGFloat(position.x + 1) * self.tileSize.width
        let y = self.frame.size.height - CGFloat(position.y + 1) * self.tileSize.height
        return CGPoint(x: x, y: y)
    }

     // マップを描画するメソッド
    func drawMap() {
        // CSVファイルのパスを求める
        if let fileName = NSBundle.mainBundle().pathForResource("map", ofType: "csv") {
            // マップを読み込む
            self.loadMapData(fileName)
        }

        // タイルのスプライトをシーンに貼り付ける
        for tile in self.tileMap {
            self.addChild(tile)
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

        // マップを描画する
        self.drawMap()
        // プレイヤーを作成する
        self.createPlayer(TilePosition(x: 0, y: 2))
        // 敵を作成する
        self.createEnemy(TilePosition(x: 5, y: 5))
        // self.createEnemy(TilePosition(x: 10, y: 5))

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

        // "points"ラベルを設置する
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
        player.delegate = self              // デリゲートにGameSceneを指定する
        player.position = firstPosition
        player.sprite = sprite
        player.startMoving()                // 移動を開始する
        self.player = player
    }

    // 敵(オオカミ)を作成するメソッド
    func createEnemy(firstPosition:TilePosition) {
        // テクスチャを二枚用意する
        let wolf1 = SKTexture(imageNamed: "wolf01")
        let wolf2 = SKTexture(imageNamed: "wolf02")

        // 一枚目のテクスチャでスプライトを作成する
        var sprite = SKSpriteNode(texture: wolf1)
        sprite.size = CGSize(width: self.tileSize.width * 1.5, height: self.tileSize.height)    // タイルから少しはみ出るくらい横幅を確保する
        sprite.position = self.getScenePointByTilePosition(firstPosition)
        self.addChild(sprite)

        // 二枚のテクスチャでアニメーションを行う
        let animation = SKAction.animateWithTextures([wolf1, wolf2], timePerFrame: 0.5)
        let repeat = SKAction.repeatActionForever(animation)
        sprite.runAction(repeat)

        // Enemyクラスのオブジェクトを作成する
        var enemy = Enemy()
        enemy.delegate = self               // デリゲートにGameSceneを指定する
        enemy.position = firstPosition
        enemy.sprite = sprite
        enemy.startMoving()                 // 移動を開始する

        self.enemies.append(enemy)
    }

    // キャラクターが移動したときに呼ばれるメソッド
    func moveCharacter(character: Character) {
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
                    // ゲームオーバー画面のシーンを作成する
                    let scene = self.createImageScene("gameover")
                    // クロスフェードトランジションを適用しながらシーンを移動する
                    let transition = SKTransition.crossFadeWithDuration(1.0)
                    self.view?.presentScene(scene, transition: transition)

                    // プレイヤーの動きを止める
                    player.stopMoving()
                    // 全ての敵の動きを止める
                    for e in self.enemies {
                        e.stopMoving()
                    }
                    break
                }
            }
        }
    }

    // 指定位置のタイルを返すメソッド
    func tileByPosition(position: TilePosition) -> Tile? {
        // タイルの位置からインデックスを求める
        let index = position.y * self.mapWidth + position.x
        // インデックスがマップの範囲外ならnilを返す
        if position.x < 0 || position.y < 0 || position.x >= self.mapWidth || position.y >= self.mapHeight {
            return nil
        }
        // インデックスからタイルを返却する
        return self.tileMap[index]
    }

    // 花を摘むときに呼ばれるメソッド
    func removeFlower(position: TilePosition) {
        // タイルの位置からインデックスを求める
        let index = position.y * self.mapWidth + position.x
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
                // ゲームクリア画面のシーンを作成する
                let scene = self.createImageScene("gameclear")
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
        }
    }

    typealias CSVType = (Int, Int, Array<Array<Int>>)
    // CSV を読み込む
    func readCSV(fileName : String) -> CSVType {

        var error = NSErrorPointer()

        var ary = Array<Array<Int>>()
        var dimx = 0
        var dimy = 0

        // ファイルをUTF-8エンコードの文字列として読み込む
        let fileString = String(contentsOfFile: fileName, encoding: NSUTF8StringEncoding, error: error)
        // 改行で区切って配列にする
        let lineList = fileString!.componentsSeparatedByString("\n")
        // 配列の要素数(CSVファイルの行数)を縦方向のタイル数として保持
        dimy = lineList.count

        // 行ごとに処理を行う
        for line in lineList {
            // カンマで要素を分割する
            let items = line.componentsSeparatedByString(",")
            // 行中の要素ごとに処理を行う
            var vector = Array<Int>()
            var x = 0
            for item in items {
                vector.append(item.toInt()!)
                x += 1
            }
            ary.append(vector)
            dimx = max(x, dimx)
        }
        return (dimx, dimy, ary)
    }

    // マップデータを読み込むメソッド
    func loadMapData(fileName:String) {
        // csv を読み込む
        let csv = readCSV(fileName)
        self.mapWidth = csv.0
        self.mapHeight = csv.1

        // タイルの幅を求める
        let tileWidth = Double(self.frame.width) * 0.9 / Double(self.mapWidth)
        // タイルの大きさを得る
        self.tileSize = CGSize(width: tileWidth, height: tileWidth)

        var y = 0
        // 行中の要素ごとに処理を行う
        for line in csv.2 {
            var x = 0
            for value in line {
                // 文字列をInt型に変換する
                let tileString = "\(value)"
                // Int型の値をTileType型に変換する
                if let type = TileType(rawValue: value) {
                    // インデックスからタイルの位置を求める
                    let position = TilePosition(x: x, y: y)

                    // タイルを作成して配列に納める
                    let tile = Tile(imageNamed: tileString)
                    tile.position = self.getScenePointByTilePosition(position)
                    tile.size = self.tileSize
                    tile.type = type
                    self.tileMap.append(tile)  // 一次元配列

                    // タイルが花を置く条件にあてはまる場合
                    if type == .Road1 || type == .Road2 {
                        // 花のスプライトを作成して配列に収める
                        let flowerSprite = SKSpriteNode(imageNamed: "flower")
                        flowerSprite.size = tile.size
                        flowerSprite.position = tile.position
                        flowerSprite.anchorPoint = tile.anchorPoint
                        self.flowerMap[y * self.mapWidth + x] = flowerSprite // 一次元配列
                    }
                }
                x += 1
            }
            y += 1
        }
    }
}
