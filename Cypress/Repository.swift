//
//  Repository.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/6/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import GitUpKit

class Repository: NSObject, GCRepositoryDelegate {
    var repository: GCRepository!
    
    var delegate: RepositoryDelegate?
    
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
    
    init(url: NSURL, delegate: RepositoryDelegate?) throws {
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
            self.delegate = delegate
            repository.delegate = self
            let remote = try repository.addRemoteWithName("origin", url: url)
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                do {
                    try self.repository.cloneUsingRemote(remote, recursive: false)
                }
                catch let e as NSError {
                    print(e)
                }
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
    
    // MARK - GCRepositoryDelegate
    
    func repository(repository: GCRepository!, willStartTransferWithURL url: NSURL!) {
        print("forwarding willStartTransfer")
        self.delegate?.repository(self, willStartTransferWithURL: url)
    }
    
    func repository(repository: GCRepository!, updateTransferProgress progress: Float, transferredBytes bytes: UInt) {
        print("forwarding updateTransferProgress")
        self.delegate?.repository(self, updateTransferProgress: progress, transferredBytes: bytes)
    }
    
    func repository(repository: GCRepository!, didFinishTransferWithURL url: NSURL!, success: Bool) {
        print("forwarding didFinishTransferWithURL")
        self.delegate?.repository(self, didFinishTransferWithURL: url, success: success)
    }
    
    func repository(repository: GCRepository!, requiresPlainTextAuthenticationForURL url: NSURL!, user: String?, username: AutoreleasingUnsafeMutablePointer<NSString?>, password: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool {
        if let cred = self.credentials {
            username.memory = NSString(UTF8String: cred.username)
            password.memory = NSString(UTF8String: cred.password)
            return true
        }
        else {
            self.delegate?.repository(self, requiresPlainTextAuthenticationForURL: url, user: user, callback: getCredentialsCallback)
            return false
        }
    }
    
    // MARK: -
    
    var credentials: (username: String, password: String)? = nil
    
    func getCredentialsCallback(success: Bool, username: String?, password: String?) {
        if success {
            credentials = (username: username!, password: password!)
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                do {
                    try self.repository.cloneUsingRemote(self.repository.listRemotes()[0] as! GCRemote, recursive: false)
                }
                catch let e as NSError {
                    print(e)
                }
            })
        }
    }
}

protocol RepositoryDelegate {
    
    func repository(repository: Repository, willStartTransferWithURL url: NSURL)
    func repository(repository: Repository, updateTransferProgress progress: Float, transferredBytes bytes: UInt)
    func repository(repository: Repository, didFinishTransferWithURL url: NSURL, success: Bool)
    func repository(repository: Repository, requiresPlainTextAuthenticationForURL url: NSURL, user: String?, callback: (success: Bool, username: String?, password: String?) -> Void)
    
}
