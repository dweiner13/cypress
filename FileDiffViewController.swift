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
    @IBOutlet weak var leftActionButton: UIBarButtonItem!
    @IBOutlet weak var rightActionButton: UIBarButtonItem!
    
    let disposeBag = DisposeBag()
    
    var detailItem = Variable<ChangedFileViewModel?>(nil)
    
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, Line>>()
    
    typealias Section = SectionModel<String, Line>
    
    var selectedLines: [Line] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = detailItem.value?.fileName
        
        self.tableView.registerNib(UINib(nibName: "lineDiffCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "lineDiffCell")
        
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
            guard let cell = tableView.dequeueReusableCellWithIdentifier("lineDiffCell") as? lineDiffCell else {
                errorStream.value = NSError(domain: "Could not deuqueue cell with identifier lineDiffCell", code: 0, userInfo: nil)
                return UITableViewCell()
            }
            cell.configureForLine(line)
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
        
        self.detailItem.subscribeNext() {
            [weak self] _ in
            self?.configureToolbarButtons()
        }
        .addDisposableTo(disposeBag)

        tableView.rx_setDelegate(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func modelForIndexPath(indexPath: NSIndexPath) -> Line? {
        guard let file = detailItem.value else {
            return nil
        }
        
        let hunk = file.hunks[indexPath.section]
        return hunk.lines[indexPath.row]
    }
    
    // MARK: - Toolbar buttons
    
    private func configureToolbarButtons() {
        guard let changedFile = detailItem.value else {
            return
        }
        if changedFile.staged {
            leftActionButton.title = ""
            rightActionButton.title = "Unstage lines"
        }
        else {
            leftActionButton.title = "Discard lines"
            rightActionButton.title = "Stage lines"
        }
        
        leftActionButton.enabled = selectedLines.count != 0
        rightActionButton.enabled = selectedLines.count != 0
    }
    
    @IBAction func tappedLeftActionButton(sender: AnyObject) {
        guard let file = detailItem.value else {
            return
        }
        
        if !file.staged {
            askForConfirmation("Are you sure?", message: "This action cannot be undone", confirmActionTitle: "Unstage", confirmedHandler: {
                [weak self] () -> Void in
                if let s = self, file = s.detailItem.value {
                    s.detailItem.value = file.discardLines(s.selectedLines)
                }
            })
        }
    }
    
    @IBAction func tappedRightActionButton(sender: AnyObject) {
        guard let file = detailItem.value else {
            return
        }
        
        if file.staged {
            detailItem.value = file.unstageLines(selectedLines)
        }
        else {
            detailItem.value = file.stageLines(selectedLines)
        }
    }
    
    // MARK: - Table view
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let line = modelForIndexPath(indexPath) else {
            return
        }
        selectedLines.append(line)
        print(selectedLines)
        configureToolbarButtons()
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        guard let line = modelForIndexPath(indexPath) else {
            return
        }
        selectedLines.removeObject(line)
        print(selectedLines)
        configureToolbarButtons()
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
