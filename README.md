# DQLoopScrollView
DQLoopScrollView是一个轻量级的支持无限循环滚动的轮播视图组件

##特点
- 支持设置手动滚动和自动滚动
- 支持设置是否可以无限循环滚动
- 无论添加多少页内部实现最多只创建两页

##使用

```objc

#pragma mark - view live cycle
- (void)viewDidLoad 
{
    [super viewDidLoad];
    self.loopScrollView = [[DQLoopScrollView alloc] initWithFrame:CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, 200)];
    
    self.loopScrollView.animationDuration = 3;//设置自动滚动的动画时间，当小于0时禁止自动滚动   
    
    self.loopScrollView.infiniteLoopEnable = YES;//设置是否支持无限循环滚动
    
    self.loopScrollView.delegate = self;//设置代理
    
    [self.view addSubview:self.loopScrollView];
}

#pragma mark- DQLoopScrollViewDelegate
//返回总页数 住：必须实现
- (NSInteger)numberOfItemsInLoopScrollView:(DQLoopScrollView *)loopScrollView
{
    return self.imageNames.count;
}

//返回每一页的内容视图代理方法 注：必须实现
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

//点击某一页触发的代理方法
- (void)loopScrollView:(DQLoopScrollView *)loopScrollView didSelectItem:(DQLoopScrollViewItem *)contentView atIndex:(NSInteger)pageIndex
{
    NSLog(@"select:%@",@(pageIndex));
}

//已经滚动到某一页触发的代理方法
- (void)loopScrollView:(DQLoopScrollView *)loopScrollView didScrollToItem:(DQLoopScrollViewItem *)contentView atIndex:(NSInteger)pageIndex
{
    NSLog(@"当前页:%@",@(pageIndex));
}

```
- 详细使用请参照demo

##安装

将`DQLoopScrollView/`目录下的`DQLoopScrollView.m`/`DQLoopScrollView.h`两个文件拷贝到项目中即可


##运行环境

- iOS 7+
- 支持 armv7/armv7s/arm64
