//
//  FileBrowserTableViewController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/8/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit

class FileBrowserTableViewController: UITableViewController {
    
    var longPressBackButtonGestureRecognizer: UILongPressGestureRecognizer!
    
    var fileContentsViewController: FileContentsViewController?
    
    var directoryContents: DirectoryContents!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Create long-press view and gesture recognizer
        longPressBackButtonGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "longPressedNavigationBar:")
        self.navigationController!.navigationBar.addGestureRecognizer(longPressBackButtonGestureRecognizer)
        longPressBackButtonGestureRecognizer.enabled = true
        
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.fileContentsViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? FileContentsViewController
        }
        
        self.navigationItem.title = directoryContents.directoryName
        self.tableView.dataSource = directoryContents
    }
    
    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view delegate
    
    
    // TODO: take this navigation code and remove it from view controller
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == directoryContents.foldersSectionIndex { //tapped directory
            let newFileBrowser = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("fileBrowser") as! FileBrowserTableViewController
            newFileBrowser.directoryContents = DirectoryContents(directoryURL: directoryContents.directories[indexPath.row])
            self.navigationController!.showViewController(newFileBrowser, sender: directoryContents.directories[indexPath.row])
        }
        else { // tapped file
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
                url = directoryContents.files[indexPath.row]
                
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! FileContentsViewController
                controller.detailItem = url
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
                controller.fileContentsViewSettings = FileContentsViewSettings.sharedFileContentsViewSettings
            }
        }
    }
}
