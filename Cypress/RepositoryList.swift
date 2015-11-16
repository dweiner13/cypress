//
//  RepoList.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/6/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import GitUpKit

private let _SingletonSharedInstance = RepositoryList()

class RepositoryList {
    private var list: [Repository]
    
    static var sharedRepositoryList: RepositoryList {
        return _SingletonSharedInstance
    }
    
    init() {
        list = []
        let defaults = NSUserDefaults.standardUserDefaults()
        if let storedRepositoryList: AnyObject = defaults.objectForKey("repositoryList") {
            for repoName: String in storedRepositoryList as! [String] {
                do {
                    try list.append(Repository(name: repoName))
                }
                catch let e {
                    print("Error reloading local repository: \(e)");
                }
            }
        }
    }
    
    // MARK: - Modifying
    
    func addRepository(repo: Repository) {
        list.append(repo);
        save()
    }
    
    func deleteRepository(repo: Repository) {
        repo.delete()
        for var i = 0; i < list.count; i++ {
            if list[i] == repo {
                list.removeAtIndex(i)
            }
        }
    }
    
    // MARK: - Getting
    
    var count: Int {
        get {
            return list.count
        }
    }
    
    func repositoryWithGCRepository(gcRepo: GCRepository) -> (repo: Repository, indexInArray: Int)? {
        for var i = 0; i < list.count; i++ {
            if list[i].repository == gcRepo {
                return (list[i], i)
            }
        }
        return nil
    }
    
    func repositoryWithName(name: String) -> (repo: Repository, indexInArray: Int)? {
        for var i = 0; i < list.count; i++ {
            if list[i].name == name {
                return (list[i], i)
            }
        }
        return nil
    }
    
    func repositoryAtIndex(index: Int) -> Repository? {
        return list[index]
    }
    
    func indexOfRepository(repository: Repository) -> Int? {
        return list.indexOf(repository)
    }
    
    // MARK: - Saving
    
    func save() {
        var repositoryNames = [String]()
        for repo: Repository in list {
            repositoryNames.append(repo.name)
        }
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(repositoryNames, forKey: "repositoryList")
        defaults.synchronize()
    }
    
    // MARK: - Comparing
}
