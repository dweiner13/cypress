//
//  SceneTransitionIntent.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 12/30/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit

enum SceneTransitionStyle {
    case Detail // e.g. pushing or showing detail in SplitViewController
    case ModalFormSheet
    case ModalPageSheet
    case Popover
    case DismissSelf
}

struct SceneTransitionIntent {
    let transitionStyle: SceneTransitionStyle
    let destinationViewControllerIdentifier: String?
}