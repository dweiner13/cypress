//
//  BaseViewController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 12/30/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit

class BaseViewController : UIViewController, CypressViewController {
    
    var appCoordinator: AppCoordinator?
    var viewModel: BaseViewModel?
    func bindViewModel() -> Bool {
        return true
    }
    
//    func showErrorAlertWithMessage(message: String) {
//        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
//        
//        let okayAction = UIAlertAction(title: "Okay", style: .Default, handler: nil)
//        alertController.addAction(okayAction)
//        alertController.preferredAction = okayAction
//        
//        self.presentViewController(alertController, animated: true, completion: nil)
//    }
//    
//    func showTextInputPrompt(title: String, message: String, handler: (String) -> Void) {
//        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
//        
//        alertController.addTextFieldWithConfigurationHandler(nil)
//        
//        let confirmAction = UIAlertAction(title: "Okay", style: .Default, handler: {
//            (action: UIAlertAction) -> Void in
//            handler(alertController.textFields![0].text!)
//        })
//        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
//        
//        alertController.addAction(confirmAction)
//        alertController.preferredAction = confirmAction
//        alertController.addAction(cancelAction)
//        
//        self.presentViewController(alertController, animated: true, completion: nil)
//    }
//    
//    func askForConfirmation(title: String, message: String, confirmActionTitle: String, confirmedHandler: () -> Void) {
//        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
//        
//        let confirmAction = UIAlertAction(title: confirmActionTitle, style: .Destructive, handler: {
//            (action: UIAlertAction) -> Void in
//            confirmedHandler()
//        })
//        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
//        
//        alertController.addAction(confirmAction)
//        alertController.preferredAction = confirmAction
//        alertController.addAction(cancelAction)
//        
//        self.presentViewController(alertController, animated: true, completion: nil)
//    }
}