//: Playground - noun: a place where people can play

import UIKit
import RxSwift

let files = ["a", "b", "c", "d"]

var a = Variable(files)

a.value[1] = "z"

a.value[3] = "5"

a.subscribeNext() {
    print("\($0)")
}

//let c = combineLatest(a, b, resultSelector: {$0 * $1})
//    .filter({ $0 >= 0})
//    .map({ "\($0) is positive" })
//
//c.subscribeNext({print($0)})
//
//a.value = 4
//
//a.value = -2
//
//a.value = 100