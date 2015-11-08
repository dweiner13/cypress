//
//  FileBrowserTableViewController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/8/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit

class FileBrowserTableViewController: UITableViewController {
    
    var directory: NSURL!
    
    var files = [NSURL]()
    
    var directories = [NSURL]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let contents = try! NSFileManager.defaultManager().contentsOfDirectoryAtURL(directory, includingPropertiesForKeys: nil, options: .SkipsHiddenFiles)
        print(directory)
        print(contents)
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
        
        self.navigationItem.title = directory.lastPathComponent
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
}
