//
//  ScoreController.swift
//  TimerQuiz
//
//  Created by 酒井文也 on 2016/03/24.
//  Copyright © 2016年 just1factory. All rights reserved.
//

import UIKit

//Realmクラスのインポート
import RealmSwift

//Charsクラスのインポート
import Charts

//日付の相互変換用
struct ChangeDate {
    
    //NSDate → Stringへの変換
    static func convertNSDateToString (date: NSDate) -> String {
        let dateFormatter: NSDateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "ja_JP")
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let dateString: String = dateFormatter.stringFromDate(date)
        return dateString
    }
}

//テーブルビューに関係する定数
struct ScoreTableStruct {
    static let cellSectionCount: Int = 1
    static let cellHeight: CGFloat = 79.5
}

class ScoreController: UIViewController ,UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate {

    //QuizControllerより引き渡される値を格納する
    var correctProblemNumber: Int!
    var totalSeconds: String!
    
    //テーブルデータ表示用に一時的にすべてのfetchデータを格納する
    var scoreArrayForCell: NSMutableArray = []
    
    //折れ線グラフ用のメンバ変数
    var lineChartView: LineChartView = LineChartView()
    
    //Outlet接続した部品一覧
    @IBOutlet var resultDisplayLabel: UILabel!
    @IBOutlet var analyticsSegmentControl: UISegmentedControl!
    @IBOutlet var resultHistoryTable: UITableView!
    @IBOutlet var resultGraphView: UIView!
    
    //画面出現中のタイミングに読み込まれる処理
    override func viewWillAppear(animated: Bool) {
        
        //QuizControllerから渡された値を出力
        self.resultDisplayLabel.text = "正解数：合計" + String(self.correctProblemNumber) + "問 / 経過時間：" + self.totalSeconds + "秒"
        
        //Realmから履歴データを呼び出す
        self.fetchHistoryDataFromRealm()
        
        self.resultHistoryTable.alpha = 0
        self.resultGraphView.alpha = 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //ナビゲーションのデリゲート設定
        self.navigationController?.delegate = self
        self.navigationItem.title = "ゲーム結果"
                
        //テーブルビューのデリゲート設定
        self.resultHistoryTable.delegate = self
        self.resultHistoryTable.dataSource = self
        
        //Xibのクラスを読み込む
        let nibDefault:UINib = UINib(nibName: "scoreCell", bundle: nil)
        self.resultHistoryTable.registerNib(nibDefault, forCellReuseIdentifier: "scoreCell")
        
        
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
        let unitsSold = [20.0, 4.0, 6.0, 3.0, 12.0, 16.0]
        
        var dataEntries: [ChartDataEntry] = []
        
        for i in 0..<months.count {
            let dataEntry = ChartDataEntry(value: unitsSold[i], xIndex: i)
            dataEntries.append(dataEntry)
        }
        
        /*
         let pieChartDataSet = PieChartDataSet(yVals: dataEntries, label: "Units Sold")
         let pieChartData = PieChartData(xVals: dataPoints, dataSet: pieChartDataSet)
         pieChartView.data = pieChartData
         
         var colors: [UIColor] = []
         
         for i in 0..<dataPoints.count {
         let red = Double(arc4random_uniform(256))
         let green = Double(arc4random_uniform(256))
         let blue = Double(arc4random_uniform(256))
         
         let color = UIColor(red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: 1)
         colors.append(color)
         }
         
         pieChartDataSet.colors = colors
         */
        
        let lineChartDataSet = LineChartDataSet(yVals: dataEntries, label: "Units Sold")
        let lineChartData = LineChartData(xVals: months, dataSet: lineChartDataSet)
        print(lineChartData)
        self.lineChartView.data = lineChartData
        print(self.lineChartView)
        self.resultGraphView.addSubview(self.lineChartView)
        
        //self.setChart(months, values: unitsSold)
    }

    //レイアウト処理が完了した際の処理
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //レイアウトの再配置
        self.lineChartView.frame = CGRectMake(0, 0, self.resultGraphView.frame.width, self.resultGraphView.frame.height)
    }
    
    //TableViewに関する設定一覧（セクション数）
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return ScoreTableStruct.cellSectionCount
    }
    
    //TableViewに関する設定一覧（セクションのセル数）
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.scoreArrayForCell.count
    }
    
    //TableViewに関する設定一覧（セルに関する設定）
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        //Xibファイルを元にデータを作成する
        let cell = tableView.dequeueReusableCellWithIdentifier("scoreCell") as? scoreCell
        
        //取得したデータを読み込ませる
        let scoreData: GameScore = self.scoreArrayForCell[indexPath.row] as! GameScore
        
        cell!.scoreDate.text = ChangeDate.convertNSDateToString(scoreData.createDate)
        cell!.scoreAmount.text = "あなたの正解数：" + String(scoreData.correctAmount) + "問正解"
        cell!.scoreTime.text = "あなたのかかった時間：" + String(scoreData.timeCount) + "秒"
 
        //セルのアクセサリタイプと背景の設定
        cell!.accessoryType = UITableViewCellAccessoryType.None
        cell!.selectionStyle = UITableViewCellSelectionStyle.None
        
        return cell!
    }
    
    
    func setChart(dataPoints: [String], values: [Double]) {
        

        
    }
    
    //TableView: セルの高さを返す
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return ScoreTableStruct.cellHeight
    }
    
    //TableView: テーブルビューをリロードする
    func reloadData(){
        self.resultHistoryTable.reloadData()
    }
    
    //Realmに計算結果データを持ってくるメソッド（履歴一覧に表示するためのもの）
    func fetchHistoryDataFromRealm() {
        
        //履歴データをフェッチしてTableViewへの一覧表示用のデータを作成
        self.scoreArrayForCell.removeAllObjects()
        let gameScores = GameScore.fetchAllGameScore()
        
        if gameScores.count != 0 {
            for gameScore in gameScores {
                self.scoreArrayForCell.addObject(gameScore)
            }
        }
        
        //テーブルビューをリロード
        self.reloadData()
        
        //セグメントコントロール位置の初期設定
        self.analyticsSegmentControl.selectedSegmentIndex = 0
    }
    
    //セグメントコントロールで表示するものを切り替える
    @IBAction func changeDataDisplayAction(sender: AnyObject) {
        
        switch sender.selectedSegmentIndex {
            
            case 0:
                break
            
            case 1:
                break
            
            default:
                break
        }
    }
    
    //このサンプルの解説のページをSafariで立ち上げる
    @IBAction func goExplainHowtoAction(sender: AnyObject) {
        
        //Safariで立ち上げるようにする
        let url = NSURL(string: "http://qiita.com")
        let app: UIApplication = UIApplication.sharedApplication()
        app.openURL(url!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
