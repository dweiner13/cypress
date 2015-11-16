//
//  SwitchCell.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/14/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit

class SwitchTableViewCell: UITableViewCell {
    
    @IBOutlet weak var mainSwitch: UISwitch!
    
    @IBOutlet weak var mainLabel: UILabel!
    
    var switchOn: Bool {
        set {
            mainSwitch.on = newValue
        }
        get {
            return mainSwitch.on
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
