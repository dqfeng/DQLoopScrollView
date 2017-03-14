//
//  DQLoopScrollView.m
//  DQLoopScrollView
//
//  Created by dqfeng   on 14/7/14.
//  Copyright (c) 2015年 dqfeng. All rights reserved.
//

#import "DQLoopScrollView.h"

@implementation DQLoopScrollViewItem

- (instancetype)initWithContentView:(UIView *)contentView identifier:(NSString *)identifier
{
    self = [super init];
    if (self) {
        _contentView = contentView;
        _identifier  = identifier;
        [self addSubview:_contentView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.contentView.frame = self.bounds;
}

@end



static const CGFloat kDQLoopScrollViewAnimationDuration = -1;
@interface DQLoopScrollView ()<UIScrollViewDelegate>

@property (nonatomic , assign) NSInteger         currentPageIndex;
@property (nonatomic , strong) NSMutableArray *  contentViews;
@property (nonatomic , strong) UIScrollView   *  scrollView;
@property (nonatomic , weak)   NSTimer        *  animationTimer;
@property (nonatomic,  assign) BOOL              scrolling;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic,strong) NSMutableDictionary<NSString *,NSMutableArray<DQLoopScrollViewItem *> *> *  reusableQueue;

@end

@implementation DQLoopScrollView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commentInit];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commentInit];
    }
    return self;
}

- (void)commentInit
{
    _scrollView = [UIScrollView new];
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.contentMode      = UIViewContentModeCenter;
    _scrollView.delegate         = self;
    _scrollView.pagingEnabled    = YES;
    _scrollView.contentOffset    = CGPointMake(CGRectGetWidth(self.scrollView.frame), 0);
    _scrollView.contentSize      = CGSizeMake(3 * CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.scrollView.frame));
    _animationDuration           = kDQLoopScrollViewAnimationDuration;
    _selectedEnable              = YES;
    _currentPageIndex            = 0;
    [self addSubview:_scrollView];
    _pageControl                 = [[UIPageControl alloc] init];
    _pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
    _pageControl.pageIndicatorTintColor = [UIColor grayColor];
    _pageControl.currentPage = 0;
    _pageControl.frame = CGRectMake(0, CGRectGetHeight(self.frame) - 25, CGRectGetWidth(self.frame), 20);
    [self addSubview:_pageControl];
}

- (void)createTimer
{
    _animationTimer = [NSTimer scheduledTimerWithTimeInterval:self.animationDuration target:self selector:@selector(animationTimerFired:) userInfo:nil repeats:YES];
    [_animationTimer setFireDate:[NSDate distantFuture]];
}

#pragma mark-
#pragma mark setter
- (void)setTotalPageCount:(NSInteger)totalPageCount
{
    _totalPageCount = totalPageCount;
    _scrollView.scrollEnabled = totalPageCount > 1;
    _pageControl.numberOfPages = totalPageCount;
    self.currentPageIndex = _currentPageIndex;
    _pageControl.currentPage = _currentPageIndex;
    
    if (_totalPageCount > 0) {
        [self setNeedsLayout];
    }
    if (!_animationTimer && self.animationDuration > 1 && self.totalPageCount > 1) {
        [self createTimer];
        [self.animationTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:self.animationDuration]];
    }
}

- (void)setDelegate:(id<DQLoopScrollViewDelegate>)delegate
{
    if (_delegate != delegate) {
        _delegate = delegate;
        if (self.totalPageCount > 0) {
            [self setNeedsLayout];
        }
        if (!_animationTimer && self.animationDuration > 1 && self.totalPageCount > 1) {
            [self createTimer];
            [self.animationTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:self.animationDuration]];
        }
    }
}

- (void)setAnimationDuration:(float)animationDuration
{
    _animationDuration = animationDuration;
    if (animationDuration <= 0) {
        [_animationTimer invalidate];
        _animationTimer = nil;
    }
    else if (!_animationTimer && self.totalPageCount > 1) {
        [self createTimer];
        [self.animationTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:self.animationDuration]];
    }
}

- (void)setCurrentPageIndex:(NSInteger)currentPageIndex
{
    _currentPageIndex = currentPageIndex;
    [self configContentViews];
    if ([self.delegate respondsToSelector:@selector(loopScrollView:didScrollToContentView:atIndex:)]) {
        [self.delegate loopScrollView:self didScrollToContentView:_contentViews[1] atIndex:self.currentPageIndex];
    }
}

#pragma mark-
#pragma mark configContentViews
- (void)configContentViews
{
    if (self.totalPageCount <= 0) return;
    [self.scrollView.subviews enumerateObjectsUsingBlock:^(DQLoopScrollViewItem *  item, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!self.reusableQueue) self.reusableQueue = @{}.mutableCopy;
        NSMutableArray *array = self.reusableQueue[item.identifier];
        if (!array){
            array = @[].mutableCopy;
            self.reusableQueue[item.identifier] = array;
        }
        [array addObject:item];
        [item removeFromSuperview];
    }];
    [self setContentViewsForScrollView];
    NSInteger counter = 0;
    for (UIView *contentView in self.contentViews) {
        if (self.selectedEnable) {
            contentView.userInteractionEnabled = YES;
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contentViewTapAction:)];
            [contentView addGestureRecognizer:tapGesture];
        }
        CGRect rightRect = self.scrollView.frame;
        rightRect.origin = CGPointMake(CGRectGetWidth(self.scrollView.frame) * (counter++), 0);
        contentView.frame = rightRect;
        [self.scrollView addSubview:contentView];
    }
    [self.scrollView setContentOffset:CGPointMake(self.scrollView.frame.size.width, 0)];
}

