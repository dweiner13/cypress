//
//  FileBrowserTableViewController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/8/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit

class FileBrowserTableViewController: UITableViewController {
    
    var directory: NSURL?
    
    var files = [NSURL]()
    
    var directories = [NSURL]()
    
    var longPressBackButtonGestureRecognizer: UILongPressGestureRecognizer!
    
    var fileContentsViewController: FileContentsViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Create long-press view and gesture recognizer
        longPressBackButtonGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "longPressedNavigationBar:")
        self.navigationController!.navigationBar.addGestureRecognizer(longPressBackButtonGestureRecognizer)
        longPressBackButtonGestureRecognizer.enabled = true
        
        if directory == nil {
            resetDirectory()
        }
        else {
            self.populateDataFromDirectory()
        }
        
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.fileContentsViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? FileContentsViewController
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        
        super.viewWillAppear(animated)
    }
    
    func resetDirectory() {
        if let activeRepo = AppState.sharedAppState.activeRepository {
            directory = NSURL(fileURLWithPath: activeRepo.repository.workingDirectoryPath, isDirectory: true)
            files = []
            directories = []
            self.populateDataFromDirectory()
        }
        else {
            self.performSegueWithIdentifier("showRepositoryListSegue", sender: self)
            files = []
            directories = []
        }
    }
    
    func populateDataFromDirectory() {
        let contents = try! NSFileManager.defaultManager().contentsOfDirectoryAtURL(directory!, includingPropertiesForKeys: nil, options: .SkipsHiddenFiles)
        for item: NSURL in contents {
            var isDirectory: ObjCBool = ObjCBool(false)
            NSFileManager.defaultManager().fileExistsAtPath(item.path!, isDirectory: &isDirectory)
            if isDirectory {
                directories.append(item)
            }
            else {
                files.append(item)
            }
        }
        self.navigationItem.title = directory!.lastPathComponent
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var sectionCount = 0
        if !files.isEmpty {
            sectionCount++
        }
        if !directories.isEmpty {
            sectionCount++
        }
        
        return sectionCount
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if directories.isEmpty {
                return files.count
            }
            else {
                return directories.count
            }
        }
        else if section == 1 {
            return files.count
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            if directories.isEmpty {
                return "Files"
            }
            else {
                return "Folders"
            }
        }
        else if section == 1 {
            return "Files"
        }
        return nil
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("basicCell", forIndexPath: indexPath)
        if indexPath.section == 0 {
            if directories.isEmpty {
                cell.textLabel!.text = files[indexPath.row].lastPathComponent
            }
            else {
                cell.textLabel!.text = directories[indexPath.row].lastPathComponent
            }
        }
        else if indexPath.section == 1 {
            cell.textLabel!.text = files[indexPath.row].lastPathComponent
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && !directories.isEmpty {
            let newFileBrowser = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("fileBrowser") as! FileBrowserTableViewController
            newFileBrowser.directory = directories[indexPath.row]
            self.navigationController!.showViewController(newFileBrowser, sender: directories[indexPath.row])
        }
        else {
            self.performSegueWithIdentifier("showFileContents", sender: self)
        }
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showFileContents" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let url: NSURL?
                // doesn't check if selected row is in directories or files section but doesn't matter
                // because this segue will only be performed if selected row is in files section
                url = files[indexPath.row]
                
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! FileContentsViewController
                controller.detailItem = url
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
                controller.fileContentsViewSettings = FileContentsViewSettings.sharedFileContentsViewSettings
            }
        }
    }
}
