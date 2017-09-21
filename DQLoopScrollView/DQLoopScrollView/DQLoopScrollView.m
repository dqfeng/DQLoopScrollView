//
//  DQLoopScrollView.m
//  DQLoopScrollView
//
//  Created by dqfeng   on 14/7/14.
//  Copyright (c) 2015年 dqfeng. All rights reserved.
//

#import "DQLoopScrollView.h"

@interface DQLoopScrollViewItem ()

@property (nonatomic,assign) NSInteger index;
@property (nonatomic,assign) BOOL      fromReusableQueue;
@property (nonatomic,assign) BOOL      isInvalidIndex;

@end

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
    if (self.contentView.constraints.count <= 0 && CGRectEqualToRect(self.contentView.frame, CGRectZero)) {
        self.contentView.frame = self.bounds;
    }
}

@end

static const CGFloat kDQLoopScrollViewAnimationDuration = -1;
@interface DQLoopScrollView ()<UIScrollViewDelegate>

@property (nonatomic,strong) UIScrollView         *  scrollView;
@property (nonatomic,strong) NSTimer              *  animationTimer;
@property (nonatomic,strong) DQLoopScrollViewItem *  rightItem;
@property (nonatomic,strong) DQLoopScrollViewItem *  leftItem;
@property (nonatomic,strong) DQLoopScrollViewItem *  midItem;
@property (nonatomic,strong) DQLoopScrollViewItem *  visibleItem;
@property (nonatomic,assign) NSInteger               totalPageCount;
@property (nonatomic,strong) NSMutableDictionary<NSString *,DQLoopScrollViewItem *> *  reusableQueue;
@property (nonatomic,assign) BOOL reloadingData;

@end

@implementation DQLoopScrollView

#pragma mark- init
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

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self commentInit];
}

- (void)commentInit
{
    _infiniteLoopEnable          = YES;
    _manualScrollSupport         = YES;
    _animationDuration           = kDQLoopScrollViewAnimationDuration;
    [self addSubview:self.scrollView];
}