- (void)setContentViewsForScrollView
{
    NSInteger previousPageIndex = [self getValidNextPageIndexWithPageIndex:self.currentPageIndex - 1];
    NSInteger rearPageIndex = [self getValidNextPageIndexWithPageIndex:self.currentPageIndex + 1];
    if (!self.contentViews) self.contentViews = @[].mutableCopy;
    [self.contentViews removeAllObjects];
    if ([self.delegate respondsToSelector:@selector(loopScrollView: contentViewAtIndex:)]) {
        [self.contentViews addObject:[self.delegate loopScrollView:self contentViewAtIndex:previousPageIndex]];
        [self.contentViews addObject:[self.delegate loopScrollView:self contentViewAtIndex:self.currentPageIndex]];
        [self.contentViews addObject:[self.delegate loopScrollView:self contentViewAtIndex:rearPageIndex]];
    }
}

- (NSInteger)getValidNextPageIndexWithPageIndex:(NSInteger)currentPageIndex;
{
    if(currentPageIndex == -1) {
        return self.totalPageCount - 1;
    }
    else if (currentPageIndex == self.totalPageCount) {
        return 0;
    }
    else {
        return currentPageIndex;
    }
}

#pragma mark -
#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.animationTimer setFireDate:[NSDate distantFuture]];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.animationTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:self.animationDuration]];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    int contentOffsetX = scrollView.contentOffset.x;
    if(contentOffsetX >= (2 * CGRectGetWidth(scrollView.frame))) {
        self.currentPageIndex = [self getValidNextPageIndexWithPageIndex:self.currentPageIndex + 1];
    }
    if(contentOffsetX <= 0) {
        self.currentPageIndex = [self getValidNextPageIndexWithPageIndex:self.currentPageIndex - 1];
    }
    self.pageControl.currentPage = self.currentPageIndex;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [scrollView setContentOffset:CGPointMake(CGRectGetWidth(scrollView.frame), 0) animated:YES];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    _scrolling = NO;
}

#pragma mark-
#pragma mark action
- (void)animationTimerFired:(NSTimer *)animationTimer
{
    CGFloat newOffsetX = CGRectGetWidth(self.scrollView.frame)*2;
    [self.scrollView setContentOffset:CGPointMake(newOffsetX, 0) animated:YES];
}

- (void)contentViewTapAction:(UITapGestureRecognizer *)tap
{
    [self.animationTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:self.animationDuration]];
    BOOL responsToSel = [self.delegate respondsToSelector:@selector(loopScrollView:didSelectContentView:atIndex:)];
    if (responsToSel) {
        [self.delegate loopScrollView:self didSelectContentView:tap.view atIndex:self.currentPageIndex];
    }
}

#pragma mark- public
- (void)scrollToIndex:(NSInteger)pageIndex
{
    
    if (_scrolling || pageIndex > self.totalPageCount || pageIndex < 0) return;
    [self.animationTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:self.animationDuration]];
    CGPoint newOffset;
    if (pageIndex == self.currentPageIndex +1) {
        newOffset = CGPointMake(self.scrollView.contentOffset.x +CGRectGetWidth(self.scrollView.frame), self.scrollView.contentOffset.y);
        [self.scrollView setContentOffset:newOffset animated:YES];
        _scrolling = YES;
    }
    else if (pageIndex == self.currentPageIndex - 1) {
        newOffset = CGPointMake(self.scrollView.contentOffset.x - CGRectGetWidth(self.scrollView.frame), self.scrollView.contentOffset.y);
        [self.scrollView setContentOffset:newOffset animated:YES];
        _scrolling = YES;
    }
    else {
        if (pageIndex < self.totalPageCount || pageIndex >= 0) {
            self.currentPageIndex = pageIndex;
        }
    }
}

- (DQLoopScrollViewItem *)dequeueReusableItemWithIdentifier:(NSString *)identifier
{
    DQLoopScrollViewItem *item = self.reusableQueue[identifier].lastObject;
    [self.reusableQueue[identifier] removeLastObject];
    return item;
}


#pragma mark- override
- (void)layoutSubviews
{
    [super layoutSubviews];
    self.scrollView.frame = self.bounds;
    _scrollView.contentSize      = CGSizeMake(3 * CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.scrollView.frame));
    _scrollView.contentOffset    = CGPointMake(CGRectGetWidth(_scrollView.frame), 0);
    [self configContentViews];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    if (!newWindow) {
        [_animationTimer invalidate];
        _animationTimer = nil;
    }
    else if (!_animationTimer && self.animationDuration > 0) {
        if (self.totalPageCount > 1) {
            _animationTimer = [NSTimer scheduledTimerWithTimeInterval:self.animationDuration target:self selector:@selector(animationTimerFired:) userInfo:nil repeats:YES];
            [self.animationTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:self.animationDuration]];
        }
    }
}

@end
