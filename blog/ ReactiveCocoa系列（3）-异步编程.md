# ReactiveCocoa系列（3）

ReactiveCocoa（以下简称“RAC”）是一个函数响应式编程框架。本文主要讲解下ReactiveCocoa关于异步编程的实现。ReactiveCocoa的异步编程是基于GCD来实现。任务是放在dispatch_queue_t 里面串行的执行。

## 一、RACScheduler

`RACScheduler` 是一个线性执行队列，RAC 中的信号可以在 `RACScheduler` 上执行任务、发送结果；

```objective-c
@interface RACScheduler : NSObject
/// A singleton scheduler that immediately executes the blocks it is given.
+ (RACScheduler *)immediateScheduler;
/// A singleton scheduler that executes blocks in the main thread.
+ (RACScheduler *)mainThreadScheduler;

/// Creates and returns a new background scheduler with the given priority and
/// name. The name is for debug and instrumentation purposes only.
+ (RACScheduler *)schedulerWithPriority:(RACSchedulerPriority)priority name:(NSString *)name;
- (RACDisposable *)schedule:(void (^)(void))block;
- (RACDisposable *)after:(NSDate *)date schedule:(void (^)(void))block;
```

1、immediateScheduler 用来创建一个单例调度器，这个调度器会在当前线程同步执行传入的block

2、mainThreadScheduler 用来创建一个单例调度器，这个调度器会在主线程异步执行传入的block

3、schedulerWithPriority 每次都创建一个新的调度器。用于在全局线程异步执行传入的block。支持四个优先级：RACSchedulerPriorityHigh、RACSchedulerPriorityDefault、RACSchedulerPriorityLow、RACSchedulerPriorityBackground。

`RACScheduler` 在某些方面与 GCD 中的队列十分相似，与 GCD 中的队列不同的有两点，第一，它可以通过 `RACDisposable` 对执行中的任务进行取消，第二是 `RACScheduler` 中任务的执行都是串行的。

## 二、RACTargetQueueScheduler

整个 `RACTargetQueueScheduler` 类中只有一个初始化方法：

```
- (instancetype)initWithName:(NSString *)name targetQueue:(dispatch_queue_t)targetQueue {
	dispatch_queue_t queue = dispatch_queue_create(name.UTF8String, DISPATCH_QUEUE_SERIAL);
	dispatch_set_target_queue(queue, targetQueue);
	return [super initWithName:name queue:queue];
}
```

使用 `dispatch_queue_create` 创建了一个串行队列，然后使用`dispatch_set_target_queue` 修改`queue`的优先级，使之跟targetQueue的优先级一样。

另外使用dispatch_queue_create创建的多个队列，是会并行执行。 但使用dispatch_set_target_queue就可以将多个串行的queue指定到同一目标，那么多个串行queue在目标queue上就是串行执行的，不再是并行执行。

## 三、RACSubscriptionScheduler

RACScheduler中还有一个私有方法

```objective-c
(instancetype)subscriptionScheduler;
```

这个方法会返回一个单例的调度器。优先级是RACSchedulerPriorityDefault。ReactiveCocoa里面的任务默认都是通过这个调度器来执行。例如

```objective-c

- (RACDisposable *)subscribe:(id<RACSubscriber>)subscriber {
	NSCParameterAssert(subscriber != nil);

	return [RACScheduler.subscriptionScheduler schedule:^{
		[subscriber sendNext:self.value];
		[subscriber sendCompleted];
	}];
}
```

因为RAC默认都是在同一个队列串行的执行任务。所以很少有并发问题。



## 四、RACSignal

RACSignal中跟调度器有关的主要是下面三方法

```objective-c
/// Creates and returns a signal that delivers its events on the given scheduler.
/// Any side effects of the receiver will still be performed on the original
/// thread.
- (RACSignal *)deliverOn:(RACScheduler *)scheduler;

/// Creates and returns a signal that executes its side effects and delivers its
/// events on the given scheduler.
- (RACSignal *)subscribeOn:(RACScheduler *)scheduler;

/// Creates and returns a signal that delivers its events on the main thread.
/// If events are already being sent on the main thread, they may be passed on
/// without delay. An event will instead be queued for later delivery on the main
/// thread if sent on another thread, or if a previous event is already being
/// processed, or has been queued.
- (RACSignal *)deliverOnMainThread;
```



1、subscribeOn是用来把执行任务、发送结果都放在指定的调度器上执行

```objective-c
- (RACSignal *)subscribeOn:(RACScheduler *)scheduler {
	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		RACCompoundDisposable *disposable = [RACCompoundDisposable compoundDisposable];
		RACDisposable *schedulingDisposable = [scheduler schedule:^{
			RACDisposable *subscriptionDisposable = [self subscribe:subscriber];
			[disposable addDisposable:subscriptionDisposable];
		}];
		[disposable addDisposable:schedulingDisposable];
		return disposable;
	}] setNameWithFormat:@"[%@] -subscribeOn: %@", self.name, scheduler];
}
```



2、deliverOn是用来把发送结果放在指定的调度器上执行。跟subscribeOn是有很大的区别

```objective-c
- (RACSignal *)deliverOn:(RACScheduler *)scheduler {
	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		return [self subscribeNext:^(id x) {
			[scheduler schedule:^{
				[subscriber sendNext:x];
			}];
		} error:^(NSError *error) {
			[scheduler schedule:^{
				[subscriber sendError:error];
			}];
		} completed:^{
			[scheduler schedule:^{
				[subscriber sendCompleted];
			}];
		}];
	}] setNameWithFormat:@"[%@] -deliverOn: %@", self.name, scheduler];
}
```



3、deliverOnMainThread方法不是通过RACScheduler来实现。它有进行了优化。它会判断是否在主线程。如果是的话就直接执行block。不是的话直接调用dispatch_async。代码如下：

```objective-c
	void (^performOnMainThread)(dispatch_block_t) = ^(dispatch_block_t block) {
			int32_t queued = OSAtomicIncrement32(&queueLength);
			if (NSThread.isMainThread && queued == 1) {
				block();
				OSAtomicDecrement32(&queueLength);
			} else {
				dispatch_async(dispatch_get_main_queue(), ^{
					block();
					OSAtomicDecrement32(&queueLength);
				});
			}
		};
```

