//
//  RepositoryManager.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/17/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import Foundation
import GitUpKit
import RxSwift

private let _singletonSharedInstance = RepositoryManager()

class RepositoryManager {
    
    let disposeBag = DisposeBag()
    
    static func defaultManager() -> RepositoryManager {
        return _singletonSharedInstance
    }
    
    // MARK: - Creation
    
    func createNewRepositoryAtURL(url: NSURL) {
        if let repoPath = url.path {
            do {
                try GCRepository(newLocalRepository: repoPath, bare: false)
            }
            catch let e as NSError {
                errorStream.value = e
            }
        }
        else {
            errorStream.value = NSError(domain: "Could not create repository at \(url): could not get path", code: 0, userInfo: nil)
        }
    }
    
    func createNewRepositoryAtDefaultPathWithName(name: String) {
        let url = Cypress.getRepositoriesDirectoryURL().URLByAppendingPathComponent(name)
        createNewRepositoryAtURL(url)
    }
    
    func cloneRepository(url: NSURL) -> (localURL: NSURL, cloningProgress: Observable<RepositoryCloningDelegate.CloningEvent>)? {
        do {
            if let pathComponents = url.pathComponents {
                let gitName = pathComponents[pathComponents.count - 1] // "repo.git"
                let repoName = gitName.substringWithRange(gitName.startIndex ... gitName.endIndex.advancedBy(-5))
                let repoURL = Cypress.getRepositoriesDirectoryURL().URLByAppendingPathComponent(repoName, isDirectory: true)
                if let localPath = repoURL.path {
                    if NSFileManager.defaultManager().fileExistsAtPath(localPath) {
                        throw NSError(domain: "could not clone repository from \(url): already exists at \(localPath)", code: 0, userInfo: nil)
                    }
                    else {
                        let repository = try GCRepository(newLocalRepository: repoURL.path!, bare: false)
                        let remote = try repository.addRemoteWithName("origin", url: url)
                        let delegate = RepositoryCloningDelegate()
                        delegate.repository = repository
                        delegate.remote = remote
                        
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                            do {
                                repository.delegate = delegate
                                try repository.cloneUsingRemote(remote, recursive: false)
                            }
                            catch let e as NSError {
                                if e.code != -7 {
                                    errorStream.value = e
                                }
                            }
                        })
                        
                        // On error, delete temporary directory
                        delegate.cloningProgress
                            .subscribeError() {
                                _ in
                                debugLog("error received, deleting temporary repo at \(repoURL)")
                                self.deleteRepositoryAtURL(repoURL)
                            }
                            .addDisposableTo(disposeBag)
                        
                        return (repoURL, delegate.cloningProgress)
                    }
                }
                else {
                    throw NSError(domain: "could not clone repository from \(url): could not get local path", code: 0, userInfo: nil)
                }
            }
            else {
                throw NSError(domain: "could not clone repository from \(url): could not get URL path components", code: 0, userInfo: nil)
            }
        }
        catch let e as NSError {
            errorStream.value = e
        }
        
        return nil
    }
    
    // MARK: - Deletion
    
    func deleteRepositoryAtURL(url: NSURL) {
        if let path = url.path {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(path)
                if activeRepositoryStream.value == url {
                    activeRepositoryStream.value = nil
                }
            }
            catch let e as NSError {
                errorStream.value = e
            }
        }
        else {
            errorStream.value = NSError(domain: "Could not delete repository at \(url): could not get path", code: 0, userInfo: nil)
        }
    }
}