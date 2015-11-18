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
    let encoding = NSStringEncoding()
    
    init(url: NSURL) {
        self.url = url
        self.text = try! String(contentsOfURL: url, usedEncoding: &self.encoding)
    }
    
    func save() {
        try! text.writeToFile(url.path!, atomically: false, encoding: self.encoding)
        print("saved file \(url)")
    }
}