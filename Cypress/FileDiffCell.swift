//
//  FileDiffCell.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 12/28/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import RxSwift

class FileDiffCell: UITableViewCell {
    
    @IBOutlet weak var changeImage: UIImageView!
    @IBOutlet weak var mainLabel: UILabel!
    
    var file: Variable<ChangedFileViewModel?> = Variable(nil)
    
    let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        file.subscribeNext() {
                [weak self] in
                if let file = $0, s = self {
                    s.configureForFile(file)
                }
            }
            .addDisposableTo(disposeBag)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureForFile(file: ChangedFileViewModel) {
        var image: UIImage?
        switch file.delta.change {
            case .Added:
                image = UIImage(named: "icon_file_a")
                break
            case .Conflicted:
                image = UIImage(named: "icon_file_conflict")
                break
            case .Deleted:
                image = UIImage(named: "icon_file_d")
                break
            case .Modified:
                image = UIImage(named: "icon_file_m")
                break
            case .Renamed:
                image = UIImage(named: "icon_file_r")
                break
            case .Untracked:
                image = UIImage(named: "icon_file_u")
                break
            default:
                image = nil
        }
        print(image)
        changeImage.image = image
        
        mainLabel.text = file.canonicalPath
        
        if file.delta.change == .Renamed {
            mainLabel.text = "\(file.delta.oldFile.path) ►︎ \(file.delta.newFile.path)"
        }
    }
}
