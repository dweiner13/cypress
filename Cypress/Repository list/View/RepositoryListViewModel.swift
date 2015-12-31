//
//  RepositoryListViewModel.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/18/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import Foundation
import RxSwift

class RepositoryListViewModel: BaseViewModel {
    var repositories: Variable<[RepositoryViewModel]>
    
    override init(coordinator: AppCoordinator) {
        repositories = coordinator.repositoryManager.getRepositories()
        super.init(coordinator: coordinator)
    }
    
}

class RepositoryViewModel: Equatable {
    
    enum RepoStatus {
        case Available
        case InProgress
    }
    
    let name: String
    let url: NSURL
    var cloningProgress: Observable<RepositoryCloningDelegate.CloningEvent>? = nil
    
    init(url: NSURL) {
        self.url = url
        if let name = url.lastPathComponent {
            self.name = name
        }
        else {
            errorStream.value = NSError(domain: "URL had no last path component", code: 0, userInfo: nil)
            self.name = "[error]"
        }
    }
    
    func selectAsActive() {
        activeRepositoryStream.value = url
    }
}

func ==(lhs: RepositoryViewModel, rhs:RepositoryViewModel) -> Bool {
    return lhs.url == rhs.url
}