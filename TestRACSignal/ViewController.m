//
//  ViewController.m
//  TestRACSignal
//
//  Created by ys on 2018/7/5.
//  Copyright © 2018年 ys. All rights reserved.
//

#import "ViewController.h"

#import <ReactiveCocoa.h>

@interface ViewController ()

//@property (nonatomic, weak) RACSignal *signal;
@property (nonatomic, strong) RACSignal *signal;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createSignal];
    NSLog(@"作用域外容信号：%@", _signal);
}

- (void)createSignal
{
    self.signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        NSLog(@"信号来了");
        
        return nil;
    }];
    
    NSLog(@"作用域内信号：%@", _signal);
}
- (IBAction)buttonAction:(id)sender {
    NSLog(@"button点击下信号：%@", _signal);
}

@end
