# 放心使用ReactiveCocoa ： RACSignal生命周期

为什么要关心RACSignal的生命周期呢？原因有两点：
1. 网上关于ReactiveCocoa的教程很少，一般都是说些用法，而ReactiveCocoa很多的函数方法没有涉及到。
2. ReactiveCocoa里面很多的block很容易出现内存泄露，了解了信号的生命周期会更得心应手的使用此框架。

* 如果你已经在使用了此框架，并且对此框架非常了解，可以忽略下面内容，或者继续看，文中写的有什么不好的地方，请指教。
* 如果你会使用此框架，但是没有考虑过信号的生命周期，请继续往下看，有什么问题可以共同交流。
* 如果你还没有接触过或者刚开始接触，建议你先看下一些网上对此框架的介绍，然后继续阅读。

网上一些相关的技术文章：
* [美团技术团队的文章](https://tech.meituan.com/tag/ReactiveCocoa)
* [limboy的文章](http://limboy.me/)
* [雷纯锋的技术博客](http://blog.leichunfeng.com/blog/2015/12/25/reactivecocoa-v2-dot-5-yuan-ma-jie-xi-zhi-jia-gou-zong-lan/)

#### 下面开始对ReactiveCocoa v2.5版本 RACSignal的生命周期进行解读
开始之前先声明一下：文章中的代码可在github中下载，地址：<https://github.com/jianghui1/RACSignal-life-cycle.git>

1. 信号的创建：
    
    在ViewController中增加一个方法：
    
        - (void)createSignal
        {
            [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
            NSLog(@"信号来了");
        
            return nil;
            }];
        }
    然后看下`RACSignal createSignal:`的实现，进入`createSignal:`方法：

        + (RACSignal *)createSignal:(RACDisposable * (^)(id<RACSubscriber> subscriber))didSubscribe {
	        return [RACDynamicSignal createSignal:didSubscribe];
        }
    进入`RACDynamicSignal`类中：
    
        + (RACSignal *)createSignal:(RACDisposable * (^)(id<RACSubscriber> subscriber))didSubscribe {
	        RACDynamicSignal *signal = [[self alloc] init];
	        signal->_didSubscribe = [didSubscribe copy];
	        return [signal setNameWithFormat:@"+createSignal:"];
        }
    到此，信号创建完成，其实是创建了一个`RACDynamicSignal`。
    注意此时的信号是一个临时变量，生命周期就在`- (void)createSignal`作用域中。下面进行验证。
    修改ViewController中代码如下：
    
        @property (nonatomic, weak) RACSignal *signal;
        - (void)viewDidLoad {
            [super viewDidLoad];
    
            [self createSignal];
            NSLog(@"作用域外信号：%@", _signal);
        }
        - (void)createSignal
        {
            self.signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
            NSLog(@"信号来了");
        
            return nil;
            }];
    
            NSLog(@"作用域内信号：%@", _signal);
        }
    运行查看log日志：
    
        2018-07-05 12:03:19.543655+0800 TestRACSignal[10614:728631] 作用域内信号：<RACDynamicSignal: 0x600000234c00> name:
        2018-07-05 12:03:19.543864+0800 TestRACSignal[10614:728631] 作用域外信号：<RACDynamicSignal: 0x600000234c00> name: 
    输出日志实力打脸呀。在修改下代码看下：
        
        - (IBAction)buttonAction:(id)sender {
            NSLog(@"button点击下信号：%@", _signal);
        }
    创建一个`button`然后在`buttonAction:`中打印信号，log日志：
    
        2018-07-05 12:17:52.481839+0800 TestRACSignal[11224:770370] 作用域内信号：<RACDynamicSignal: 0x600000421d60> name: 
        2018-07-05 12:17:52.482105+0800 TestRACSignal[11224:770370] 作用域外信号：<RACDynamicSignal: 0x600000421d60> name: 
        2018-07-05 12:17:56.731703+0800 TestRACSignal[11224:770370] button点击下信号：(null)
    ok，发现问题了吗？
    看下`viewDidLoad`中的方法：

         - (void)viewDidLoad {
            [super viewDidLoad];
    
            [self createSignal];
            NSLog(@"作用域外信号：%@", _signal);
        }
    方法中调用`createSignal`创建了信号，但是在`viewDidLoad`方法中，`weak`修饰的`signal`还是有效的，而`buttonAction:`中`signal`已经被释放了，证实了`RACDynamicSignal`是一个临时变量被释放了。如果还有问题，可以把信号改成`strong`修饰，log日志如下：
    
        2018-07-05 12:26:30.103753+0800 TestRACSignal[11579:795309] 作用域内信号：<RACDynamicSignal: 0x60000023bd40> name: 
        2018-07-05 12:26:30.103971+0800 TestRACSignal[11579:795309] 作用域外容信号：<RACDynamicSignal: 0x60000023bd40> name: 
        2018-07-05 12:26:40.416392+0800 TestRACSignal[11579:795309] button点击下信号：<RACDynamicSignal: 0x60000023bd40> name: 
    
    现在信号的创建已经完成，接下来开始信号的订阅。
