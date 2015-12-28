//: Playground - noun: a place where people can play

import UIKit
import RxSwift

struct tinyStruct {
    var a: Int
}

// struct

struct TestStruct {
    var arr = [tinyStruct(a: 1), tinyStruct(a: 2), tinyStruct(a: 3)]
}

let aStruct = Variable<TestStruct>(TestStruct())

aStruct.subscribeNext() {
    print($0)
}

var arrZero = aStruct.value.arr[0]
arrZero.a = 4

// class

class tinyClass {
    var a: Int
    
    init(a: Int) {
        self.a = a
    }
}

class TestClass {
    var arr = [tinyClass(a: 1), tinyClass(a: 2), tinyClass(a: 3)]
}

let aClass = Variable(TestClass())
aClass.subscribeNext() {
    print($0)
}

var classArrZero = aClass.value.arr[0]
classArrZero.a = 4
aClass.value.arr[0] = tinyClass(a: 5)
aClass.value.arr = [tinyClass(a: 6)]