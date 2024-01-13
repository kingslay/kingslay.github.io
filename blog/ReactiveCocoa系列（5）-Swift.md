# ReactiveCocoa-Swift

ReactiveCocoa（以下简称“RAC”）是一个函数响应式编程框架。本文主要讲解下ReactiveSwift

## 一、变动

在RAC3.0，有了很大的改动，API已经重新命名。并且抽象出一个新的核心框架：ReactiveSwift。

### 1、类名改动部分：

1. RACSignal 和 SignalProducer、 Signal
2. ###### RACSubject 和 Signal.Observer
3. RACCommand 和 Action
4. RACScheduler 和 SchedulerType
5. RACDisposable 和 Disposable

### 2、方法名变动部分

```objective-c
- (void)sendNext:(nullable id)value;
- (RACDisposable *)subscribeNext:(void (^)(id x))nextBlock;
- (RACSignal<ValueType> *)distinctUntilChanged;
- (RACSignal *)scanWithStart:(nullable id)startingValue reduce:(id _Nullable (^)(id _Nullable running, ValueType _Nullable next))reduceBlock;
- (RACSignal *)flattenMap:(__kindof RACSignal * _Nullable (^)(ValueType _Nullable value))block;
- (RACSignal<ValueType> *)doNext:(void (^)(ValueType _Nullable x))block RAC_WARN_UNUSED_RESULT;
- (RACSignal<ValueType> *)doError:(void (^)(NSError * _Nonnull error))block RAC_WARN_UNUSED_RESULT;
- (RACSignal<ValueType> *)doCompleted:(void (^)(void))block RAC_WARN_UNUSED_RESULT;
```

```swift
//方法名修改
func send(value: Value) 
func observeValues(_ action: @escaping (Value) -> Void) -> Disposable?  
func uniqueValues() -> Signal<Value, Error>
func reduce<U>(_ initialResult: U, _ nextPartialResult: @escaping (U, Value) -> U) -> Signal<U, Error> 
func flatMap<U>(_ strategy: FlattenStrategy, _ transform: @escaping (Value) -> SignalProducer<U, Error>) -> Signal<U, Error>
public func on(
		event: ((Event) -> Void)? = nil,
		failed: ((Error) -> Void)? = nil,
		completed: (() -> Void)? = nil,
		interrupted: (() -> Void)? = nil,
		terminated: (() -> Void)? = nil,
		disposed: (() -> Void)? = nil,
		value: ((Value) -> Void)? = nil
	) -> Signal<Value, Error> {
//新增方法
func collect() -> ReactiveSwift.SignalProducer<[ReactiveSwift.SignalProducer<Value, Error>.Value], ReactiveSwift.SignalProducer<Value, Error>.Error>
func skipNil() -> ReactiveSwift.Signal<Value.Wrapped, Error> 

```

### 3、SignalProducer、 Signal区别

除了API有变动外，冷热信号也有改动。RAC2.5只有一个信号RACSignal（冷信号），现在分开成两个信号SignalProducer（冷信号），Signal（热信号）。热信号是创建了就会执行了。冷信号是要有人订阅才会执行。

```swift
//订阅信号的方式不同
//Signal
public func observe(_ observer: ReactiveSwift.Signal<Value, Error>.Observer) -> Disposable?
//SignalProducer
public func start(_ observer: Signal<Value, Error>.Observer = .init()) -> Disposable

let emptyProducer = SignalProducer<Int, NoError>.empty

let observer = Signal<Int, NoError>.Observer(
    value: { _ in print("value not called") },
    failed: { _ in print("error not called") },
    completed: { print("completed called") }
)
emptyProducer.start(observer)
//执行结果：completed called

let emptySignal = Signal<Int, NoError>.empty
let observer = Signal<Int, NoError>.Observer(
    value: { _ in print("value not called") },
    failed: { _ in print("error not called") },
    completed: { print("completed not called") },
    interrupted: { print("interrupted called") }
)
emptySignal.observe(observer)
//执行结果：interrupted called

```



### 二、管道操作

###  `Signal.merge `

该`merge`函数组合了两个（或多个）事件流的最新值。任何新的输入值将引起一个新的输出值

```swift
 let (lettersSignal, lettersObserver) = Signal<String, NoError>.pipe()
    let (numbersSignal, numbersObserver) = Signal<String, NoError>.pipe()
    Signal.merge([lettersSignal,numbersSignal]).observeValues { print($0) }
    lettersObserver.send(value: "a")    // prints "a"
    numbersObserver.send(value: "1")    // prints "1"
    lettersObserver.send(value: "b")    // prints "b"
    numbersObserver.send(value: "2")    // prints "2"
    lettersObserver.send(value: "c")    // prints "c"
    numbersObserver.send(value: "3")    // prints "3"
```

### `Signal.combineLatest`

该`combineLatest`函数组合了两个（或多个）事件流的最新值。 所得到的stream将在每个输入发送至少一个值后才发送其第一个值。之后，任何新的输入值将引起一个新的输出值。

```swift
 let (lettersSignal, lettersObserver) = Signal<String, NoError>.pipe()
    let (numbersSignal, numbersObserver) = Signal<String, NoError>.pipe()
    Signal.combineLatest([lettersSignal,numbersSignal]).observeValues { print($0) }
    lettersObserver.send(value: "a")    // nothing printed
    numbersObserver.send(value: "1")    // prints ["a","1"]
    lettersObserver.send(value: "b")    // prints ["b","1"]
    numbersObserver.send(value: "2")    // prints ["b","2"]
    lettersObserver.send(value: "c")    // prints ["c","2"]
    numbersObserver.send(value: "3")    // prints ["c","3"]
```

### `Signal.zip` 

该`zip`函数将两个（或多个）事件流的值成对连接。任何第N个元组的元素对应于输入流的第`N`个元素。 这意味着输出流的第`N`个值不能发送，直到每个输入至少发送了`N`个值。

```swift
 let (lettersSignal, lettersObserver) = Signal<String, NoError>.pipe()
    let (numbersSignal, numbersObserver) = Signal<String, NoError>.pipe()
    Signal.zip(lettersSignal, numbersSignal).observeValues { print($0) }
    lettersObserver.send(value: "a")    // nothing printed
    numbersObserver.send(value: "1")    // prints ["a","1"]
    lettersObserver.send(value: "b")    // nothing printed
    numbersObserver.send(value: "2")    // prints ["b","2"]
    lettersObserver.send(value: "c")    // nothing printed
    numbersObserver.send(value: "3")    // prints ["c","3"]
```

### `flatMap(.merge)` 

该`.merge`策略是立即将内部事件流的每个值转发到外部事件流。在外部事件流或任何内部事件流上发送的任何失败都将立即发送到铺展的事件流中并终止。

```swift
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
```

### `flatMap(.concat)` 

该`.concat`策略用于序列化内部事件流的事件。观察外部事件流。直到前一个完成之后才会观察到每个后续的事件流。失败会立即转发到铺展事件流。

```swift
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
```

### `flatMap(.latest)` 

该`.latest`策略仅转发最新输入事件流中的值或失败。

```swift
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
```



#### `flatMap(.race)` 

该`.race`策略仅转发最先输出值的事件流中的值或失败

```swift
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
```



## 三、福利

ReactiveSwift官方文档 http://reactivecocoa.io/reactiveswift/docs/latest/index.html

RxJS操作示意图 http://rxmarbles.com/

ReactiveSwift操作示意图 http://neilpa.me/rac-marbles/