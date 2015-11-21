//
//  RepositoryViewModel.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/21/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import Foundation

struct FileViewModel {
    
    enum FileStatus {
        case Modified
        case New
        case Unchanged
    }
    
    let url: NSURL
    let name: String
    let ext: String
    let isDirectory: Bool
    
    // TODO: replace this with real status
    let fileStatus = FileStatus.Unchanged
    
    init(url: NSURL) {
        self.url = url
        guard let fileName = url.lastPathComponent else {
            errorStream.value = NSError(domain: "could not get filename from url \(url)", code: 0, userInfo: nil)
            name = "[error]"
            ext = "[error]"
            isDirectory = false
            return
        }
        name = fileName
        guard let fileExt = url.pathExtension else {
            errorStream.value = NSError(domain: "could not get file extension from url \(url)", code: 0, userInfo: nil)
            ext = "[error]"
            isDirectory = false
            return
        }
        ext = fileExt
        
        guard let path = url.path else {
            errorStream.value = NSError(domain: "could not get file extension from url \(url)", code: 0, userInfo: nil)
            isDirectory = false
            return
        }
        var isDir: ObjCBool = ObjCBool(false)
        NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDir)
        isDirectory = isDir.boolValue
    }
}