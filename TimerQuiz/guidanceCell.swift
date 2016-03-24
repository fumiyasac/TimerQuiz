//
//  guidanceCell.swift
//  TimerQuiz
//
//  Created by 酒井文也 on 2016/03/24.
//  Copyright © 2016年 just1factory. All rights reserved.
//

import UIKit

class guidanceCell: UITableViewCell {

    //ガイダンステキストのタイトル・文言
    @IBOutlet var guidanceTitle: UILabel!
    @IBOutlet var guidanceDescription: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
