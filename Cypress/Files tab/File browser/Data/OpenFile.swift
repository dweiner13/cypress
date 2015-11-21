//
//  OpenFile.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/14/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import Foundation
import RxSwift

class OpenFile {
    
    let url: NSURL
    let text = Variable<String>("")
    var encoding = NSStringEncoding()
    
    var disposeBag = DisposeBag()
    
    init(url: NSURL) {
        debugLog("new OpenFile init at \(url.lastPathComponent!)")
        
        self.url = url
        
        do {
            text.value = try String(contentsOfURL: url, usedEncoding: &self.encoding)
        }
        catch let e as NSError {
            errorStream.value = e
            text.value = ""
        }
        
        text
            .debounce(2.00, MainScheduler.sharedInstance)
            .subscribeNext() {
                self.saveText($0)
            }
            .addDisposableTo(disposeBag)
    }
    
    func save() {
        saveText(text.value)
    }
    
    func saveText(text: String) {
        do {
            try text.writeToFile(url.path!, atomically: false, encoding: self.encoding)
            debugLog("saved file \(url.lastPathComponent!)")
        }
        catch let e as NSError {
            debugLog("could not save file \(url.lastPathComponent!)")
            errorStream.value = e
        }
    }
}