//
//  DMLazyScrollView.m
//  Lazy Loading UIScrollView for iOS
//
//  Created by Daniele Margutti (me@danielemargutti.com) on 24/11/12.
//  Copyright (c) 2012 http://www.danielemargutti.com. All rights reserved.
//  Distribuited under MIT License
//

#import "DMLazyScrollView.h"

enum {
    DMLazyScrollViewScrollDirectionBackward     = 0,
    DMLazyScrollViewScrollDirectionForward      = 1
}; typedef NSUInteger DMLazyScrollViewScrollDirection;

#define kDMLazyScrollViewTransitionDuration     0.4

@interface DMLazyScrollView() <UIScrollViewDelegate> {
    NSUInteger      numberOfPages;
    NSUInteger      currentPage;
    BOOL            isManualAnimating;
    BOOL            circularScrollEnabled;
}

@end

@implementation DMLazyScrollView

@synthesize numberOfPages,currentPage;
@synthesize dataSource,controlDelegate;

- (id)init {
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrameAndDirection:frame direction:DMLazyScrollViewDirectionHorizontal circularScroll:NO];
}

- (id)initWithFrameAndDirection:(CGRect)frame
                      direction:(DMLazyScrollViewDirection)direction
                 circularScroll:(BOOL) circularScrolling {
    
    self = [super initWithFrame:frame];
    if (self) {
        _direction = direction;
        [self initializeControl];
    }
    return self;
}

- (void) awakeFromNib {
    [self initializeControl];
}

- (void) initializeControl {
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.pagingEnabled = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    if (_direction == DMLazyScrollViewDirectionHorizontal) {
        self.contentSize = CGSizeMake(self.frame.size.width*5.0f, self.contentSize.height);
    } else {
        self.contentSize = CGSizeMake(self.frame.size.width, self.contentSize.height*5.0f);
        
    }
    self.delegate = self;
    
    currentPage = NSNotFound;
}

- (void) setNumberOfPages:(NSUInteger)pages {
    if (pages != numberOfPages) {
        numberOfPages = pages;
        [self reloadData];
    }
}

- (void) reloadData {
    [self setCurrentViewController:0];
}

- (void) layoutSubviews {
    [super layoutSubviews];
}

- (CGRect) visibleRect {
    CGRect visibleRect;
    visibleRect.origin = self.contentOffset;
    visibleRect.size = self.bounds.size;
    return visibleRect;
}

- (CGPoint) createPoint:(CGFloat) size {
    if (_direction == DMLazyScrollViewDirectionHorizontal) {
        return CGPointMake(size, 0);
    } else {
        return CGPointMake(0, size);
    }
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    self.bounces = YES;
    if (nil != controlDelegate && [controlDelegate respondsToSelector:@selector(lazyScrollViewDidEndDragging:)])
        [controlDelegate lazyScrollViewDidEndDragging:self];
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (nil != controlDelegate && [controlDelegate respondsToSelector:@selector(lazyScrollViewWillBeginDragging:)])
        [controlDelegate lazyScrollViewWillBeginDragging:self];
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    if (isManualAnimating) return;
    
    CGFloat offset = (_direction==DMLazyScrollViewDirectionHorizontal) ? scrollView.contentOffset.x : scrollView.contentOffset.y;
    CGFloat size =(_direction==DMLazyScrollViewDirectionHorizontal) ? self.frame.size.width : self.frame.size.height;
    
    
    // with two pages only scrollview you can only go forward
    // (this prevents us to have a glitch with the next UIView (it can't be placed in two positions at the same time)
    DMLazyScrollViewScrollDirection proposedScroll = (offset <= (size*2) ?
                                                      DMLazyScrollViewScrollDirectionBackward : // we're moving back
                                                      DMLazyScrollViewScrollDirectionForward); // we're moving forward

    // you can go back if circular mode is enabled or your current page is not the first page
    BOOL canScrollBackward = (circularScrollEnabled || (!circularScrollEnabled && self.currentPage != 0));
    // you can go forward if circular mode is enabled and current page is not the last page
    BOOL canScrollForward = (circularScrollEnabled || (!circularScrollEnabled && self.currentPage < (self.numberOfPages-1)));
    
    NSInteger prevPage = [self pageIndexByAdding:-1 from:self.currentPage];
    NSInteger nextPage = [self pageIndexByAdding:+1 from:self.currentPage];
    if (prevPage == nextPage) {
        // This happends when our scrollview have only two and we should have the same prev/next page at left/right
        // A single UIView instance can't be in two different location at the same moment so we need to place it
        // loooking at proposed direction
        [self loadControllerAtIndex:prevPage andPlaceAtIndex:(proposedScroll == DMLazyScrollViewScrollDirectionBackward ? -1 : 1)];
    }

    if ( (proposedScroll == DMLazyScrollViewScrollDirectionBackward && !canScrollBackward) ||
         (proposedScroll == DMLazyScrollViewScrollDirectionForward && !canScrollForward)) {
        self.bounces = NO;
        [scrollView setContentOffset:[self createPoint:size*2] animated:NO];
        return;
    } else self.bounces = YES;

    NSInteger newPageIndex = currentPage;
    
    if (offset <= size)
        newPageIndex = [self pageIndexByAdding:-1 from:currentPage];
    else if (offset >= (size*3))
        newPageIndex = [self pageIndexByAdding:+1 from:currentPage];
    
    [self setCurrentViewController:newPageIndex];
    
    // alert delegate
    if (nil != controlDelegate && [controlDelegate respondsToSelector:@selector(lazyScrollViewDidScroll:at:)])
        [controlDelegate lazyScrollViewDidScroll:self at:[self visibleRect].origin];
}