2. 信号的订阅：
    
    创建`SubscriptionViewController`并添加如下代码：

        - (void)viewDidLoad {
            [super viewDidLoad];
    
            [[self createSignal] subscribeNext:^(id x) {
                NSLog(@"信号值：%@", x);
            } completed:^{
                NSLog(@"信号完成");
            }];
        }
        
        - (RACSignal *)createSignal
        {
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
                [subscriber sendNext:@"nextValue"];
                [subscriber sendCompleted];
        
                return nil;
            }];
        }
    运行，log日志如下：
    
        2018-07-05 13:29:23.506086+0800 TestRACSignal[13839:961969] 信号值：nextValue
        2018-07-05 13:29:23.506565+0800 TestRACSignal[13839:961969] 信号完成
    可以看到，完成了信号的订阅。这时，信号的生命周期是否会受到订阅的影响呢？先使用代码测试一下：
        
        @property (nonatomic, weak) RACSignal *signal;
        - (void)viewDidLoad {
            [super viewDidLoad];
    
            self.signal = [self createSignal];
            [_signal subscribeNext:^(id x) {
                NSLog(@"信号值：%@", x);
            } completed:^{
                NSLog(@"信号完成");
            }];
            NSLog(@"作用域内信号：%@", _signal);
        }
        - (IBAction)buttonAction:(id)sender {
            NSLog(@"button点击下信号：%@", _signal);
        }
        
    log日志如下：
    
        2018-07-05 13:37:24.577649+0800 TestRACSignal[14216:986140] 作用域内信号：<RACDynamicSignal: 0x6040002206e0> name: 
        2018-07-05 13:37:27.576780+0800 TestRACSignal[14216:986140] button点击下信号：(null)
    可以看到，对信号的订阅并没有引起信号生命周期的改变。下面追踪下源码看下订阅的调用逻辑：
    `RACSignal.m`中的方法`- (RACDisposable *)subscribeNext:(void (^)(id x))nextBlock completed:(void (^)(void))completedBlock；`创建了一个`RACSubscriber`对象，并通过`subscribe:`使用了`RACSubscriber`对象，查看`subscribe:`方法：
    
        - (RACDisposable *)subscribe:(id<RACSubscriber>)subscriber {
	        NSCParameterAssert(subscriber != nil);

    	    RACCompoundDisposable *disposable = [RACCompoundDisposable compoundDisposable];
	        subscriber = [[RACPassthroughSubscriber alloc] initWithSubscriber:subscriber signal:self disposable:disposable];

	        if (self.didSubscribe != NULL) {
		        RACDisposable *schedulingDisposable = [RACScheduler.subscriptionScheduler schedule:^{
			    RACDisposable *innerDisposable = self.didSubscribe(subscriber);
			    [disposable addDisposable:innerDisposable];
		    }];

		    [disposable addDisposable:schedulingDisposable];
	        }
	
	        return disposable;
        }
    里面创建了`RACCompoundDisposable`对象来处理清理工作，将`subscriber`转换为`RACPassthroughSubscriber`对象作为`didSubscribe`回调的参数，使用`RACScheduler.subscriptionScheduler`队列调用信号的block进行信号事件的发送。
    所有的过程中创建的对象都是临时变量，超出作用域会在适合的时候进行释放，不会造成内存的泄露。
    
#### 通过上面的分析，我们知道了一个信号从创建到订阅的生命周期，包括里面涉及的对象的创建，对于内存方面不会造成泄露。

