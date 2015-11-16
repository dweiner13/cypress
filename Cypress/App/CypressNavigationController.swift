//
//  CypressNavigationController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/14/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit

class CypressNavigationController: UINavigationController, UIPopoverPresentationControllerDelegate {
    
    // MARK: PopoverPresentationControllerDelegate
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
}
