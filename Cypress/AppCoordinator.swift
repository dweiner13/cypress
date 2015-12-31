//
//  AppCoordinator.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 12/30/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import RxSwift

protocol AppCoordinator {
    
    var repositoryManager: RepositoryManager { get }
    
    var activeRepository: Variable<NSURL?> { get }
    
    // view controller controlling whole current scene
    var currentViewController: UIViewController? { get set }
    
    init(rootViewController: UIViewController)
    
    func transitionToScene(nextViewModel: BaseViewModel, intent: SceneTransitionIntent) -> Void
    
    func popScene() -> Bool
    
    func reportError(error: NSError)
}