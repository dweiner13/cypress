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
    static var sharedAppState: AppState {
        return _singletonSharedInstance
    }
    
    enum Notification: String {
        case activeRepositoryChanged = "appStateActiveRepositoryChanged"
        case fileContentsViewSettingsChanged = "fileContentsViewSettingsChanged"
    }
    
    // State variables
    
    // SAVED
    var activeRepository: Repository? {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName("appStateActiveRepositoryChanged", object: self)
            save()
        }
    }
    
    // NOT SAVED
    var currentOpenFile: OpenFile? {
        didSet {
            save()
        }
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