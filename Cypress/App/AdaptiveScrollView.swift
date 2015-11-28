//
//  AdaptiveTableView.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/28/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit

class AdaptiveScrollView: UIScrollView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        let defaultCenter = NSNotificationCenter.defaultCenter()
        defaultCenter.addObserver(self,
            selector: "keyboardDidShow:",
            name: UIKeyboardDidShowNotification,
            object: nil)
        defaultCenter.addObserver(self,
            selector: "keyboardWillHide:",
            name: UIKeyboardWillHideNotification,
            object: nil)
    }
    
    func keyboardDidShow(notification:NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIKeyboardFrameBeginUserInfoKey]
            as? NSValue else {
                return
        }
        
        let keyboardSize = keyboardFrame.CGRectValue().size
        adjustContentInsetsForKeyboardHeight(keyboardSize.height)
    }
    
    func keyboardWillHide(notification:NSNotification) {
        adjustContentInsetsForKeyboardHeight(0.0)
    }
    
    private func adjustContentInsetsForKeyboardHeight(keyboardHeight: CGFloat) {
        contentInset = UIEdgeInsets(top: contentInset.top, left: contentInset.left, bottom: keyboardHeight, right: contentInset.right)
        scrollIndicatorInsets = UIEdgeInsets(top: scrollIndicatorInsets.top, left: scrollIndicatorInsets.left, bottom: keyboardHeight, right: scrollIndicatorInsets.right)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
