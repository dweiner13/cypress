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
    var canonicalPath: String
    let staged: Bool
    let hunks: [Hunk]
    let delta: GCDiffDelta
    let isBinary: Bool
    
    var indexChangeStream: Variable<String>
    
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
    
    init(patch: GCDiffPatch, delta: GCDiffDelta, staged: Bool, indexChangeStream: Variable<String>, isBinary: Bool) {
        self.patch = patch
        self.staged = staged
        self.indexChangeStream = indexChangeStream
        self.canonicalPath = delta.canonicalPath
        self.delta = delta
        self.isBinary = isBinary
        
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
    
    // MARK: - Operations
    
    func stage() {
        guard let repoPath = activeRepositoryStream.value?.path, repo = try? GCRepository(existingLocalRepository: repoPath) else {
            return
        }
        
        do {
            print(canonicalPath)
            let fileManager = NSFileManager.defaultManager()
            if fileManager.fileExistsAtPath(repo.absolutePathForFile(canonicalPath)) {
                try repo.addFileToIndex(canonicalPath)
            }
            else {
                try repo.removeFileFromIndex(canonicalPath)
            }
            indexChangeStream.value = "stagedFile"
        }
        catch let e as NSError {
            errorStream.value = e
        }
    }
    
    func unstage() {
        guard let repoPath = activeRepositoryStream.value?.path, repo = try? GCRepository(existingLocalRepository: repoPath) else {
            return
        }
        
        do {
            try repo.resetFileInIndexToHEAD(canonicalPath)
            indexChangeStream.value = "unstagedFile"
        }
        catch let e as NSError {
            errorStream.value = e
        }
    }
    
    func discard() {
        guard let repoPath = activeRepositoryStream.value?.path, repo = try? GCRepository(existingLocalRepository: repoPath) else {
            return
        }
        
        do {
            try repo.safeDeleteFileIfExists(canonicalPath)
            try repo.checkoutFileFromIndex(canonicalPath)
            
            indexChangeStream.value = "discardedFile"
        }
        catch let e as NSError {
            errorStream.value = e
        }
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
            try repo.addLinesFromFileToIndex(canonicalPath) {
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
            try repo.resetLinesFromFileInIndexToHEAD(canonicalPath, usingFilter: {
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
            try repo.checkoutLinesFromFileFromIndex(canonicalPath, usingFilter: {
                (change, oldLineNumber, newLineNumber) -> Bool in
                if change == .Added {
                    return newLines.contains(newLineNumber)
                }
                if change == .Deleted {
                    return oldLines.contains(oldLineNumber)
                }
                return false
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
                diff = try repo.diffRepositoryIndexWithHEAD(canonicalPath, options: kCypressDefaultDiffOptions, maxInterHunkLines: 0, maxContextLines: 3)
            }
            else {
                diff = try repo.diffWorkingDirectoryWithRepositoryIndex(canonicalPath, options: kCypressDefaultDiffOptions, maxInterHunkLines: 0, maxContextLines: 3)
            }
            let patch = try repo.makePatchForDiffDelta(diff.deltas[0] as! GCDiffDelta, isBinary: nil)
            let newChangedFile = ChangedFileViewModel(patch: patch, delta: diff.deltas[0] as! GCDiffDelta, staged: staged, indexChangeStream: indexChangeStream, isBinary: isBinary)
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