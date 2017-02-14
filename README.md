# DQLoopScrollView
DQLoopScrollView是一个支持循环滚动的轮播视图组件

##特点
- 支持手动滚动和自动滚动
- 无论添加多少页内部实现最多只有3页避免内存增加

##使用

```objc

#pragma mark - view live cycle
- (void)viewDidLoad 
{
    [super viewDidLoad];
    self.title = @"轮播图";
    self.loopScrollView = [[DQLoopScrollView alloc] initWithFrame:CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, 200)];
    
    self.loopScrollView.animationDuration = 3;//设置自动滚动的动画时间，当小于0时禁止自动滚动
    
    self.loopScrollView.totalPageCount = 5;//设置页数
    
    self.loopScrollView.selectedEnable = YES;//设置是否支持点击
    
    self.loopScrollView.delegate = self;//设置代理
    
    [self.view addSubview:self.loopScrollView];
}

#pragma mark- DQLoopScrollViewDelegate
//返回每一页的内容视图代理方法 注：必须实现
- (UIView *)loopScrollView:(DQLoopScrollView *)loopScrollView contentViewAtIndex:(NSInteger)pageIndex
{
    UIImageView *imgView = [UIImageView new];
    //设置图片...
    return imgView;
}

//点击某一页触发的代理方法
- (void)loopScrollView:(DQLoopScrollView *)loopScrollView didSelectContentView:(UIView *)contentView atIndex:(NSInteger)pageIndex
{
    NSLog(@"select:%@",@(pageIndex));
}

//已经滚动到某一页触发的代理方法
- (void)loopScrollView:(DQLoopScrollView *)loopScrollView didScrollToContentView:(UIView *)contentView atIndex:(NSInteger)pageIndex
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
