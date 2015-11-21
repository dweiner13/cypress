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

class FileBrowserTableViewController: UIViewController, UITableViewDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    var directory: Variable<NSURL?> = Variable(nil)
    
    let disposeBag = DisposeBag()
    
    let files = Variable<[FileViewModel]>([])
    let directories = Variable<[FileViewModel]>([])
    
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, FileViewModel>>()
    
    typealias Section = SectionModel<String, FileViewModel>
    
    var longPressBackButtonGestureRecognizer: UILongPressGestureRecognizer!
    var fileContentsViewController: FileContentsViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.fileContentsViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? FileContentsViewController
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
                _ in
                self.loadFiles()
            }
            .addDisposableTo(disposeBag)
        
        tableView.rx_setDelegate(self)
            .addDisposableTo(disposeBag)
        
        tableView.rx_itemSelected
            .map() {
                indexPath in
                return self.dataSource.itemAtIndexPath(indexPath)
            }
            .subscribeNext() {
                item in
                if item.isDirectory { //tapped directory
                    let newFileBrowser = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("fileBrowser") as! FileBrowserTableViewController
                    newFileBrowser.directory.value = item.url
                    self.navigationController!.pushViewController(newFileBrowser, animated: true)
                }
                else { // tapped file
                    self.performSegueWithIdentifier("showFileContents", sender: self)
                }
            }
            .addDisposableTo(disposeBag)
    }
    
    func loadFiles() {
        // load files
        guard let dir = directory.value else {
            errorStream.value = NSError(domain: "directory not set for file browser table view controller", code: 0, userInfo: nil)
            return
        }
        let contents = try! NSFileManager.defaultManager().contentsOfDirectoryAtURL(dir, includingPropertiesForKeys: nil, options: .SkipsHiddenFiles)
        for item: NSURL in contents {
            var isDirectory: ObjCBool = ObjCBool(false)
            NSFileManager.defaultManager().fileExistsAtPath(item.path!, isDirectory: &isDirectory)
            if isDirectory {
                directories.value.append(FileViewModel(url: item))
            }
            else {
                files.value.append(FileViewModel(url: item))
            }
        }
        navigationItem.title = dir.lastPathComponent
    }
    
    override func viewWillAppear(animated: Bool) {
        // clear selection on viewWillAppear
        if self.splitViewController!.collapsed {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }
        
        // Create long-press view and gesture recognizer
        longPressBackButtonGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "longPressedNavigationBar:")
        self.navigationController!.navigationBar.addGestureRecognizer(longPressBackButtonGestureRecognizer)
        longPressBackButtonGestureRecognizer.enabled = true
        
        super.viewWillAppear(animated)
    }
    
    func longPressedNavigationBar(sender: UIGestureRecognizer) {
        if sender.state != .Began {
            return
        }
        // set default rectangle in case we can't find back button
        var rect = CGRect(x: 0, y: 0, width: 100, height: 40)
        
        //iterate through subviews looking for something where the back button should be
        for subview in self.navigationController!.navigationBar.subviews {
            if subview.frame.origin.x < 30 && subview.frame.width < self.navigationController!.navigationBar.frame.width/2 {
                rect = subview.frame
                break
            }
        }
        
        // get long press location
        let longPressPoint = sender.locationInView(self.navigationController!.navigationBar)
        
        if rect.contains(longPressPoint) {
            self.longPressedBackButton(rect)
        }
    }
    
    func longPressedBackButton(backButtonRect: CGRect) {
        let navigationHistoryViewController = NavigationHistoryTableViewController()
        navigationHistoryViewController.sourceNavigationController = self.navigationController!
        navigationHistoryViewController.modalPresentationStyle = .Popover
        navigationHistoryViewController.popoverPresentationController!.sourceRect = backButtonRect
        navigationHistoryViewController.popoverPresentationController!.sourceView = self.navigationController!.navigationBar
        navigationHistoryViewController.popoverPresentationController!.delegate = self.navigationController! as! CypressNavigationController
        self.navigationController?.presentViewController(navigationHistoryViewController, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        longPressBackButtonGestureRecognizer.enabled = false
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showFileContents" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let url: NSURL?
                // doesn't check if selected row is in directories or files section but doesn't matter
                // because this segue will only be performed if selected row is in files section
                url = dataSource.itemAtIndexPath(indexPath).url
                
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! FileContentsViewController
                controller.detailItem = url
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
                controller.fileContentsViewSettings = FileContentsViewSettings.sharedFileContentsViewSettings
            }
        }
    }
}
