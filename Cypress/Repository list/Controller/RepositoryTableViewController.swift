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
    
    let disposeBag = DisposeBag()
    
    let repositories: Variable<[RepositoryViewModel]> = Variable([])
    
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, RepositoryViewModel>>()
    
    typealias Section = SectionModel<String, RepositoryViewModel>
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(UINib(nibName: repositoryListCellIdentifier, bundle: NSBundle.mainBundle()), forCellReuseIdentifier: repositoryListCellIdentifier)
        
        let allRepositories =
            self.repositories.map() {
                repos in
                return [
                    SectionModel(model: "All Repositories", items: repos)
                ]
            }
        
        dataSource.cellFactory = {
            (tableView, indexPath, repository: RepositoryViewModel) in
            let cell = tableView.dequeueReusableCellWithIdentifier(repositoryListCellIdentifier)! as! RepositoryTableViewCell
            cell.repository = repository
            cell.configureView()
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
                repositories.append(RepositoryViewModel(url: item))
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
        let url = NSURL(string: "https://github.com/danw13335/Cypress.git")!
//        let url = NSURL(string: "https://github.com/ReactiveX/RxSwift.git")!
        if let result = RepositoryManager.defaultManager().cloneRepository(url) {
            var newRepo = RepositoryViewModel(url: result.localURL)
            newRepo.cloningProgress = result.cloningProgress
            self.repositories.value.append(newRepo)
            
            // bind actions to observable that emits status of cloning
            newRepo.cloningProgress?
                .subscribe(onNext: {
                    event in
                    debugLog(event)
                    switch event {
                        case .requiresPlainTextAuthentication(let url, let delegate):
                            self.showAuthenticationPromptForURL(url, withDelegate: delegate)
                        default:
                            break
                    }
                }, onError: {
                    error in
                    if let repoIndex = self.repositories.value.indexOf(newRepo) {
                        self.repositories.value.removeAtIndex(repoIndex)
                    }
                    let err = error as NSError
                    if err.domain != "User canceled transfer" {
                        self.showErrorAlertWithMessage("\(err)")
                    }
                }, onCompleted: nil, onDisposed: nil)
                .addDisposableTo(disposeBag)
        }
    }
    
    func showAuthenticationPromptForURL(url: NSURL, withDelegate delegate: RepositoryCloningDelegate) {
        debugLog("showing auth prompt")
        let alertController = UIAlertController(title: "Authenticate", message: "Please enter your username and password for \(url.host!)", preferredStyle: .Alert)
        alertController.addTextFieldWithConfigurationHandler(nil)
        alertController.addTextFieldWithConfigurationHandler() {
            textField -> Void in
            textField.secureTextEntry = true
        }
        
        let confirmAction = UIAlertAction(title: "Okay", style: .Default, handler: {
            (action: UIAlertAction) -> Void in
            debugLog("setting credentials")
            delegate.credentials.value = (username: alertController.textFields![0].text!, password: alertController.textFields![1].text!)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            _ in
            debugLog("cancelling")
            delegate.cancelTransfer()
        })
        
        alertController.addAction(confirmAction)
        alertController.preferredAction = confirmAction
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
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
