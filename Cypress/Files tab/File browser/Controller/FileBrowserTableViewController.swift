//
//  FileBrowserTableViewController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/8/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

private let basicCellIdentifier = "basicCell"

class FileBrowserTableViewController: CypressMasterViewController, UITableViewDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    var directory = Variable<NSURL?>(nil)
    
    let disposeBag = DisposeBag()
    
    let files = Variable<[FileViewModel]>([])
    let directories = Variable<[FileViewModel]>([])
    
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, FileViewModel>>()
    
    typealias Section = SectionModel<String, FileViewModel>
    
    var longPressBackButtonGestureRecognizer: UILongPressGestureRecognizer?
    var fileContentsViewController: FileContentsViewController?
    
    let fileOperationStream = Variable<String?>("")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if activeRepositoryStream.value == nil {
            performSegueWithIdentifier("showRepositoryListSegue", sender: nil)
        }
        
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            debugLog((controllers[controllers.count-1] as? UINavigationController)!.topViewController as? FileContentsViewController)
            guard let navController = controllers[controllers.count-1] as? UINavigationController else {
                errorStream.value = NSError(domain: "Could not get file contents view controller for file browser", code: 0, userInfo: nil)
                return
            }
            self.fileContentsViewController = navController.topViewController as? FileContentsViewController
        }
        
        let allFiles = combineLatest(files, directories) {
            (files: [FileViewModel], directories: [FileViewModel]) throws -> [Section] in
            var sections = [Section]()
            if !directories.isEmpty {
                sections.append(SectionModel(model: "Folders", items: directories))
            }
            if !files.isEmpty {
                sections.append(SectionModel(model: "Files", items: files))
            }
            return sections
        }
        
        dataSource.cellFactory = {
            (tableView, indexPath, file) in
            guard let cell = tableView.dequeueReusableCellWithIdentifier(basicCellIdentifier) else {
                errorStream.value = NSError(domain: "Could not deuqueue cell with identifier \(basicCellIdentifier)", code: 0, userInfo: nil)
                return UITableViewCell()
            }
            guard let textLabel = cell.textLabel else {
                errorStream.value = NSError(domain: "Could not get text label for cell in FileBrowserTableViewController", code: 0, userInfo: nil)
                return UITableViewCell()
            }
            textLabel.text = file.name
            if file.isDirectory {
                cell.accessoryType = .DisclosureIndicator
            }
            else {
                cell.accessoryType = .None
            }
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
        
        self.directory
            .subscribeNext() {
                [weak self] in
                if let dir = $0 {
                    self?.loadFilesForDirectory(dir)
                }
            }
            .addDisposableTo(disposeBag)
        
        tableView.rx_setDelegate(self)
            .addDisposableTo(disposeBag)
        
        tableView.rx_itemSelected
            .map() {
                [weak self] indexPath in
                return self?.dataSource.itemAtIndexPath(indexPath)
            }
            .subscribeNext() {
                [weak self] item in
                guard let file = item else {
                    return
                }
                if file.isDirectory { //tapped directory
                    guard let newFileBrowser = UIStoryboard(name: "FileBrowser", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("fileBrowserTableViewController") as? FileBrowserTableViewController else {
                        errorStream.value = NSError(domain: "Could not get file browser controller from storyboard", code: 0, userInfo: nil)
                        return
                    }
                    newFileBrowser.directory.value = file.url
                    guard let navController = self?.navigationController else {
                        errorStream.value = NSError(domain: "navController does not exist for FileBrowserTableViewController", code: 0, userInfo: nil)
                        return
                    }
                    navController.pushViewController(newFileBrowser, animated: true)
                }
                else { // tapped file
                    self?.performSegueWithIdentifier("showFileContents", sender: self)
                }
            }
            .addDisposableTo(disposeBag)
        
        fileOperationStream.subscribeNext() {
            [weak self] _ in
            if let s = self, dir = s.directory.value {
                s.loadFilesForDirectory(dir)
            }
        }
        .addDisposableTo(disposeBag)
    }
    
    func loadFilesForDirectory(dir: NSURL) {
        // load files
        guard let contents = try? NSFileManager.defaultManager().contentsOfDirectoryAtURL(dir, includingPropertiesForKeys: nil, options: .SkipsHiddenFiles) else {
            errorStream.value = NSError(domain: "could not read contents of directory at URL \(dir)", code: 0, userInfo: nil)
            return
        }
        var directoryItems = [FileViewModel]()
        var fileItems = [FileViewModel]()
        for item: NSURL in contents {
            var isDirectory: ObjCBool = ObjCBool(false)
            guard let path = item.path else {
                errorStream.value = NSError(domain: "could not get path for item url \(item)", code: 0, userInfo: nil)
                return
            }
            NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDirectory)
            if isDirectory {
                directoryItems.append(FileViewModel(url: item))
            }
            else {
                fileItems.append(FileViewModel(url: item))
            }
        }
        directories.value = directoryItems
        files.value = fileItems
        navigationItem.title = dir.lastPathComponent
    }
    
    override func viewWillAppear(animated: Bool) {
        // clear selection on viewWillAppear
        guard let split = self.splitViewController else {
            errorStream.value = NSError(domain: "could not get split view controller in file browser table view controller", code: 0, userInfo: nil)
            return
        }
        guard let navigation = self.navigationController else {
            errorStream.value = NSError(domain: "could not get navigation controller in file browser table view controller", code: 1, userInfo: nil)
            return
        }
        if split.collapsed {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }
        
        // Create long-press view and gesture recognizer
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(FileBrowserTableViewController.longPressedNavigationBar(_:)))
        navigation.navigationBar.addGestureRecognizer(recognizer)
        recognizer.enabled = true
        longPressBackButtonGestureRecognizer = recognizer
        
        super.viewWillAppear(animated)
    }
    
    func longPressedNavigationBar(sender: UIGestureRecognizer) {
        if sender.state != .Began {
            return
        }
        // set default rectangle in case we can't find back button
        var rect = CGRect(x: 0, y: 0, width: 100, height: 40)
        
        guard let navigation = self.navigationController else {
            errorStream.value = NSError(domain: "could not get navigation controller in file browser table view controller", code: 2, userInfo: nil)
            return
        }
        //iterate through subviews looking for something where the back button should be
        for subview in navigation.navigationBar.subviews {
            if subview.frame.origin.x < 30 && subview.frame.width < navigation.navigationBar.frame.width/2 {
                rect = subview.frame
                break
            }
        }
        
        // get long press location
        let longPressPoint = sender.locationInView(navigation.navigationBar)
        
        if rect.contains(longPressPoint) {
            self.longPressedBackButton(rect)
        }
    }
    
    func longPressedBackButton(backButtonRect: CGRect) {
        let navigationHistoryViewController = NavigationHistoryTableViewController()
        guard let navigation = self.navigationController as? CypressNavigationController else {
            errorStream.value = NSError(domain: "could not get navigation controller in file browser table view controller", code: 3, userInfo: nil)
            return
        }
        navigationHistoryViewController.sourceNavigationController = navigation
        navigationHistoryViewController.modalPresentationStyle = .Popover
        guard let popover = navigationHistoryViewController.popoverPresentationController else {
            errorStream.value = NSError(domain: "Could not get popover presentation controller for navigation history controller in file browser view controller", code: 0, userInfo: nil)
            return
        }
        popover.sourceRect = backButtonRect
        popover.sourceView = navigation.navigationBar
        popover.delegate = navigation
        navigation.presentViewController(navigationHistoryViewController, animated: true, completion: nil)
    }
    
    private func fileForIndexPath(indexPath: NSIndexPath) -> FileViewModel? {
        if indexPath.section == 0 {
            if indexPath.row >= directories.value.count {
                return nil
            }
            return directories.value[indexPath.row]
        }
        else if indexPath.section == 1 {
            if indexPath.row >= files.value.count {
                return nil
            }
            return files.value[indexPath.row]
        }
        return nil
    }
    
    override func viewWillDisappear(animated: Bool) {
        guard let recognizer = longPressBackButtonGestureRecognizer else {
            errorStream.value = NSError(domain: "could not get long press gesture recognizer in FileBrowserTableViewController", code: 0, userInfo: nil)
            return
        }
        recognizer.enabled = false
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        guard let file = fileForIndexPath(indexPath) else {
            return nil
        }
        return [
            UITableViewRowAction(style: UITableViewRowActionStyle.Destructive, title: "Delete", handler: {
                _ in
                do {
                    try file.deleteFile()
                    self.fileOperationStream.value = "Delete"
                }
                catch let e as NSError {
                    self.showErrorAlertWithMessage("Could not delete file:\n\(e.localizedDescription)")
                }
            }),
            UITableViewRowAction(style: .Normal, title: "More", handler: {
                _ in
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
                alert.addAction(UIAlertAction(title: "Rename", style: .Default, handler: {
                    _ in
                    self.showTextInputPrompt("New file name", message: "Enter the new name for \"\(file.name)\"", handler: {
                        (newName) -> Void in
                        do {
                            try file.renameFile(newName)
                            self.fileOperationStream.value = "Rename"
                        }
                        catch let e as NSError {
                            self.showErrorAlertWithMessage("Could not rename file:\n\(e.localizedDescription)")
                        }
                    })
                }))
                alert.addAction(UIAlertAction(title: "Duplicate", style: .Default, handler: {
                    _ in
                    do {
                        try file.duplicateFile()
                        self.fileOperationStream.value = "Duplicate"
                    }
                    catch let e as NSError {
                        self.showErrorAlertWithMessage("Could not rename file:\n\(e.localizedDescription)")
                    }
                }))
                
                if let popover = alert.popoverPresentationController {
                    popover.sourceView = self.tableView
                    popover.sourceRect = self.tableView.rectForRowAtIndexPath(indexPath)
                }
                
                self.presentViewController(alert, animated: true, completion: nil)
            })
        ]
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showFileContents" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let url: NSURL?
                // doesn't check if selected row is in directories or files section but doesn't matter
                // because this segue will only be performed if selected row is in files section
                url = dataSource.itemAtIndexPath(indexPath).url
                
                guard let navController = segue.destinationViewController as? UINavigationController, fileContentsViewController = navController.topViewController as? FileContentsViewController else {
                    errorStream.value = NSError(domain: "Could not get file contents view controller for file browser", code: 1, userInfo: nil)
                    return
                }
                fileContentsViewController.detailItem.value = url
                fileContentsViewController.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                fileContentsViewController.navigationItem.leftItemsSupplementBackButton = true
                fileContentsViewController.fileContentsViewSettings = FileContentsViewSettings.sharedFileContentsViewSettings
            }
        }
    }
}
