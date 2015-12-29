//
// Created by Daniel A. Weiner on 12/29/15.
// Copyright (c) 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import GitUpKit
import RxSwift
import RxCocoa

class ChangedFileListViewController: UIViewController, UITableViewDelegate {

    let disposeBag = DisposeBag()

    // Dependencies
    weak var masterViewController: CommitMasterViewController?
    var indexChangeStream: Variable<String>!
    var files: Observable<[ChangedFileViewModel]?>? {
        didSet {
            configure()
        }
    }

    @IBOutlet var tableView: UITableView!

    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, ChangedFileViewModel>>()
    typealias Section = SectionModel<String, ChangedFileViewModel>

    let rx_viewDidAppear = Variable<Bool>(false)

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerNib(UINib(nibName: "FileDiffCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "changedFileCell")

        if activeRepositoryStream.value == nil {
            performSegueWithIdentifier("showRepositoryListSegue", sender: nil)
        }
        
        guard let changedFiles = files else {
            debugLog("files does not exist yet")
            return
        }
    }
    
    func configure() {
        guard let changedFiles = files else {
            return
        }
        let allFiles = changedFiles.map() {
            (files) -> [Section] in
            guard let changedFiles = files else {
                return []
            }
            return [
                SectionModel(model: "Files", items: changedFiles)
            ]
        }
        
        dataSource.cellFactory = {
            (tableView, indexPath, file) in
            guard let cell = tableView.dequeueReusableCellWithIdentifier("changedFileCell") as? FileDiffCell else {
                errorStream.value = NSError(domain: "Could not deuqueue cell with identifier \("changedFileCell")", code: 0, userInfo: nil)
                return UITableViewCell()
            }
            cell.file.value = file
            return cell
        }
        
        dataSource.titleForHeaderInSection = {
            [unowned dataSource] sectionIndex in
            return dataSource.sectionAtIndex(sectionIndex).model
        }
        
        // reactive data source
        allFiles
            .bindTo(tableView.rx_itemsWithDataSource(dataSource))
            .addDisposableTo(disposeBag)
        
        self.tableView.rx_itemSelected
            .map() {
                [weak self] indexPath in
                return self?.dataSource.itemAtIndexPath(indexPath)
            }
            .subscribeNext() {
                [weak self] file in
                self?.masterViewController?.performSegueWithIdentifier("showFileChanges", sender: self)
            }
            .addDisposableTo(disposeBag)
        
        self.tableView.rx_setDelegate(self)
    }

    func fileForIndexPath(indexPath: NSIndexPath) -> ChangedFileViewModel? {
        if indexPath.section > dataSource.sectionModels.count {
            return nil
        }
        if indexPath.row > dataSource.sectionModels[indexPath.section].items.count {
            return nil
        }
        return dataSource.sectionModels[indexPath.section].items[indexPath.row]
    }

    // MARK: - Operations

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        guard let file = fileForIndexPath(indexPath) else {
            return nil
        }
        if file.staged {
            return [
                UITableViewRowAction(style: .Normal, title: "Unstage", handler: {
                    _ in
                    file.unstage()
                })
            ]
        }
        else {
            return [
                UITableViewRowAction(style: .Destructive, title: "Discard", handler: {
                    _ in
                    file.discard()
                }),
                UITableViewRowAction(style: .Normal, title: "Stage", handler: {
                    _ in
                    file.stage()
                })
            ]
        }
    }

}
