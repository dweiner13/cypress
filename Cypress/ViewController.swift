//
//  ViewController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/1/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import GitUpKit

class ViewController: UIViewController {
    
    var repoDirectory: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
        self.repoDirectory = documentDirectoryPath.stringByAppendingString("/repo")
        listFilesAtPath(self.repoDirectory)
        clearDocuments()
        if !NSFileManager.defaultManager().fileExistsAtPath(repoDirectory) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(repoDirectory, withIntermediateDirectories: false, attributes: nil)
            }
            catch let createDirectoryError as NSError {
                print("Error with creating directory at path: \(createDirectoryError.localizedDescription)");
            }
        }
        let fileName = "\(self.repoDirectory)/test2.txt"
        let content = "Hello World"
        do {
            try content.writeToFile(fileName, atomically: false, encoding: NSUTF8StringEncoding)
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }
        listFilesAtPath(repoDirectory)
        testRepo()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func listFilesAtPath(path: String) {
        do {
            let directoryContent = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(path)
            print(directoryContent.count)
            for file in directoryContent {
                print(file)
            }
        }
        catch let error as NSError {
            print("Error: \(error.localizedDescription)")
        }
    }
    
    func testRepo() {
        do {
            // create repo
            let repo = try? GCRepository(newLocalRepository: self.repoDirectory, bare: false)
            print(repo)
            // config user info
            try repo?.writeConfigOptionForLevel(GCConfigLevel.Global, variable: "user.name", withValue: "Beep Boop")
            try repo?.writeConfigOptionForLevel(GCConfigLevel.Global, variable: "user.email", withValue: "beep.boop@me.com")
            // commit file to repo
            try repo?.addFileToIndex("test2.txt")
            try repo?.createCommitFromHEADWithMessage("test commit")
        }
        catch let error as NSError {
            print("Error: \(error.localizedDescription)")
        }
        // get head branch and commit
//        var headBranch: GCLocalBranch? = nil
//        var headCommit: GCCommit? = nil
//        try! repo?.lookupHEADCurrentCommit(&headCommit, branch: &headBranch)
//        print(headBranch)
//        print(headCommit)
    }
    
    func clearDocuments() {
        do {
            let directoryContent = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(repoDirectory)
            print(directoryContent.count)
            for file in directoryContent {
                print("deleting file \(file)")
                let fullPath = "\(repoDirectory)/\(file)"
                try NSFileManager.defaultManager().removeItemAtPath(fullPath)
            }
        }
        catch let error as NSError {
            print("Error: \(error.localizedDescription)")
        }
    }
}

