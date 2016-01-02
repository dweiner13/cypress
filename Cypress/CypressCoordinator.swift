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
        guard let current = currentViewController else {
            return
        }
        let storyboard = UIStoryboard(name: intent.destinationStoryboardIdentifier, bundle: NSBundle.mainBundle())
        let destination = storyboard.instantiateViewControllerWithIdentifier(intent.destinationViewControllerIdentifier) as! BaseViewController
        destination.viewModel = nextViewModel
        switch intent.transitionStyle {
            case .SplitViewDetail:
                let split = current.splitViewController!
                split.showDetailViewController(destination, sender: current)
                break
            case .ModalFormSheet:
                destination.modalPresentationStyle = .FormSheet
                current.presentViewController(destination, animated: true, completion: nil)
                break
            case .ModalPageSheet:
                destination.modalPresentationStyle = .PageSheet
                current.presentViewController(destination, animated: true, completion: nil)
            case .Popover(let sourceView, let sourceRect):
                destination.modalPresentationStyle = .Popover
                destination.popoverPresentationController!.sourceView = sourceView
                destination.popoverPresentationController!.sourceRect = sourceRect
                current.presentViewController(destination, animated: true, completion: nil)
            case .Push:
                current.showViewController(destination, sender: current)
        }
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