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

struct testStruct {
    
    var a = 5
    
    var b = 6
    
}

let v = Variable(testStruct())

v.subscribeNext() {
    print($0)
}

v.value.a = 2

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