#pragma mark- override
- (void)layoutSubviews
{
    [super layoutSubviews];
    if (!CGRectEqualToRect(self.bounds, self.scrollView.frame)) {
        self.scrollView.frame        = self.bounds;
        [self reloadData];
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    if (!newWindow) {
        [self stopTimer];
        [self unregisterObserver];
    }
    else {
        [self registerObserver];
        if (!_animationTimer && self.animationDuration > 0 && self.totalPageCount > 1) {
            [self startTimer];
        }
    }
}

#pragma mark -
#pragma mark  UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.animationTimer setFireDate:[NSDate distantFuture]];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.animationTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:self.animationDuration]];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    _currentPageIndex = self.visibleItem.index;
    if ([self.delegate respondsToSelector:@selector(loopScrollView:didScrollToItem:atIndex:)]) {
        [self.delegate loopScrollView:self didScrollToItem:self.visibleItem atIndex:self.visibleItem.index];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [scrollView setContentOffset:CGPointMake(self.visibleItem.frame.origin.x, 0) animated:NO];
    
    _currentPageIndex = self.visibleItem.index;
    if ([self.delegate respondsToSelector:@selector(loopScrollView:didScrollToItem:atIndex:)]) {
        [self.delegate loopScrollView:self didScrollToItem:self.visibleItem atIndex:self.visibleItem.index];
    }
}

#pragma mark-
#pragma mark action
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (![keyPath isEqualToString:@"contentOffset"] || CGRectEqualToRect(self.scrollView.frame, CGRectZero) || self.reloadingData || self.totalPageCount <= 0) {
        return;
    }
    NSValue *old = change[NSKeyValueChangeOldKey];
    NSValue *new = change[NSKeyValueChangeNewKey];
    CGFloat oldContentOffsetX = [old CGPointValue].x;
    CGFloat contentOffsetX    = [new CGPointValue].x;
    if (oldContentOffsetX == contentOffsetX) return;
    if ((contentOffsetX <= 0 || contentOffsetX >= CGRectGetWidth(self.frame)*2) && self.midItem) {
        self.midItem.hidden = YES;
        self.reusableQueue[self.midItem.identifier] = self.midItem;
        self.midItem = nil;
    }
    else if (contentOffsetX > CGRectGetWidth(self.frame) && self.leftItem){
        self.leftItem.hidden = YES;
        self.reusableQueue[self.leftItem.identifier] = self.leftItem;
        self.leftItem = nil;
    }
    else if (contentOffsetX < CGRectGetWidth(self.frame) && self.rightItem) {
        self.rightItem.hidden = YES;
        self.reusableQueue[self.rightItem.identifier] = self.rightItem;
        self.rightItem = nil;
    }
    
    if (contentOffsetX == CGRectGetWidth(self.frame) && oldContentOffsetX >=0 && oldContentOffsetX <= CGRectGetWidth(self.frame)*2) {
        if (self.leftItem) {
            self.leftItem.hidden = YES;
            self.reusableQueue[self.leftItem.identifier] = self.leftItem;
            self.leftItem = nil;
        }
        
        if (self.rightItem) {
            self.rightItem.hidden = YES;
            self.reusableQueue[self.rightItem.identifier] = self.rightItem;
            self.rightItem = nil;
        }
    }
    
    if (contentOffsetX > CGRectGetWidth(self.scrollView.frame) && contentOffsetX < CGRectGetWidth(self.frame)*2) {
        if (!self.infiniteLoopEnable && self.totalPageCount == 2) return;
        if (contentOffsetX < oldContentOffsetX) {
            NSInteger index = [self getValidNextPageIndexWithPageIndex:self.rightItem.index - 1];
            if (!self.midItem || (self.midItem && (self.midItem.index != index || self.midItem.isInvalidIndex))) {
                if (self.midItem) {
                    self.midItem.hidden = YES;
                    self.reusableQueue[self.midItem.identifier] = self.midItem;
                }
                self.midItem = [self configItemWithPageIndex:index originX:CGRectGetWidth(self.frame)];
            }
        }
        else if (contentOffsetX > oldContentOffsetX){
            NSInteger index = [self getValidNextPageIndexWithPageIndex:self.midItem.index + 1];
            if (!self.rightItem || (self.rightItem && (self.rightItem.index != index || self.rightItem.isInvalidIndex))) {
                if (self.rightItem) {
                    self.rightItem.hidden = YES;
                    self.reusableQueue[self.rightItem.identifier] = self.rightItem;
                }
                self.rightItem = [self configItemWithPageIndex:index originX:CGRectGetWidth(self.frame)*2];
            }
        }
    }
    else if (contentOffsetX < CGRectGetWidth(self.frame) && contentOffsetX > 0) {
        if (contentOffsetX < oldContentOffsetX) {
            NSInteger index = [self getValidNextPageIndexWithPageIndex:self.midItem.index - 1];
            if (!self.leftItem || (self.leftItem && (self.leftItem.index != index || self.leftItem.isInvalidIndex))) {
                if (self.leftItem) {
                    self.leftItem.hidden = YES;
                    self.reusableQueue[self.leftItem.identifier] = self.leftItem;
                }
                self.leftItem = [self configItemWithPageIndex:index originX:0];
            }
        }
        else if (contentOffsetX > oldContentOffsetX){
            NSInteger index = [self getValidNextPageIndexWithPageIndex:self.leftItem.index + 1];
            if (!self.midItem || (self.midItem && (self.midItem.index != index || self.midItem.isInvalidIndex))) {
                if (self.midItem) {
                    self.midItem.hidden = YES;
                    self.reusableQueue[self.midItem.identifier] = self.midItem;
                }
                self.midItem = [self configItemWithPageIndex:index originX:CGRectGetWidth(self.frame)];
            }
        }
    }
    
    if(contentOffsetX > (2 * CGRectGetWidth(self.frame))) {
        NSInteger index = [self getValidNextPageIndexWithPageIndex:self.rightItem.index + 1];
        if (self.infiniteLoopEnable || self.rightItem.index != self.totalPageCount - 1) {
            self.rightItem.frame = CGRectMake(CGRectGetWidth(self.frame), 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
            self.midItem = self.rightItem;
            self.rightItem = [self configItemWithPageIndex:index originX:CGRectGetWidth(self.frame)*2];
            [self.scrollView setContentOffset:CGPointMake(CGRectGetWidth(self.frame), 0)];
        }
    }
    
    if(contentOffsetX < 0) {
        NSInteger index = [self getValidNextPageIndexWithPageIndex:self.leftItem.index - 1];
        if (self.infiniteLoopEnable || self.leftItem.index != 0) {
            self.leftItem.frame = CGRectMake(CGRectGetWidth(self.frame), 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
            self.midItem = self.leftItem;
            self.leftItem = [self configItemWithPageIndex:index originX:0];
            [self.scrollView setContentOffset:CGPointMake(CGRectGetWidth(self.frame), 0)];
        }
    }
    NSInteger scrollIndex = (contentOffsetX + CGRectGetWidth(self.frame)/2)/CGRectGetWidth(self.frame);
    if (scrollIndex == 0) {
        self.visibleItem = self.leftItem;
    }
    else if (scrollIndex == 1) {
        self.visibleItem = self.midItem;
    }
    else {
        self.visibleItem = self.rightItem;
    }
    if ([self.delegate respondsToSelector:@selector(loopScrollView:willScrollToItem:atIndex:)]) {
        if (contentOffsetX < CGRectGetWidth(self.frame)*2 && contentOffsetX > 0) {
            [self.delegate loopScrollView:self willScrollToItem:self.visibleItem atIndex:self.visibleItem.index];
        }
    }
}

- (void)timerFiredAction:(NSTimer *)timer
{
    if (self.infiniteLoopEnable || self.currentPageIndex != self.totalPageCount - 1) {
        CGFloat newOffsetX = CGRectGetWidth(self.scrollView.frame) + self.visibleItem.frame.origin.x ;
        [self.scrollView setContentOffset:CGPointMake(newOffsetX, 0) animated:YES];
    }
    else {
        self.currentPageIndex = 0;
    }
}

- (void)contentViewTapAction:(UITapGestureRecognizer *)tap
{
    [self.animationTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:self.animationDuration]];
    if ([self.delegate respondsToSelector:@selector(loopScrollView:didSelectItem:atIndex:)]) {
        [self.delegate loopScrollView:self didSelectItem:(DQLoopScrollViewItem *)tap.view atIndex:self.currentPageIndex];
    }
}

#pragma mark- public
- (void)reloadData
{
    if (CGRectEqualToRect(self.scrollView.frame, CGRectZero)) {return;}
    [self stopTimer];
    self.reloadingData = YES;
    if ([self.delegate respondsToSelector:@selector(numberOfItemsInLoopScrollView:)]) {
        self.totalPageCount = [self.delegate numberOfItemsInLoopScrollView:self];
    }
    if (self.totalPageCount <= 1) {
        self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
    }
    else {
        if (self.infiniteLoopEnable) {
            self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.frame)*3, CGRectGetHeight(self.frame));
        }
        else {
            if (self.totalPageCount == 2) {
                self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.frame)*2, CGRectGetHeight(self.frame));
            }
            else {
                self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.frame)*3, CGRectGetHeight(self.frame));
            }
        }
    }
    self.rightItem = nil;
    self.leftItem  = nil;
    self.midItem   = nil;
    [self.scrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[DQLoopScrollViewItem class]]) {
            DQLoopScrollViewItem *item = (DQLoopScrollViewItem *)obj;
            if (item != self.visibleItem) {
                self.reusableQueue[item.identifier] = item;
            }
            [obj removeFromSuperview];
        }
    }];
    
    if (self.totalPageCount <= 0) {
        if (self.visibleItem) {
            self.reusableQueue[self.visibleItem.identifier] = self.visibleItem;
            [self.visibleItem removeFromSuperview];
            self.visibleItem = nil;
        }
        _currentPageIndex = 0;
        if ([self.delegate respondsToSelector:@selector(loopScrollView:didScrollToItem:atIndex:)]) {
            [self.delegate loopScrollView:self didScrollToItem:self.visibleItem atIndex:self.currentPageIndex];
        }
        self.reloadingData = NO;
        return;
    }
    
    _currentPageIndex = _currentPageIndex>self.totalPageCount - 1?0:_currentPageIndex;
    if (self.infiniteLoopEnable) {
        self.midItem = [self configItemWithPageIndex:self.currentPageIndex originX:CGRectGetWidth(self.frame)];
        if (self.visibleItem) {
            self.reusableQueue[self.visibleItem.identifier] = self.visibleItem;
            self.visibleItem.hidden = YES;
        }
        self.visibleItem = self.midItem;
    }
    else {
        CGFloat originX = 0;
        if (self.currentPageIndex == self.totalPageCount - 1 && self.totalPageCount > 2) {
            originX = CGRectGetWidth(self.frame)*2;
        }
        else if (self.currentPageIndex > 0) {
            originX = CGRectGetWidth(self.frame);
        }
        
        DQLoopScrollViewItem *item = [self configItemWithPageIndex:self.currentPageIndex originX:originX];
        if (originX == CGRectGetWidth(self.frame)*2) {
            self.rightItem = item;
        }
        else if (originX == 0){
            self.leftItem = item;
        }
        else {
            self.midItem = item;
        }
        if (self.visibleItem) {
            self.reusableQueue[self.visibleItem.identifier] = self.visibleItem;
            self.visibleItem.hidden = YES;
        }
        self.visibleItem = item;
    }
    
    CGFloat contentOffsetX       = self.infiniteLoopEnable?CGRectGetWidth(self.frame):self.visibleItem.frame.origin.x;
    [self.scrollView setContentOffset:CGPointMake(contentOffsetX, 0) animated:NO];
    if ([self.delegate respondsToSelector:@selector(loopScrollView:didScrollToItem:atIndex:)]) {
        [self.delegate loopScrollView:self didScrollToItem:self.visibleItem atIndex:self.currentPageIndex];
    }
    self.reloadingData = NO;
    [self setAnimationDuration:self.animationDuration];
}

