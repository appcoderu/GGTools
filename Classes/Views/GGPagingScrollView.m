//
//  GGPagingScrollView.m
//	GGFramework
//
//  Created by Evgeniy Shurakov on 10/5/12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGPagingScrollView.h"

#import <QuartzCore/QuartzCore.h>

@interface GGPagingScrollView () <UIScrollViewDelegate>

@end

@implementation GGPagingScrollView {
	NSUInteger _totalPages;
	
	NSMutableSet *_visiblePages;
	NSMutableSet *_recycledPages;
}

- (void)_initialize {
	_visiblePages = [[NSMutableSet alloc] init];
	_recycledPages = [[NSMutableSet alloc] init];
	
	_pageInsets = UIEdgeInsetsZero;
	
	self.pagingEnabled = YES;
	self.showsHorizontalScrollIndicator = NO;
	self.showsVerticalScrollIndicator = NO;
		
	[super setDelegate:self];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self _initialize];
	}
	return self;
}

- (void)setDelegate:(id<UIScrollViewDelegate>)delegate {
	[super setDelegate:self];
}

- (void)setFrame:(CGRect)frame {
	CGRect oldFrame = self.frame;
	[super setFrame:frame];
	if (!CGSizeEqualToSize(oldFrame.size, self.frame.size)) {
		[self setupViews];
	}
}

#pragma mark -

- (void)reloadData {
	_totalPages = [self.pagingDataSource pagesCountForPagingScrollView:self];
	
	for (UIView *page in _visiblePages) {
        [_recycledPages addObject:page];
		[page removeFromSuperview];
    }
	[_visiblePages removeAllObjects];
	
	[self setupViews];

	[self tilePages];
}

- (void)setupViews {
	DJLOG;
	self.contentSize = CGSizeMake(self.frame.size.width * _totalPages, self.frame.size.height);
	self.contentOffset = CGPointMake(self.frame.size.width * [self currentPageIndex], 0.0f);
	
	for (UIView *page in _visiblePages) {
		[self configurePage:page forIndex:page.tag];
    }
}

#pragma mark -

- (NSUInteger)currentPageIndex {
	return MIN(_totalPages, (NSUInteger)roundf(self.contentOffset.x / self.frame.size.width));
}

- (void)tilePages  {
    CGRect visibleBounds = self.bounds;
	
    int firstNeededPageIndex = floorf(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds));
    int lastNeededPageIndex  = floorf((CGRectGetMaxX(visibleBounds)-1) / CGRectGetWidth(visibleBounds));
	
    firstNeededPageIndex = MAX(firstNeededPageIndex, 0);
    lastNeededPageIndex  = MIN(lastNeededPageIndex, _totalPages - 1);
	
    for (UIView *page in _visiblePages) {
        if (page.tag < firstNeededPageIndex || page.tag > lastNeededPageIndex) {
			//GGLog(@"recycle: %d", page.tag);
            [_recycledPages addObject:page];
            [page removeFromSuperview];
        }
    }
    [_visiblePages minusSet:_recycledPages];
    
	if (_totalPages == 0) {
		return;
	}
	
    for (int index = firstNeededPageIndex; index <= lastNeededPageIndex; index++) {
        if ([self isDisplayingPageForIndex:index]) {
			continue;
		}
		
		UIView *recycledPage = [self dequeueRecycledPage];
		UIView *page = [self.pagingDataSource pagingScrollView:self
												   pageAtIndex:index
												   reusingPage:recycledPage];
		
		NSAssert(page, @"Page shouldn't be nil");
		
		[self addSubview:page];
		[self bringSubviewToFront:page];
		
		[self configurePage:page forIndex:index];
		[_visiblePages addObject:page];
    }
}

- (UIView *)dequeueRecycledPage {
    UIView *page = [_recycledPages anyObject];
    if (page) {
        [_recycledPages removeObject:page];
    }
    return page;
}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index {
    for (UIView *page in _visiblePages) {
        if (page.tag == index) {
            return YES;
        }
    }
	return NO;
}

- (void)configurePage:(UIView *)page forIndex:(NSUInteger)index {
    page.tag = index;
	
    CGRect frame = [self frameForPageAtIndex:index];
	if (self.keepAspectRatio &&
		page.frame.size.width > 0.01f && page.frame.size.height > 0.01f &&
		frame.size.width > 0.01f && frame.size.height > 0.01f) {
		CGFloat xratio = page.frame.size.width / frame.size.width;
		CGFloat yratio = page.frame.size.height / frame.size.height;
		CGFloat ratio = (xratio > yratio) ? xratio : yratio;
		
		CGFloat width = floorf(page.frame.size.width / ratio);
		CGFloat height = floorf(page.frame.size.height / ratio);
		
		frame.origin.x += floorf((frame.size.width - width) / 2.0f);
		frame.origin.y += floorf((frame.size.height - height) / 2.0f);
		frame.size.width = width;
		frame.size.height = height;
	}
	page.frame = frame;
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    CGRect pagingScrollViewFrame = self.frame;
    
    CGRect pageFrame = pagingScrollViewFrame;
    pageFrame.origin.x = pagingScrollViewFrame.size.width * index + self.pageInsets.left;
	pageFrame.size.width = pageFrame.size.width - self.pageInsets.left - self.pageInsets.right;
	
	pageFrame.origin.y = self.pageInsets.top;
	pageFrame.size.height = pageFrame.size.height - self.pageInsets.top - self.pageInsets.bottom;
	
    return pageFrame;
}

- (void)notifyAboutChangedPage {
	[self.pagingDelegate pagingScrollViewDidChangePage:self];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self tilePages];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if ( !decelerate ) {
		[self notifyAboutChangedPage];
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	[self notifyAboutChangedPage];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
	[self notifyAboutChangedPage];
}

@end
