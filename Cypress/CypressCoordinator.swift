//
//  CypressCoordinator.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 12/30/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import RxSwift

class CypressCoordinator: AppCoordinator {
    var repositoryManager: RepositoryManager = RepositoryManager()
    
    var activeRepository: Variable<NSURL?> = Variable<NSURL?>(nil)
    
    // view controller controlling whole current scene
    var currentViewController: UIViewController?
    
    required init(rootViewController: UIViewController) {
        currentViewController = rootViewController
    }
    
    func transitionToScene(nextViewModel: BaseViewModel, intent: SceneTransitionIntent) {
        return
    }
    
    func popScene() -> Bool {
        if let presenting = currentViewController?.presentingViewController {
            presenting.dismissViewControllerAnimated(true, completion: nil)
            return true
        }
        return false
    }
    
    func reportError(error: NSError) {
        return
    }
}