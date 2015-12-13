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
    
    func getChanges() {
        self.patch.enumerateUsingBeginHunkHandler({
            oldLineNumber, oldLineCount, newLineNumber, newLineCount in
            print("oldLineNumber: \(oldLineNumber), oldLineCount: \(oldLineCount), newLineNumber: \(newLineNumber), newLineCount: \(newLineCount)")
        }, lineHandler: {
            change, oldLineNumber, newLineNumber, contentBytes, contentLength in
            print("\tchange: \(change.rawValue), oldLineNumber: \(oldLineNumber), newLineNumber: \(newLineNumber), contentBytes: \(String.fromCString(contentBytes)), contentLength: \(contentLength)")
            }, endHunkHandler: { return })
    }
    
    init(patch: GCDiffPatch, fileURL: NSURL) {
        self.patch = patch
        self.fileURL = fileURL
    }
}
