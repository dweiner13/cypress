//
//  RepositoryViewModel.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/18/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import Foundation


struct RepositoryViewModel: Equatable {
    
    enum RepoStatus {
        case Available
        case InProgress
    }
    
    let name: String
    let url: NSURL
    var status: RepoStatus
    var statusProgress: Float?
    
    init(url: NSURL, status: RepoStatus) {
        self.url = url
        if let name = url.lastPathComponent {
            self.name = name
        }
        else {
            errorStream.value = NSError(domain: "URL had no last path component", code: 0, userInfo: nil)
            self.name = "[error]"
        }
        self.status = status
    }
    
    func selectAsActive() {
        activeRepositoryStream.value = url
    }
}

func ==(lhs: RepositoryViewModel, rhs:RepositoryViewModel) -> Bool {
    return lhs.url == rhs.url &&
        lhs.status == rhs.status &&
        lhs.statusProgress == rhs.statusProgress
}