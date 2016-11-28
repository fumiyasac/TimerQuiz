//
//  scoreCell.swift
//  TimerQuiz
//
//  Created by 酒井文也 on 2016/03/26.
//  Copyright © 2016年 just1factory. All rights reserved.
//

import UIKit

class scoreCell: UITableViewCell {

    //スコア履歴用セルのタイトル・文言
    @IBOutlet var scoreDate: UILabel!
    @IBOutlet var scoreAmount: UILabel!
    @IBOutlet var scoreTime: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
