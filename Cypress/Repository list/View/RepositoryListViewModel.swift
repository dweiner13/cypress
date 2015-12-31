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
    let disposeBag = DisposeBag()
    override init(coordinator: AppCoordinator) {
        repositories = coordinator.repositoryManager.getRepositories()
        super.init(coordinator: coordinator)
    }
    
    func addNewRepository(name: String) throws {
        try coordinator.repositoryManager.createNewRepositoryAtDefaultPathWithName(name)
    }
    
    func cloneRepository(url: NSURL) throws -> Observable<RepositoryCloningDelegate.CloningEvent>? {
        guard let result = try coordinator.repositoryManager.cloneRepository(url) else {
            throw NSError(domain: "Error cloning repository", code: 0, userInfo: nil)
        }
        let newRepo = RepositoryViewModel(url: result.localURL)
        newRepo.cloningProgress = result.cloningProgress
        repositories.value.append(newRepo)
        newRepo.cloningProgress?
            .subscribeError({
                [weak self] (e) -> Void in
                try! self?.deleteRepository(newRepo.url)
            })
        .addDisposableTo(disposeBag)
        return newRepo.cloningProgress
    }
    
    func deleteRepository(url: NSURL) throws {
        return try coordinator.repositoryManager.deleteRepositoryAtURL(url)
    }
    
    func selectRepository(url: NSURL) {
        coordinator.activeRepository.value = url
        coordinator.popScene()
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