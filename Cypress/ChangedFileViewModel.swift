//
//  ChangedFileViewModel.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/28/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import GitUpKit

struct ChangedFileViewModel {
    let patch: GCDiffPatch
    let fileURL: NSURL
    var fileName: String {
        get {
            guard let name = fileURL.lastPathComponent else {
                return ""
            }
            return name
        }
    }
    
    init(patch: GCDiffPatch, fileURL: NSURL) {
        self.patch = patch
        self.fileURL = fileURL
    }
}
