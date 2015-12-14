//
//  lineDiffCell.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 12/14/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit

private let addedColor = UIColor(red:0.852, green:0.993, blue:0.85, alpha:1)
private let deletedColor = UIColor(red:0.999, green:0.901, blue:0.902, alpha:1)

class lineDiffCell: UITableViewCell {
    
    @IBOutlet weak var oldNumberLabel: UILabel!
    @IBOutlet weak var newNumberLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var changeSymbolLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureForLine(line: Line) {
        if let old = line.oldLineNumber {
            oldNumberLabel.text = "\(old)"
        }
        else {
            oldNumberLabel.text = ""
        }
        
        if let new = line.newLineNumber {
            newNumberLabel.text = "\(new)"
        }
        else {
            newNumberLabel.text = ""
        }
        
        switch line.change {
            case .Added:
                changeSymbolLabel.text = "+"
                self.backgroundColor = addedColor
                break
            case .Deleted:
                changeSymbolLabel.text = "-"
                self.backgroundColor = deletedColor
                break
            default:
                changeSymbolLabel.text = ""
        }
        
        contentLabel.text = line.content
    }

}
