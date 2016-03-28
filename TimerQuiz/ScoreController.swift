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

//グラフに描画する要素数に関するenum
enum GraphXLabelList : Int {
    
    case One = 1
    case Two = 2
    case Three = 3
    case Four = 4
    case Five = 5
    
    static func getXLabelList(count: Int) -> [String] {
        
        var xLabels: [String] = []
        
        //※この画面に遷移したらデータが登録されるので0は考えなくて良い
        if count == self.One.rawValue {
            xLabels = ["最新"]
        } else if count == self.Two.rawValue {
            xLabels = ["最新", "2つ前"]
        } else if count == self.Three.rawValue {
            xLabels = ["最新", "2つ前", "3つ前"]
        } else if count == self.Four.rawValue {
            xLabels = ["最新", "2つ前", "3つ前", "4つ前"]
        } else {
            xLabels = ["最新", "2つ前", "3つ前", "4つ前", "5つ前"]
        }
        return xLabels
    }
    
}

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
        
        //セグメントコントロールの初期値を設定する
        self.analyticsSegmentControl.selectedSegmentIndex = 0
        self.resultHistoryTable.alpha = 1
        self.resultGraphView.alpha = 0
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
        let nibDefault: UINib = UINib(nibName: "scoreCell", bundle: nil)
        self.resultHistoryTable.registerNib(nibDefault, forCellReuseIdentifier: "scoreCell")
        
        //データを成型して表示する（変数xLabelsとunitSoldに入る配列の要素数は合わせないと落ちる）
        let unitsSold: [Double] = GameScore.fetchGraphGameScore()
        let xLabels = GraphXLabelList.getXLabelList(unitsSold.count)
        
        var dataEntries: [ChartDataEntry] = []
        
        for i in 0..<xLabels.count {
            let dataEntry = ChartDataEntry(value: unitsSold[i], xIndex: i)
            dataEntries.append(dataEntry)
        }
        
        //グラフに描画するデータを表示する
        let lineChartDataSet = LineChartDataSet(yVals: dataEntries, label: "ここ最近の得点グラフ")
        let lineChartData = LineChartData(xVals: xLabels, dataSet: lineChartDataSet)
        
        //LineChartViewのインスタンスに値を追加する
        self.lineChartView.data = lineChartData
        
        //UIViewの中にLineChartViewを追加する
        self.resultGraphView.addSubview(self.lineChartView)
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
                self.resultHistoryTable.alpha = 1
                self.resultGraphView.alpha = 0
                break
            
            case 1:
                self.resultHistoryTable.alpha = 0
                self.resultGraphView.alpha = 1
                break
            
            default:
                self.resultHistoryTable.alpha = 1
                self.resultGraphView.alpha = 0
                break
        }
    }
    
    //このサンプルの解説のページをSafariで立ち上げる
    @IBAction func goExplainHowtoAction(sender: AnyObject) {
        
        //Safariで立ち上げるようにする
        let url = NSURL(string: "http://qiita.com/fumiyasac@github/items/18ae522885b5aa507ca3")
        let app: UIApplication = UIApplication.sharedApplication()
        app.openURL(url!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