- (void) setCurrentViewController:(NSInteger) index {
    if (index == currentPage) return;
    currentPage = index;
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSInteger prevPage = [self pageIndexByAdding:-1 from:currentPage];
    NSInteger nextPage = [self pageIndexByAdding:+1 from:currentPage];
        
    [self loadControllerAtIndex:prevPage andPlaceAtIndex:-1];   // load previous page
    [self loadControllerAtIndex:index andPlaceAtIndex:0];       // load current page
    [self loadControllerAtIndex:nextPage andPlaceAtIndex:1];   // load next page
    
    CGFloat size =(_direction==DMLazyScrollViewDirectionHorizontal) ? self.frame.size.width : self.frame.size.height;
    
    self.contentOffset = [self createPoint:size*2.]; // recenter
    
    if ([self.controlDelegate respondsToSelector:@selector(lazyScrollView:currentPageChanged:)])
        [self.controlDelegate lazyScrollView:self currentPageChanged:self.currentPage];
}

- (UIViewController *) visibleViewController {
    __block UIView *visibleView = nil;
    [self.subviews enumerateObjectsUsingBlock:^(UIView *subView, NSUInteger idx, BOOL *stop) {
        if (CGRectIntersectsRect([self visibleRect], subView.frame)) {
            visibleView = subView;
            *stop = YES;
        }
    }];
    if (visibleView == nil) return nil;
    return [self viewControllerFromView:visibleView];
}

- (UIViewController *) viewControllerFromView:(UIView*) targetView {
    return (UIViewController *)[self traverseResponderChainForUIViewController:targetView];
}

- (id) traverseResponderChainForUIViewController:(UIView *) targetView {
    id nextResponder = [targetView nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]]) {
        return nextResponder;
    } else if ([nextResponder isKindOfClass:[UIView class]]) {
        return [nextResponder traverseResponderChainForUIViewController:targetView];
    } else {
        return nil;
    }
}

- (NSInteger) pageIndexByAdding:(NSInteger) offset from:(NSInteger) index {
    // Complicated stuff with negative modulo
    while (offset<0) offset += numberOfPages;
    return (numberOfPages+index+offset) % numberOfPages;

}

- (void) moveByPages:(NSInteger) offset animated:(BOOL) animated {
    NSUInteger finalIndex = [self pageIndexByAdding:offset from:self.currentPage];
    DMLazyScrollViewTransition transition = (offset >= 0 ?  DMLazyScrollViewTransitionForward :
                                             DMLazyScrollViewTransitionBackward);
    [self setPage:finalIndex transition:transition animated:animated];
}

- (void) setPage:(NSInteger) newIndex animated:(BOOL) animated {
    [self setPage:newIndex transition:DMLazyScrollViewTransitionForward animated:animated];
}

- (void) setPage:(NSInteger) newIndex transition:(DMLazyScrollViewTransition) transition animated:(BOOL) animated {
    if (newIndex == currentPage) return;
    
    if (animated) {
        BOOL isOnePageMove = (abs(self.currentPage-newIndex) == 1);
        CGPoint finalOffset;
        
        if (transition == DMLazyScrollViewTransitionAuto) {
            if (newIndex > self.currentPage) transition = DMLazyScrollViewTransitionForward;
            else if (newIndex < self.currentPage) transition = DMLazyScrollViewTransitionBackward;
        }
        
        CGFloat size =(_direction==DMLazyScrollViewDirectionHorizontal) ? self.frame.size.width : self.frame.size.height;
        
        if (transition == DMLazyScrollViewTransitionForward) {
            if (!isOnePageMove)
                [self loadControllerAtIndex:newIndex andPlaceAtIndex:2];
            
            
            finalOffset = [self createPoint:(size*(isOnePageMove ? 3 : 4))];
        } else {
            if (!isOnePageMove)
                [self loadControllerAtIndex:newIndex andPlaceAtIndex:-2];
            
            finalOffset = [self createPoint:(size*(isOnePageMove ? 1 : 0))];
        }
        isManualAnimating = YES;
        
        [UIView animateWithDuration:kDMLazyScrollViewTransitionDuration
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.contentOffset = finalOffset;
                         } completion:^(BOOL finished) {
                             if (!finished) return;
                             [self setCurrentViewController:newIndex];
                             isManualAnimating = NO;
                         }];
    } else {
        [self setCurrentViewController:newIndex];
    }
}

- (void) setCurrentPage:(NSUInteger)newCurrentPage {
    [self setCurrentViewController:newCurrentPage];
}

- (UIViewController *) loadControllerAtIndex:(NSInteger) index andPlaceAtIndex:(NSInteger) destIndex {
    UIViewController *viewController = dataSource(index);
    viewController.view.tag = 0;
    
    if (_direction == DMLazyScrollViewDirectionHorizontal) {
        viewController.view.frame = CGRectMake(self.frame.size.width*(destIndex+2),
                                               0,
                                               self.frame.size.width,
                                               self.frame.size.height);
    } else {
        viewController.view.frame = CGRectMake(0,
                                               self.frame.size.height*(destIndex+2),
                                               self.frame.size.width,
                                               self.frame.size.height);
        
    }
    [self addSubview:viewController.view];
    return viewController;
}


- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if (nil != controlDelegate && [controlDelegate respondsToSelector:@selector(lazyScrollViewWillBeginDecelerating:)])
        [controlDelegate lazyScrollViewWillBeginDecelerating:self];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (nil != controlDelegate && [controlDelegate respondsToSelector:@selector(lazyScrollViewDidEndDecelerating:atPageIndex:)])
        [controlDelegate lazyScrollViewDidEndDecelerating:self atPageIndex:self.currentPage];
}


@end
