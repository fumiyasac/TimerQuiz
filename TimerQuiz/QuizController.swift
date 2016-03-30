//
//  QuizController.swift
//  TimerQuiz
//
//  Created by 酒井文也 on 2016/03/24.
//  Copyright © 2016年 just1factory. All rights reserved.
//

import UIKit

//回答した番号の識別用enum
enum Answer: Int {
    case One = 1
    case Two = 2
    case Three = 3
    case Four = 4
}

//ゲームに関係する定数
struct QuizStruct {
    static let timerDuration: Double = 10
    static let dataMaxCount: Int = 5
    static let limitTimer: Double = 10.000
    static let defaultCounter: Int = 10
}

class QuizController: UIViewController, UINavigationControllerDelegate, UITextViewDelegate {

    //Outlet接続をした部品
    @IBOutlet var timerDisplayLabel: UILabel!
    
    @IBOutlet var problemCountLabel: UILabel!
    @IBOutlet var problemTextView: UITextView!
    
    @IBOutlet var answerButtonOne: UIButton!
    @IBOutlet var answerButtonTwo: UIButton!
    @IBOutlet var answerButtonThree: UIButton!
    @IBOutlet var answerButtonFour: UIButton!
    
    //タイマー関連のメンバ変数
    var pastCounter: Int = 10
    var perSecTimer: NSTimer? = nil
    var doneTimer: NSTimer? = nil
    
    //問題関連のメンバ変数
    var counter: Int = 0
    
    //正解数と経過した時間
    var correctProblemNumber: Int = 0
    var totalSeconds: Double = 0.000
    
    //問題の内容を入れておくメンバ変数（計5問）
    var problemArray: NSMutableArray = []
    
    //問題毎の回答時間を算出するための時間を一時的に格納するためのメンバ変数
    var tmpTimerCount: Double!
    
    //タイム表示用のメンバ変数
    var timeProblemSolvedZero: NSDate!  //画面表示時点の時間
    var timeProblemSolvedOne: NSDate!   //第1問回答時点の時間
    var timeProblemSolvedTwo: NSDate!   //第2問回答時点の時間
    var timeProblemSolvedThree: NSDate! //第3問回答時点の時間
    var timeProblemSolvedFour: NSDate!  //第4問回答時点の時間
    var timeProblemSolvedFive: NSDate!  //第5問回答時点の時間
    
    //画面出現中のタイミングに読み込まれる処理
    override func viewWillAppear(animated: Bool) {
        
        //計算配列のセット
        self.setProblemsFromCSV()
    }

    //画面出現しきったタイミングに読み込まれる処理
    override func viewDidAppear(animated: Bool) {
        
        //ラベルを表示を「しばらくお待ちください...」から「あと10秒」という表記へ変更する
        self.timerDisplayLabel.text = "あと" + String(self.pastCounter) + "秒"
        
        //ボタンを全て活性状態にする
        self.allAnswerBtnEnabled()
        
        //問題を取得する
        self.createNextProblem()
        
        //1問目の解き始めの時間を保持する
        self.timeProblemSolvedZero = NSDate()
        
        //タイマーをセットする
        self.setTimer()
    }
    
    //画面が消えるタイミングに読み込まれる処理
    override func viewWillDisappear(animated: Bool) {
        
        //ラベルを表示を「しばらくお待ちください...」へ戻す
        self.timerDisplayLabel.text = "しばらくお待ちください..."
        
        //タイマーをリセットしておく
        self.resetTimer()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //ナビゲーションのデリゲート設定
        self.navigationController?.delegate = self
        self.navigationItem.title = "問題を解く"
        
        //テキストフィールドのデリゲート
        self.problemTextView.delegate = self
    }
    
    //各選択肢のボタンアクション
    @IBAction func answerActionOne(sender: AnyObject) {
        self.judgeCurrentAnswer(Answer.One.rawValue)
    }
    
    @IBAction func answerActionTwo(sender: AnyObject) {
        self.judgeCurrentAnswer(Answer.Two.rawValue)
    }
    
    @IBAction func answerActionThree(sender: AnyObject) {
        self.judgeCurrentAnswer(Answer.Three.rawValue)
    }
    
