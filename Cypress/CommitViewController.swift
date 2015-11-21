//
//  UICommitViewController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/21/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import GitUpKit

class CommitViewController: UIViewController, UITableViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        let repo = try! GCRepository(existingLocalRepository: activeRepositoryStream.value!.path!)
        
        let diff = try! repo.diffWorkingDirectoryWithHEAD(nil, options: GCDiffOptions.IncludeUntracked, maxInterHunkLines: 0, maxContextLines: 3)
        
        debugLog(diff)
        let delta = diff.deltas[0] as! GCDiffDelta
        
        var isBinary = ObjCBool(false)
        print(try! repo.makePatchForDiffDelta(delta, isBinary: &isBinary))
        
        super.viewWillAppear(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
