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
    
    let progressStream = Variable<Float?>(0)
    
    override init() {
        super.init()
    }
    
    func repository(repository: GCRepository!, willStartTransferWithURL url: NSURL!) {
        progressStream.value = 0.0
    }
    
    func repository(repository: GCRepository!, updateTransferProgress progress: Float, transferredBytes bytes: UInt) {
        progressStream.value = progress
    }
    
    deinit {
        print("RepositoryCloningDelegate deinit")
    }
}