- (DQLoopScrollViewItem *)dequeueReusableItemWithIdentifier:(NSString *)identifier
{
    DQLoopScrollViewItem *item = self.reusableQueue[identifier];
    if (item) item.fromReusableQueue = YES;
    self.reusableQueue[identifier] = nil;
    return item;
}

#pragma mark- private
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

- (DQLoopScrollViewItem *)configItemWithPageIndex:(NSInteger)index originX:(CGFloat)originX
{
    if ([self.delegate respondsToSelector:@selector(loopScrollView:itemAtIndex:)] && index < self.totalPageCount) {
        DQLoopScrollViewItem *item = [self.delegate loopScrollView:self itemAtIndex:index];
        item.frame = CGRectMake(originX, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
        item.hidden = NO;
        item.index = index;
        item.isInvalidIndex = NO;
        if (!item.superview) [self.scrollView addSubview:item];
        if (!item.fromReusableQueue) {
            item.contentView.userInteractionEnabled = YES;
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contentViewTapAction:)];
            [item addGestureRecognizer:tapGesture];
        }
        return item;
    }
    return nil;
}

- (void)startTimer
{
    if (self.totalPageCount <= 0 && self.animationDuration <= 0) {return;}
    if (!_animationTimer) {
        _animationTimer = [NSTimer scheduledTimerWithTimeInterval:self.animationDuration target:self selector:@selector(timerFiredAction:) userInfo:nil repeats:YES];
    }
    [self.animationTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:self.animationDuration]];
}

