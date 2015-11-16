//
//  OpenFile.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/14/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import Foundation

class OpenFile {
    
    let url: NSURL
    var text: String
    var encoding = UnsafeMutablePointer<NSStringEncoding>.alloc(1)
    
    init(url: NSURL) {
        self.url = url
        self.text = try! String(contentsOfURL: url, usedEncoding: self.encoding)
    }
    
    func save() {
        try! text.writeToFile(url.path!, atomically: false, encoding: encoding.memory)
        print("saved file \(url)")
    }
    
    deinit {
        encoding.dealloc(1)
    }
}