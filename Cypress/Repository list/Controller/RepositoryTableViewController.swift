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

class RepositoryTableViewController: BaseViewController {
    
    @IBOutlet var tableView: UITableView!
    var repositories: [RepositoryViewModel]?
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(UINib(nibName: repositoryListCellIdentifier, bundle: NSBundle.mainBundle()), forCellReuseIdentifier: repositoryListCellIdentifier)
        viewModel = RepositoryListViewModel(coordinator: CypressCoordinator(rootViewController: self))
        bindViewModel()
        
        tableView.dataSource = self
    }
    
    override func bindViewModel() -> Bool {
        let vm = viewModel as! RepositoryListViewModel
        
        vm.repositories.subscribeNext() {
            [weak self] in
            debugLog("repositories update")
            self?.repositories = $0
            debugLog(self?.repositories)
            self?.tableView.reloadData()
        }
        .addDisposableTo(disposeBag)
        
        return true
    }

    // MARK: - UI Actions
//    @IBAction func tappedAddButton(sender: UIBarButtonItem) {
//        let alertController = UIAlertController(title: "Add a repository", message: "", preferredStyle: .ActionSheet)
//        
//        let createNewAction = UIAlertAction(title: "Create new repository", style: .Default, handler: {
//            (action: UIAlertAction) -> Void in
//            self.tappedAddNewRepositoryAction()
//        })
//        let cloneAction = UIAlertAction(title: "Clone from a URL", style: .Default, handler: {
//            (action: UIAlertAction) -> Void in
//            self.tappedCloneRepositoryAction()
//        })
//        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
//        
//        alertController.addAction(createNewAction)
//        alertController.addAction(cloneAction)
//        alertController.addAction(cancelAction)
//        
//        alertController.popoverPresentationController?.barButtonItem = sender
//        
//        self.presentViewController(alertController, animated: true, completion: nil)
//    }
//    
//    func tappedAddNewRepositoryAction() {
//        showTextInputPrompt("New Repository", message: "Enter the name for the new repository", handler: {
//            self.confirmedAddNewRepositoryWithName($0)
//        })
//    }
//    
//    func confirmedAddNewRepositoryWithName(name: String) {
//        do {
//            let url = try RepositoryManager.defaultManager().createNewRepositoryAtDefaultPathWithName(name)
//        }
//        catch let e as NSError {
//            self.showErrorAlertWithMessage(String(reflecting: e))
//            errorStream.value = e
//        }
//    }
//
//    func tappedCloneRepositoryAction() {
//        showTextInputPrompt("Clone Repository", message: "Enter the URL to clone from", handler: {
//            if let url = NSURL(string: $0) {
//                self.confirmedCloneRepositoryWithURL(url)
//            }
//            else {
//                self.showErrorAlertWithMessage("Not a valid URL")
//            }
//        })
//    }
//    
//    func confirmedCloneRepositoryWithURL(url: NSURL) {
//        do {
//            if let result = try RepositoryManager.defaultManager().cloneRepository(url) {
//                var newRepo = RepositoryViewModel(url: result.localURL)
//                newRepo.cloningProgress = result.cloningProgress
//                self.repositories.value.append(newRepo)
//                
//                // bind actions to observable that emits status of cloning
//                newRepo.cloningProgress?
//                    .subscribe(onNext: {
//                        [weak self] event in
//                        debugLog(event)
//                        switch event {
//                            case .requiresPlainTextAuthentication(let url, let delegate):
//                                self?.showAuthenticationPromptForURL(url, withDelegate: delegate)
//                            default:
//                                break
//                            }
//                    }, onError: {
//                        [weak self] error in
//                        if let repoIndex = self?.repositories.value.indexOf(newRepo) {
//                            self?.repositories.value.removeAtIndex(repoIndex)
//                        }
//                        let err = error as NSError
//                        if err.domain != "User canceled transfer" {
//                            self?.showErrorAlertWithMessage("\(err)")
//                        }
//                        errorStream.value = err
//                    }, onCompleted: nil, onDisposed: nil)
//                    .addDisposableTo(disposeBag)
//            }
//        }
//        catch let e {
//            showErrorAlertWithMessage(String(reflecting: e))
//        }
//    }
//    
//    func showAuthenticationPromptForURL(url: NSURL, withDelegate delegate: RepositoryCloningDelegate) {
//        debugLog("showing auth prompt")
//        guard let urlHost = url.host else {
//            errorStream.value = NSError(domain: "Could not get host from url \(url)", code: 0, userInfo: nil)
//            return
//        }
//        let alertController = UIAlertController(title: "Authenticate", message: "Please enter your username and password for \(urlHost)", preferredStyle: .Alert)
//        alertController.addTextFieldWithConfigurationHandler(nil)
//        alertController.addTextFieldWithConfigurationHandler() {
//            textField -> Void in
//            textField.secureTextEntry = true
//        }
//        
//        let confirmAction = UIAlertAction(title: "Okay", style: .Default, handler: {
//            (action: UIAlertAction) -> Void in
//            debugLog("setting credentials")
//            guard let usernameFieldText = alertController.textFields?[0].text, passwordFieldText = alertController.textFields?[1].text else {
//                errorStream.value = NSError(domain: "Could not get value of text fields from authentication alert view", code: 0, userInfo: nil)
//                return
//            }
//            delegate.credentials.value = (username: usernameFieldText, password: passwordFieldText)
//        })
//        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
//            _ in
//            debugLog("cancelling")
//            delegate.cancelTransfer()
//        })
//        
//        alertController.addAction(confirmAction)
//        alertController.preferredAction = confirmAction
//        alertController.addAction(cancelAction)
//        
//        self.presentViewController(alertController, animated: true, completion: nil)
//    }
//    
//    func dismissSelf() {
//        if let presenting = presentingViewController {
//            presenting.dismissViewControllerAnimated(true, completion: nil)
//        }
//    }
//    
//    @IBAction func tappedCancelButton(sender: UIBarButtonItem) {
//        dismissSelf()
//    }
}

extension RepositoryTableViewController : UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        debugLog(section)
        if section == 0 {
            debugLog(repositories)
            if let repos = repositories {
                return repos.count
            }
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier(repositoryListCellIdentifier) as? RepositoryTableViewCell else {
            return UITableViewCell()
        }
        
        cell.repository = repositories?[indexPath.row]
        cell.configureView()
        
        return cell
    }
}
