//
//  DirectoryContents.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/15/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit

class DirectoryContents: NSObject, UITableViewDataSource {
    
    var directoryURL: NSURL? = nil
    var files = [NSURL]()
    var directories = [NSURL]()
    var directoryName: String?
    
    var foldersSectionIndex: Int? {
        get {
            if directories.isEmpty {
                return nil
            }
            else {
                return 0
            }
        }
    }
    
    var filesSectionIndex: Int {
        get {
            if directories.isEmpty {
                return 0
            }
            else {
                return 1
            }
        }
    }
    
    init(directoryURL: NSURL?) {
        super.init()
        if let url = directoryURL {
            self.directoryURL = url
            self.loadContents()
        }
        else { // If no URL is passed, we are at repo root dir or no repo is active
            if let activeRepo = AppState.sharedAppState.activeRepository {
                self.directoryURL = NSURL(fileURLWithPath: activeRepo.repository.workingDirectoryPath, isDirectory:true)
                self.loadContents()
            }
            else {
                files = []
                directories = []
            }
        }
    }
    
    func objectAtIndexPath(indexPath: NSIndexPath) -> NSURL? {
        if indexPath.section == foldersSectionIndex {
            return directories[indexPath.row]
        }
        else if indexPath.section == filesSectionIndex {
            return files[indexPath.row]
        }
        return nil
    }
    
    func loadContents() {
        let contents = try! NSFileManager.defaultManager().contentsOfDirectoryAtURL(directoryURL!, includingPropertiesForKeys: nil, options: .SkipsHiddenFiles)
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
        self.directoryName = directoryURL!.lastPathComponent!
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var sectionCount = 0
        if !files.isEmpty {
            sectionCount++
        }
        if !directories.isEmpty {
            sectionCount++
        }
        
        return sectionCount
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == foldersSectionIndex {
            return directories.count
        }
        else if section == filesSectionIndex {
            return files.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == foldersSectionIndex {
            return "Folders"
        }
        else if section == filesSectionIndex {
            return "Files"
        }
        return nil
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("basicCell", forIndexPath: indexPath)
        if indexPath.section == foldersSectionIndex {
            cell.textLabel!.text = directories[indexPath.row].lastPathComponent
        }
        else if indexPath.section == filesSectionIndex {
            cell.textLabel!.text = files[indexPath.row].lastPathComponent
        }
        return cell
    }
}
