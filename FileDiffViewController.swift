//
//  FileDiffViewController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 12/14/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import GitUpKit
import RxSwift
import RxCocoa

class FileDiffViewController: UIViewController, UITableViewDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    let disposeBag = DisposeBag()
    
    var detailItem = Variable<ChangedFileViewModel?>(nil)
    
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, Line>>()
    
    typealias Section = SectionModel<String, Line>
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let allLines = self.detailItem.map() {
            (changedFile: ChangedFileViewModel?) throws -> [Section] in
            var sections: [Section] = []
            guard let file = changedFile else {
                return sections
            }
            for hunk in file.hunks {
                sections.append(SectionModel(model: "Hunk", items: hunk.lines))
            }
            return sections
        }
        
        dataSource.cellFactory = {
            (tableView, indexPath, line) in
            guard let cell = tableView.dequeueReusableCellWithIdentifier("lineDiffCell") else {
                errorStream.value = NSError(domain: "Could not deuqueue cell with identifier lineDiffCell", code: 0, userInfo: nil)
                return UITableViewCell()
            }
            guard let label = cell.textLabel else {
                return UITableViewCell()
            }
            label.text = "\(line.newLineNumber): \(line.content)"
            return cell
        }
        
        dataSource.titleForHeaderInSection = {
            [unowned dataSource] sectionIndex in
            return dataSource.sectionAtIndex(sectionIndex).model
        }
        
        // reactive data source
        
        allLines
            .bindTo(tableView.rx_itemsWithDataSource(dataSource))
            .addDisposableTo(disposeBag)

        // Do any additional setup after loading the view.
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}
