//
//  guidanceCell.swift
//  TimerQuiz
//
//  Created by 酒井文也 on 2016/03/24.
//  Copyright © 2016年 just1factory. All rights reserved.
//

import UIKit

class guidanceCell: UITableViewCell {

    //ガイダンステキスト用セルのタイトル・文言
    @IBOutlet var guidanceTitle: UILabel!
    @IBOutlet var guidanceDescription: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
