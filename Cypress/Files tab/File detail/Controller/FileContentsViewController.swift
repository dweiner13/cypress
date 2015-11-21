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
    
    var disposeBag = DisposeBag()
    
    // The URL of the file being shown
    var detailItem = Variable<NSURL?>(nil)
    
    weak var openFile: OpenFile? = nil
    
    var fileContentsViewSettings: FileContentsViewSettings? = nil
    
    @IBOutlet weak var contentsTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let defaultInsets = self.contentsTextView.textContainerInset
        self.contentsTextView.textContainerInset = UIEdgeInsets(top: defaultInsets.top, left: 8.0, bottom: defaultInsets.bottom, right: defaultInsets.right)
        self.configureTextDisplay()
        
        detailItem
            .subscribeNext() {
                if let url = $0 {
                    self.openFile = OpenFile(url: url)
                    self.configureViewForURL(url)
                }
            }
            .addDisposableTo(disposeBag)
        
        guard let textView = contentsTextView else {
            errorStream.value = NSError(domain: "could not configure contents view because no textView", code: 0, userInfo: nil)
            return
        }
        
        textView.rx_text
            .subscribeNext() {
                self.openFile?.text.value = $0
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
        // Update the user interface for the detail item.
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
    
    func configureTextDisplay() {
        if let wordWrap = fileContentsViewSettings?.getValueForSetting(.wordWrap) as? Bool {
            self.contentsTextView.textContainer.lineBreakMode = wordWrap ? NSLineBreakMode.ByWordWrapping :
                NSLineBreakMode.ByClipping
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
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
    
    deinit {
        debugLog("deinit filecontents")
    }

}
