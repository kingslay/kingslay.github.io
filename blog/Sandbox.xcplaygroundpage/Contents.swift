/*:
 > # IMPORTANT: To use `ReactiveSwift.playground`, please:

 1. Retrieve the project dependencies using one of the following terminal commands from the ReactiveSwift project root directory:
 - `git submodule update --init`
 **OR**, if you have [Carthage](https://github.com/Carthage/Carthage) installed
 - `carthage checkout --no-use-binaries`
 1. Open `ReactiveSwift.xcworkspace`
 1. Build `Result-Mac` scheme
 1. Build `ReactiveSwift-macOS` scheme
 1. Finally open the `ReactiveSwift.playground`
 1. Choose `View > Show Debug Area`
 */

import Result
import ReactiveSwift
import Foundation

/*:
 ## Sandbox

 A place where you can build your sand castles 🏖.
 */

scopedExample("merge") {
    let (lettersSignal, lettersObserver) = Signal<String, NoError>.pipe()
    let (numbersSignal, numbersObserver) = Signal<String, NoError>.pipe()
    Signal.merge([lettersSignal,numbersSignal]).observeValues { print($0) }
    lettersObserver.send(value: "a")    // prints "a"
    numbersObserver.send(value: "1")    // prints "1"
    lettersObserver.send(value: "b")    // prints "b"
    numbersObserver.send(value: "2")    // prints "2"
    lettersObserver.send(value: "c")    // prints "c"
    numbersObserver.send(value: "3")    // prints "3"
}

scopedExample("combineLatest") {
    let (lettersSignal, lettersObserver) = Signal<String, NoError>.pipe()
    let (numbersSignal, numbersObserver) = Signal<String, NoError>.pipe()
    Signal.combineLatest([lettersSignal,numbersSignal]).observeValues { print($0) }
    lettersObserver.send(value: "a")    // nothing printed
    numbersObserver.send(value: "1")    // prints ["a","1"]
    lettersObserver.send(value: "b")    // prints ["b","1"]
    numbersObserver.send(value: "2")    // prints ["b","2"]
    lettersObserver.send(value: "c")    // prints ["c","2"]
    numbersObserver.send(value: "3")    // prints ["c","3"]
}
scopedExample("zip") {
    let (lettersSignal, lettersObserver) = Signal<String, NoError>.pipe()
    let (numbersSignal, numbersObserver) = Signal<String, NoError>.pipe()
    Signal.zip(lettersSignal, numbersSignal).observeValues { print($0) }
    lettersObserver.send(value: "a")    // nothing printed
    numbersObserver.send(value: "1")    // prints ["a","1"]
    lettersObserver.send(value: "b")    // nothing printed
    numbersObserver.send(value: "2")    // prints ["b","2"]
    lettersObserver.send(value: "c")    // nothing printed
    numbersObserver.send(value: "3")    // prints ["c","3"]
}
scopedExample("flatMap(.merge)") {
    let (lettersSignal, lettersObserver) = Signal<String, NoError>.pipe()
    let (numbersSignal, numbersObserver) = Signal<String, NoError>.pipe()
    let (signal, observer) = Signal<Signal<String, NoError>, NoError>.pipe()

    signal.flatten(.merge).observeValues { print($0) }

    observer.send(value: lettersSignal)
    numbersObserver.send(value: "1")    // nothing printed
    lettersObserver.send(value: "a")    // prints "a"
    lettersObserver.send(value: "b")    // prints "b"
    observer.send(value: numbersSignal)
    numbersObserver.send(value: "2")    // prints "2"
    lettersObserver.send(value: "c")    // prints "c"
    lettersObserver.sendCompleted()     // nothing printed
    numbersObserver.send(value: "3")    // prints "3"
    numbersObserver.sendCompleted()     // nothing printed
}
scopedExample("flatMap(.concat)") {
    let (lettersSignal, lettersObserver) = Signal<String, NoError>.pipe()
    let (numbersSignal, numbersObserver) = Signal<String, NoError>.pipe()
    let (signal, observer) = Signal<Signal<String, NoError>, NoError>.pipe()

    signal.flatten(.concat).observeValues { print($0) }

    observer.send(value: lettersSignal)
    numbersObserver.send(value: "1")    // nothing printed
    lettersObserver.send(value: "a")    // prints "a"
    lettersObserver.send(value: "b")    // prints "b"
    observer.send(value: numbersSignal)
    numbersObserver.send(value: "2")    // nothing printed
    lettersObserver.send(value: "c")    // prints "c"
    lettersObserver.sendCompleted()     // nothing printed
    numbersObserver.send(value: "3")    // prints "3"
    numbersObserver.sendCompleted()     // nothing printed
}
scopedExample("flatMap(.latest)") {
    let (lettersSignal, lettersObserver) = Signal<String, NoError>.pipe()
    let (numbersSignal, numbersObserver) = Signal<String, NoError>.pipe()
    let (signal, observer) = Signal<Signal<String, NoError>, NoError>.pipe()

    signal.flatten(.latest).observeValues { print($0) }

    observer.send(value: lettersSignal)
    numbersObserver.send(value: "1")    // nothing printed
    lettersObserver.send(value: "a")    // prints "a"
    lettersObserver.send(value: "b")    // prints "b"
    observer.send(value: numbersSignal)
    numbersObserver.send(value: "2")    // prints "2"
    lettersObserver.send(value: "c")    // nothing printed
    lettersObserver.sendCompleted()     // nothing printed
    numbersObserver.send(value: "3")    // prints "3"
    numbersObserver.sendCompleted()     // nothing printed
}

scopedExample("flatMap(.race)") {
    let (lettersSignal, lettersObserver) = Signal<String, NoError>.pipe()
    let (numbersSignal, numbersObserver) = Signal<String, NoError>.pipe()
    let (signal, observer) = Signal<Signal<String, NoError>, NoError>.pipe()
    signal.flatten(.race).observeValues { print($0) }
    observer.send(value: lettersSignal)
    numbersObserver.send(value: "1")    // nothing printed
    lettersObserver.send(value: "a")    // prints "a"
    lettersObserver.send(value: "b")    // prints "b"
    observer.send(value: numbersSignal)
    numbersObserver.send(value: "2")    // nothing printed
    lettersObserver.send(value: "c")    // prints "c"
    lettersObserver.sendCompleted()     // nothing printed
    numbersObserver.send(value: "3")    // nothing printed
    numbersObserver.sendCompleted()     // nothing printed
}
scopedExample("flatMap(.race)") {
    let (lettersSignal, lettersObserver) = Signal<String, NSError>.pipe()
    let (numbersSignal, numbersObserver) = Signal<String, NSError>.pipe()
    let (signal, observer) = Signal<Signal<String, NSError>, NSError>.pipe()
    signal.flatten(.race).observeResult { print($0) }
    observer.send(value: lettersSignal)
    observer.send(value: numbersSignal)
    numbersObserver.send(value: "1")    // prints "1"
    lettersObserver.send(value: "a")    // nothing printed
    lettersObserver.send(value: "b")    // nothing printed
    numbersObserver.send(value: "2")    // prints "2"
    lettersObserver.send(value: "c")    // nothing printed
    lettersObserver.sendCompleted()     // nothing printed
    numbersObserver.send(error: NSError(domain: "retry", code: 0, userInfo: nil))
    numbersObserver.send(value: "3")    // prints "3"
    numbersObserver.sendCompleted()     // nothing printed
}
