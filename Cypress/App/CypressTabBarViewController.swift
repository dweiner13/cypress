//
//  CypressTabBarViewController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/8/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit

class CypressTabBarViewController: UITabBarController, UISplitViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        for viewController in self.viewControllers! {
            if let splitViewController = viewController as? UISplitViewController {
                debugLog(splitViewController)
                debugLog(splitViewController.viewControllers[splitViewController.viewControllers.count-1])
                let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
                navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
                splitViewController.delegate = self
            }
        }
        
        viewControllers![0].tabBarItem.image = UIImage.fontAwesomeIconWithName(.FilesO, textColor: UIColor.blackColor(), size: CGSizeMake(30, 30))
        viewControllers![1].tabBarItem.image = UIImage.fontAwesomeIconWithName(.List, textColor: UIColor.blackColor(), size: CGSizeMake(30, 30))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Split View Delegate
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        //        if let secondaryAsNavController = secondaryViewController as? UINavigationController {
        //            if let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController {
        //                if topAsDetailController.detailItem == nil {
        //                    return true
        //                }
        //            }
        //        }
        //        return false
        return true
    }
    
    func splitViewController(svc: UISplitViewController, shouldHideViewController vc: UIViewController, inOrientation orientation: UIInterfaceOrientation) -> Bool {
        return false
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
