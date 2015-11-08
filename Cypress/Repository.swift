//
//  Repository.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/6/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import GitUpKit

class Repository: NSObject {
    var repository: GCRepository!
    
    var gcdelegate: GCRepositoryDelegate? {
        get {
            return self.repository.delegate
        }
        set {
            self.repository.delegate = newValue
        }
    }
    
    var name: String {
        get {
            let pathComponents = NSURL(fileURLWithPath: repository.workingDirectoryPath, isDirectory: true).pathComponents!;
            return pathComponents[pathComponents.count - 1]
        }
    }
    
    // ought to be able to init: new, from web URL
    
    init(name: String) throws {
        super.init()
        let repoPath = Cypress.getRepositoriesDirectoryURL().URLByAppendingPathComponent(name, isDirectory: true).path!
        if NSFileManager.defaultManager().fileExistsAtPath(repoPath) {
            repository = try GCRepository(existingLocalRepository: repoPath);
        }
        else {
            repository = try GCRepository(newLocalRepository: repoPath, bare: false);
        }
    }
    
    init(url: NSURL, gcdelegate: GCRepositoryDelegate?) throws {
        super.init()
        let pathComponents = url.pathComponents!
        let gitName = pathComponents[pathComponents.count - 1] // "repo.git"
        let repoName = gitName.substringWithRange(gitName.startIndex ... gitName.endIndex.advancedBy(-5))
        let repoURL = Cypress.getRepositoriesDirectoryURL().URLByAppendingPathComponent(repoName, isDirectory: true)
        if NSFileManager.defaultManager().fileExistsAtPath(repoURL.path!) {
            print("Repo with name already exists")
        }
        else {
            repository = try GCRepository(newLocalRepository: repoURL.path!, bare: false)
            self.gcdelegate = gcdelegate
            let remote = try repository.addRemoteWithName("origin", url: url)
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                try! self.repository.cloneUsingRemote(remote, recursive: false)
            })
        }
    }
    
    func delete() {
        do {
            try NSFileManager.defaultManager().removeItemAtPath(repository.workingDirectoryPath)
        }
        catch let e {
            print(e)
        }
    }
}
