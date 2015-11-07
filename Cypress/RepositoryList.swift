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
    
    func addRepository(repo: Repository) {
        list.append(repo);
    }
    
    func asArray() -> [Repository] {
        return list;
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
}
