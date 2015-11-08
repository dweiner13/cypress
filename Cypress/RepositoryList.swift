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
    
    var array: [Repository] {
        get {
            return list
        }
    }
    
    init() {
        list = []
        let defaults = NSUserDefaults.standardUserDefaults()
        if let storedRepositoryList: AnyObject = defaults.objectForKey("repositoryList") {
            print("reading saved repo list")
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
    
    func addRepository(repo: Repository) {
        list.append(repo);
        save()
    }
    
    func repositoryWithGCRepository(gcRepo: GCRepository) -> (repo: Repository, indexInArray: Int)? {
        for var i = 0; i < list.count; i++ {
            if list[i].repository == gcRepo {
                return (list[i], i)
            }
        }
        return nil
    }
    
    func deleteRepository(repo: Repository) {
        repo.delete()
        for var i = 0; i < list.count; i++ {
            if list[i] == repo {
                list.removeAtIndex(i)
            }
        }
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
        print("saved repo list")
    }
    
    // MARK: - Comparing
}
