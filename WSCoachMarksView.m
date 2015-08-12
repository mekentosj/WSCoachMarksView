//
//  WSCoachMarksView.m
//  Version 0.2
//
//  Created by Dimitry Bentsionov on 4/1/13.
//  Copyright (c) 2013 Workshirt, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "WSCoachMarksView.h"

static const CGFloat kAnimationDuration = 0.3f;
static const CGFloat kCutoutRadius = 2.0f;
static const CGFloat kMaxLblWidth = 300.0f;
static const CGFloat kLblSpacing = 35.0f;
static const CGFloat kButtonHeight = 60.0f;
static const CGFloat kButtonPadding = 10.0f;
static const CGFloat kShadowLayerOffset = 3.0f;

@implementation WSCoachMarksView {
    CAShapeLayer *mask;
    UIButton *btnBack;
    UILabel *lblContinue;
    UIButton *btnSkipCoach;
}

#pragma mark - Properties

@synthesize delegate;
@synthesize coachMarks;
@synthesize lblCaption;
@synthesize maskColor = _maskColor;
@synthesize animationDuration;
@synthesize cutoutRadius;
@synthesize maxLblWidth;
@synthesize lblSpacing;

#pragma mark - Methods

- (id)initWithFrame:(CGRect)frame coachMarks:(NSArray *)marks {
    self = [super initWithFrame:frame];
    if (self) {
        // Save the coach marks
        self.coachMarks = marks;
        
        // Setup
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Setup
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Setup
        [self setup];
    }
    return self;
}

- (void)setup {
    // Default
    self.animationDuration = kAnimationDuration;
    self.cutoutRadius = kCutoutRadius;
    self.maxLblWidth = kMaxLblWidth;
    self.lblSpacing = kLblSpacing;
    
    // Shape layer mask
    mask = [CAShapeLayer layer];
    [mask setFillRule:kCAFillRuleEvenOdd];
    [mask setFillColor:[[UIColor colorWithHue:0.0f saturation:0.0f brightness:0.0f alpha:0.9f] CGColor]];
    [self.layer addSublayer:mask];
    
    // Overdraw the layer so an overlap = kShadowLayer offset exists around all four edges of the layer
    // (This allows the underlying shadow to extend to the edges of the transluscent coach marks view)
    CGRect layerBounds = self.layer.bounds;
    layerBounds.origin = CGPointMake(-kShadowLayerOffset, -kShadowLayerOffset);
    CGSize layerSize = layerBounds.size;
    layerSize.height += (2 * kShadowLayerOffset);
    layerSize.width += (2 * kShadowLayerOffset);
    layerBounds.size = layerSize;
    self.layer.bounds = layerBounds;
    self.layer.masksToBounds = NO;
    self.layer.shadowColor = _maskColor.CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    self.layer.shadowOpacity = 1.0;
    self.layer.shadowRadius = kShadowLayerOffset;
    
    // Capture touches
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userDidTap:)];
    [self addGestureRecognizer:tapGestureRecognizer];
    
    // Captions
    self.lblCaption = [[UILabel alloc] initWithFrame:(CGRect){{0.0f, 0.0f}, {self.maxLblWidth, 0.0f}}];
    self.lblCaption.backgroundColor = [UIColor clearColor];
    self.lblCaption.textColor = [UIColor whiteColor];
    self.lblCaption.font = [UIFont systemFontOfSize:20.0f];
    self.lblCaption.lineBreakMode = NSLineBreakByWordWrapping;
    self.lblCaption.numberOfLines = 0;
    self.lblCaption.textAlignment = NSTextAlignmentCenter;
    self.lblCaption.alpha = 0.0f;
    [self addSubview:self.lblCaption];
    
    // Hide until unvoked
    self.hidden = YES;
}

#pragma mark - Cutout modify

- (void)setCutoutToRect:(CGRect)rect withShape:(NSString *)shape{
    // Define shape
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRect:self.bounds];
    UIBezierPath *cutoutPath;
    
    if ([shape isEqualToString:@"circle"])
        cutoutPath = [UIBezierPath bezierPathWithOvalInRect:rect];
    else if ([shape isEqualToString:@"square"])
        cutoutPath = [UIBezierPath bezierPathWithRect:rect];
    else
        cutoutPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:self.cutoutRadius];
    
    
    [maskPath appendPath:cutoutPath];
    
    // Set the new path
    mask.path = maskPath.CGPath;
}

