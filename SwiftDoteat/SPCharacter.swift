//
//  Character.swift
//  SwiftDoteat
//
//  Created by katoy on 2015/05/05.
//  Copyright (c) 2015年 Youichi Kato. All rights reserved.
//

import Foundation
import SpriteKit

// キャラクターとシーンの橋渡しをするプロトコル
protocol SPCharacterDelegate {
    // キャラクターが動いたことを通知する
    func moveCharacter(character:SPCharacter)

    // 花を摘んだことを通知する
    func removeFlower(position:TilePosition)

    // 指定した位置のタイルを取得する
    func tileByPosition(position:TilePosition) -> Tile?
}

// キャラクターを表すクラス
class SPCharacter: NSObject {
    var sprite: SKSpriteNode?                // キャラクタのスプライト
    var direction = Direction.None           // 現在の進行方向
    var nextDirection = Direction.None       // 次回の進行方向
    var position = TilePosition(x: 0, y: 0)  // 現在の位置

    var timer: NSTimer?                      // 移動用タイマー
    let timerInterval = 0.6                  // 移動する間隔(秒)

    // キャラクターで起きたイベントを通知するデリゲート
    var delegate: SPCharacterDelegate?

    // キャラクターが移動可能かどうかを返すメソッド
    func canMove(position:TilePosition) -> Bool {
        // 移動先のタイルを取得する
        if let tile = self.delegate?.tileByPosition(position) {
            // タイルが移動可能なものかどうかを返す
            return tile.type.canMove()
        }
        return false
    }

    // キャラクターが方向転換可能かどうかを返すメソッド
    func canRotate(direction:Direction) -> Bool {
        // 方向転換したときの位置を求める
        let position = self.position.movedPosition(direction)
        // 位置からタイルを取得する
        if let tile = self.delegate?.tileByPosition(position) {
            // タイルが移動可能なものかどうかを返す
            return tile.type.canMove()
        }
        return false
    }

    // 移動用タイマーを開始する
    func startMoving() {
        if self.timer == nil {
            // タイマーの作成
            self.timer = NSTimer.scheduledTimerWithTimeInterval(timerInterval, target: self, selector: "timerTick", userInfo: nil, repeats: true)
        }
    }

    // 移動用タイマーを停止する
    func stopMoving() {
        if let timer = self.timer {
            // タイマーの停止
            timer.invalidate()
            self.timer = nil
        }
    }

    // タイマーによって呼ばれるメソッド
    func timerTick() {
        // moveメソッドを呼ぶ
        self.move()
    }

    // Splite を移動する。
    func doStep(position: TilePosition) {
        // 方向と位置を反映する
        self.direction = self.nextDirection
        self.position = position
        // デリゲート(シーン)にキャラクターの移動を通知する
        delegate?.moveCharacter(self)
    }

    // 移動を行うメソッド
    func move() {
        // 移動したときの位置を求める
        let position = self.position.movedPosition(self.nextDirection)

        // 移動しようとする位置が移動可能であれば
        if self.canMove(position) {
            doStep(position)
        } else {
            // 移動可能な方向を求める
            var directions = self.getMovableDirections()
            if directions.count == 1 {
                // 反転方向以外の可能性が 1 つだけなら、そこに自動移動する
                self.nextDirection = directions[0]
                doStep(self.position.movedPosition(self.nextDirection))
            } else {
                // 停止する
                self.stopMoving()
            }
        }
    }

    // 移動可能な方向を求めるメソッド
    func getMovableDirections() -> [Direction] {
        // 移動する可能性のある位置を全て取得する
        let positions = self.getPositions()
        // 移動可能な方向を格納する
        var directions = [Direction]()

        // 各方向について検証する
        for (position, direction) in positions {
            // 移動先のタイルを取得する
            let tile = self.delegate?.tileByPosition(position)
            if let tile = tile {
                // 移動先のタイルが移動可能であり、現在の進行方向と逆でなければ
                if tile.type.canMove() && direction != self.direction.reverseDirection() {
                    // 移動可能な方向として加える
                    directions.append(direction)
                }
            }
        }
        return directions
    }

    // 上下左右の移動先の位置を取得する
    func getPositions() -> [(TilePosition, Direction)] {
        return [
            (self.position.movedPosition(.Up), .Up),
            (self.position.movedPosition(.Down), .Down),
            (self.position.movedPosition(.Left), .Left),
            (self.position.movedPosition(.Right), .Right),
        ]
    }
}