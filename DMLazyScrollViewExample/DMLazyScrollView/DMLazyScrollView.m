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
@property (nonatomic, strong) NSTimer* timer_autoPlay;
@end

@implementation DMLazyScrollView

@synthesize numberOfPages,currentPage;
@synthesize dataSource,controlDelegate;
@synthesize autoPlay = _autoPlay;
@synthesize timer_autoPlay = _timer_autoPlay;
@synthesize autoPlayTime = _autoPlayTime;

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
        circularScrollEnabled = circularScrolling;
        _autoPlayTime = 3;
        [self initializeControl];
    }
    return self;
}

- (void)setAutoPlay:(BOOL)autoPlay
{
    _autoPlay = autoPlay;
    if(self.numberOfPages)
    {
        [self reloadData];
    }
}

- (BOOL)hasMultiplePages {
    return numberOfPages > 1;
}

- (void)resetAutoPlay
{
    if(_autoPlay)
    {
        if(_timer_autoPlay)
        {
            [_timer_autoPlay invalidate];
            _timer_autoPlay = nil;
        }
        _timer_autoPlay = [NSTimer scheduledTimerWithTimeInterval:_autoPlayTime target:self selector:@selector(autoPlayHanlde:) userInfo:nil repeats:YES];
    }
    else
    {
        if(_timer_autoPlay)
        {
            [_timer_autoPlay invalidate];
            _timer_autoPlay = nil;
        }
    }
}

- (void)autoPlayHanlde:(id)timer
{
    if ([self hasMultiplePages]) {
        [self autoPlayGoToNextPage];
    }
}

- (void)autoPlayGoToNextPage
{
    NSInteger nextPage = self.currentPage+1;
    if(nextPage >= self.numberOfPages)
    {
        nextPage = 0;
    }
    [self setPage:nextPage animated:YES];
}

- (void)autoPlayPause
{
    if(_timer_autoPlay)
    {
        [_timer_autoPlay invalidate];
        _timer_autoPlay = nil;
    }
}

- (void)autoPlayResume
{
    [self resetAutoPlay];
}

- (void)setEnableCircularScroll:(BOOL)circularScrolling
{
    circularScrollEnabled = circularScrolling;
}

- (BOOL)circularScrollEnabled
{
    return circularScrollEnabled;
}

- (void) awakeFromNib {
    [self initializeControl];
}

- (void) initializeControl {
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.pagingEnabled = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.delegate = self;
    self.contentSize = CGSizeMake(self.frame.size.width, self.contentSize.height);
    currentPage = NSNotFound;
}

- (void) setNumberOfPages:(NSUInteger)pages {
    if (pages != numberOfPages) {
        numberOfPages = pages;
        int offset = [self hasMultiplePages] ? numberOfPages + 2 : 1;
        if (_direction == DMLazyScrollViewDirectionHorizontal) {
            self.contentSize = CGSizeMake(self.frame.size.width * offset,
                                          self.contentSize.height);
        } else {
            self.contentSize = CGSizeMake(self.frame.size.width,
                                          self.frame.size.height * offset);
        }
        [self reloadData];
    }
}

- (void) reloadData {
    [self setCurrentViewController:0];
    [self resetAutoPlay];
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
    [self autoPlayResume];
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self autoPlayPause];
    if (nil != controlDelegate && [controlDelegate respondsToSelector:@selector(lazyScrollViewWillBeginDragging:)])
        [controlDelegate lazyScrollViewWillBeginDragging:self];
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    if (isManualAnimating) {
        if (nil != controlDelegate && [controlDelegate respondsToSelector:@selector(lazyScrollViewDidScroll:at:withSelfDrivenAnimation:)]) {
            [controlDelegate lazyScrollViewDidScroll:self at:[self visibleRect].origin withSelfDrivenAnimation:YES];
        }
        return;
    }
    
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
    if (nil != controlDelegate && [controlDelegate respondsToSelector:@selector(lazyScrollViewDidScroll:at:withSelfDrivenAnimation:)]) {
        [controlDelegate lazyScrollViewDidScroll:self at:[self visibleRect].origin withSelfDrivenAnimation:NO];
    }
    else if (nil != controlDelegate && [controlDelegate respondsToSelector:@selector(lazyScrollViewDidScroll:at:)]) {
        [controlDelegate lazyScrollViewDidScroll:self at:[self visibleRect].origin];
    }
}

- (void) setCurrentViewController:(NSInteger) index {
    if (index == currentPage) return;
    currentPage = index;
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSInteger prevPage = [self pageIndexByAdding:-1 from:currentPage];
    NSInteger nextPage = [self pageIndexByAdding:+1 from:currentPage];
    
    [self loadControllerAtIndex:index andPlaceAtIndex:0];
    // Pre-load the content for the adjacent pages if multiple pages are to be displayed
    if ([self hasMultiplePages]) {
        [self loadControllerAtIndex:prevPage andPlaceAtIndex:-1];   // load previous page
        [self loadControllerAtIndex:nextPage andPlaceAtIndex:1];   // load next page
    }

    CGFloat size =(_direction==DMLazyScrollViewDirectionHorizontal) ? self.frame.size.width : self.frame.size.height;
    
    self.contentOffset = [self createPoint:size * ([self hasMultiplePages] ? 2 : 0)]; // recenter
    
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
        //BOOL isOnePageMove = (abs(self.currentPage-newIndex) == 1);
        CGPoint finalOffset;
        
        if (transition == DMLazyScrollViewTransitionAuto) {
            if (newIndex > self.currentPage) transition = DMLazyScrollViewTransitionForward;
            else if (newIndex < self.currentPage) transition = DMLazyScrollViewTransitionBackward;
        }
        
        CGFloat size =(_direction==DMLazyScrollViewDirectionHorizontal) ? self.frame.size.width : self.frame.size.height;
        
        if (transition == DMLazyScrollViewTransitionForward) {
            //if (!isOnePageMove)
                //[self loadControllerAtIndex:newIndex andPlaceAtIndex:2];
            [self loadControllerAtIndex:newIndex andPlaceAtIndex:1];
            
            //finalOffset = [self createPoint:(size*(isOnePageMove ? 3 : 4))];
            finalOffset = [self createPoint:(size*3)];
        } else {
            //if (!isOnePageMove)
                //[self loadControllerAtIndex:newIndex andPlaceAtIndex:-2];
            [self loadControllerAtIndex:newIndex andPlaceAtIndex:-1];
            
            //finalOffset = [self createPoint:(size*(isOnePageMove ? 1 : 0))];
            finalOffset = [self createPoint:(size*1)];
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
    
    CGRect viewFrame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    int offset = [self hasMultiplePages] ? 2 : 0;
    if (_direction == DMLazyScrollViewDirectionHorizontal) {
        viewFrame = CGRectOffset(viewFrame, self.frame.size.width * (destIndex + offset), 0);
    } else {
        viewFrame = CGRectOffset(viewFrame, 0, self.frame.size.height * (destIndex + offset));
    }
    viewController.view.frame = viewFrame;
    
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
