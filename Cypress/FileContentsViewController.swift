//
//  DetailViewController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/6/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit

class FileContentsViewController: UIViewController {
    
    // The URL of the file being shown
    var detailItem: NSURL? {
        didSet{
            configureView()
        }
    }
    
    
    @IBOutlet weak var contentsTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
        let defaultInsets = self.contentsTextView.textContainerInset
        self.contentsTextView.textContainerInset = UIEdgeInsets(top: defaultInsets.top, left: 8.0, bottom: defaultInsets.bottom, right: defaultInsets.right)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = self.detailItem {
            if let textView = contentsTextView {
                let contents = try? String(contentsOfFile: detail.path!)
                print(contentsTextView)
                textView.text = contents;
            }
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
