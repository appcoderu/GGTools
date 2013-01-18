//
//  GGLazyImageView.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 26.06.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGLazyImageView.h"

#import <GGTools/GGTools.h>
#import <QuartzCore/QuartzCore.h>

@implementation GGLazyImageView {
	GGHTTPServiceTicket *_ticket;
	NSURL *_url;
	
	UIActivityIndicatorView *_activityIndicator;
}

- (void)dealloc {
	[self cancelLoadingImage];
}

- (void)setTouchUpInsideBlock:(void (^)())touchUpInsideBlock {
	_touchUpInsideBlock = [touchUpInsideBlock copy];
	
	if (_touchUpInsideBlock) {
		self.userInteractionEnabled = YES;
		self.multipleTouchEnabled = YES;
	}
}

- (void)_setImage:(UIImage *)image {
	[self willChangeValueForKey:@"image"];
	if (self.imagePreprocessingBlock) {
		image = self.imagePreprocessingBlock(image);
	}
	[super setImage:image];
	[self didChangeValueForKey:@"image"];
}

- (void)setImage:(UIImage *)image {
	[self cancelLoadingImage];
	[self _setImage:image];
}


- (void)setImageWithURL:(NSURL *)url {
	[self setImageWithURL:url placeholderImage:nil showActivityIndicator:NO];
}

- (void)setImageWithURL:(NSURL *)url showActivityIndicator:(BOOL)showActivityIndicator {
	[self setImageWithURL:url placeholderImage:nil showActivityIndicator:showActivityIndicator];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage {
	[self setImageWithURL:url placeholderImage:placeholderImage showActivityIndicator:NO];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage showActivityIndicator:(BOOL)showActivityIndicator {
		
	if (!url) {
		return;
	}
		
	if (_url && [_url isEqual:url]) {
		return;
	}
		
	[self cancelLoadingImage];
	
	_url = url;
	
	if ( [_url isFileURL] ) {
		NSData *imageData = [NSData dataWithContentsOfURL:_url];
		[self _setImage:[UIImage imageWithData:imageData]];
		[self setActivityIndicatorHidden:YES];
		return;
	}
	
	__weak GGLazyImageView *weakSelf = self;
	
	id completionHandler = ^(GGHTTPServiceTicket *ticket, GGHTTPQueryResult *result) {
		GGLazyImageView *localSelf = weakSelf;
		if (!localSelf) {
			return;
		}
				
		if (localSelf->_ticket && (ticket != localSelf->_ticket) ) {
			return;
		}
		
		if (result.error) {
			localSelf->_url = nil;
		}
		
		localSelf->_ticket = nil;
		
		if (!result.error && result.data) {
			[localSelf _setImage:result.data];
		}
		
		[localSelf setActivityIndicatorHidden:YES];
	};
	
	GGHTTPQuery *query = [GGHTTPQuery queryWithURL:url];
	query.expectedResultClass = [UIImage class];
	
	_ticket = [[GGHTTPService sharedService] executeQuery:query
										completionHandler:completionHandler];
	
	if (_ticket) {
		if (_ticket.used) {
			_ticket = nil;
		} else if (placeholderImage) {
			[self _setImage:placeholderImage];
		} else if (showActivityIndicator) {
			[self setActivityIndicatorHidden:NO];
		}
	} else {
		_url = nil;
	}
}

- (void)cancelLoadingImage {
	if (_ticket) {
		[[GGHTTPService sharedService] cancelQueryWithTicket:_ticket];
		_ticket = nil;
	}
	_url = nil;
	
	[self setActivityIndicatorHidden:YES];
}

- (void)setActivityIndicatorHidden:(BOOL)hidden {
	if (hidden && !_activityIndicator) {
		return;
	}
	
	if (!_activityIndicator) {
		_activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		[self addSubview:_activityIndicator];
		[self layoutSubviews];
	}
	
	_activityIndicator.hidden = hidden;
	if (hidden) {
		[_activityIndicator stopAnimating];
	} else {
		[_activityIndicator startAnimating];
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if (!_activityIndicator) {
		return;
	}
	
	CGRect f = _activityIndicator.frame;
	f.origin.x = floorf((self.frame.size.width - f.size.width) / 2.0f);
	f.origin.y = floorf((self.frame.size.height - f.size.height) / 2.0f);
	_activityIndicator.frame = f;
}

#pragma mark -

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	if (touch.tapCount == 1) {
		if (self.touchUpInsideBlock) {
			self.touchUpInsideBlock();
		}
	}
	
	[super touchesEnded:touches withEvent:event];
}

@end
