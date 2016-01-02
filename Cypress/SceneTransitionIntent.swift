//
//  SceneTransitionIntent.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 12/30/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit

enum SceneTransitionStyle {
    case SplitViewDetail
    case ModalFormSheet
    case ModalPageSheet
    case Popover(sourceView: UIView, sourceRect: CGRect)
    case Push
}

struct SceneTransitionIntent {
    let transitionStyle: SceneTransitionStyle
    let destinationViewControllerIdentifier: String
    let destinationStoryboardIdentifier: String
}