//
//  AppState.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/8/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import RxSwift

private let _singletonSharedInstance = AppState()

let errorStream = Variable<NSError?>(nil)

let activeRepositoryStream: Variable<NSURL?> = Variable(nil)

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
    var activeRepository: RepositoryViewModel? {
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
            self.activeRepository = nil
        }
        
        activeRepositoryStream.subscribeNext() {
            url in
            print("set active URL to: \(url)")
        }
        
        errorStream.subscribeNext() {
            error in
            if let e = error {
                print(e)
            }
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
