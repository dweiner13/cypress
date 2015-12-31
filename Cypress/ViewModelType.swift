//
//  ViewModelType.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 12/30/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import Foundation

protocol ViewModelType {
    // the app coordinator that manages this view model
    
    var coordinator: AppCoordinator { get }
}