//
//  NavigationHistoryTableViewController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/8/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit

class NavigationHistoryTableViewController: UITableViewController {
    
    // 0 Repositories       2 (indented 0)
    // 1 PsiTurk            1 (indented 1)
    // 2 psiTurk            0 (indented 2)
    // 3 psiTurk_js (---)
    // count: 4
    
    weak var sourceNavigationController: UINavigationController!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "basicCell")
        self.preferredContentSize = CGSize(width: 300, height: 44.0 * Double(sourceNavigationController.viewControllers.count - 1))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sourceNavigationController.viewControllers.count - 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("basicCell", forIndexPath: indexPath)
        let historyCount = sourceNavigationController.viewControllers.count
        cell.textLabel!.text = sourceNavigationController.viewControllers[historyCount - indexPath.row - 2].navigationItem.title
        cell.indentationLevel = historyCount - indexPath.row - 2
        if (indexPath.row != historyCount - 2) {
            cell.textLabel!.text = "\(cell.textLabel!.text!)/"
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.sourceNavigationController.dismissViewControllerAnimated(true, completion: {
            let historyCount = self.sourceNavigationController.viewControllers.count
            self.sourceNavigationController.popToViewController(self.sourceNavigationController.viewControllers[historyCount - indexPath.row - 2], animated: true)
        })
    }
    
}
