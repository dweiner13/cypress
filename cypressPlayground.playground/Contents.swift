//: Playground - noun: a place where people can play

import UIKit
import RxSwift

let files = ["a", "b", "c", "d"]

var a: Observable<String> = create() {
    observer in
    for file in files {
        observer.onNext(file)
    }
    observer.onError(NSError(domain: "beep boop error", code: 0, userInfo: nil))
    return NopDisposable.instance
}

class observer<String>: ObserverType {
    typealias E = String
    
    func on(event: Event<E>) {
        print(event)
    }
}

a.subscribe(observer())