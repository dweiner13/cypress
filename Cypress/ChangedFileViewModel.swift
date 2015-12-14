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
    
    let hunks: [Hunk]
    
    private func getChanges(patch: GCDiffPatch) -> [Hunk] {
        var hunks: [Hunk] = []
        var hunk: Hunk? = nil
        patch.enumerateUsingBeginHunkHandler({
            oldLineNumber, oldLineCount, newLineNumber, newLineCount in
            hunk = Hunk(oldLineNumber: oldLineNumber, oldLineCount: oldLineCount, newLineNumber: newLineNumber, newLineCount: newLineCount)
        }, lineHandler: {
            change, oldLineNumber, newLineNumber, contentBytes, contentLength in
            do {
                hunk?.addLine(try Line(change: change, oldLineNumber: oldLineNumber, newLineNumber: newLineNumber, contentBytes: contentBytes, contentLength: contentLength))
            }
            catch let e as NSError {
                errorStream.value = e
            }
        }, endHunkHandler: {
            guard let h = hunk else {
                return
            }
            hunks.append(h)
        })
        
        return hunks
    }
    
    init(patch: GCDiffPatch, fileURL: NSURL) {
        self.patch = patch
        self.fileURL = fileURL
        
        
        var changedHunks: [Hunk] = []
        var hunk: Hunk? = nil
        patch.enumerateUsingBeginHunkHandler({
            oldLineNumber, oldLineCount, newLineNumber, newLineCount in
            hunk = Hunk(oldLineNumber: oldLineNumber, oldLineCount: oldLineCount, newLineNumber: newLineNumber, newLineCount: newLineCount)
            }, lineHandler: {
                change, oldLineNumber, newLineNumber, contentBytes, contentLength in
                do {
                    hunk?.addLine(try Line(change: change, oldLineNumber: oldLineNumber, newLineNumber: newLineNumber, contentBytes: contentBytes, contentLength: contentLength))
                }
                catch let e as NSError {
                    errorStream.value = e
                }
            }, endHunkHandler: {
                guard let h = hunk else {
                    return
                }
                changedHunks.append(h)
        })
        
        self.hunks = changedHunks
    }
}

struct Hunk {
    var lines: [Line] = []
    let oldLineNumber: UInt
    let oldLineCount: UInt
    let newLineNumber: UInt
    let newLineCount: UInt
    
    mutating func addLine(line: Line) {
        self.lines.append(line)
    }
    
    init(oldLineNumber: UInt, oldLineCount: UInt, newLineNumber: UInt, newLineCount: UInt) {
        self.oldLineNumber = oldLineNumber
        self.oldLineCount = oldLineCount
        self.newLineNumber = newLineNumber
        self.newLineCount = newLineCount
    }
}

struct Line {
    let change: GCLineDiffChange
    let oldLineNumber: UInt?
    let newLineNumber: UInt?
    let content: String
    
    init(change: GCLineDiffChange, oldLineNumber: UInt, newLineNumber: UInt, contentBytes: UnsafePointer<Int8>, contentLength: UInt) throws {
        self.change = change
        if oldLineNumber.toInt != Int.max {
            self.oldLineNumber = oldLineNumber
        }
        else {
            self.oldLineNumber = nil
        }
        if newLineNumber.toInt != Int.max {
            self.newLineNumber = newLineNumber
        }
        else {
            self.newLineNumber = nil
        }
        
        guard let str = String.fromCString(contentBytes) else {
            throw NSError(domain: "Could not get string from C String", code: 0, userInfo: nil)
        }
        content = str[0..<contentLength.toInt]
    }
}