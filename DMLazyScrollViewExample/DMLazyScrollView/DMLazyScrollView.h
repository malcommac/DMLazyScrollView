//
//  DMLazyScrollView.h
//  Lazy Loading UIScrollView for iOS
//
//  Created by Daniele Margutti (me@danielemargutti.com) on 24/11/12.
//  Copyright (c) 2012 http://www.danielemargutti.com. All rights reserved.
//  Distribuited under MIT License
//

#import <UIKit/UIKit.h>

@class DMLazyScrollView;

enum {
    DMLazyScrollViewTransitionAuto      =   0,
    DMLazyScrollViewTransitionForward   =   1,
    DMLazyScrollViewTransitionBackward  =   2
}; typedef NSUInteger DMLazyScrollViewTransition;

@protocol DMLazyScrollViewDelegate <NSObject>
@optional
- (void)lazyScrollViewWillBeginDragging:(DMLazyScrollView *)pagingView;
- (void)lazyScrollViewDidScroll:(DMLazyScrollView *)pagingView at:(CGPoint) visibleOffset;
- (void)lazyScrollViewDidEndDragging:(DMLazyScrollView *)pagingView;
- (void)lazyScrollViewWillBeginDecelerating:(DMLazyScrollView *)pagingView;
- (void)lazyScrollViewDidEndDecelerating:(DMLazyScrollView *)pagingView atPageIndex:(NSInteger)pageIndex;
@end

typedef UIViewController*(^DMLazyScrollViewDataSource)(NSUInteger index);

@interface DMLazyScrollView : UIScrollView

@property (copy)                DMLazyScrollViewDataSource      dataSource;
@property (nonatomic, assign)   id<DMLazyScrollViewDelegate>    controlDelegate;

@property (nonatomic,assign)    NSUInteger                      numberOfPages;
@property (readonly)            NSUInteger                      currentPage;

- (void) reloadData;

- (void) setPage:(NSInteger) index animated:(BOOL) animated;
- (void) setPage:(NSInteger) newIndex transition:(DMLazyScrollViewTransition) transition animated:(BOOL) animated;
- (void) moveByPages:(NSInteger) offset animated:(BOOL) animated;

- (UIViewController *) visibleViewController;

@end
