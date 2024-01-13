# ReactiveCocoa系列（4）

ReactiveCocoa（以下简称“RAC”）是一个函数响应式编程框架。本文主要讲解下`RACCommand`

## 一、RACCommand

`RACCommand` 在RAC 中是对一个动作的触发条件以及它产生的触发事件的封装。

- 触发条件：初始化RACCommand的入参enabledSignal就决定了RACCommand是否能开始执行。入参enabledSignal就是触发条件。举个例子，一个按钮是否能点击，是否能触发点击事情，就由入参enabledSignal决定。

- 触发事件：初始化RACCommand的另外一个入参(RACSignal * (^)(id input))signalBlock就是对触发事件的封装。RACCommand每次执行都会调用一次signalBlock闭包。

  关于RACCommand的定义如下：

```objective-c
@interface RACCommand : NSObject
- (id)initWithEnabled:(RACSignal *)enabledSignal signalBlock:(RACSignal * (^)(id input))signalBlock;
@property (nonatomic, strong, readonly) RACSignal *executionSignals;
@property (nonatomic, strong, readonly) RACSignal *executing;
@property (nonatomic, strong, readonly) RACSignal *enabled;
@property (nonatomic, strong, readonly) RACSignal *errors;
@property (atomic, assign) BOOL allowsConcurrentExecution;
@property (atomic, copy, readonly) NSArray *activeExecutionSignals;
@property (nonatomic, strong, readonly) RACSignal *immediateEnabled;
@property (nonatomic, copy, readonly) RACSignal * (^signalBlock)(id input);
- (RACSignal *)execute:(id)input;
@end
```

### 1、activeExecutionSignals

用来存放`execute`产生的信号，后续`executionSignals`、`executing`、`enabled`、`errors`都是围绕`activeExecutionSignals`来做转换。

### 2、RACSignal *executionSignals

正在执行的信号的集合，里面的值是`signal`。所以需要通过flatten，switchToLatest，concat来进行降阶。

选择原则是，如果在不允许Concurrent并发的RACCommand中一般使用switchToLatest。如果在允许Concurrent并发的RACCommand中一般使用flatten。

```objective-c
RACSignal *newActiveExecutionSignals = [[[[[self
		rac_valuesAndChangesForKeyPath:@keypath(self.activeExecutionSignals) options:NSKeyValueObservingOptionNew observer:nil]
		reduceEach:^(id _, NSDictionary *change) {
			NSArray *signals = change[NSKeyValueChangeNewKey];
			if (signals == nil) return [RACSignal empty];
			return [signals.rac_sequence signalWithScheduler:RACScheduler.immediateScheduler];
		}]
		concat]
		publish]
		autoconnect];

_executionSignals = [[[newActiveExecutionSignals
		map:^(RACSignal *signal) {
			return [signal catchTo:[RACSignal empty]];
		}]
		deliverOn:RACScheduler.mainThreadScheduler]
		setNameWithFormat:@"%@ -executionSignals", self];
```



#### 3、 RACSignal *executing

这个信号表示了当前RACCommand是否在执行，信号里面的值都是BOOL类型的。YES表示的是RACCommand正在执行过程中，NO表示的是RACCommand没有被执行或者已经执行结束。

```objective-c
RACSignal *immediateExecuting = [RACObserve(self, activeExecutionSignals) map:^(NSArray *activeSignals) {
		return @(activeSignals.count > 0);
	}];

_executing = [[[[[immediateExecuting
		deliverOn:RACScheduler.mainThreadScheduler]
		startWith:@NO]
		distinctUntilChanged]
		replayLast]
		setNameWithFormat:@"%@ -executing", self];
```



#### 4、RACSignal *enabled

enabled信号就是一个开关，RACCommand是否可用。这个信号除去以下2种情况会返回NO：

- RACCommand 初始化传入的enabledSignal信号，如果返回NO，那么enabled信号就返回NO。
- RACCommand开始执行中，allowsConcurrentExecution为NO，那么enabled信号就返回NO。

除去以上2种情况以外，enabled信号基本都是返回YES。

```objective-c
RACSignal *moreExecutionsAllowed = [RACSignal
		if:RACObserve(self, allowsConcurrentExecution)
		then:[RACSignal return:@YES]
		else:[immediateExecuting not]];
	
	if (enabledSignal == nil) {
		enabledSignal = [RACSignal return:@YES];
	} else {
		enabledSignal = [[[enabledSignal
			startWith:@YES]
			takeUntil:self.rac_willDeallocSignal]
			replayLast];
	}
	_immediateEnabled = [[RACSignal
		combineLatest:@[ enabledSignal, moreExecutionsAllowed ]]
		and];
	_enabled = [[[[[self.immediateEnabled
		take:1]
		concat:[[self.immediateEnabled skip:1] deliverOn:RACScheduler.mainThreadScheduler]]
		distinctUntilChanged]
		replayLast]
		setNameWithFormat:@"%@ -enabled", self];
```



#### 5、RACSignal *errors

errors信号就是RACCommand执行过程中产生的错误信号。executionSignals把error事件过滤掉了，只能通过errors来捕获error。

```objective-c
RACMulticastConnection *errorsConnection = [[[newActiveExecutionSignals
		flattenMap:^(RACSignal *signal) {
			return [[signal
				ignoreValues]
				catch:^(NSError *error) {
					return [RACSignal return:error];
				}];
		}]
		deliverOn:RACScheduler.mainThreadScheduler]
		publish];
	_errors = [errorsConnection.signal setNameWithFormat:@"%@ -errors", self];
```



## 二、 NSControl (RACCommandSupport)

`RACCommand`代表着与交互后即将执行的一段流程。通常这个交互是UI层级的，`NSControl` 中有一个属性`rac_command`。比如你点击个Button。`RACCommand`可以方便的将Button与enable状态进行绑定，也就是当enable为NO的时候，这个`RACCommand`将不会执行。`RACCommand`还有一个常见的策略：`allowsConcurrentExecution`，默认为NO，也就是是当你这个command正在执行的话，你多次点击Button是没有用的。`RACCommand` 的`execute`方法返回值是一个`Signal`，这个`Signal`会返回`next`或者`complete`或者`error`。

```objective-c
- (void)setRac_command:(RACCommand *)command {
	objc_setAssociatedObject(self, NSControlRACCommandKey, command, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[objc_getAssociatedObject(self, NSControlEnabledDisposableKey) dispose];
	objc_setAssociatedObject(self, NSControlEnabledDisposableKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	if (command == nil) {
		self.enabled = YES;
		return;
	}
	[self rac_hijackActionAndTargetIfNeeded];
	RACScopedDisposable *disposable = [[command.enabled setKeyPath:@"enabled" onObject:self] asScopedDisposable];
	objc_setAssociatedObject(self, NSControlEnabledDisposableKey, disposable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (void)rac_hijackActionAndTargetIfNeeded {
	SEL hijackSelector = @selector(rac_commandPerformAction:);
	if (self.target == self && self.action == hijackSelector) return;
	if (self.target != nil) NSLog(@"WARNING: NSControl.rac_command hijacks the control's existing target and action.");
	self.target = self;
	self.action = hijackSelector;
}
- (void)rac_commandPerformAction:(id)sender {
	[self.rac_command execute:sender];
}
```

参考资料：

 https://juejin.im/post/5871fb3c128fe10058226c21



