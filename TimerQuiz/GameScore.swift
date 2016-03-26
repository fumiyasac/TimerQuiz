//
//  GameScore.swift
//  TimerQuiz
//
//  Created by 酒井文也 on 2016/03/24.
//  Copyright © 2016年 just1factory. All rights reserved.
//

//Realmクラスのインポート
import RealmSwift

class GameScore: Object {
    
    //Realmクラスのインスタンス
    static let realm = try! Realm()
    
    //id
    dynamic private var id = 0
    
    //音声で送信したデータ
    dynamic var correctAmount = 0
    
    //音声で送信したデータ
    dynamic var timeCount = 0.000
    
    //登録日
    dynamic var createDate = NSDate(timeIntervalSince1970: 0)
    
    //PrimaryKeyの設定
    override static func primaryKey() -> String? {
        return "id"
    }
    
    //新規追加用のインスタンス生成メソッド
    static func create() -> GameScore {
        let gameScore = GameScore()
        gameScore.id = self.getLastId()
        return gameScore
    }
    
    //プライマリキーの作成メソッドå
    static func getLastId() -> Int {
        if let gameScore = realm.objects(GameScore).last {
            return gameScore.id + 1
        } else {
            return 1
        }
    }
    
    //インスタンス保存用メソッド
    func save() {
        try! GameScore.realm.write {
            GameScore.realm.add(self)
        }
    }
    
    //登録日順のデータの全件取得をする
    static func fetchAllGameScore() -> [GameScore] {
        let gameScores: Results<GameScore> = realm.objects(GameScore).sorted("createDate", ascending: false)
        var gameScoreList: [GameScore] = []
        for gameScore in gameScores {
            gameScoreList.append(gameScore)
        }
        return gameScoreList
    }
}
