# WWDC18学习笔记 - Swift



## 一、Collection of Enum Cases 

 新的 `CaseInterable` 协议，枚举类型实现这个协议后，能自动生成一个包含所有 `case` 项的数组。这个操作是在编译时进行的，`Swift` 会自动合成一个 `allCases` 属性，包含枚举的所有 `case` 项。

```swift
enum Gait: CaseIterable {
 case walk
case trot
 case canter case gallop
 case jog
 }
 for gait in Gait.allCases {
 print(gait)
 }
```

## 二、Conditional Conformance 

包括运行时查询条件一致性、提升自动合成 `Equatable`  `Hashable` `Encodable`  的能力（一个类型的所有元素如果符合 `Hashable` 协议，则类型自动符合 `Hashable` 协议）

```swift
let s: Set<[Int?]> = [[1, nil, 2], [3, 4], [5, nil, nil]] 
// Int is Hashable
// => Int? is Hashable
// => [Int?] is Hashable
```

### 三、 Hashable 

协议`Hashable`变的更好用了。

```swift
struct City {
 let name: String
 let state: String
 let population: Int
}
///swift 4.1
extension City: Hashable {
	var hashValue: Int {
    return (name.hashValue &* 58374501) &+ state.hashValue
	}
}
///swift 4.2
extension City: Hashable {
    func hash(into hasher: inout Hasher) {
        name.hash(into: &hasher)
        state.hash(into: &hasher)
    }
}
 
```

## 四、Random Number Generation 

提供了一些系列方法来获取随机数。如果解决苹果的随机算法不好的话，还可以实现协议`RandomNumberGenerator`  定制随机算法

```swift
let randomIntFrom0To10 = Int.random(in: 0 ..< 10)
let randomFloat = Float.random(in: 0 ..< 1)
let greetings = ["hey", "hi", "hello", "hola"]
print(greetings.randomElement()!)
let randomlyOrderedGreetings = greetings.shuffled()
 
struct MersenneTwister: RandomNumberGenerator { ... }
var mt = MersenneTwister()
let randomIntFrom0To10 = Int.random(in: 0 ..< 10, using: &mt)
let randomlyOrderedGreetings = greetings.shuffled(using: &mt)
let randomFloat = Float.random(in: 0 ..< 1, using: &mt)
let greetings = ["hey", "hi", "hello", "hola"]
print(greetings.randomElement()!, using: &mt)
print(greetings)
```

# 五、Checking Platform Conditions 

增加方法判断能不能导入Kit，判断是不是模拟器

```swift
#if canImport(UIKit)
 import UIKit
 ...
#else
 import AppKit
 ...
#endif

#if hasTargetEnvironment(simulator)
 ...
#else
 // FIXME: We need to test this better
 ...
#endif
```

# 六、Implicitly Unwrapped Optionals 

IUO is an attribute of a declaration, not a type of an expression  First, try type checking value as T? — otherwise, force unwrap to get T 

隐式解包(T!) 是一种声明属性，不是一种类型。首先先判断是不是类型T?，否则就强制解包为T

# 七、Extension

Extension里面的方法是不能被重载的。猜下下面代码的输出结果是什么

```swift
protocol A {
    func set(str: String)
    func set(int2: Int)
}
extension A {
    func set(int1: Int) {
        set(str: String(int1))
    }
    func set(int2: Int) {
        set(str: String(int2))
    }
}
class B: A {
    func set(str: String) {
        print(str)
    }
    func set(int1: Int) {
        set(str: String(int1*10))
    }
    func set(int2: Int) {
        set(str: String(int2*10))
    }
}
let b1: A = B()
b1.set(int1: 12)
b1.set(int2: 12)
let b2 = B()
b2.set(int1: 12)
b2.set(int2: 12)
```



# 七、福利

格式化swift代码的工具 [SwiftFormat](https://github.com/nicklockwood/SwiftFormat)

#### 