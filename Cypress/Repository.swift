//
//  Repository.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/6/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import GitUpKit

class Repository {
    var repository: GCRepository!
    
    var name: String {
        get {
            let pathComponents = NSURL(fileURLWithPath: repository.workingDirectoryPath, isDirectory: true).pathComponents!;
            return pathComponents[pathComponents.count - 1]
        }
    }
    
    // ought to be able to init: new, from web URL, from serialized format
    
    init(name: String) throws {
        let repoPath = Cypress.getRepositoriesDirectoryURL().URLByAppendingPathComponent(name, isDirectory: true).path!
        if NSFileManager.defaultManager().fileExistsAtPath(repoPath) {
            repository = try GCRepository(existingLocalRepository: repoPath);
        }
        else {
            repository = try GCRepository(newLocalRepository: repoPath, bare: false);
        }
    }
    
    init(url: NSURL) throws {
        let pathComponents = url.pathComponents!
        let gitName = pathComponents[pathComponents.count - 1] // "repo.git"
        let repoName = gitName.substringWithRange(gitName.startIndex ... gitName.endIndex.advancedBy(-5))
        let repoURL = Cypress.getRepositoriesDirectoryURL().URLByAppendingPathComponent(repoName, isDirectory: true)
        if NSFileManager.defaultManager().fileExistsAtPath(repoURL.path!) {
            print("Repo with name already exists")
        }
        else {
            repository = try GCRepository(newLocalRepository: repoURL.path!, bare: false)
            
            let remote = try repository.addRemoteWithName("origin", url: url)
            try repository.cloneUsingRemote(remote, recursive: false)
        }
    }
}
