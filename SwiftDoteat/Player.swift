//
//  Player.swift
//  SwiftDoteat
//
//  Created by katoy on 2015/05/05.
//  Copyright (c) 2015年 Youichi Kato. All rights reserved.
//

import Foundation

// プレイヤーを表すクラス (キャラクターを継承)
class Player: Character {
    // moveメソッドをオーバライドする
    override func move() {
        // Characterクラスの move メソッドを呼ぶ
        super.move()
        // 花の削除をデリゲートに通知する
        delegate?.removeFlower(self.position)
    }
}