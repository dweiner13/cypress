//
//  RepositoryCloningDelegate.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/19/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import Foundation
import GitUpKit
import RxSwift

class RepositoryCloningDelegate: NSObject, GCRepositoryDelegate {
    
    let progressStream = Variable<CloningProgress?>(CloningProgress(progress: 0, completed: false, authenticationRequired: false, credentials: nil))
    
    var repository: GCRepository?
    var remote: GCRemote?
    
    let disposeBag = DisposeBag()
    
    override init() {
        super.init()
        
        progressStream
            .subscribeNext() {
                debugPrint("progressStream changed to \($0)")
            }
            .addDisposableTo(disposeBag)
    }
    
    func repository(repository: GCRepository!, willStartTransferWithURL url: NSURL!) {
        debugPrint("willStartTransfer")
        progressStream.value?.progress = 0.0
    }
    
    func repository(repository: GCRepository!, updateTransferProgress progress: Float, transferredBytes bytes: UInt) {
        progressStream.value?.progress = progress
    }
    
    func repository(repository: GCRepository!, requiresPlainTextAuthenticationForURL url: NSURL!, user: String?, username: AutoreleasingUnsafeMutablePointer<NSString?>, password: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool {
        debugPrint("requiresPlainTextAuthentication")
        if let creds = progressStream.value?.credentials {
            debugPrint("credentials exist: \(creds)")
            username.memory = creds.username
            password.memory = creds.password
            progressStream.value?.credentials = nil
            return true
        }
        else {
            debugPrint("credentials do not exist")
            // once credentials have been supplied (e.g. from a view controller
            // that shows an alert), retry cloning with credentials
            progressStream
                .filter() {
                    if let progress = $0 {
                        debugPrint("progress is not nil: \(progress)")
                        return progress.credentials != nil && progress.authenticationRequired
                    }
                    else {
                        debugPrint("returning false because progress is nil")
                        return false
                    }
                }
                .subscribeNext() {
                    if self.progressStream.value != nil {
                        do {
                            debugPrint("retrying because credentials now exist: \($0?.credentials!)")
                            self.progressStream.value!.authenticationRequired = false
                            if let repo = self.repository {
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                                    do {
                                        try repo.cloneUsingRemote(self.remote, recursive: false)
                                    }
                                    catch let e as NSError {
                                        errorStream.value = e
                                    }
                                })
                            }
                            else {
                                debugPrint("repo does not exist")
                            }
                            debugPrint("called retry request")
                        }
                        catch let e as NSError {
                            errorStream.value = e
                        }
                    }
                }
                .addDisposableTo(disposeBag)
            
            debugPrint("putting out call for authentication required")
            
            progressStream.value?.authenticationRequired = true
            
            return false
        }
    }
    
    func repository(repository: GCRepository!, didFinishTransferWithURL url: NSURL!, success: Bool) {
        if !success {
            debugPrint("didFinishTransfer with error")
            errorStream.value = NSError(domain: "repository transfer finished with error: \(repository.workingDirectoryPath)", code: 0, userInfo: nil)
        }
        else {
            debugPrint("didFinishTransfer successfully")
            progressStream.value = nil
        }
    }
    
    deinit {
        debugPrint("RepositoryCloningDelegate deinit")
    }
}

struct CloningProgress {
    
    var progress: Float
    var completed: Bool
    var authenticationRequired: Bool
    var credentials: (username: String, password: String)?
    
}