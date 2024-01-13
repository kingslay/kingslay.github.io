# Swift用法

## 一、内存管理

Swift 是自动管理内存的，遵循了自动引用计数 (ARC) 的规则. 所有的自动引用计数机制都有一个从理论上无法绕过的限制，那就是循环引用 (retain cycle)  

类实例之间的循环强引用

```swift
class B {
    weak var a: A? = nil
    deinit {
        print("B deinit")
    }
}
```

闭包引起的循环强引用 

```swift
class Person {
    let name: String
    lazy var printName: ()->() = {
       [weak self] in
    	if let strongSelf = self {
        	print("The name is \(strongSelf.name)")
    	}
    }

    init(personName: String) {
        name = personName
    }

    deinit {
        print("Person deinit \(self.name)")
    }
}
```

swift也是用Runloop机制.不会马上的回收内存.所以有涉及耗用内存高的的方法可以用autoreleasepool 包起来

```swift
 for _ in 0..<999 {
        autoreleasepool ｛
            let a = loadBigData()
        ｝
    }
```



## 二、访问控制

| 权限                  | 作用域                           |
| ------------------- | ----------------------------- |
| private             | 类、结构体、extension               |
| fileprivate         | 类、结构体、extension、文件            |
| internal(默认权限,不用声明) | 类、结构体、extension、文件、module     |
| public              | 任意作用域,但只能在module内被override,继承 |
| open                | 任意作用域,能被任意人override,继承        |



## 三、懒加载

### 1、懒加载字段

```swift
class ClassA {
  	lazy var str1: String = "Hello"
    lazy var str2: String = {
        let str = "World"
        print("只在首次访问输出")
        return str
    }()
}
```

### 2、懒加载方法

```swift
let data = 1...3
let result = data.map {
    (i: Int) -> Int in
    print("正在处理 \(i)")
    return i * 2
}

print("准备访问结果")
for i in result {
    print("操作后结果为 \(i)")
}

print("操作完毕")
```

这么做的输出为：

```swift
// 正在处理 1
// 正在处理 2
// 正在处理 3
// 准备访问结果
// 操作后结果为 2
// 操作后结果为 4
// 操作后结果为 6
// 操作完毕
```

而如果我们先进行一次 `lazy` 操作的话，我们就能得到延时运行版本的容器：

```swift
let result = data.lazy.map {
    (i: Int) -> Int in
    print("正在处理 \(i)")
    return i * 2
}

print("准备访问结果")
for i in result {
    print("操作后结果为 \(i)")
}

print("操作完毕")

```

此时的运行结果：

```Swift
// 准备访问结果
// 正在处理 1
// 操作后结果为 2
// 正在处理 2
// 操作后结果为 4
// 正在处理 3
// 操作后结果为 6
// 操作完毕
```

## 四、字符串

### 多行字符串字面量

Swift 4 可以把字符串写在一对 `"""` 中，这样字符串就可以写成多行。

```swift
  let joke = """
        Q: Why does apple have  in their name?
        A: I don't know, why does \(name) have \(n) \(character)'s in their name?
        Q: Because otherwise they'd be called \(punchline).
        """
```

## Substring

