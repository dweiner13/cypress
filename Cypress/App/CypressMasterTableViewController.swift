//
//  CypressMasterTableViewController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/28/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit

class CypressMasterViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let rightButton = navigationItem.rightBarButtonItem {
            let attributes = [NSFontAttributeName: UIFont.fontAwesomeOfSize(20)] as Dictionary!
            rightButton.setTitleTextAttributes(attributes, forState: .Normal)
            rightButton.title = String.fontAwesomeIconWithName(.Clone)
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

}
