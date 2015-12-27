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

let CypressDefaultDiffOptions = GCDiffOptions.IncludeUntracked

struct IndexViewModel {
    
    let repository: GCRepository
    
    let unstagedChangedFiles = Variable<[ChangedFileViewModel]>([])
    let stagedChangedFiles = Variable<[ChangedFileViewModel]>([])
    
    init(repositoryURL: NSURL) throws {
        guard let path = repositoryURL.path else {
            throw NSError(domain: "indexviewmodel could not get path for repositoryURL \(repositoryURL)", code: 0, userInfo: nil)
        }
        repository = try GCRepository(existingLocalRepository: path)
        
        (unstagedChangedFiles.value, stagedChangedFiles.value) = readChangedFiles()
    }
    
    private func readChangedFiles() -> (unstaged: [ChangedFileViewModel], staged: [ChangedFileViewModel]) {
        var unstagedFiles = [ChangedFileViewModel]()
        var stagedFiles = [ChangedFileViewModel]()
        do {
            let diff = try repository.diffWorkingDirectoryWithHEAD(nil, options: CypressDefaultDiffOptions, maxInterHunkLines: 0, maxContextLines: 3)
            for delta in diff.deltas as! [GCDiffDelta]  {
                var isBinary = ObjCBool(false)
                let patch = try repository.makePatchForDiffDelta(delta, isBinary: &isBinary)
                let file = ChangedFileViewModel(patch: patch, fileURL: NSURL(fileURLWithPath: delta.oldFile.path), staged: false)
                unstagedFiles.append(file)
            }
        }
        catch let e as NSError {
            errorStream.value = e
        }
        return (unstagedFiles, stagedFiles)
    }
}