    @IBAction func answerActionFour(sender: AnyObject) {
        self.judgeCurrentAnswer(Answer.Four.rawValue)
    }

    //タイマーをセットするメソッド
    func setTimer() {
        
        //毎秒ごとにperSecTimerDoneメソッドを実行するタイマーを作成する
        self.perSecTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(QuizController.perSecTimerDone), userInfo: nil, repeats: true)
        
        //指定秒数後にtimerDoneメソッドを実行するタイマーを作成する（問題の時間制限に到達した場合の実行）
        self.doneTimer = NSTimer.scheduledTimerWithTimeInterval(QuizStruct.timerDuration, target: self, selector: #selector(QuizController.timerDone), userInfo: nil, repeats: true)
    }
    
    //毎秒ごとのタイマーで呼び出されるメソッド
    func perSecTimerDone() {
        self.pastCounter -= 1
        self.timerDisplayLabel.text = "あと" + String(self.pastCounter) + "秒"
    }
    
    //問題の時間制限に到達した場合に実行されるメソッド
    func timerDone() {
        
        //10秒経過時は不正解として次の問題を読み込む
        self.totalSeconds = self.totalSeconds + QuizStruct.limitTimer
        self.pastCounter = QuizStruct.defaultCounter
        
        switch self.counter {
        case 0:
            self.timeProblemSolvedOne = NSDate()
        case 1:
            self.timeProblemSolvedTwo = NSDate()
        case 2:
            self.timeProblemSolvedThree = NSDate()
        case 3:
            self.timeProblemSolvedFour = NSDate()
        case 4:
            self.timeProblemSolvedFive = NSDate()
        default:
            self.tmpTimerCount = 0.000
        }
        
        //カウンターの値に+1をする
        self.counter += 1
        
        //タイマーを再設定する
        self.reloadTimer()
    }
    
    //CSVデータから問題を取得するメソッド
    func setProblemsFromCSV() {
        
        //問題を(CSV形式で準備)読み込む
        let csvBundle = NSBundle.mainBundle().pathForResource("problem", ofType: "csv")
        
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
                self.problemArray.addObject(parts)
            }
            