- (void)stopTimer
{
    [_animationTimer invalidate];
    _animationTimer = nil;
}

- (void)unregisterObserver
{
    [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
}

- (void)registerObserver
{
    [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew |NSKeyValueObservingOptionOld context:nil];
}

#pragma mark-
#pragma mark setter
- (void)setTotalPageCount:(NSInteger)totalPageCount
{
    _totalPageCount = totalPageCount;
}

- (void)setDelegate:(id<DQLoopScrollViewDelegate>)delegate
{
    if (_delegate != delegate) {
        _delegate = delegate;
    }
}

- (void)setAnimationDuration:(CGFloat)animationDuration
{
    _animationDuration = animationDuration;
    if (animationDuration <= 0) {
        [self stopTimer];
    }
    else if (!_animationTimer && self.totalPageCount > 1) {
        [self startTimer];
    }
}

- (void)setCurrentPageIndex:(NSInteger)pageIndex
{
    if (CGRectEqualToRect(self.scrollView.frame, CGRectZero)) {
        _currentPageIndex = pageIndex;
        return;
    }
    if (_currentPageIndex != pageIndex) {
        NSInteger oldIndex = _currentPageIndex;
        _currentPageIndex = pageIndex;
        if (pageIndex > self.totalPageCount || pageIndex < 0) return;
        [self.animationTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:self.animationDuration]];
        if (pageIndex > oldIndex) {
            if (self.visibleItem.index != pageIndex -1) {
                self.visibleItem.index = pageIndex - 1;
                self.visibleItem.isInvalidIndex = YES;
            }
            CGFloat newOffsetX = CGRectGetWidth(self.scrollView.frame) + self.visibleItem.frame.origin.x;
            [self.scrollView setContentOffset:CGPointMake(newOffsetX, 0) animated:YES];
        }
        else if (pageIndex < oldIndex){
            if (self.visibleItem.index != pageIndex + 1) {
                self.visibleItem.index = pageIndex + 1;
                self.visibleItem.isInvalidIndex = YES;
            }
            CGFloat newOffsetX =  self.visibleItem.frame.origin.x - CGRectGetWidth(self.scrollView.frame);
            [self.scrollView setContentOffset:CGPointMake(newOffsetX, 0) animated:YES];
        }
    }
}

- (void)setInfiniteLoopEnable:(BOOL)infiniteLoopEnable
{
    if (_infiniteLoopEnable != infiniteLoopEnable) {
        _infiniteLoopEnable = infiniteLoopEnable;
        [self reloadData];
    }
}

- (void)setManualScrollSupport:(BOOL)manualScrollSupport
{
    if (_manualScrollSupport != manualScrollSupport) {
        _manualScrollSupport = manualScrollSupport;
        self.scrollView.scrollEnabled = manualScrollSupport;
    }
}

#pragma mark- getter
- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [UIScrollView new];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator   = NO;
        _scrollView.contentMode      = UIViewContentModeCenter;
        _scrollView.delegate         = self;
        _scrollView.pagingEnabled    = YES;
    }
    return _scrollView;
}

- (NSMutableDictionary <NSString *,DQLoopScrollViewItem *>*)reusableQueue
{
    if (!_reusableQueue) {
        _reusableQueue = @{}.mutableCopy;
    }
    return _reusableQueue;
}

@end
