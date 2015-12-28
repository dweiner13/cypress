//
//  IndexViewModel.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/28/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import GitUpKit
import RxSwift

let kCypressDefaultDiffOptions = GCDiffOptions.IncludeUntracked.union(.FindRenames)

struct IndexViewModel {
    
    let repository: GCRepository
    
    let unstagedChangedFiles = Variable<[ChangedFileViewModel]>([])
    let stagedChangedFiles = Variable<[ChangedFileViewModel]>([])
    
    var indexChangeStream: Variable<String>
    
    init(repositoryURL: NSURL, indexChangeStream: Variable<String>) throws {
        guard let path = repositoryURL.path else {
            throw NSError(domain: "indexviewmodel could not get path for repositoryURL \(repositoryURL)", code: 0, userInfo: nil)
        }
        repository = try GCRepository(existingLocalRepository: path)
        self.indexChangeStream = indexChangeStream
        (unstagedChangedFiles.value, stagedChangedFiles.value) = try readChangedFiles()
    }
    
    private func readChangedFiles() throws -> (unstaged: [ChangedFileViewModel], staged: [ChangedFileViewModel]) {
        var unstagedFiles = [ChangedFileViewModel]()
        var stagedFiles = [ChangedFileViewModel]()

        // unstaged changes
        let unstagedDiff = try repository.diffWorkingDirectoryWithRepositoryIndex(nil, options: kCypressDefaultDiffOptions, maxInterHunkLines: 0, maxContextLines: 3)
        
        guard let unstagedDeltas = unstagedDiff.deltas as? [GCDiffDelta] else {
            throw NSError(domain: "could not get list of deltas", code: 0, userInfo: nil)
        }
        
        for delta in unstagedDeltas {
            var isBinary = ObjCBool(false)
            let patch = try repository.makePatchForDiffDelta(delta, isBinary: &isBinary)
            let file = delta.canonicalPath
            unstagedFiles.append(ChangedFileViewModel(patch: patch, delta: delta, staged: false, indexChangeStream: indexChangeStream))
        }
        
        // staged changes
        let stagedDiff = try repository.diffRepositoryIndexWithHEAD(nil, options: kCypressDefaultDiffOptions, maxInterHunkLines: 0, maxContextLines: 3)
        
        guard let stagedDeltas = stagedDiff.deltas as? [GCDiffDelta] else {
            throw NSError(domain: "Could not get list of deltas", code: 0, userInfo: nil)
        }
        
        for delta in stagedDeltas {
            var isBinary = ObjCBool(false)
            let patch = try repository.makePatchForDiffDelta(delta, isBinary: &isBinary)
            let file = delta.canonicalPath
            stagedFiles.append(ChangedFileViewModel(patch: patch, delta: delta, staged: true, indexChangeStream: indexChangeStream))
        }
        
        return (unstagedFiles, stagedFiles)
    }
}
