//
//  ScoreController.swift
//  TimerQuiz
//
//  Created by 酒井文也 on 2016/03/24.
//  Copyright © 2016年 just1factory. All rights reserved.
//

import UIKit

class ScoreController: UIViewController /*,UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate*/ {

    //QuizControllerより引き渡される値を格納する
    var correctProblemNumber: Int!
    var totalSeconds: Double!
    
    //Outlet接続した部品一覧
    @IBOutlet var resultDisplayLabel: UILabel!
    @IBOutlet var analyticsSegmentControl: UISegmentedControl!
    @IBOutlet var resultHistoryTable: UITableView!
    @IBOutlet var resultGraphView: UIView!
    
    //画面出現中のタイミングに読み込まれる処理
    override func viewWillAppear(animated: Bool) {
        
        //QuizControllerから渡された値を出力
        self.resultDisplayLabel.text = "正解数：合計" + String(self.correctProblemNumber) + "問 / 経過時間：" + String( self.totalSeconds) + "秒"
        
        //@todo: デリゲートとかその他もろもろの処理
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //@todo:Realmに計算結果データを持ってくるメソッド（履歴一覧に表示するためのもの）
    
    
    //セグメントコントロールで表示するものを切り替える
    @IBAction func changeDataDisplayAction(sender: AnyObject) {
        
    }
    
    //このサンプルの解説のページをSafariで立ち上げる
    @IBAction func goExplainHowtoAction(sender: AnyObject) {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
