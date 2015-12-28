//
//  ChangedFileViewModel.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/28/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import GitUpKit

import RxSwift

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
    let staged: Bool
    let hunks: [Hunk]
    
    var indexChangeStream: Variable<String>
    
    // getting path from URL will have initial "/", which we don't want
    var relativeFilePath: String {
        get {
            return self.fileURL.path![1..<self.fileURL.path!.length]
        }
    }
    
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
    
    init(patch: GCDiffPatch, fileURL: NSURL, staged: Bool, indexChangeStream: Variable<String>) {
        self.patch = patch
        self.fileURL = fileURL
        self.staged = staged
        self.indexChangeStream = indexChangeStream
        
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
    
    private func lineNumberSets(lines: [Line]) -> (newLines: Set<UInt>, oldLines: Set<UInt>) {
        var newLines = Set<UInt>()
        var oldLines = Set<UInt>()
        for line in lines {
            if line.change == .Added {
                newLines.insert(line.newLineNumber!)
            }
            else if line.change == .Deleted {
                oldLines.insert(line.oldLineNumber!)
            }
        }
        return (newLines, oldLines)
    }
    
    func stageLines(lines: [Line]) -> ChangedFileViewModel? {
        guard let repoPath = activeRepositoryStream.value?.path, repo = try? GCRepository(existingLocalRepository: repoPath) else {
            return nil
        }
        
        let (newLines, oldLines) = lineNumberSets(lines)
        
        do {
            try repo.addLinesFromFileToIndex(relativeFilePath) {
                (change, oldLineNumber, newLineNumber) -> Bool in
                print("\(change) \(oldLineNumber) \(newLineNumber)")
                if (change == .Added) {
                    return newLines.contains(newLineNumber)
                }
                if (change == .Deleted) {
                    return oldLines.contains(oldLineNumber)
                }
                return true
            }
            
            indexChangeStream.value = "stagedLines"
            var newFile = getNewChangedFile()
            return newFile
        }
        catch let e as NSError {
            errorStream.value = e
            return nil
        }
    }
    
    func unstageLines(lines: [Line]) -> ChangedFileViewModel? {
        guard let repoPath = activeRepositoryStream.value?.path, repo = try? GCRepository(existingLocalRepository: repoPath) else {
            return nil
        }
        
        let (newLines, oldLines) = lineNumberSets(lines)
        
        do {
            try repo.resetLinesFromFileInIndexToHEAD(relativeFilePath, usingFilter: {
                (change, oldLineNumber, newLineNumber) -> Bool in
                if change == .Added {
                    return newLines.contains(newLineNumber)
                }
                if change == .Deleted {
                    return oldLines.contains(oldLineNumber)
                }
                return true
            })
            
            indexChangeStream.value = "unstagedLines"
            return getNewChangedFile()
        }
        catch let e as NSError {
            errorStream.value = e
            return nil
        }
    }
    
    func discardLines(lines: [Line]) -> ChangedFileViewModel? {
        guard let repoPath = activeRepositoryStream.value?.path, repo = try? GCRepository(existingLocalRepository: repoPath) else {
            return nil
        }
        
        let (newLines, oldLines) = lineNumberSets(lines)
        
        do {
            try repo.checkoutLinesFromFileFromIndex(relativeFilePath, usingFilter: {
                (change, oldLineNumber, newLineNumber) -> Bool in
                if change == .Added {
                    return newLines.contains(newLineNumber)
                }
                if change == .Deleted {
                    return oldLines.contains(oldLineNumber)
                }
                return true
            })
            
            
            indexChangeStream.value = "discardedLines"
            return getNewChangedFile()
        }
        catch let e as NSError {
            errorStream.value = e
            return nil
        }
    }
    
    private func getNewChangedFile() -> ChangedFileViewModel? {
        guard let repoPath = activeRepositoryStream.value?.path, repo = try? GCRepository(existingLocalRepository: repoPath) else {
            return nil
        }
        
        do {
            let diff: GCDiff
            if self.staged {
                diff = try repo.diffRepositoryIndexWithHEAD(relativeFilePath, options: .IncludeUntracked, maxInterHunkLines: 0, maxContextLines: 3)
            }
            else {
                diff = try repo.diffWorkingDirectoryWithRepositoryIndex(relativeFilePath, options: .IncludeUntracked, maxInterHunkLines: 0, maxContextLines: 3)
            }
            if diff.deltas.count != 1 {
                throw NSError(domain: "delta count when recalculating changed file != 1", code: 0, userInfo: nil)
            }
            let patch = try repo.makePatchForDiffDelta(diff.deltas[0] as! GCDiffDelta, isBinary: nil)
            let newChangedFile = ChangedFileViewModel(patch: patch, fileURL: self.fileURL, staged: self.staged, indexChangeStream: indexChangeStream)
            return newChangedFile
        }
        catch let e as NSError {
            errorStream.value = e
            return nil
        }
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

struct Line: Equatable {
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

func ==(lhs: Line, rhs: Line) -> Bool {
    print("comparing \(lhs) to \(rhs)")
    return lhs.change == rhs.change && lhs.oldLineNumber == rhs.oldLineNumber && lhs.newLineNumber == rhs.newLineNumber && lhs.content == rhs.content
}