- (void)animateCutoutToRect:(CGRect)rect withShape:(NSString *)shape{
    // Define shape
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRect:self.bounds];
    UIBezierPath *cutoutPath;

    if ([shape isEqualToString:@"circle"])
        cutoutPath = [UIBezierPath bezierPathWithOvalInRect:rect];
    else if ([shape isEqualToString:@"square"])
        cutoutPath = [UIBezierPath bezierPathWithRect:rect];
    else
        cutoutPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:self.cutoutRadius];
    
    
    [maskPath appendPath:cutoutPath];
    
    // Animate it
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"path"];
    anim.delegate = self;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    anim.duration = self.animationDuration;
    anim.removedOnCompletion = NO;
    anim.fillMode = kCAFillModeForwards;
    anim.fromValue = (__bridge id)(mask.path);
    anim.toValue = (__bridge id)(maskPath.CGPath);
    [mask addAnimation:anim forKey:@"path"];
    mask.path = maskPath.CGPath;
}

#pragma mark - Mask color

- (void)setMaskColor:(UIColor *)maskColor {
    _maskColor = maskColor;
    [mask setFillColor:[maskColor CGColor]];
}

#pragma mark - Touch handler

- (void)userDidTap:(UITapGestureRecognizer *)recognizer {
    // Go to the next coach mark
    [self goToCoachMarkIndexed:(self.markIndex+1)];
}

#pragma mark - Navigation

- (void)start {
    [self startAtCoachMark:0];
}

- (void)startAtCoachMark:(NSUInteger)coachMarkIndex {
    // Fade in self
    self.alpha = 0.0f;
    self.hidden = NO;
    [UIView animateWithDuration:self.animationDuration
                     animations:^{
                         self.alpha = 1.0f;
                     }
                     completion:^(BOOL finished) {
                         // Go to the first coach mark
                         [self goToCoachMarkIndexed:coachMarkIndex];
                     }];
}

- (void)goToPreviousCoachMark {
    // Go to the previous coach mark
    if (self.markIndex > 0) {
        [self goToCoachMarkIndexed:(self.markIndex-1)];
    }
}

- (void)skipCoach {
    [self goToCoachMarkIndexed:self.coachMarks.count];
}