#### 有人觉得代码中有block呀，block会造成循环引用的呀，这样子不就造成了内存泄露嘛。还有的人不管怎样，如果block里面用到self就进行弱指针转换，省时又省力。但是现在既然讲信号的生命周期，就要用严谨的方式探讨这个问题。
block为什么会造成循环引用呢，因为A引用了B，然后B的block中引用了A，就会造成循环引用，对于信号来说会发生这种情况吗，能否使用代码来模拟下这种情况呢。
假设可以的话，我们可以在`CycleReferenceViewController`中创建一个对信号的强引用`@property (nonatomic, strong) RACSignal *signal;`,然后在所有涉及到的block中引用`self`。
代码如下：

    - (void)viewDidLoad {
        [super viewDidLoad];
    
        self.signal = [self createSignal];
        [_signal subscribeNext:^(id x) {
            NSLog(@"信号值：%@", x);
            NSLog(@"2 -- self：%@", self);
        } completed:^{
            NSLog(@"信号完成");
        }];
        NSLog(@"作用域内信号：%@", _signal);
    }
    
    - (RACSignal *)createSignal
    {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
            NSLog(@"1 -- self：%@", self);
            [subscriber sendNext:@"nextValue"];
            [subscriber sendCompleted];
        
            return nil;
        }];
    }

    - (void)dealloc
    {
        NSLog(@"我挂了");
    }
运行代码,从`CycleReferenceViewController`返回到上个界面，log如下：

    2018-07-05 14:37:06.767533+0800 TestRACSignal[16588:1152683] 1 -- self：<CycleReferenceViewController: 0x7fdf8cd19df0>
    2018-07-05 14:37:06.768181+0800 TestRACSignal[16588:1152683] 信号值：nextValue
    2018-07-05 14:37:06.768689+0800 TestRACSignal[16588:1152683] 2 -- self：<CycleReferenceViewController: 0x7fdf8cd19df0>
    2018-07-05 14:37:06.769019+0800 TestRACSignal[16588:1152683] 信号完成
    2018-07-05 14:37:06.769162+0800 TestRACSignal[16588:1152683] 作用域内信号：<RACDynamicSignal: 0x60400043cf80> name:
`CycleReferenceViewController`确实没有释放，产生了内存泄露，但是具体是哪个block导致的呢，还是两个都会造成呢，此时我们可以修改`createSignal`方法中的代码如下:

    - (RACSignal *)createSignal
    {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            
            // NSLog(@"1 -- self：%@", self);
            [subscriber sendNext:@"nextValue"];
            [subscriber sendCompleted];
        
            return nil;
        }];
    }
打印log如下：

    2018-07-05 14:40:34.097979+0800 TestRACSignal[16775:1164756] 信号值：nextValue
    2018-07-05 14:40:34.098199+0800 TestRACSignal[16775:1164756] 2 -- self：<CycleReferenceViewController: 0x7fc04e473320>
    2018-07-05 14:40:34.098388+0800 TestRACSignal[16775:1164756] 信号完成
    2018-07-05 14:40:34.098583+0800 TestRACSignal[16775:1164756] 作用域内信号：<RACDynamicSignal: 0x600000626ba0> name: 
    2018-07-05 14:40:38.025929+0800 TestRACSignal[16775:1164756] 我挂了
`CycleReferenceViewController`释放，没有内存泄露。所以造成内存泄露的原因就是信号创建中对self的引用这段代码。为什么订阅的block不会造成内存泄露呢？
* 信号创建时,信号中的`_didSubscribe`引用了`CycleReferenceViewController`,而`CycleReferenceViewController`通过`signal`对信号进行了强引用，也就是循环引用。
* 信号订阅时，创建了`RACSubscriber`对`CycleReferenceViewController`进行了引用，然后通过`subscribe:`方法创建了`RACPassthroughSubscriber`并对`signal`和`RACSubscriber`进行了引用，并没有出现闭合环路，所以没有循环引用。


#### 以上就是信号生命周期与造成循环引用的地方，还在犹豫的可以开始使用ReactiveCocoa了，保证你用上之后爱不释手。还有信号的其他函数基本都是通过`RACDynamicSignal`的`createSignal:`实现的，下一篇将会介绍`RACSignal`各个函数的用法与实现。
