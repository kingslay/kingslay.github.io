# ReactiveCocoa系列（1）

## 一.ReactiveCocoa简介

ReactiveCocoa（简称为`RAC`）,是由Github开源的一个应用于iOS和OS开发的新框架,由[Josh Abernathy](https://github.com/joshaber)和[Justin Spahr-Summers](https://github.com/jspahrsummers)在对[GitHub for Mac](http://mac.github.com/)的开发过程中建立。[ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa)是一个将函数响应式编程范例带入Objective-C的开源库。

ReactiveCocoa现在最新的版本是7.0。ReactiveCocoa从3.0开始引入swift，如果不想引入swfit的话，可以用2.5版本。2.5版跟5.0版差异非常大。本文主要讨论的是2.5版本

## 二.核心概念

​	ReactiveCocoa衍生自FRP（响应链编程）的一种，它是用OC语言来描述FRP的一个框架。其根源可以追述到Haskell。

> 信号(Signal)：Signal是构造FRP程序最基础的砖块，一般来说，我们的程序组织一系列的signal，决定这些signal的值从何而来，signal之间如何连接，以及值如何在signal中传递。我们可以认为signal是一个管道，我们的应用程序是一个复杂的管道系统，将事件放入管道系统的输入端，从输出端得到结果。
>
> ReactiveCocoa 2.x的框架中使用`RACSignal`对signal进行了抽象和包装。`RACSignal`继承于`RACStream`。`RACStream` 用来处理signal之间如何连接，以及值如何在signal中传递。`RACSignal`用来决定  signal的值从何而来。  一个`RACSignal`可以传递*value*，*error*，*complete*三种值，在一个`RACSignal`接收了*error*或者*complete*之后，那么就不会在传递任何发送给他的值了。
>
> 订阅者 (Subscriber)：订阅者是使信号有效的一个重要角色。在FRP中，一个信号创建之后，是没有意义的，此时它不知道给谁传送数据，此时它是Cold的。而只有当他被一个或多个Subscriber订阅之后，信号接到事件源之后，就会触发响应，并发送数据给订阅者。



## 三.RACStream

`RACStream` 用来处理signal之间如何连接，以及值如何在signal中传递。

### 1、管道数据过滤、处理

对信号发出的数据进行转换，过滤

#### `filter`

信号过滤，用于判断信号返回值的业务合法性。只有合法的信号，才可以被继续向下输送。

```objc
RACSequence *numbers = [@"1 2 3 4 5 6 7 8 9" componentsSeparatedByString:@" "].rac_sequence;

// Contains: 2 4 6 8
RACSequence *filtered = [numbers filter:^ BOOL (NSString *value) {
    return (value.intValue % 2) == 0;
}];
```

#### `flattenMap(Map)`

信号映射，可以将信号的发送过来的值重新计算，并以一个新值发送出去。

```objc
RACSequence *letters = [@"A B C D E F G H I" componentsSeparatedByString:@" "].rac_sequence;

// Contains: AA BB CC DD EE FF GG HH II
RACSequence *mapped = [letters map:^(NSString *value) {
    return [value stringByAppendingString:value];
}];
```

flattenMap和map的区别

1. flattenMap中的Block返回信号。
2. `map`中的Block返回对象。

#### `distinctUntilChanged`

- 当上一次的值和当前的值有明显的变化就会发出信号，否则会被忽略掉。
- 过滤，当上一次和当前的值不一样，就会发出内容。
- 在开发中，刷新UI经常使用，只有两次数据不一样才需要刷新。

```
[[self.textField.rac_textSignal distinctUntilChanged] subscribeNext:^(id x) {
   NSLog(@"%@",x);
}];
```

#### `take`

- 从开始一共取N次的信号。

```
// 1、创建信号
RACSubject *signal = [RACSubject subject];
// 2、处理信号，订阅信号
[[signal take:1] subscribeNext:^(id x) {
   NSLog(@"%@", x);
}];
// 3.发送信号
[signal sendNext:@1];
[signal sendNext:@2];

```

```
2016-03-21 14:00:52.519 RACDemo[47218:5457876] 1

```

#### `takeLast`

- 取最后N次的信号，前提条件，订阅者必须调用完成，因为只有完成，就知道总共有多少信号。

```
// 1、创建信号
RACSubject *signal = [RACSubject subject];
// 2、处理信号，订阅信号
[[signal takeLast:1] subscribeNext:^(id x) {
   
   NSLog(@"%@",x);
}];
// 3.发送信号
[signal sendNext:@1];
[signal sendNext:@2];
[signal sendCompleted];

```

```
2016-03-21 14:02:57.279 RACDemo[47228:5458489] 2
```

#### `takeUntil`

- 获取信号直到某个信号执行完成（监听文本框的改变直到当前对象被销毁）。

```
 @weakify(self);
 [[[self.bt_focus rac_signalForControlEvents:UIControlEventTouchUpInside] takeUntil:self.rac_prepareForReuseSignal] subscribeNext:^(id x) {
        @strongify(self);
        [viewModel focusDarenWithCellTag:self.bt_focus.tag];
    }];
```

#### takeWhileBlock

- 当符合block逻辑时返回yes，订阅者才接收。

#### `skip`

- 跳过几个信号，不接受(表示输入第一次，不会被监听到，跳过第一次发出的信号)。

```
[[self.textField.rac_textSignal skip:1] subscribeNext:^(id x) {
    NSLog(@"%@",x);
}];
```

### 2、管道连接

#### `then`

- 用于连接两个信号，当第一个信号完成，才会连接then返回的信号。

- 注意使用then，之前信号的值会被忽略掉。

  ```objc
  RACSignal *letters = [@"A B C D E F G H I" componentsSeparatedByString:@" "].rac_sequence.signal;

  // The new signal only contains: 1 2 3 4 5 6 7 8 9
  //
  // But when subscribed to, it also outputs: A B C D E F G H I
  RACSignal *sequenced = [[letters
      doNext:^(NSString *letter) {
          NSLog(@"%@", letter);
      }]
      then:^{
          return [@"1 2 3 4 5 6 7 8 9" componentsSeparatedByString:@" "].rac_sequence.signal;
      }];
  ```

#### `merge`

- 把多个信号合并为一个信号，任何一个信号有新值的时候就会调用。

- 同时订阅，任何一个响应都会响应。

  ```objc
  RACSubject *letters = [RACSubject subject];
  RACSubject *numbers = [RACSubject subject];
  RACSignal *merged = [RACSignal merge:@[ letters, numbers ]];

  // Outputs: A 1 B C 2
  [merged subscribeNext:^(NSString *x) {
      NSLog(@"%@", x);
  }];

  [letters sendNext:@"A"];
  [numbers sendNext:@"1"];
  [letters sendNext:@"B"];
  [letters sendNext:@"C"];
  [numbers sendNext:@"2"];
  ```

#### `combineLatest`

- 将多个信号合并起来，并且拿到各个信号的最新的值，必须每个合并的signal至少都有过一次`sendNext`，才会触发合并的信号。

  ```objc
  RACSubject *letters = [RACSubject subject];
  RACSubject *numbers = [RACSubject subject];
  RACSignal *combined = [RACSignal
      combineLatest:@[ letters, numbers ]
      reduce:^(NSString *letter, NSString *number) {
          return [letter stringByAppendingString:number];
      }];

  // Outputs: B1 B2 C2 C3
  [combined subscribeNext:^(id x) {
      NSLog(@"%@", x);
  }];

  [letters sendNext:@"A"];
  [letters sendNext:@"B"];
  [numbers sendNext:@"1"];
  [numbers sendNext:@"2"];
  [letters sendNext:@"C"];
  [numbers sendNext:@"3"];
  ```

### 3、其他操作

timeout   超时，可以让一个信号在一定的时间后，自动报错。

Interval 	定时：每隔一段时间发出信号。

delay     	延迟发送`next`

Retry     	重试：只要失败，就会重新执行创建信号中的block，直到成功。

throttle  截流:当某个信号发送比较频繁时，可以使用节流，在某一段时间不发送信号内容，过了一段时间获取信号的最新内容发出。常用于即时搜索优化，防止频繁发出请求。

### 4、应用

​	Signals可以被链接起来按顺序地执行异步操作，而不用嵌套回调blocks。这类似[futures and promises](http://en.wikipedia.org/wiki/Futures_and_promises)

```objective-c
[[[[client logInUser]  flattenMap:^(User *user) {
      // Return a signal that loads cached messages for the user.
      return [client loadCachedMessagesForUser:user];
   }] flattenMap:^(NSArray *messages) {
      // Return a signal that fetches any remaining messages.
      return [client fetchMessagesAfterMessage:messages.lastObject];
   }] subscribeNext:^(NSArray *newMessages) {
      NSLog(@"New messages: %@", newMessages);
   } completed:^{
      NSLog(@"Fetched all messages.");
   }];
```

​	RAC甚至使绑定到异步操作结果更加容易：

```objective-c
RAC(self.imageView, image) = [[[[client fetchUserWithUsername:@"joshaber"]
   deliverOn:[RACScheduler scheduler]] map:^(User *user) {
      // Download the avatar (this is done on a background queue).
      return [[NSImage alloc] initWithContentsOfURL:user.avatarURL];
   }]
   // Now the assignment will be done on the main thread.
   deliverOn:RACScheduler.mainThreadScheduler];
```

## 四.RACSignal

`RACSignal`用来决定  signal的值从何而来。并提供信号订阅的功能

### 1、订阅信号

信号订阅就是把订阅者传递给信号，通过方法`subscribe`完成信号和订阅者的绑定。不同类型的信号，对subscribe的处理都不一样。后续会讲解几种简单信号的订阅行为的实现。

```objective-c
/// Subscribes `subscriber` to changes on the receiver. The receiver defines which
/// events it actually sends and in what situations the events are sent.
///
/// Subscription will always happen on a valid RACScheduler. If the
/// +[RACScheduler currentScheduler] cannot be determined at the time of
/// subscription (e.g., because the calling code is running on a GCD queue or
/// NSOperationQueue), subscription will occur on a private background scheduler.
/// On the main thread, subscriptions will always occur immediately, with a
/// +[RACScheduler currentScheduler] of +[RACScheduler mainThreadScheduler].
///
/// This method must be overridden by any subclasses.
///
/// Returns nil or a disposable. You can call -[RACDisposable dispose] if you
/// need to end your subscription before it would "naturally" end, either by
/// completing or erroring. Once the disposable has been disposed, the subscriber
/// won't receive any more events from the subscription.
- (RACDisposable *)subscribe:(id<RACSubscriber>)subscriber;
```

RACSubscriber是对value、error、completed的封装

```objective-c
+ (instancetype)subscriberWithNext:(void (^)(id x))next error:(void (^)(NSError *error))error completed:(void (^)(void))completed {
	RACSubscriber *subscriber = [[self alloc] init];

	subscriber->_next = [next copy];
	subscriber->_error = [error copy];
	subscriber->_completed = [completed copy];

	return subscriber;
}
```

### 2、创建信号

常见的信号有两种`RACSubject`，`RACDynamicSignal`。

#### `RACDynamicSignal`

是开发者创建的，所以叫“动态”的signal，我们可以把一个block转换为一个signal，就像下面这样：

```objective-c
  @weakify(self);
[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
	@strongify(self);
	self.dataSource = [MessageDetailModel searchWithWhere:[NSString stringWithFormat:@"topic_id = %lu",(unsigned long)self.topic_id] orderBy:@"updated_date desc" offset:0 count:100];
        [subscriber sendNext:@(self.dataSource.count)];
        [subscriber sendCompleted];
        return nil;
}];
```

`RACDynamicSignal`的`subscribe`实现可以简单的理解为调用创建时的block。代码如下

```objective-c
- (RACDisposable *)subscribe:(id<RACSubscriber>)subscriber {
	return self.didSubscribe(subscriber);
}
```



#### `RACSubject`

是连接rac代码和非rac代码的桥梁，`RACSubject`是一个`RACSignal`（继承而来）但是可以手动push值到里面，就像下面这样：

```objective-c
RACSubject *subject = [RACSubject subject];
RACSignal *derived = [subject map:^(id value) {
    return someAction(value);
}];
[subject sendNext:@YES]; // 这里就把YES的值push给subject，然后push给derived这个signal了
```

RACSubject的`subscribe`实现可以简单的理解为把订阅者放在Array里面,然后信号产生值的时候把值发送给每个订阅者。代码如下

```objective-c

- (RACDisposable *)subscribe:(id<RACSubscriber>)subscriber {
	[self.subscribers addObject:subscriber];
  	return nil;
}
- (void)sendNext:(id)value {
	for (id<RACSubscriber> subscriber in self.subscribers) {
		[subscriber sendNext:value];
	}];
}
```



RACSubject实现了 `RACSubscriber` 协议，所以它也可以作为订阅者订阅其他信号源，这个就是 `RACSubject` 为什么可以手动控制的原因。这也就是RACSubject的特殊和灵活之处，其他的signal在创建的时候就确定好值从何而来。但是你可以从任何地方，任何时候给RACSubject发送值。根据官方的 [Design Guidelines](https://github.com/ReactiveCocoa/ReactiveCocoa/blob/v2.5/Documentation/DesignGuidelines.md#avoid-using-subjects-when-possible) 中的说法，我们应该尽可能少地使用RACSubject。因为它太过灵活，我们可以在任何时候任何地方操作它，所以一旦过度使用，就会使代码变得非常复杂，难以理解。所以要尽量少使用RACSubject。



还有几个比较简单的signal：RACEmptySignal、RACErrorSignal、RACReturnSignal。

未完待续。。。