//
//  DetailViewController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/6/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit

class FileContentsViewController: UIViewController, UITextViewDelegate {
    
    // The URL of the file being shown
    var detailItem: NSURL? {
        didSet {
            self.openFile = OpenFile(url: self.detailItem!)
            AppState.sharedAppState.currentOpenFile = self.openFile
            configureView()
        }
    }
    
    var openFile: OpenFile? = nil
    
    var fileContentsViewSettings: FileContentsViewSettings? = nil
    
    @IBOutlet weak var contentsTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
        let defaultInsets = self.contentsTextView.textContainerInset
        self.contentsTextView.textContainerInset = UIEdgeInsets(top: defaultInsets.top, left: 8.0, bottom: defaultInsets.bottom, right: defaultInsets.right)
        self.configureTextDisplay()
        
        contentsTextView.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserverForName(FileContentsViewSettings.Notification.fileContentsViewSettingsChanged.rawValue, object: nil, queue: nil, usingBlock: {
            _ in
            self.configureTextDisplay()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        if let file = self.openFile {
            if let textView = contentsTextView {
                textView.text = file.text
            }
        }
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
    
    // MARK: UITextViewDelegate
    
    func textViewDidChange(textView: UITextView) {
        openFile?.text = textView.text
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        openFile?.text = textView.text
        openFile?.save()
    }

}