            //配列を引数分の要素をランダムにシャッフルする(※Extension.swift参照)
            self.problemArray.shuffle(self.problemArray.count)
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
    }
    
    //タイマーを破棄して再起動を行うメソッド
    func reloadTimer() {
        
        //タイマーを破棄する
        self.resetTimer()
        
        //結果表示ページへ遷移するか次の問題を表示する
        self.compareNextProblemOrResultView()
    }
    
    //次の問題を表示を行うメソッド
    func createNextProblem() {
        
        //取得した問題を取得する
        let targetProblem: NSArray = self.problemArray[self.counter] as! NSArray
        
        //ラベルに表示されている値を変更する
        //配列 → 0番目：問題文, 1番目：正解の番号, 2番目：1番目の選択肢, 3番目：2番目の選択肢, 4番目：3番目の選択肢, 5番目：4番目の選択肢
        self.problemCountLabel.text = "第" + String(self.counter + 1) + "問"
        self.problemTextView.text = targetProblem[0] as! String
        
        //ボタンに選択肢を表示する
        self.answerButtonOne.setTitle("1." + String(targetProblem[2]), forState: .Normal)
        self.answerButtonTwo.setTitle("2." + String(targetProblem[3]), forState: .Normal)
        self.answerButtonThree.setTitle("3." + String(targetProblem[4]), forState: .Normal)
        self.answerButtonFour.setTitle("4." + String(targetProblem[5]), forState: .Normal)
    }
    
    //選択された答えが正しいか誤りかを判定するメソッド
    func judgeCurrentAnswer(answer: Int) {
        
        //ボタンを全て非活性にする
        self.allAnswerBtnDisabled()
        
        //カウントを元に戻す
        self.pastCounter = QuizStruct.defaultCounter
        
        //[問題の回答時間] = [n問目の回答した際の時間] - [(n-1)問目の回答した際の時間]として算出する
        switch self.counter {
            case 0:
                self.timeProblemSolvedOne = NSDate()
                self.tmpTimerCount = self.timeProblemSolvedOne.timeIntervalSinceDate(self.timeProblemSolvedZero)
            case 1:
                self.timeProblemSolvedTwo = NSDate()
                self.tmpTimerCount = self.timeProblemSolvedTwo.timeIntervalSinceDate(self.timeProblemSolvedOne)
            case 2:
                self.timeProblemSolvedThree = NSDate()
                self.tmpTimerCount = self.timeProblemSolvedThree.timeIntervalSinceDate(self.timeProblemSolvedTwo)
            case 3:
                self.timeProblemSolvedFour = NSDate()
                self.tmpTimerCount = self.timeProblemSolvedFour.timeIntervalSinceDate(self.timeProblemSolvedThree)
            case 4:
                self.timeProblemSolvedFive = NSDate()
                self.tmpTimerCount = self.timeProblemSolvedFive.timeIntervalSinceDate(self.timeProblemSolvedFour)
            default:
                self.tmpTimerCount = 0.000
        }
        
        //合計時間に問題の回答時間を加算する
        self.totalSeconds = self.totalSeconds + self.tmpTimerCount
        
        //該当の問題の回答番号を取得する
        let targetProblem: NSArray = self.problemArray[self.counter] as! NSArray
        let targetAnswer: Int = Int(targetProblem[1] as! String)!
        
        //カウンターの値に+1をする
        self.counter += 1
        
        //もし回答の数字とメソッドの引数が同じならば正解数の値に+1する
        if answer == targetAnswer {
            self.correctProblemNumber += 1
        }
        
        //タイマーを再設定する
        self.reloadTimer()
    }
    
    //結果表示ページへ遷移するか次の問題を表示するかを決めるメソッド
    func compareNextProblemOrResultView() {
        
        if self.counter == QuizStruct.dataMaxCount {
            
            /**
             *（処理）規定回数まで到達した場合は次の画面へ遷移する
             */
            
            //タイマーを破棄する
            self.resetTimer()
            
            //Realmに計算結果データを保存する
            let gameScoreObject = GameScore.create()
            gameScoreObject.correctAmount = self.correctProblemNumber
            gameScoreObject.timeCount = NSString(format:"%.3f", self.totalSeconds) as String
            gameScoreObject.createDate = NSDate()
            gameScoreObject.save()
            
            //次のコントローラーへ遷移する
            self.performSegueWithIdentifier("goScore", sender: nil)
            
        } else {
            
            /**
             *（処理）規定回数に達していない場合はカウントをリセットして次の問題を表示する
             */
            
            //ボタンを全て活性にする
            self.allAnswerBtnEnabled()
            
            //次の問題をセットする
            self.createNextProblem()
            
            //ラベルの値を再セットする
            self.timerDisplayLabel.text = "あと" + String(self.pastCounter) + "秒"
            
            //タイマーをセットする
            self.setTimer()
        }
    }
    
    //セグエを呼び出したときに呼ばれるメソッド
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        //セグエ名で判定を行う
        if segue.identifier == "goScore" {
            
            //遷移先のコントローラーの変数を用意する
            let scoreController = segue.destinationViewController as! ScoreController
            
            //遷移先のコントローラーに渡したい変数を格納（型を合わせてね）
            scoreController.correctProblemNumber = self.correctProblemNumber
            scoreController.totalSeconds = NSString(format:"%.3f", self.totalSeconds) as String
            
            //計算結果を入れる変数を初期化
            self.resetGameValues()
        }
    }
    
    //ゲームのカウントに関する数を初期化する
    func resetGameValues() {
        self.counter = 0
        self.correctProblemNumber = 0
        self.totalSeconds = 0.000
    }
    
    //タイマー処理を全てリセットするメソッド
    func resetTimer() {
        self.perSecTimer!.invalidate()
        self.doneTimer!.invalidate()
    }
    
    //全ボタンを非活性にする
    func allAnswerBtnDisabled() {
        self.answerButtonOne.enabled = false
        self.answerButtonTwo.enabled = false
        self.answerButtonThree.enabled = false
        self.answerButtonFour.enabled = false
    }
    
    //全ボタンを活性にする
    func allAnswerBtnEnabled() {
        self.answerButtonOne.enabled = true
        self.answerButtonTwo.enabled = true
        self.answerButtonThree.enabled = true
        self.answerButtonFour.enabled = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
