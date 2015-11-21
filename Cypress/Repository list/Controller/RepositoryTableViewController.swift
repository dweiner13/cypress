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
        let alertController = UIAlertController(title: "Add a repository", message: "", preferredStyle: .ActionSheet)
        
        let createNewAction = UIAlertAction(title: "Create new repository", style: .Default, handler: {
            (action: UIAlertAction) -> Void in
            self.tappedAddNewRepositoryAction()
        })
        let cloneAction = UIAlertAction(title: "Clone from a URL", style: .Default, handler: {
            (action: UIAlertAction) -> Void in
            self.tappedCloneRepositoryAction()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        alertController.addAction(createNewAction)
        alertController.addAction(cloneAction)
        alertController.addAction(cancelAction)
        
        alertController.popoverPresentationController?.barButtonItem = sender
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func tappedAddNewRepositoryAction() {
        showTextInputPrompt("New Repository", message: "Enter the name for the new repository", handler: {
            self.confirmedAddNewRepositoryWithName($0)
        })
    }
    
    func confirmedAddNewRepositoryWithName(name: String) {
        do {
            let url = try RepositoryManager.defaultManager().createNewRepositoryAtDefaultPathWithName(name)
            self.repositories.value.append(RepositoryViewModel(url: url))
        }
        catch let e as NSError {
            self.showErrorAlertWithMessage(String(reflecting: e))
            errorStream.value = e
        }
    }

    func tappedCloneRepositoryAction() {
        showTextInputPrompt("Clone Repository", message: "Enter the URL to clone from", handler: {
            if let url = NSURL(string: $0) {
                self.confirmedCloneRepositoryWithURL(url)
            }
            else {
                self.showErrorAlertWithMessage("Not a valid URL")
            }
        })
    }
    
    func confirmedCloneRepositoryWithURL(url: NSURL) {
        do {
            if let result = try RepositoryManager.defaultManager().cloneRepository(url) {
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
                        errorStream.value = err
                    }, onCompleted: nil, onDisposed: nil)
                    .addDisposableTo(disposeBag)
            }
        }
        catch let e as ErrorType {
            showErrorAlertWithMessage(String(reflecting: e))
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
