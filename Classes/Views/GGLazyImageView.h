//
//  GGLazyImageView.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 26.06.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GGLazyImageView : UIImageView

- (void)setImageWithURL:(NSURL *)url;
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage;
- (void)setImageWithURL:(NSURL *)url showActivityIndicator:(BOOL)showActivityIndicator;

- (void)cancelLoadingImage;

@property(nonatomic, copy) UIImage * (^imagePreprocessingBlock)(UIImage *image);

@property(nonatomic, copy) void (^touchUpInsideBlock)();

@end
