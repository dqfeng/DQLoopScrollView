//
//  DQLoopScrollView.h
//  DQLoopScrollView
//
//  Created by dqfeng   on 14/7/14.
//  Copyright (c) 2015年 dqfeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DQLoopScrollView;
@protocol DQLoopScrollViewDelegate <NSObject>

- (UIView *)loopScrollView:(DQLoopScrollView *)loopScrollView contentViewAtIndex:(NSInteger)pageIndex;

@optional
- (void)loopScrollView:(DQLoopScrollView *)loopScrollView didSelectContentView:(UIView *)contentView atIndex:(NSInteger)pageIndex;
- (void)loopScrollView:(DQLoopScrollView *)loopScrollView didScrollToContentView:(UIView *)contentView atIndex:(NSInteger)pageIndex;

@end


/**
 循环滚动的轮播图组件
 */
@interface DQLoopScrollView : UIView

@property (nonatomic,  assign)     NSInteger                    totalPageCount;//总页数,必须设置
@property (nonatomic,  readonly)   NSInteger                    currentPageIndex;
///自动滑动的间隔时间，默认不自动滑动，值大于0时会自动滑动
@property (nonatomic,  assign)     float                        animationDuration;
@property (nonatomic,  assign)     BOOL                         selectedEnable;//default NO
@property (nonatomic,   weak)      id<DQLoopScrollViewDelegate> delegate;
@property (nonatomic, readonly) UIPageControl *pageControl;

/**
 使滚动到指定页

 @param pageIndex pageIndex
 */
- (void)scrollToIndex:(NSInteger)pageIndex;


@end
