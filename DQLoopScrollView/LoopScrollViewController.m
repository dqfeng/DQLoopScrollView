//
//  LoopScrollViewController.m
//  DQLoopScrollView
//
//  Created by dqfeng   on 14/7/14.
//  Copyright (c) 2015年 dqfeng. All rights reserved.
//

#import "LoopScrollViewController.h"
#import "DQLoopScrollView.h"
@interface LoopScrollViewController ()<DQLoopScrollViewDelegate,UITableViewDelegate,UITableViewDataSource>

@property(nonatomic,strong) NSArray          * imageNames;
@property(nonatomic,strong) DQLoopScrollView * loopScrollView;
@property(nonatomic,strong) UITableView      * tableView;
@property(nonatomic,strong) UILabel          * trackLabel;

@end

@implementation LoopScrollViewController

#pragma mark- view live cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self addViews];
}

#pragma mark- setup views
- (void)addViews
{
    [self.view addSubview:self.tableView];
    [self layoutViews];
}

- (void)layoutViews
{
    self.tableView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
}

#pragma mark- DQLoopScrollViewDelegate
- (NSInteger)numberOfItemsInLoopScrollView:(DQLoopScrollView *)loopScrollView
{
    return self.imageNames.count;
}

- (DQLoopScrollViewItem *)loopScrollView:(DQLoopScrollView *)loopScrollView itemAtIndex:(NSInteger)pageIndex
{
    static NSString * Iden = @"ImageView";
    DQLoopScrollViewItem *item = [loopScrollView dequeueReusableItemWithIdentifier:Iden];
    if (!item) {
        UIImageView  *view = [[UIImageView alloc] init];
        item = [[DQLoopScrollViewItem alloc] initWithContentView:view identifier:Iden];
    }
    UIImageView *imgView = (UIImageView *)item.contentView;
    imgView.image = [UIImage imageNamed:self.imageNames[pageIndex]];
    return item;
}

- (void)loopScrollView:(DQLoopScrollView *)loopScrollView didSelectItem:(DQLoopScrollViewItem *)contentView atIndex:(NSInteger)pageIndex
{
    NSLog(@"select:%@",@(pageIndex));
}

- (void)loopScrollView:(DQLoopScrollView *)loopScrollView didScrollToItem:(DQLoopScrollViewItem *)contentView atIndex:(NSInteger)pageIndex
{
    NSLog(@"当前页:%@",@(pageIndex));
    self.trackLabel.text = [NSString stringWithFormat:@"%@/%@",@(self.imageNames.count),@(pageIndex + 1)];
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIden = @"CellIden";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIden];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIden];
        UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 80, (55 - 30)/2, 60, 30)];
        sw.tag = indexPath.row + 1000;
        [sw addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
        sw.hidden = YES;
        [cell addSubview:sw];
    }
    UISwitch *sw = (UISwitch *)[cell viewWithTag:indexPath.row + 1000];
    switch (indexPath.row) {
        case 0:
            sw.hidden = NO;
            sw.on = self.loopScrollView.infiniteLoopEnable;
            cell.textLabel.text = @"切换是否支持无限循环滚动";
            break;
        case 1:
            sw.hidden = NO;
            sw.on = self.loopScrollView.animationDuration > 0;
            cell.textLabel.text = @"切换是否支持自动滚动";
            break;
        case 2:
            cell.textLabel.text = @"使滚动到指定页（4）";
            break;
        case 3:
            cell.textLabel.text = @"更新数据源1张的情况";
            break;
        case 4:
            cell.textLabel.text = @"更新数据源2张的情况";
            break;
        case 5:
            cell.textLabel.text = @"更新数据源多张的情况";
            break;
        default:
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0:
            self.loopScrollView.infiniteLoopEnable = !self.loopScrollView.infiniteLoopEnable;
            break;
        case 1:
            self.loopScrollView.animationDuration = self.loopScrollView.animationDuration == -1?3:-1;
            break;
        case 2:
            [self.loopScrollView scrollToIndex:3];
            break;
        case 3:
            self.imageNames = @[@"third_loopScrollView_test1.jpg"];
            [self.loopScrollView reloadData];
            break;
        case 4:
            self.imageNames = @[@"third_loopScrollView_test1.jpg",@"third_loopScrollView_test2.jpg"];
            [self.loopScrollView reloadData];
            break;
        case 5:
            self.imageNames = @[@"third_loopScrollView_test1.jpg",@"third_loopScrollView_test2.jpg",@"third_loopScrollView_test3.jpg",@"third_loopScrollView_test4.jpg",@"third_loopScrollView_test5.jpg",@"third_loopScrollView_test6.jpg",@"third_loopScrollView_test7.jpg",@"third_loopScrollView_test8.jpg",@"third_loopScrollView_test9.jpg"];
            ;
            [self.loopScrollView reloadData];
            break;
        default:
            break;
    }
}

#pragma mark- action
- (void)switchAction:(UISwitch *)sw
{
    switch (sw.tag - 1000) {
        case 0:
            self.loopScrollView.infiniteLoopEnable = sw.on;
            break;
        case 1:
            self.loopScrollView.animationDuration = sw.on?3:-1;
            break;
        default:
            break;
    }
}


#pragma mark- getter
- (DQLoopScrollView *)loopScrollView
{
    if (!_loopScrollView) {
        _loopScrollView = [[DQLoopScrollView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 200)];
        _loopScrollView.animationDuration  = 3;
        _loopScrollView.delegate = self;
        [_loopScrollView addSubview:self.trackLabel];
    }
    return _loopScrollView;
}

- (NSArray *)imageNames
{
    if (!_imageNames) {
        _imageNames = @[@"third_loopScrollView_test1.jpg",@"third_loopScrollView_test2.jpg",@"third_loopScrollView_test3.jpg",@"third_loopScrollView_test4.jpg",@"third_loopScrollView_test5.jpg",@"third_loopScrollView_test6.jpg",@"third_loopScrollView_test7.jpg",@"third_loopScrollView_test8.jpg",@"third_loopScrollView_test9.jpg"];
    }
    return _imageNames;
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) style:UITableViewStylePlain];
        _tableView.delegate   = self;
        _tableView.dataSource = self;
        _tableView.rowHeight  = 55;
        _tableView.tableHeaderView = self.loopScrollView;
    }
    return _tableView;
}

- (UILabel *)trackLabel
{
    if (!_trackLabel) {
        _trackLabel = [[UILabel alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 70, 200 - 20, 60, 20)];
        _trackLabel.layer.cornerRadius = 8;
        _trackLabel.layer.masksToBounds = YES;
        _trackLabel.textAlignment = NSTextAlignmentCenter;
        _trackLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.5];
        _trackLabel.textColor = [UIColor whiteColor];
        _trackLabel.font = [UIFont systemFontOfSize:14];
    }
    return _trackLabel;
}

@end
