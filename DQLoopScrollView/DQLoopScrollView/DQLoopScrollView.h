//
//  DQLoopScrollView.h
//  DQLoopScrollView
//
//  Created by dqfeng   on 14/7/14.
//  Copyright (c) 2015年 dqfeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DQLoopScrollViewItem :UIView

@property (nonatomic,readonly) UIView   *  contentView;
@property (nonatomic,readonly) NSString *  identifier;

- (instancetype)initWithContentView:(UIView *)contentView identifier:(NSString *)identifier;

@end


@class DQLoopScrollView;
@protocol DQLoopScrollViewDelegate <NSObject>

- (NSInteger)numberOfItemsInLoopScrollView:(DQLoopScrollView *)loopScrollView;
- (DQLoopScrollViewItem *)loopScrollView:(DQLoopScrollView *)loopScrollView itemAtIndex:(NSInteger)pageIndex;

@optional
- (void)loopScrollView:(DQLoopScrollView *)loopScrollView didSelectItem:(DQLoopScrollViewItem *)item atIndex:(NSInteger)pageIndex;
- (void)loopScrollView:(DQLoopScrollView *)loopScrollView didScrollToItem:(DQLoopScrollViewItem *)item atIndex:(NSInteger)pageIndex;

@end


/**
 *循环滚动的轮播图组件:
 *1.
 */
@interface DQLoopScrollView : UIView

@property (nonatomic,readonly) NSInteger                     totalPageCount;
@property (nonatomic,readonly) NSInteger                     currentPageIndex;
///自动滑动的间隔时间，值大于0时会自动滑动 default -1
@property (nonatomic,assign)   CGFloat                       animationDuration;
///是否支持无限循环滚动 default YES
@property (nonatomic,assign)   BOOL                          infiniteLoopEnable;
@property (nonatomic,weak)     id<DQLoopScrollViewDelegate>  delegate;

/**
 使滚动到指定页
 @param pageIndex pageIndex
 */
- (void)scrollToIndex:(NSInteger)pageIndex;
/**
 当数据源更新的时候调用此方法
 */
- (void)reloadData;

/**
 从复用池中取出一个item
 
 @param identifier 标识
 @return 返回一个item,如果复用池为空返回nil
 */
- (DQLoopScrollViewItem *)dequeueReusableItemWithIdentifier:(NSString *)identifier;

@end

