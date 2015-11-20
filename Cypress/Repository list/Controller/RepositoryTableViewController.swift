//
//  RepoTableViewController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/6/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import GitUpKit

import RxSwift
import RxCocoa

private let repositoryListCellIdentifier = "RepositoryTableViewCell"

class RepositoryTableViewController: UIViewController, UITableViewDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    var disposeBag = DisposeBag()
    
    let repositories = Variable([RepositoryViewModel]())
    let otherRepositories = Variable([RepositoryViewModel]())
    
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, RepositoryViewModel>>()
    
    typealias Section = SectionModel<String, RepositoryViewModel>
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(UINib(nibName: repositoryListCellIdentifier, bundle: NSBundle.mainBundle()), forCellReuseIdentifier: repositoryListCellIdentifier)
        
        let allRepositories =
            self.repositories.map() {
                repositories in
                return [
                    SectionModel(model: "All Repositories", items: repositories)
                ]
            }
        
        dataSource.cellFactory = {
            (tableView, indexPath, repository: RepositoryViewModel) in
            let cell = tableView.dequeueReusableCellWithIdentifier(repositoryListCellIdentifier)! as! RepositoryTableViewCell
            cell.repository = repository
            return cell
        }
        
        dataSource.titleForHeaderInSection = {
            [unowned dataSource] sectionIndex in
            return dataSource.sectionAtIndex(sectionIndex).model
        }
        
        // reactive data source
        
        allRepositories
            .bindTo(tableView.rx_itemsWithDataSource(dataSource))
            .addDisposableTo(disposeBag)
        
        // Load repositories
        var repositories: [RepositoryViewModel] = []
        let fileManager = NSFileManager.defaultManager()
        let directoryURL = Cypress.getRepositoriesDirectoryURL()
        let contents = try! fileManager.contentsOfDirectoryAtURL(directoryURL, includingPropertiesForKeys: nil, options: .SkipsHiddenFiles)
        for item: NSURL in contents {
            var isDirectory: ObjCBool = ObjCBool(false)
            NSFileManager.defaultManager().fileExistsAtPath(item.path!, isDirectory: &isDirectory)
            if isDirectory {
                repositories.append(RepositoryViewModel(url: item, status: .Available))
            }
        }
        self.repositories.value = repositories
        
        tableView.rx_setDelegate(self)
            .addDisposableTo(disposeBag)
        
        tableView.rx_itemSelected
            .map() {
                indexPath in
                return self.repositories.value[indexPath.row]
            }
            .subscribeNext() {
                repo in
                activeRepositoryStream.value = repo.url
                self.dismissSelf()
            }
            .addDisposableTo(disposeBag)
        
        tableView.rx_itemDeleted
            .subscribeNext() {
                indexPath in
                self.removeItemAtPath(indexPath)
            }
            .addDisposableTo(disposeBag)
    }
    
    func removeItemAtPath(indexPath: NSIndexPath) {
        let repo = self.repositories.value[indexPath.row]
        self.repositories.value.removeAtIndex(indexPath.row)
        RepositoryManager.defaultManager().deleteRepositoryAtURL(repo.url)
    }

    // MARK: - UI Actions
    @IBAction func tappedAddButton(sender: UIBarButtonItem) {
        // TODO: this is just for debugging
        let url = NSURL(string: "https://github.com/ReactiveX/RxSwift.git")!
        if let result = RepositoryManager.defaultManager().cloneRepository(url) {
            let newRepo = RepositoryViewModel(url: result.localURL, status: .InProgress)
            self.repositories.value.append(newRepo)
            result.progressStream
                .subscribeNext() {
                    progress in
                    let index = self.repositories.value.indexOf({
                        newRepo.name == $0.name
                    })!
                    let originalValue = self.repositories.value[index]
                    print("progress update \(progress)")
                    if progress != 1.00 {
                        var newValue = RepositoryViewModel(url: originalValue.url, status: originalValue.status)
                        newValue.statusProgress = progress
                        self.repositories.value[index] = newValue
                    }
                    else {
                        var newValue = RepositoryViewModel(url: originalValue.url, status: .Available)
                        newValue.statusProgress = nil
                        self.repositories.value[index] = newValue
                    }
                }
                .addDisposableTo(disposeBag)
        }
    }
    
    func dismissSelf() {
        if let presenting = presentingViewController {
            presenting.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func tappedCancelButton(sender: UIBarButtonItem) {
        dismissSelf()
    }
}
