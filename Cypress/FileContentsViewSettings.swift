//
//  FileContentsViewSettings.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/14/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import Foundation

private let _singletonSharedInstance = FileContentsViewSettings()

class FileContentsViewSettings {
    
    enum Setting {
        case wordWrap
    }
    
    static var sharedFileContentsViewSettings: FileContentsViewSettings {
        return _singletonSharedInstance
    }
    
    enum Notification: String {
        case fileContentsViewSettingsChanged = "fileContentsViewSettingsChanged"
    }
    
    // State variables
    
    private var settings: [Setting: Any] = [
        Setting.wordWrap: true
    ]
    
    init() {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let storedActiveRepoName: AnyObject = defaults.objectForKey("fileContentsViewSettings") {
            self.settings = storedActiveRepoName as! [Setting: Any]
        }
    }
    
    func setValue(value: Any, forSetting setting: Setting) {
        settings[setting] = value
        NSNotificationCenter.defaultCenter().postNotificationName(Notification.fileContentsViewSettingsChanged.rawValue, object: self)
    }
    
    func getValueForSetting(setting: Setting) -> Any? {
        return settings[setting]
    }
    
    func save() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(settings as! AnyObject, forKey: "fileContentsViewSettings")
        defaults.synchronize()
    }
}