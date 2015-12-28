//
//  UICommitViewController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/21/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import GitUpKit
import RxSwift
import RxCocoa

class CommitViewController: CypressMasterViewController, UITableViewDelegate {
    
    let disposeBag = DisposeBag()
    
    //TODO: hook up
    @IBOutlet var tableView: UITableView!
    
    var index: Observable<IndexViewModel?>!
    
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, ChangedFileViewModel>>()
    
    typealias Section = SectionModel<String, ChangedFileViewModel>
    
    let rx_viewDidAppear = Variable<Bool>(false)
    
    let indexChangeStream = Variable<String>("")

    override func viewDidLoad() {
        super.viewDidLoad()
    
        tableView.registerNib(UINib(nibName: "FileDiffCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "changedFileCell")
        
        if activeRepositoryStream.value == nil {
            performSegueWithIdentifier("showRepositoryListSegue", sender: nil)
        }

        index = combineLatest(activeRepositoryStream, rx_viewDidAppear, indexChangeStream, resultSelector: {
            [weak self] (url, _, _) -> IndexViewModel? in
            guard let repoURL = url else {
                return nil
            }
            do {
                if let changeStream = self?.indexChangeStream {
                    return try IndexViewModel(repositoryURL: repoURL, indexChangeStream: changeStream)
                }
                else {
                    return nil
                }
            }
            catch let e as NSError {
                errorStream.value = e
                return nil
            }
        })
        
        let allFiles = index.map() {
            (index) -> [Section] in
            guard let ind = index else {
                return []
            }
            return [
                SectionModel(model: "Unstaged", items: ind.unstagedChangedFiles.value),
                SectionModel(model: "Staged", items: ind.stagedChangedFiles.value)
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
                self?.performSegueWithIdentifier("showFileChanges", sender: self)
            }
            .addDisposableTo(disposeBag)
    }
    
    override func viewDidAppear(animated: Bool) {
        rx_viewDidAppear.value = animated
        
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showFileChanges" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let file = dataSource.itemAtIndexPath(indexPath)
                
                guard let navController = segue.destinationViewController as? UINavigationController, diffViewController = navController.topViewController as? FileDiffViewController else {
                    errorStream.value = NSError(domain: "Could not get diff view controller in commit view controller", code: 1, userInfo: nil)
                    return
                }
                
                diffViewController.detailItem.value = file
                diffViewController.masterViewController = self
            }
        }
    }

}
