//: Playground - noun: a place where people can play

import UIKit
import RxSwift

let xObservable = Variable<String>("x")
let yObservable = Variable<String>("y")

let a = combineLatest(xObservable, yObservable) {
    x, y in
    return [
        x,
        y
    ]
}

let b = combineLatest(xObservable, yObservable) {
    (x: String, y: String) throws -> [String] in
    var ret = [String]()
    if !x.isEmpty {
        ret.append(x)
    }
    if !y.isEmpty {
        ret.append(y)
    }
    return [String]()
}