//
//  DetailViewController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/6/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class FileContentsViewController: UIViewController {
    
    @IBOutlet weak var defaultView: UIView!
    var disposeBag = DisposeBag()
    
    // The URL of the file being shown
    var detailItem = Variable<NSURL?>(nil)
    
    var openFile: OpenFile? = nil
    
    var fileContentsViewSettings: FileContentsViewSettings? = nil
    
    @IBOutlet weak var contentsTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.detailItem.subscribeNext() {
            [weak self] in
            guard let s = self else {
                return
            }
            s.defaultView.hidden = $0 != nil
        }
        .addDisposableTo(disposeBag)
        
        detailItem
            .subscribeNext() {
                [weak self] in
                if let url = $0 {
                    self?.openFile = OpenFile(url: url)
                    self?.configureViewForURL(url)
                }
            }
            .addDisposableTo(disposeBag)
        
        guard let textView = contentsTextView else {
            errorStream.value = NSError(domain: "could not configure contents view because no textView", code: 0, userInfo: nil)
            return
        }
        
        textView.rx_text
            .subscribeNext() {
                [weak self] in
                self?.openFile?.text.value = $0
            }
            .addDisposableTo(disposeBag)
    }
    
    override func viewWillDisappear(animated: Bool) {
        openFile?.save()
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureViewForURL(url: NSURL) {
        guard let file = openFile else {
            errorStream.value = NSError(domain: "could not configure contents view because no open file", code: 0, userInfo: nil)
            return
        }
        guard let textView = contentsTextView else {
            errorStream.value = NSError(domain: "could not configure contents view because no textView", code: 1, userInfo: nil)
            return
        }
        
        textView.text = file.text.value
    }

    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showFileContentsConfig" {
            let destinationNav = segue.destinationViewController as! UINavigationController
            if let popover = destinationNav.popoverPresentationController {
                popover.delegate = self.navigationController! as! CypressNavigationController
            }
            if let config = destinationNav.topViewController as? FileContentsConfigViewController {
                config.fileContentsViewSettings = self.fileContentsViewSettings
            }
        }
    }

}
