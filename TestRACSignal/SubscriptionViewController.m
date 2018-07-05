//
//  SubscriptionViewController.m
//  TestRACSignal
//
//  Created by ys on 2018/7/5.
//  Copyright © 2018年 ys. All rights reserved.
//

#import "SubscriptionViewController.h"

#import <ReactiveCocoa.h>

@interface SubscriptionViewController ()

@property (nonatomic, weak) RACSignal *signal;

@end

@implementation SubscriptionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.signal = [self createSignal];
    [_signal subscribeNext:^(id x) {
        NSLog(@"信号值：%@", x);
    } completed:^{
        NSLog(@"信号完成");
    }];
    NSLog(@"作用域内容信号：%@", _signal);
}

- (RACSignal *)createSignal
{
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@"nextValue"];
        [subscriber sendCompleted];
        
        return nil;
    }];
}

- (IBAction)buttonAction:(id)sender {
    NSLog(@"button点击下信号：%@", _signal);
}

@end
