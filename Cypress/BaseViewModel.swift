//
//  BaseViewModel.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 12/30/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import Foundation

class BaseViewModel : ViewModelType {
    let coordinator: AppCoordinator
    
    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }
}