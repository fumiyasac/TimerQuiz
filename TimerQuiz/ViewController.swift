//
//  ViewController.swift
//  TimerQuiz
//
//  Created by 酒井文也 on 2016/03/17.
//  Copyright © 2016年 just1factory. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate {

    //Outlet接続をした部品
    @IBOutlet var guideTableView: UITableView!
    
    //テーブルビューに表示する文言の内容を入れておくメンバ変数
    var guidanceArray: NSMutableArray = []
    
    //セルカウント数とセクションカウント数
    var cellCount: Int = 5
    var cellSectionCount: Int = 1
    
    //画面出現のタイミングに読み込まれる処理
    override func viewWillAppear(animated: Bool) {
        
        //ガイダンス用のテーブルビューに表示するテキストを(CSV形式で準備)読み込む
        let csvBundle = NSBundle.mainBundle().pathForResource("guidance", ofType: "csv")
        
        //CSVデータの解析処理
        do {
            
            //CSVデータを読み込む
            var csvData: String = try String(contentsOfFile: csvBundle!, encoding: NSUTF8StringEncoding)
            
            csvData = csvData.stringByReplacingOccurrencesOfString("\r", withString: "")
            
            //改行を基準にしてデータを分割する読み込む
            let csvArray = csvData.componentsSeparatedByString("\n")
            
            //CSVデータの行数分ループさせる
            for line in csvArray {
                
                //カンマ区切りの1行を["aaa", "bbb", ... , "zzz"]形式に変換して代入する
                let parts = line.componentsSeparatedByString(",")
                self.guidanceArray.addObject(parts)
            }
            
            //配列の中に配列が入った状態にする
            //print(self.guidanceArray)
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //ナビゲーションのデリゲート設定
        self.navigationController?.delegate = self
        self.navigationItem.title = "食べ合わせクイズ"
        
        //テーブルビューのデリゲート設定
        self.guideTableView.delegate = self
        self.guideTableView.dataSource = self
        
        //自動計算の場合は必要
        self.guideTableView.estimatedRowHeight = 48
        self.guideTableView.rowHeight = UITableViewAutomaticDimension
        
        //Xibのクラスを読み込む
        let nibDefault:UINib = UINib(nibName: "guidanceCell", bundle: nil)
        self.guideTableView.registerNib(nibDefault, forCellReuseIdentifier: "guidanceCell")
    }

    //TableViewに関する設定一覧（セクション数）
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.cellSectionCount
    }
    
    //TableViewに関する設定一覧（セクションのセル数）
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cellCount
    }
    
    //TableViewに関する設定一覧（セルに関する設定）
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        //Xibファイルを元にデータを作成する
        let cell = tableView.dequeueReusableCellWithIdentifier("guidanceCell") as? guidanceCell
        
        //取得したデータを読み込ませる
        //配列 → 0番目：タイトル, 1番目：説明文,
        let guidanceData: NSArray = self.guidanceArray[indexPath.row] as! NSArray
        
        cell!.guidanceTitle.text = guidanceData[0] as? String
        cell!.guidanceDescription.text = guidanceData[1] as? String
        
        //セルのアクセサリタイプと背景の設定
        cell!.accessoryType = UITableViewCellAccessoryType.None
        cell!.selectionStyle = UITableViewCellSelectionStyle.None
        
        return cell!
    }
    
    //データをリロードした際に読み込まれるメソッド
    func reloadData() {
        self.guideTableView.reloadData()
    }
    
    //クイズ画面に遷移するアクション
    @IBAction func goQuizAction(sender: AnyObject) {
        self.performSegueWithIdentifier("goQuiz", sender: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}
