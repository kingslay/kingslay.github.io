# ReactiveCocoa系列（2）

ReactiveCocoa（以下简称“RAC”）是一个函数响应式编程框架。本文主要讲解下ReactiveCocoa关于函数式编程的实现。

## 一、函数式编程

如果你是刚接触函数式编程，可能很容易被下面这些术语弄迷惑：Functor(函子)，Applicative(加强版函子)，Monad(单子)。 这些概念不是空穴来风，它们出自范畴论。

一个函子是一种表示为Type<T>的类型，它：

- 封装了另一种类型（类似于封装了某个T类型的Array<T>或Optional<T>）
- 有一个具有(T->U) -> Type<U>签名的map方法

一个Applicative 是一种类型，它：

- 是一个函子（所以它封装了一个T类型，拥有一个map方法）


- 还有一个具有 Type<T->U> -> Type<U> 签名的apply方法

一个单子是一种类型，它：

- 是一个函子（所以它封装了一个T类型，拥有一个map方法）
- 还有一个具有(T->Type<U>) -> Type<U>签名的flatMap方法

## 二、代码实现

RACSignal就是一个单子，具有flattenMap、 map方法。其中的map就是用从flattenMap衍生出来的。flattenMap又是从bind衍生出来的。所以bind是RACSignal的核心。flattenMap就是ReactiveCocoa能很好支持异步编程的原因。

### 1、bind

 bind函数会返回一个新的信号N。整体思路是对原信号O进行订阅，每当信号O产生一个值就将其转变成一个中间信号M，并马上订阅M, 之后将信号M的输出作为新信号N的输出。

```objective-c
- (RACSignal *)bind:(RACStreamBindBlock (^)(void))block {
    return [RACSignal createSignal:^(id<RACSubscriber> subscriber) { // (1)
        RACStreamBindBlock bindingBlock = block();
        [self subscribeNext:^(id x) { // (2)
            BOOL stop = NO;
            id middleSignal = bindingBlock(x, &stop); // (3)
            if (middleSignal != nil) {
                RACDisposable *disposable = [middleSignal subscribeNext:^(id x) { // (4)
                    [subscriber sendNext:x]; // (5)
                } error:^(NSError *error) {
                    [subscriber sendError:error];
                } completed:^{
                    [subscriber sendCompleted];
                }];
            }
        } error:^(NSError *error) {
            [subscriber sendError:error];
        } completed:^{
            [subscriber sendCompleted];
        }];
        return nil
    }];
}
```

当新信号N被外部订阅时，会进入信号N 的didSubscribeBlock(1处)，之后订阅原信号O (2)，当原信号O有值输出后就用bind函数传入的bindBlock将其变换成中间信号M (3), 并马上对其进行订阅(4)，最后将中间信号M的输出作为新信号N的输出 (5)

### 2、 flattenMap

在RAC的使用中，flattenMap这个操作较为常见。事实上flattenMap是对bind的包装，为bind提供bindBlock。因此flattenMap与bind操作实质上是一样的，都是将原信号传出的值map成中间信号，同时马上去订阅这个中间信号，之后将中间信号的输出作为新信号的输出。不过flattenMap在bindBlock基础上加入了一些安全检查 (1)，因此推荐还是更多的使用flattenMap而非bind。

```objective-c
- (instancetype)flattenMap:(RACStream* (^)(id value))block 
{
    Class class =self.class;

    return[self bind:^{
        return^(id value,BOOL*stop) {
            id stream = block(value) ?: [class empty];
            NSCAssert([stream isKindOfClass:RACStream.class],@"Value returned from -flattenMap: is not a stream: %@", stream); // (1)

            return stream;
        };
    }];
}
```

#### 3、 map 

map操作可将原信号输出的数据通过自定义的方法转换成所需的数据， 同时将变化后的数据作为新信号的输出。它实际调用了flattenMap, 只不过中间信号是直接将mapBlock处理的值返回 (1)。代码如下。

```objective-c
- (instancetype)map:(id(^)(id value))block
{
    Class class = self.class;

    return [self flattenMap:^(id value) {
        return[class return:block(value)]; // (1)
    }];
}
```

#### 4、filter

我们常用的filter内部也是使用了flattenMap。与map相同，它也是将filter后的结果使用中间信号进行包装并对其进行订阅，之后将中间信号的输出作为新信号的输出，以此来达到输出filter结果的目的。

```objective-c
- (instancetype)filter:(BOOL (^)(id value))block {
	Class class = self.class;
	return [self flattenMap:^ id (id value) {
		if (block(value)) {
			return [class return:value];
		} else {
			return class.empty;
		}
	}];
}
```

### 5、flatten

 该操作主要作用于信号的信号。原信号O作为信号的信号，在被订阅时输出的数据必然也是个信号(signalValue)，这往往不是我们想要的。当我们执行[O flatten]操作时，因为flatten内部调用了flattenMap (1)，flattenMap里对应的中间信号就是原信号O输出signalValue (2)。按照之前分析的经验，在flattenMap操作中新信号N输出的结果就是各中间信号M输出的集合。因此在flatten操作中新信号N被订阅时输出的值就是原信号O的各个子信号输出值的集合。这好比将多管线汇聚成单管线，将原信号压平(flatten)，

```objective-c
- (instancetype)flatten
{
    return [self flattenMap:^(RACSignal *signalValue) { // (1)
        return signalValue; // (2)
    };
}
```



参考资料：

http://adit.io/posts/2013-04-17-functors,_applicatives,_and_monads_in_pictures.html

https://tech.meituan.com/ReactiveCocoaSignalFlow.html

http://www.mokacoding.com/blog/functor-applicative-monads-in-pictures/