![img](http://or9vkv08s.bkt.clouddn.com/QQ20170609-182237@2x.png)

在 Swift 中，String 的背后有个 Owner Object 来跟踪和管理这个 String，String 对象在内存中的存储由内存其实地址、字符数、指向 Owner Object 指针组成。Owner Object 指针指向 Owner Object 对象，Owner Object 对象持有 String Buffer。当对 String 做取子字符串操作时，子字符串的 Owner Object 指针会和原字符串指向同一个对象，因此子字符串的 Owner Object 会持有原 String 的 Buffer。当原字符串销毁时，由于原字符串的 Buffer 被子字符串的 Owner Object 持有了，原字符串 Buffer 并不会释放，造成极大的内存浪费。

在 Swift 4 中，做取子串操作的结果是一个 Substring 类型，它无法直接赋值给需要 String 类型的地方。必须用 String() 包一层，系统会通过复制创建出一个新的字符串对象，这样原字符串在销毁时，原字符串的 Buffer 就可以完全释放了。

```swift
let big = downloadHugeString()
let small = extractTinyString(from: big)
mainView.titleLabel.text = small // Swift 4 编译报错
mainView.titleLabel.text = String(small) // 编译通过

```



## 五、protocol

### 1、protocol extension

可以在声明一个 protocol 之后再用 extension 的方式给出部分方法默认的实现

```swift
// 定义一个人属性的 protocol
protocol PersonProperty {
  
    var height: Int { get } // cm
    var weight: Double { get } // kg
    // 判断体重是否合格的函数
    func isStandard() -> Bool
}
extension PersonProperty {
    // 给 protocol 添加默认的实现
    func isStandard() -> Bool {
        return self.weight == Double((height - 100)) * 0.9
    }
    // 给 protocol 添加默认属性
    var isPerfectHeight: Bool {
        return self.height == 178
    }
}
```

### 2、protocol extension 中的 type constraints

```swift
// 运动因素的 protocol
protocol SportsFactors {
    // 运动量
    var sportQuantity: Double { get }
}

// 下面这种写法就用到了 extension 中的 type constraints
// 意思是 只有同时遵守了 SportsFactors 和 PersonProperty 时
// 才使 PersonProperty 获得扩展 并提供带有 sportQuantity 属性的 isStandard 方法
extension PersonProperty where Self: SportsFactors {
    func isStandard() -> Bool {
        // 随意写的算法 不要在意
        return self.weight == Double((height - 100)) * 0.9 - self.sportQuantity
    }
}
```

### 3、把类型和协议用 & 组合在一起作为一个类型使用，就可以像下面这样写了：

```swift
protocol Shakeable {
    func shake()
}
extension UIButton: Shakeable { /* ... */ }
extension UISlider: Shakeable { /* ... */ }
func shakeEm(controls: [UIControl & Shakeable]) {
    for control in controls where control.isEnabled {
        control.shake()
    }
}
```

## 六、属性

### 1、属性观察

在 Swift 中所声明的属性包括存储属性和计算属性两种。其中存储属性将会在内存中实际分配地址对属性进行存储，而计算属性则不包括背后的存储，只是提供 `set` 和 `get` 两种方法。在同一个类型中，属性观察和计算属性是不能同时共存的。也就是说，想在一个属性定义中同时出现 `set` 和 `willSet` 或 `didSet` 是一件办不到的事情。

```Swift
class MyClass {
    var date: NSDate {
        willSet {
            let d = date
            print("即将将日期从 \(d) 设定至 \(newValue)")
        }

        didSet {
            print("已经将日期从 \(oldValue) 设定至 \(date)")
        }
    }
  var date2: NSDate
  var date1: NSDate {
    set {
    	  date2 =value+12
    }
    get {
      if
	}
  }

    init() {
        date = NSDate()
    }
}

let foo = MyClass()
foo.date = foo.date.dateByAddingTimeInterval(10086)

// 输出
// 即将将日期从 2014-08-23 12:47:36 +0000 设定至 2014-08-23 15:35:42 +0000
// 已经将日期从 2014-08-23 12:47:36 +0000 设定至 2014-08-23 15:35:42 +0000
```

### 2、Key Paths 语法

支持 class、struct.  类型安全和类型推断 

```swift
struct Kid {
    var nickname: String = ""
    var age: Double = 0.0
    var friends: [Kid] = []
}
var ben = Kid(nickname: "Benji", age: 8, friends: [])
let name = ben[keyPath: \Kid.nickname]
ben[keyPath: \Kid.nickname] = "BigBen"

```

## One-sided Slicing

单向区间是一个新的类型，主要分两种：确定上限和确定下限的区间。直接用字面量定义大概可以写成 `…6`和 `2…`

```Swift
let intArr = [0, 1, 2, 3, 4]

let arr1 = intArr[...3] 	// [0, 1, 2, 3]
let arr2 = intArr[3...] 	// [3, 4]
```



## MutableCollection.swapAt(*:*:)

MutableCollection 现在有了一个新方法 swapAt(*:*:) 用来交换两个位置的值，例如：

```Swift
var mutableArray = [1, 2, 3, 4]
mutableArray.swapAt(1, 2)
print(mutableArray)
// 打印结果：[1, 3, 2, 4]

```



参考文档:

 http://swifter.tips

https://liuduo.me/2017/06/09/Whats_new_in_swift_4_completely/