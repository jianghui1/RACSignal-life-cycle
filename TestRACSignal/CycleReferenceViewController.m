//
//  CycleReferenceViewController.m
//  TestRACSignal
//
//  Created by ys on 2018/7/5.
//  Copyright © 2018年 ys. All rights reserved.
//

#import "CycleReferenceViewController.h"

#import <ReactiveCocoa.h>

@interface CycleReferenceViewController ()

@property (nonatomic, strong) RACSignal *signal;

@end

@implementation CycleReferenceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.signal = [self createSignal];
    [_signal subscribeNext:^(id x) {
        NSLog(@"信号值：%@", x);
        NSLog(@"2 -- self：%@", self);
    } completed:^{
        NSLog(@"信号完成");
    }];
    NSLog(@"作用域内容信号：%@", _signal);
}

- (RACSignal *)createSignal
{
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        // NSLog(@"1 -- self：%@", self);
        [subscriber sendNext:@"nextValue"];
        [subscriber sendCompleted];
        
        return nil;
    }];
}

- (void)dealloc
{
    NSLog(@"我挂了");
}

@end
