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
    case one = 1
    case two = 2
    case three = 3
    case four = 4
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
    var perSecTimer: Timer? = nil
    var doneTimer: Timer? = nil
    
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
    var timeProblemSolvedZero: Date!  //画面表示時点の時間
    var timeProblemSolvedOne: Date!   //第1問回答時点の時間
    var timeProblemSolvedTwo: Date!   //第2問回答時点の時間
    var timeProblemSolvedThree: Date! //第3問回答時点の時間
    var timeProblemSolvedFour: Date!  //第4問回答時点の時間
    var timeProblemSolvedFive: Date!  //第5問回答時点の時間
    
    //画面出現中のタイミングに読み込まれる処理
    override func viewWillAppear(_ animated: Bool) {
        
        //計算配列のセット
        setProblemsFromCSV()
    }

    //画面出現しきったタイミングに読み込まれる処理
    override func viewDidAppear(_ animated: Bool) {
        
        //ラベルを表示を「しばらくお待ちください...」から「あと10秒」という表記へ変更する
        timerDisplayLabel.text = "あと" + String(self.pastCounter) + "秒"
        
        //ボタンを全て活性状態にする
        allAnswerBtnEnabled()
        
        //問題を取得する
        createNextProblem()
        
        //1問目の解き始めの時間を保持する
        timeProblemSolvedZero = Date()
        
        //タイマーをセットする
        setTimer()
    }
    
    //画面が消えるタイミングに読み込まれる処理
    override func viewWillDisappear(_ animated: Bool) {
        
        //ラベルを表示を「しばらくお待ちください...」へ戻す
        timerDisplayLabel.text = "しばらくお待ちください..."
        
        //タイマーをリセットしておく
        resetTimer()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //ナビゲーションのデリゲート設定
        self.navigationController?.delegate = self
        self.navigationItem.title = "問題を解く"
        
        //テキストフィールドのデリゲート
        problemTextView.delegate = self
    }
    
    //各選択肢のボタンアクション
    @IBAction func answerActionOne(_ sender: AnyObject) {
        judgeCurrentAnswer(Answer.one.rawValue)
    }
    
    @IBAction func answerActionTwo(_ sender: AnyObject) {
        judgeCurrentAnswer(Answer.two.rawValue)
    }
    
    @IBAction func answerActionThree(_ sender: AnyObject) {
        judgeCurrentAnswer(Answer.three.rawValue)
    }
    
    @IBAction func answerActionFour(_ sender: AnyObject) {
        judgeCurrentAnswer(Answer.four.rawValue)
    }

    //タイマーをセットするメソッド
    func setTimer() {
        
        //毎秒ごとにperSecTimerDoneメソッドを実行するタイマーを作成する
        self.perSecTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(QuizController.perSecTimerDone), userInfo: nil, repeats: true)
        
        //指定秒数後にtimerDoneメソッドを実行するタイマーを作成する（問題の時間制限に到達した場合の実行）
        self.doneTimer = Timer.scheduledTimer(timeInterval: QuizStruct.timerDuration, target: self, selector: #selector(QuizController.timerDone), userInfo: nil, repeats: true)
    }
    
    //毎秒ごとのタイマーで呼び出されるメソッド
    @objc func perSecTimerDone() {
        pastCounter -= 1
        timerDisplayLabel.text = "あと" + String(self.pastCounter) + "秒"
    }
    
    //問題の時間制限に到達した場合に実行されるメソッド
    @objc func timerDone() {
        
        //10秒経過時は不正解として次の問題を読み込む
        totalSeconds = self.totalSeconds + QuizStruct.limitTimer
        pastCounter = QuizStruct.defaultCounter
        
        switch counter {
        case 0:
            timeProblemSolvedOne = Date()
        case 1:
            timeProblemSolvedTwo = Date()
        case 2:
            timeProblemSolvedThree = Date()
        case 3:
            timeProblemSolvedFour = Date()
        case 4:
            timeProblemSolvedFive = Date()
        default:
            tmpTimerCount = 0.000
        }
        
        //カウンターの値に+1をする
        counter += 1
        
        //タイマーを再設定する
        reloadTimer()
    }
    
    //CSVデータから問題を取得するメソッド
    func setProblemsFromCSV() {
        
        //問題を(CSV形式で準備)読み込む
        let csvBundle = Bundle.main.path(forResource: "problem", ofType: "csv")
        
        //CSVデータの解析処理
        do {
            
            //CSVデータを読み込む
            var csvData: String = try String(contentsOfFile: csvBundle!, encoding: String.Encoding.utf8)
            
            csvData = csvData.replacingOccurrences(of: "\r", with: "")
            
            //改行を基準にしてデータを分割する読み込む
            let csvArray = csvData.components(separatedBy: "\n")
            
            //CSVデータの行数分ループさせる
            for line in csvArray {
                
                //カンマ区切りの1行を["aaa", "bbb", ... , "zzz"]形式に変換して代入する
                let parts = line.components(separatedBy: ",")
                problemArray.add(parts)
            }
            
            //配列を引数分の要素をランダムにシャッフルする(※Extension.swift参照)
            problemArray.shuffle(self.problemArray.count)
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
    }
    
    //タイマーを破棄して再起動を行うメソッド
    func reloadTimer() {
        
        //タイマーを破棄する
        resetTimer()
        
        //結果表示ページへ遷移するか次の問題を表示する
        compareNextProblemOrResultView()
    }
    
    //次の問題を表示を行うメソッド
    func createNextProblem() {
        
        //取得した問題を取得する
        let targetProblem: NSArray = self.problemArray[self.counter] as! NSArray
        
        //ラベルに表示されている値を変更する
        //配列 → 0番目：問題文, 1番目：正解の番号, 2番目：1番目の選択肢, 3番目：2番目の選択肢, 4番目：3番目の選択肢, 5番目：4番目の選択肢
        problemCountLabel.text = "第" + String(self.counter + 1) + "問"
        problemTextView.text = targetProblem[0] as! String
        
        //ボタンに選択肢を表示する
        answerButtonOne.setTitle("1." + String(describing: targetProblem[2]), for: UIControl.State())
        answerButtonTwo.setTitle("2." + String(describing: targetProblem[3]), for: UIControl.State())
        answerButtonThree.setTitle("3." + String(describing: targetProblem[4]), for: UIControl.State())
        answerButtonFour.setTitle("4." + String(describing: targetProblem[5]), for: UIControl.State())
    }
    
    //選択された答えが正しいか誤りかを判定するメソッド
    func judgeCurrentAnswer(_ answer: Int) {
        
        //ボタンを全て非活性にする
        allAnswerBtnDisabled()
        
        //カウントを元に戻す
        pastCounter = QuizStruct.defaultCounter
        
        //[問題の回答時間] = [n問目の回答した際の時間] - [(n-1)問目の回答した際の時間]として算出する
        switch counter {
            case 0:
                timeProblemSolvedOne = Date()
                tmpTimerCount = self.timeProblemSolvedOne.timeIntervalSince(self.timeProblemSolvedZero)
            case 1:
                timeProblemSolvedTwo = Date()
                tmpTimerCount = self.timeProblemSolvedTwo.timeIntervalSince(self.timeProblemSolvedOne)
            case 2:
                timeProblemSolvedThree = Date()
                tmpTimerCount = self.timeProblemSolvedThree.timeIntervalSince(self.timeProblemSolvedTwo)
            case 3:
                timeProblemSolvedFour = Date()
                tmpTimerCount = self.timeProblemSolvedFour.timeIntervalSince(self.timeProblemSolvedThree)
            case 4:
                timeProblemSolvedFive = Date()
                tmpTimerCount = self.timeProblemSolvedFive.timeIntervalSince(self.timeProblemSolvedFour)
            default:
                tmpTimerCount = 0.000
        }
        
        //合計時間に問題の回答時間を加算する
        totalSeconds = totalSeconds + tmpTimerCount
        
        //該当の問題の回答番号を取得する
        let targetProblem: NSArray = problemArray[counter] as! NSArray
        let targetAnswer: Int = Int(targetProblem[1] as! String)!
        
        //カウンターの値に+1をする
        counter += 1
        
        //もし回答の数字とメソッドの引数が同じならば正解数の値に+1する
        if answer == targetAnswer {
            correctProblemNumber += 1
        }
        
        //タイマーを再設定する
        reloadTimer()
    }
    
    //結果表示ページへ遷移するか次の問題を表示するかを決めるメソッド
    func compareNextProblemOrResultView() {
        
        if counter == QuizStruct.dataMaxCount {
            
            /**
             *（処理）規定回数まで到達した場合は次の画面へ遷移する
             */
            
            //タイマーを破棄する
            resetTimer()
            
            //Realmに計算結果データを保存する
            let gameScoreObject = GameScore.create()
            gameScoreObject.correctAmount = self.correctProblemNumber
            gameScoreObject.timeCount = NSString(format:"%.3f", self.totalSeconds) as String
            gameScoreObject.createDate = Date()
            gameScoreObject.save()
            
            //次のコントローラーへ遷移する
            self.performSegue(withIdentifier: "goScore", sender: nil)
            
        } else {
            
            /**
             *（処理）規定回数に達していない場合はカウントをリセットして次の問題を表示する
             */
            
            //ボタンを全て活性にする
            allAnswerBtnEnabled()
            
            //次の問題をセットする
            createNextProblem()
            
            //ラベルの値を再セットする
            timerDisplayLabel.text = "あと" + String(pastCounter) + "秒"
            
            //タイマーをセットする
            setTimer()
        }
    }
    
    //セグエを呼び出したときに呼ばれるメソッド
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        //セグエ名で判定を行う
        if segue.identifier == "goScore" {
            
            //遷移先のコントローラーの変数を用意する
            let scoreController = segue.destination as! ScoreController

            //遷移先のコントローラーに渡したい変数を格納（型を合わせてね）
            scoreController.correctProblemNumber = correctProblemNumber
            scoreController.totalSeconds = NSString(format:"%.3f", totalSeconds) as String

            //計算結果を入れる変数を初期化
            self.resetGameValues()
        }
    }
    
    //ゲームのカウントに関する数を初期化する
    func resetGameValues() {
        counter = 0
        correctProblemNumber = 0
        totalSeconds = 0.000
    }
    
    //タイマー処理を全てリセットするメソッド
    func resetTimer() {
        perSecTimer!.invalidate()
        doneTimer!.invalidate()
    }
    
    //全ボタンを非活性にする
    func allAnswerBtnDisabled() {
        answerButtonOne.isEnabled = false
        answerButtonTwo.isEnabled = false
        answerButtonThree.isEnabled = false
        answerButtonFour.isEnabled = false
    }
    
    //全ボタンを活性にする
    func allAnswerBtnEnabled() {
        answerButtonOne.isEnabled = true
        answerButtonTwo.isEnabled = true
        answerButtonThree.isEnabled = true
        answerButtonFour.isEnabled = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
