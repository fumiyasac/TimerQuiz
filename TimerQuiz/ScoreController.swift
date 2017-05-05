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
    
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    
    static func getXLabelList(_ count: Int) -> [String] {
        
        var xLabels: [String] = []
        
        //※この画面に遷移したらデータが登録されるので0は考えなくて良い
        if count == self.one.rawValue {
            xLabels = ["最新"]
        } else if count == self.two.rawValue {
            xLabels = ["最新", "2つ前"]
        } else if count == self.three.rawValue {
            xLabels = ["最新", "2つ前", "3つ前"]
        } else if count == self.four.rawValue {
            xLabels = ["最新", "2つ前", "3つ前", "4つ前"]
        } else {
            xLabels = ["最新", "2つ前", "3つ前", "4つ前", "5つ前"]
        }
        return xLabels
    }
    
}

//日付の相互変換用
struct ChangeDate {
    
    //Date → Stringへの変換
    static func convertDateToString (_ date: Date) -> String {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let dateString: String = dateFormatter.string(from: date)
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
    
    //棒グラフ用のメンバ変数
    var barChartView: BarChartView = BarChartView()
    
    //Outlet接続した部品一覧
    @IBOutlet var resultDisplayLabel: UILabel!
    @IBOutlet var analyticsSegmentControl: UISegmentedControl!
    @IBOutlet var resultHistoryTable: UITableView!
    @IBOutlet var resultGraphView: UIView!
    
    //画面出現中のタイミングに読み込まれる処理
    override func viewWillAppear(_ animated: Bool) {
        
        //QuizControllerから渡された値を出力
        resultDisplayLabel.text = "正解数：合計" + String(correctProblemNumber) + "問 / 経過時間：" + totalSeconds + "秒"
        
        //Realmから履歴データを呼び出す
        fetchHistoryDataFromRealm()
        
        //セグメントコントロールの初期値を設定する
        analyticsSegmentControl.selectedSegmentIndex = 0
        resultHistoryTable.alpha = 1
        resultGraphView.alpha = 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //ナビゲーションのデリゲート設定
        self.navigationController?.delegate = self
        self.navigationItem.title = "ゲーム結果"
                
        //テーブルビューのデリゲート設定
        resultHistoryTable.delegate = self
        resultHistoryTable.dataSource = self
        
        //Xibのクラスを読み込む
        let nibDefault: UINib = UINib(nibName: "scoreCell", bundle: nil)
        resultHistoryTable.register(nibDefault, forCellReuseIdentifier: "scoreCell")
        
        //データを成型して表示する（変数xLabelsとunitSoldに入る配列の要素数は合わせないと落ちる）
        let unitsSold: [Double] = GameScore.fetchGraphGameScore()
        let xLabels = GraphXLabelList.getXLabelList(unitsSold.count)
        let xLabelsCount = xLabels.count
        
        var dataEntries: [BarChartDataEntry] = []
        
        for i in 0..<xLabelsCount {
            
            print(unitsSold[i])
            
            let dataEntry = BarChartDataEntry(x: Double(i), y: Double(unitsSold[i]))
            dataEntries.append(dataEntry)
        }
        
        //グラフに描画するデータを表示する
        let barChartDataSet = BarChartDataSet(values: dataEntries, label: "直近5回の得点を表示しています")
        let barChartData = BarChartData(dataSet: barChartDataSet)

        //BarChartViewのインスタンスに値を追加する
        // (参考) バーチャートの装飾参考
        // http://stackoverflow.com/questions/40323288/how-to-set-x-axis-labels-with-ios-charts
        // https://fussan-blog.com/swift3-charts/

        barChartView.chartDescription?.text = "得点推移グラフ"
        barChartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
        barChartView.data = barChartData
        barChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: xLabels)
        barChartView.xAxis.granularity = 1

        //UIViewの中にLineChartViewを追加する
        resultGraphView.addSubview(barChartView)
    }

    //レイアウト処理が完了した際の処理
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //レイアウトの再配置
        barChartView.frame = CGRect(x: 0, y: 0, width: resultGraphView.frame.width, height: resultGraphView.frame.height)
    }
    
    //TableViewに関する設定一覧（セクション数）
    func numberOfSections(in tableView: UITableView) -> Int {
        return ScoreTableStruct.cellSectionCount
    }
    
    //TableViewに関する設定一覧（セクションのセル数）
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scoreArrayForCell.count
    }
    
    //TableViewに関する設定一覧（セルに関する設定）
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //Xibファイルを元にデータを作成する
        let cell = tableView.dequeueReusableCell(withIdentifier: "scoreCell") as? scoreCell
        
        //取得したデータを読み込ませる
        let scoreData: GameScore = self.scoreArrayForCell[indexPath.row] as! GameScore
        
        cell!.scoreDate.text = ChangeDate.convertDateToString(scoreData.createDate)
        cell!.scoreAmount.text = "あなたの正解数：" + String(scoreData.correctAmount) + "問正解"
        cell!.scoreTime.text = "あなたのかかった時間：" + String(scoreData.timeCount) + "秒"
 
        //セルのアクセサリタイプと背景の設定
        cell!.accessoryType = UITableViewCellAccessoryType.none
        cell!.selectionStyle = UITableViewCellSelectionStyle.none
        
        return cell!
    }
    
    //TableView: セルの高さを返す
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ScoreTableStruct.cellHeight
    }
    
    //TableView: テーブルビューをリロードする
    func reloadData(){
        self.resultHistoryTable.reloadData()
    }
    
    //Realmに計算結果データを持ってくるメソッド（履歴一覧に表示するためのもの）
    func fetchHistoryDataFromRealm() {
        
        //履歴データをフェッチしてTableViewへの一覧表示用のデータを作成
        scoreArrayForCell.removeAllObjects()
        let gameScores = GameScore.fetchAllGameScore()
        
        if gameScores.count != 0 {
            for gameScore in gameScores {
                scoreArrayForCell.add(gameScore)
            }
        }
        
        //テーブルビューをリロード
        reloadData()
        
        //セグメントコントロール位置の初期設定
        analyticsSegmentControl.selectedSegmentIndex = 0
    }
    
    //セグメントコントロールで表示するものを切り替える
    @IBAction func changeDataDisplayAction(_ sender: AnyObject) {
        
        switch sender.selectedSegmentIndex {
            
            case 0:
                resultHistoryTable.alpha = 1
                resultGraphView.alpha = 0
                break
            
            case 1:
                resultHistoryTable.alpha = 0
                resultGraphView.alpha = 1
                break
            
            default:
                resultHistoryTable.alpha = 1
                resultGraphView.alpha = 0
                break
        }
    }
    
    //このサンプルの解説のページをSafariで立ち上げる
    @IBAction func goExplainHowtoAction(_ sender: AnyObject) {
        
        //Safariで立ち上げるようにする
        let url = URL(string: "http://qiita.com/fumiyasac@github/items/18ae522885b5aa507ca3")
        
        if #available(iOS 10, *) {
            UIApplication.shared.open(url!, options: [:])
        } else {
            let app: UIApplication = UIApplication.shared
            app.openURL(url!)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
