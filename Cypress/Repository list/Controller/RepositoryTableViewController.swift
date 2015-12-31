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
        tableView.delegate = self
    }
    
    override func bindViewModel() -> Bool {
        let vm = viewModel as! RepositoryListViewModel
        
        vm.repositories.subscribeNext() {
            [weak self] in
            self?.repositories = $0
            debugLog(self?.repositories)
            self?.tableView.reloadData()
        }
        .addDisposableTo(disposeBag)
        
        return true
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
            let vm = viewModel as! RepositoryListViewModel
            try vm.addNewRepository(name)
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
        let vm = viewModel as! RepositoryListViewModel
        
        do {
            if let cloningProgress = try vm.cloneRepository(url) {
                showProgressPrompt(cloningProgress)
                // bind actions to observable that emits status of cloning
                cloningProgress
                    .subscribe(onNext: {
                        [weak self] event in
                        debugLog(event)
                        switch event {
                            case .requiresPlainTextAuthentication(let url, let delegate):
                                self?.showAuthenticationPromptForURL(url, withDelegate: delegate)
                            default:
                                break
                            }
                    }, onError: {
                        [weak self] error in
                        let err = error as NSError
                        if err.domain != "User canceled transfer" {
                            self?.showErrorAlertWithMessage("\(err)")
                        }
                        errorStream.value = err
                    }, onCompleted: nil, onDisposed: nil)
                    .addDisposableTo(disposeBag)
            }
        }
        catch let e {
            showErrorAlertWithMessage(String(reflecting: e))
        }
    }
    
    func showProgressPrompt(progressStream: Observable<RepositoryCloningDelegate.CloningEvent>) {
        let alertController = UIAlertController(title: "Cloning repository", message: "In progress...", preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        self.presentViewController(alertController, animated: true, completion: nil)
        progressStream
            .subscribeCompleted {
                [weak self] () -> Void in
                debugLog("completed clone")
                self?.dismissViewControllerAnimated(true, completion: nil)
            }
            .addDisposableTo(disposeBag)
        progressStream
            .subscribeNext() {
                (progress: RepositoryCloningDelegate.CloningEvent) in
                debugLog(progress)
                switch progress {
                    case .updateTransferProgress(let percent):
                        alertController.message = "\(percent * 100)% complete"
                        break
                    default:
                        return
                }
            }
            .addDisposableTo(disposeBag)
        progressStream
            .subscribeError {
                [weak self] (e) -> Void in
                debugLog("clone error")
                self?.dismissViewControllerAnimated(true, completion: nil)
            }
            .addDisposableTo(disposeBag)
    }
    
    func showAuthenticationPromptForURL(url: NSURL, withDelegate delegate: RepositoryCloningDelegate) {
        debugLog("showing auth prompt")
        guard let urlHost = url.host else {
            errorStream.value = NSError(domain: "Could not get host from url \(url)", code: 0, userInfo: nil)
            return
        }
        let alertController = UIAlertController(title: "Authenticate", message: "Please enter your username and password for \(urlHost)", preferredStyle: .Alert)
        alertController.addTextFieldWithConfigurationHandler(nil)
        alertController.addTextFieldWithConfigurationHandler() {
            textField -> Void in
            textField.secureTextEntry = true
        }
        
        let confirmAction = UIAlertAction(title: "Okay", style: .Default, handler: {
            (action: UIAlertAction) -> Void in
            debugLog("setting credentials")
            guard let usernameFieldText = alertController.textFields?[0].text, passwordFieldText = alertController.textFields?[1].text else {
                errorStream.value = NSError(domain: "Could not get value of text fields from authentication alert view", code: 0, userInfo: nil)
                return
            }
            delegate.credentials.value = (username: usernameFieldText, password: passwordFieldText)
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

extension RepositoryTableViewController : UITableViewDataSource, UITableViewDelegate {
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
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        return [UITableViewRowAction(style: UITableViewRowActionStyle.Destructive, title: "Delete", handler: {
            _, _ in
            guard let vm = self.viewModel as? RepositoryListViewModel else {
                return
            }
            try! vm.deleteRepository(self.repositories![indexPath.row].url)
        })]
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
}
