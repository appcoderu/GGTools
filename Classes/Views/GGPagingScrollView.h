//
//  GGPagingScrollView.h
//	GGFramework
//
//  Created by Evgeniy Shurakov on 10/5/12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GGPagingScrollViewDelegate;
@protocol GGPagingScrollViewDataSource;

@interface GGPagingScrollView : UIScrollView

@property(nonatomic, weak) IBOutlet NSObject <GGPagingScrollViewDelegate> *pagingDelegate;
@property(nonatomic, weak) IBOutlet NSObject <GGPagingScrollViewDataSource> *pagingDataSource;

@property(nonatomic, assign) BOOL keepAspectRatio;
@property(nonatomic, assign) UIEdgeInsets pageInsets;

@property(nonatomic, assign, readonly) NSUInteger currentPageIndex;

- (void)reloadData;

@end

@protocol GGPagingScrollViewDelegate <NSObject>
- (void)pagingScrollViewDidChangePage:(GGPagingScrollView *)scrollView;
@end

@protocol GGPagingScrollViewDataSource <NSObject>
@required
- (NSUInteger)pagesCountForPagingScrollView:(GGPagingScrollView *)scrollView;
- (UIView *)pagingScrollView:(GGPagingScrollView *)scrollView
				 pageAtIndex:(NSUInteger)index
				 reusingPage:(UIView *)page;
@end