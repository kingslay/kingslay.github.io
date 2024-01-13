# ReactiveCocoa-Swift

ReactiveCocoa（以下简称“RAC”）是一个函数响应式编程框架。本文主要讲解下ReactiveSwift

## 一、Signal

Signal跟RACSignal一样是单子，具有 map、flattenMap方法。其中flattenMap是从map衍生出来的，map又是从flatMapEvent衍生出来的。flatMapEvent是Signal的核心。Signal的大部分操作都是从flatMapEvent衍生出来，如filter，take，skip...

### 1、flatMap

```swift
public func flatMap<U>(_ strategy: FlattenStrategy, _ transform: @escaping (Value) -> SignalProducer<U, Error>) -> Signal<U, Error>{
		return map(transform).flatten(strategy)
	}
```

### 2、map

它实际调用了flatMapEvent, 只不过把transform包装成Transformation(1) 。代码如下

```swift
public func map<U>(_ transform: @escaping (Value) -> U) -> Signal<U, Error> {
	return flatMapEvent(Signal.Event.map(transform))
}
internal static func map<U>(_ transform: @escaping (Value) -> U) -> Transformation<U, Error> {
	return { action in
		return { event in
			switch event {
			case let .value(value):
				action(.value(transform(value))) //(1)
              case .completed:
				action(.completed)
			case let .failed(error):
				action(.failed(error))
              case .interrupted:
              action(.interrupted)
            }
		}
	}
}
```

#### 

### 3、flatMapEvent

 flatMapEvent函数会返回一个新的信号N。整体思路是对原信号O进行订阅，每当信号O产生一个值就将其转变成新的值，然后手动的发送给新的信号N

```swift
extension Signal {
	public final class Observer {
		internal init<U, E>(
			_ observer: Signal<U, E>.Observer,
			_ transform: @escaping Event.Transformation<U, E>,
			_ disposable: Disposable? = nil
		) {
			var hasDeliveredTerminalEvent = false

			self._send = transform { event in
				if !hasDeliveredTerminalEvent {
					observer._send(event)// (4)
					if event.isTerminating {
						hasDeliveredTerminalEvent = true
						disposable?.dispose()
					}
				}
			}
			self.wrapped = observer.interruptsOnDeinit ? observer : nil
			self.interruptsOnDeinit = false
		}
      	public func send(_ event: Event) {
			_send(event)// (3)
		}
    }
  	internal typealias Transformation<U, E: Swift.Error> = (@escaping Signal<U, E>.Observer.Action) -> (Signal<Value, Error>.Event) -> Void
	internal func flatMapEvent<U, E>(_ transform: @escaping Event.Transformation<U, E>) -> Signal<U, E> {
		return Signal<U, E> { observer, lifetime in // (1)
			lifetime += self.observe(Signal.Observer(observer, transform)) // (2)
		}
	}
}
```

当新信号N创建时，会进入信号N 的generator(1处)，之后订阅原信号O (2)，当原信号O有值输出后就用flatMapEvent函数传入的Transformation将其变换成新的值 (3), 然后手动的发送给新的信号N (4)

#### 4、filter

我们常用的filter内部也是使用了flatMapEvent。与map相同，把isIncluded包装成Transformation(1)。

```swift
public func filter(_ isIncluded: @escaping (Value) -> Bool) -> Signal<Value, Error> {
	return flatMapEvent(Signal.Event.filter(isIncluded))
}
internal static func filter(_ isIncluded: @escaping (Value) -> Bool) -> Transformation<Value, Error> {
		return { action in
			return { event in
				switch event {
				case let .value(value):
					if isIncluded(value) {//(1)
						action(.value(value))
					}
				case .completed:
					action(.completed)
				case let .failed(error):
					action(.failed(error))
				case .interrupted:
					action(.interrupted)
				}
			}
		}
	}
```
