//
//  CypressViewController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 12/30/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit

protocol CypressViewController {
    var appCoordinator: AppCoordinator? { get set }
    var viewModel: BaseViewModel? { get set }
    func bindViewModel() -> Bool
}