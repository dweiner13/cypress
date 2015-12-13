//: Playground - noun: a place where people can play

import UIKit
import RxSwift

let x = Variable<Int>(5)

func square(int: Int) -> Int {
    return int*int
}

let y = x.map(square)

x.subscribeNext({ print("x: \($0)") })
y.subscribeNext({ print("y: \($0)") })

x.value = 6
x.value = 7