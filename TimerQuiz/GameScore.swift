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
    dynamic fileprivate var id = 0
    
    //正解数（Int型）
    dynamic var correctAmount = 0
    
    //正解までにかかった時間（String型）
    dynamic var timeCount = ""
    
    //登録日（Date型）
    dynamic var createDate = Date(timeIntervalSince1970: 0)
    
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
    
    //プライマリキーの作成メソッド
    static func getLastId() -> Int {
        if let gameScore = realm.objects(GameScore.self).last {
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
        let gameScores: Results<GameScore> = realm.objects(GameScore.self).sorted(byKeyPath: "createDate", ascending: false)
        var gameScoreList: [GameScore] = []
        for gameScore in gameScores {
            gameScoreList.append(gameScore)
        }
        return gameScoreList
    }
    
    //登録日順のデータを最新から5件取得をする
    static func fetchGraphGameScore() -> [Double] {
        let gameScores: Results<GameScore> = realm.objects(GameScore.self).sorted(byKeyPath: "createDate", ascending: false)
        var gameScoreList: [Double] = []
        for (index, element) in gameScores.enumerated() {
            if index < 5 {
                let target: Double = Double(element.correctAmount)
                gameScoreList.append(target)
            }
        }
        return gameScoreList
    }
}
