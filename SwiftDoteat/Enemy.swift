//
//  Enemy.swift
//  SwiftDoteat
//
//  Created by katoy on 2015/05/05.
//  Copyright (c) 2015年 Youichi Kato. All rights reserved.
//

import Foundation
import SpriteKit

// 敵を表すクラス (キャラクターを継承)
class Enemy : Character {

    // 敵は常に自動移動する。
    override func move() {
        // 現在の移動方向に移動したときの位置を求める
        let newPosition = self.position.movedPosition(self.direction)

        // このまま移動可能かどうかを求める
        let canMove = self.canMove(newPosition)
        // 移動可能な方向を求める
        var directions = self.getMovableDirections()

        // 進行方向に移動出来ないか、移動可能な方向が複数ある場合
        if !canMove || directions.count >= 1 {
            // 方向をランダムに一つ選択する
            let index = Int(arc4random_uniform(UInt32(directions.count)))
            // 次回の移動方向として設定する
            self.nextDirection = directions[index]
            // 移動用タイマーを開始する
            self.startMoving()
        }

        super.move()  // 移動する
    }
}