//: Playground - noun: a place where people can play

import UIKit
import RxSwift
import RxCocoa

class Test: NSObject {
    var arr = [1, 2, 3, 4, 5]
}

let test = Test()

test.rx_observe([Int].self, options: "arr", retainSelf: true)

