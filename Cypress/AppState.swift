//
//  AppState.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/8/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit

private let _singletonSharedInstance = AppState()

class AppState {
    enum Notification: String {
        case activeRepositoryChanged = "appStateActiveRepositoryChanged"
    }
    
    var activeRepository: Repository? {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName("appStateActiveRepositoryChanged", object: self)
            save()
        }
    }
    
    static var sharedAppState: AppState {
        return _singletonSharedInstance
    }
    
    init() {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let storedActiveRepoName: AnyObject = defaults.objectForKey("activeRepositoryName") {
            self.activeRepository = RepositoryList.sharedRepositoryList.repositoryWithName(storedActiveRepoName as! String)?.repo
        }
    }
    
    func save() {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let repo = activeRepository {
            defaults.setObject(repo.name, forKey: "activeRepositoryName")
        }
        defaults.synchronize()
    }
}
