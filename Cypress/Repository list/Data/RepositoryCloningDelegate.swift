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
    
    enum CloningEvent {
        case initialized
        case willStartTransfer
        case updateTransferProgress(Float)
        case requiresPlainTextAuthentication(url: NSURL, delegate: RepositoryCloningDelegate)
        case didFinishTransfer
        case error(ErrorType)
    }
    
    let credentials: Variable<(username: String, password: String)?> = Variable(nil)
    
    private let _cloningProgress: Variable<CloningEvent> = Variable(.initialized)
    var cloningProgress: Observable<CloningEvent>! = nil
    
    var repository: GCRepository?
    var remote: GCRemote?
    
    let disposeBag = DisposeBag()
    
    override init() {
        super.init()
        
        cloningProgress = create() {
            observer in
            return self._cloningProgress
                .subscribeNext() {
                    event in
                    switch event {
                        case .error(let e):
                            observer.onError(e)
                        case .didFinishTransfer:
                            observer.onCompleted()
                        default:
                            observer.onNext(event)
                    }
                }
        }
        // once credentials have been supplied (e.g. from a view controller
        // that shows an alert), retry cloning with credentials
        credentials
            .subscribeNext() {
                debugLog("credentials have been set to \($0)")
                if $0 != nil {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                        do {
                            try self.repository?.cloneUsingRemote(self.remote, recursive: false)
                        }
                        catch let e as NSError {
                            errorStream.value = e
                        }
                    })
                }
        }
    }
    
    func repository(repository: GCRepository!, willStartTransferWithURL url: NSURL!) {
        _cloningProgress.value = .willStartTransfer
    }
    
    func repository(repository: GCRepository!, updateTransferProgress progress: Float, transferredBytes bytes: UInt) {
        _cloningProgress.value = .updateTransferProgress(progress)
    }
    
    func repository(repository: GCRepository!, requiresPlainTextAuthenticationForURL url: NSURL!, user: String?, username: AutoreleasingUnsafeMutablePointer<NSString?>, password: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool {
        debugLog("requiresPlainTextAuthentication")
        if let creds = credentials.value {
            debugLog("credentials exist: \(creds)")
            username.memory = creds.username
            password.memory = creds.password
            credentials.value = nil
            return true
        }
        else {
            debugLog("credentials do not exist")
            
            debugLog("putting out call for authentication required")
            
            _cloningProgress.value = .requiresPlainTextAuthentication(url: url, delegate: self)
            
            return false
        }
    }
    
    func repository(repository: GCRepository!, didFinishTransferWithURL url: NSURL!, success: Bool) {
        if success {
            debugLog("didFinishTransfer successfully")
            _cloningProgress.value = .didFinishTransfer
        }
        else {
            debugLog("didFinishTransfer with error")
        }
    }
    
    func cancelTransfer() {
        _cloningProgress.value = .error(NSError(domain: "User canceled transfer", code: 0, userInfo: nil))
    }
    
    deinit {
        debugLog("RepositoryCloningDelegate deinit")
    }
}