- (void)goToCoachMarkIndexed:(NSUInteger)index {
    // Out of bounds
    if (index >= self.coachMarks.count) {
        [self cleanup];
        return;
    }
    
    // Current index
    self.markIndex = index;
    
    // Coach mark definition
    NSDictionary *markDef = [self.coachMarks objectAtIndex:index];
    NSString *markCaption = [markDef objectForKey:@"caption"];
    
    NSString *shape = @"other";
    if([[markDef allKeys] containsObject:@"shape"])
        shape = [markDef objectForKey:@"shape"];
    
    UIEdgeInsets markInsets = UIEdgeInsetsZero;
    if ([[markDef allKeys] containsObject:@"insets"])
        markInsets = [[markDef objectForKey:@"insets"] UIEdgeInsetsValue];
    
    // Type-check the object found for the "views" key
    NSArray *markViewsArray = nil;
    id viewOrArray = [markDef objectForKey:@"views"];
    if ([viewOrArray isKindOfClass:[UIView class]])
    {
        markViewsArray = @[viewOrArray];
    }
    else if ([viewOrArray isKindOfClass:[NSArray class]])
    {
        markViewsArray = viewOrArray;
    }
    else
    {
        // Un-expected format or nil object
        NSAssert(NO, @"Unexpected class for object for key 'views', or no object set. Please pass in one or more UIViews for the 'views' key instead.");
    }
    
    // Construct the CGRect for the current coach mark from one or more UIViews.
    // (The resulting CGRect is a CGRectUnion of all those views' bounds).
    CGRect markRect = CGRectNull;
    for (UIView *view in markViewsArray)
    {
        CGRect currentRect = UIEdgeInsetsInsetRect([view convertRect:view.bounds toView:self.superview], markInsets);
        
        if (CGRectEqualToRect(markRect, CGRectNull))
        {
            // First time around the loop
            markRect = currentRect;
        }
        else
        {
            markRect = CGRectUnion(currentRect, markRect);
        }
    }
    
    // Delegate (coachMarksView:willNavigateTo:atIndex:)
    if ([self.delegate respondsToSelector:@selector(coachMarksView:willNavigateToIndex:)]) {
        [self.delegate coachMarksView:self willNavigateToIndex:self.markIndex];
    }
    
    // Calculate the caption position and size
    self.lblCaption.alpha = 0.0f;
    self.lblCaption.frame = (CGRect){{0.0f, 0.0f}, {self.maxLblWidth, 0.0f}};
    self.lblCaption.text = markCaption;
    [self.lblCaption sizeToFit];
    CGFloat y = markRect.origin.y + markRect.size.height + self.lblSpacing;
    CGFloat bottomY = y + self.lblCaption.frame.size.height + self.lblSpacing;
    if (bottomY > self.bounds.size.height) {
        y = markRect.origin.y - self.lblSpacing - self.lblCaption.frame.size.height;
    }
    CGFloat x = floorf((self.bounds.size.width - (2 * kShadowLayerOffset) - self.lblCaption.frame.size.width) / 2.0f);
    
    // Animate the caption label
    self.lblCaption.frame = (CGRect){{x, y}, self.lblCaption.frame.size};
    
    [UIView animateWithDuration:0.3f animations:^{
        self.lblCaption.alpha = 1.0f;
    }];
    
    // If first mark, set the cutout to the center of first mark
    if (self.markIndex == 0) {
        CGPoint center = CGPointMake(floorf(markRect.origin.x + (markRect.size.width / 2.0f)), floorf(markRect.origin.y + (markRect.size.height / 2.0f)));
        CGRect centerZero = (CGRect){center, CGSizeZero};
        [self setCutoutToRect:centerZero withShape:shape];
    }
    
    // Animate the cutout
    [self animateCutoutToRect:markRect withShape:shape];
    
    CGFloat backButtonWidth = (16.0f/100.0f) * self.bounds.size.width - (2 * kShadowLayerOffset);
    CGFloat skipButtonWidth = (16.0f/100.0f) * self.bounds.size.width - (2 * kShadowLayerOffset);
    CGFloat continueLabelWidth = (16.0f/100.0f) * self.bounds.size.width - (2 * kShadowLayerOffset);
    CGFloat backButtonX = kButtonPadding;
    CGFloat skipButtonX = self.bounds.size.width - (2.0f * kShadowLayerOffset) - continueLabelWidth - skipButtonWidth - kButtonPadding;
    CGFloat continueLabelX = self.bounds.size.width - (2.0f * kShadowLayerOffset) - continueLabelWidth - kButtonPadding;
    CGFloat buttonY = self.bounds.size.height - (2.0f * kShadowLayerOffset) - kButtonHeight;
    
    // Back button
    btnBack = [[UIButton alloc] initWithFrame:CGRectMake(backButtonX, buttonY, backButtonWidth, kButtonHeight)];
    [btnBack addTarget:self action:@selector(goToPreviousCoachMark) forControlEvents:UIControlEventTouchUpInside];
    [btnBack setTitle:@"Back" forState:UIControlStateNormal];
    btnBack.titleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
    btnBack.alpha = 0.0f;
    [self addSubview:btnBack];
    [UIView animateWithDuration:0.3f delay:1.0f options:0 animations:^{
        btnBack.alpha = 1.0f;
    } completion:nil];
    
    // Skip button
    btnSkipCoach = [[UIButton alloc] initWithFrame:CGRectMake(skipButtonX, buttonY, skipButtonWidth, kButtonHeight)];
    [btnSkipCoach addTarget:self action:@selector(skipCoach) forControlEvents:UIControlEventTouchUpInside];
    [btnSkipCoach setTitle:@"Skip" forState:UIControlStateNormal];
    btnSkipCoach.titleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
    btnSkipCoach.alpha = 0.0f;
    [btnSkipCoach setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [self addSubview:btnSkipCoach];
    [UIView animateWithDuration:0.3f delay:1.0f options:0 animations:^{
        btnSkipCoach.alpha = 1.0f;
    } completion:nil];
    
    // Next label
    lblContinue = [[UILabel alloc] initWithFrame:CGRectMake(continueLabelX, buttonY, continueLabelWidth, kButtonHeight)];
    lblContinue.font = [UIFont boldSystemFontOfSize:15.0f];
    lblContinue.textAlignment = NSTextAlignmentCenter;
    lblContinue.text = @"Next";
    lblContinue.alpha = 0.0f;
    lblContinue.textColor = [UIColor whiteColor];
    [self addSubview:lblContinue];
    [UIView animateWithDuration:0.3f delay:1.0f options:0 animations:^{
        lblContinue.alpha = 1.0f;
    } completion:nil];
}

#pragma mark - Cleanup

- (void)cleanup {
    // Delegate (coachMarksViewWillCleanup:)
    if ([self.delegate respondsToSelector:@selector(coachMarksViewWillCleanup:)]) {
        [self.delegate coachMarksViewWillCleanup:self];
    }
    
    // Fade out self
    [UIView animateWithDuration:self.animationDuration
                     animations:^{
                         self.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         // Remove self
                         [self removeFromSuperview];
                         
                         // Delegate (coachMarksViewDidCleanup:)
                         if ([self.delegate respondsToSelector:@selector(coachMarksViewDidCleanup:)]) {
                             [self.delegate coachMarksViewDidCleanup:self];
                         }
                     }];
}

#pragma mark - Animation delegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    // Delegate (coachMarksView:didNavigateTo:atIndex:)
    if ([self.delegate respondsToSelector:@selector(coachMarksView:didNavigateToIndex:)]) {
        [self.delegate coachMarksView:self didNavigateToIndex:self.markIndex];
    }
}

@end
