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
    
    func createNewRepositoryAtURL(url: NSURL) throws {
        if let repoPath = url.path {
            let fileManager = NSFileManager.defaultManager()
            if fileManager.fileExistsAtPath(repoPath) {
                let error = NSError(domain: "Repository already exists at URL", code: 0, userInfo: nil)
                errorStream.value = error
                throw error
            }
            try fileManager.createDirectoryAtURL(url, withIntermediateDirectories: false, attributes: nil)
            do {
                try GCRepository(newLocalRepository: repoPath, bare: false)
            }
            catch let e as NSError {
                try fileManager.removeItemAtURL(url)
                throw e
            }
        }
        else {
            errorStream.value = NSError(domain: "Could not create repository at \(url): could not get path", code: 0, userInfo: nil)
        }
    }
    
    func createNewRepositoryAtDefaultPathWithName(name: String) throws -> NSURL {
        let url = Cypress.getRepositoriesDirectoryURL().URLByAppendingPathComponent(name)
        try createNewRepositoryAtURL(url)
        return url
    }
    
    func cloneRepository(url: NSURL) throws -> (localURL: NSURL, cloningProgress: Observable<RepositoryCloningDelegate.CloningEvent>)? {
        if let pathComponents = url.pathComponents {
            let gitName = pathComponents[pathComponents.count - 1] // "repo.git"
            let repoName = gitName.substringWithRange(gitName.startIndex ... gitName.endIndex.advancedBy(-5))
            let repoURL = Cypress.getRepositoriesDirectoryURL().URLByAppendingPathComponent(repoName, isDirectory: true)
            if let localPath = repoURL.path {
                if NSFileManager.defaultManager().fileExistsAtPath(localPath) {
                    throw NSError(domain: "could not clone repository from \(url): already exists at \(localPath)", code: 0, userInfo: nil)
                }
                else {
                    guard let path = repoURL.path else {
                        throw NSError(domain: "could not clone repositroy from \(url): could not get path of URL", code: 0, userInfo: nil)
                    }
                    let repository = try GCRepository(newLocalRepository: path, bare: false)
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
                            // if e.code is -7, then it was an authorization
                            // error, which we threw that ourselves before
                            // re-trying the download now that we know we need
                            // authentication
                            if e.code != -7 {
                                errorStream.value = e
                            }
                        }
                    })
                    
                    // On error, delete temporary directory
                    guard let cloningProgress = delegate.cloningProgress else {
                        errorStream.value = NSError(domain: "Cloning progress stream not set yet in delegate", code: 0, userInfo: nil)
                        return nil
                    }
                    cloningProgress
                        .subscribeError() {
                            [weak self] _ in
                            debugLog("error received, deleting temporary repo at \(repoURL)")
                            self?.deleteRepositoryAtURL(repoURL)
                        }
                        .addDisposableTo(disposeBag)
                    
                    return (repoURL, cloningProgress)
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