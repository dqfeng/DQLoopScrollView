//
//  LoopScrollViewController.m
//  DQLoopScrollView
//
//  Created by dqfeng   on 14/7/14.
//  Copyright (c) 2015年 dqfeng. All rights reserved.
//

#import "LoopScrollViewController.h"
#import "DQLoopScrollView.h"
@interface LoopScrollViewController ()<DQLoopScrollViewDelegate>

@property(nonatomic,strong) NSArray *imageNames;
@property(nonatomic,strong) DQLoopScrollView *loopScrollView;
@property (nonatomic,strong) UIButton *  preButton;
@property (nonatomic,strong) UIButton *  nextButton;

@end

@implementation LoopScrollViewController

#pragma mark- view live cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"轮播图";
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self addViews];
}

#pragma mark- setup views
- (void)addViews
{
    [self.view addSubview:self.loopScrollView];
    [self.view addSubview:self.preButton];
    [self.view addSubview:self.nextButton];
}

- (void)layoutViews
{
    self.loopScrollView.frame = CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, 200);
    self.nextButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width/2 + 50, 300, 80, 30);
    self.preButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 130, 300, 80, 30);
}

#pragma mark- DQLoopScrollViewDelegate
- (DQLoopScrollViewItem *)loopScrollView:(DQLoopScrollView *)loopScrollView contentViewAtIndex:(NSInteger)pageIndex
{
    static NSString * Iden = @"ImageView";
    DQLoopScrollViewItem *item = [loopScrollView dequeueReusableItemWithIdentifier:Iden];
    if (!item) {
       UIImageView  *view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:self.imageNames[pageIndex]]];
        item = [[DQLoopScrollViewItem alloc] initWithContentView:view identifier:Iden];
    }
    UIImageView *imgView = (UIImageView *)item.contentView;
    imgView.image = [UIImage imageNamed:self.imageNames[pageIndex]];
    return item;
}

- (void)loopScrollView:(DQLoopScrollView *)loopScrollView didSelectContentView:(UIView *)contentView atIndex:(NSInteger)pageIndex
{
    NSLog(@"select:%@",@(pageIndex));
}

- (void)loopScrollView:(DQLoopScrollView *)loopScrollView didScrollToContentView:(UIView *)contentView atIndex:(NSInteger)pageIndex
{
    NSLog(@"当前页:%@",@(pageIndex));
}

#pragma mark- action
- (void)nextBtAction
{
    [self.loopScrollView scrollToIndex:self.loopScrollView.currentPageIndex + 1];
}

- (void)preBtAction
{
    [self.loopScrollView scrollToIndex:self.loopScrollView.currentPageIndex - 1];
}

- (DQLoopScrollView *)loopScrollView
{
    if (!_loopScrollView) {
        _loopScrollView = [[DQLoopScrollView alloc] initWithFrame:CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, 200)];
        _loopScrollView.animationDuration = 3;
        _loopScrollView.totalPageCount = self.imageNames.count;

        _loopScrollView.delegate = self;
    }
    return _loopScrollView;
}

- (NSArray *)imageNames
{
    if (!_imageNames) {
        _imageNames = @[@"hehe.jpg",@"test_1.jpeg",@"test_2.jpeg",@"test_3.jpeg",@"tuzi.jpg",@"car.jpg"];
    }
    return _imageNames;
}

- (UIButton *)nextButton
{
    if (!_nextButton) {
        _nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_nextButton setTitle:@"下一张" forState:UIControlStateNormal];
        _nextButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width/2 + 50, 300, 80, 30);
        [_nextButton addTarget:self action:@selector(nextBtAction) forControlEvents:UIControlEventTouchUpInside];
        [_nextButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    }
    return _nextButton;
}

- (UIButton *)preButton
{
    if (!_preButton) {
        _preButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_preButton setTitle:@"上一张" forState:UIControlStateNormal];
        _preButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 130, 300, 80, 30);
        [_preButton addTarget:self action:@selector(preBtAction) forControlEvents:UIControlEventTouchUpInside];
        [_preButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    }
    return _preButton;
}

@end
