//
//  TLTransition.m
//  TLPopViewController
//
//  Created by 故乡的云 on 2018/8/1.
//  Copyright © 2018年 Gxdy. All rights reserved.
//  present 转场

#import "TLTransition.h"
#import "TLPopViewController.h"

/**
 * 自适应位置情况下的显示样式
 */
typedef enum : NSUInteger {
    TLShowTypeDefault = 0,    // TLPopType样式
    TLShowTypePoint = 1,      // 定点显示
    TLShowTypeFrame = 2,      // 动态Frame显示：frame1 -> frame2
    
} TLShowType;

// MARK: - TLTransition

@interface TLTransition ()
<UIViewControllerAnimatedTransitioning>
{
    BOOL _isAnimating; // 响应键盘动画中
}

/** 蒙板 */
@property(nonatomic, strong) UIView *coverView;
@property (nonatomic, strong) UIView *presentationWrappingView;

@property (nonatomic, weak) TLPopViewController *toVc;

@property(nonatomic, assign) TLShowType showType;

/** 最终显示坐标 */
@property(nonatomic, assign) CGPoint showPoint;

/** 最初显示坐标 */
@property(nonatomic, assign) CGRect initialFrame;
/** 最终显示坐标 */
@property(nonatomic, assign) CGRect finalFrame;

@end

@implementation TLTransition
// MARK: - 辅助方法
/// 当前控制器
+ (UIViewController *)topController {
    UIWindow *keyW = [UIApplication sharedApplication].keyWindow;
    UIViewController *appRootVC = keyW.rootViewController;
    
    return [self getTopViewControllerWithViewController:appRootVC];
}

+ (UIViewController *)getTopViewControllerWithViewController:(UIViewController *)vc {
    UIViewController *topVC = vc;
    if ([topVC isKindOfClass:[UITabBarController class]]) {
        topVC = ((UITabBarController *)topVC).selectedViewController;
        topVC = [self getTopViewControllerWithViewController:topVC];
        
    }else if([topVC isKindOfClass:[UINavigationController class]]){
        UINavigationController *navVc = (UINavigationController *)topVC;
        topVC = [self getTopViewControllerWithViewController:navVc.visibleViewController];
    }
    return topVC;
}

+ (BOOL)isIPhoneX {
    // iPhoneX 系列(XR & X Max : 414, 896, X & Xs : 375, 812)
    BOOL isIPhoneX = (CGSizeEqualToSize([UIScreen mainScreen].bounds.size, CGSizeMake(375, 812)) ||
                      CGSizeEqualToSize([UIScreen mainScreen].bounds.size, CGSizeMake(812, 375)) ||
                      CGSizeEqualToSize([UIScreen mainScreen].bounds.size, CGSizeMake(414, 896)) ||
                      CGSizeEqualToSize([UIScreen mainScreen].bounds.size, CGSizeMake(896, 414)));
    return isIPhoneX;
}

// MARK: - 创建实例并显示
+ (instancetype)showView:(UIView *)popView popType:(TLPopType)pType {
    
    return [self showView:popView
                 showType:TLShowTypeDefault
                  popType:pType
                  toPoint:CGPointZero
             initialFrame:CGRectNull
               finalFrame:CGRectNull];
}

+ (instancetype)showView:(UIView *)popView toPoint:(CGPoint)point {
    return [self showView:popView
                 showType:TLShowTypePoint
                  popType:TLPopTypeAlert
                  toPoint:point
             initialFrame:CGRectNull
               finalFrame:CGRectNull];
}

+ (instancetype)showView:(UIView *)popView
            initialFrame:(CGRect)iFrame
              finalFrame:(CGRect)fFrame {
   
    return [self showView:popView
                 showType:TLShowTypeFrame
                  popType:TLPopTypeAlert
                  toPoint:CGPointZero
             initialFrame:iFrame
               finalFrame:fFrame];
}

+ (instancetype)showView:(UIView *)popView
                showType:(TLShowType)showType
                 popType:(TLPopType)pType
                 toPoint:(CGPoint)point
            initialFrame:(CGRect)iFrame
              finalFrame:(CGRect)fFrame {
    UIViewController *topVc = [self topController];
    TLPopViewController *toVc = [[TLPopViewController alloc] init];
    [popView layoutIfNeeded];
    toVc.popView = popView;
    
    TLTransition *pt;
    pt = [[TLTransition alloc] initWithPresentedViewController:toVc
                                      presentingViewController:topVc];
    toVc.transitioningDelegate = pt;
    pt.showType = showType;
    
    if (showType == TLShowTypeFrame) {
        pt.initialFrame = iFrame;
        pt.finalFrame = fFrame;
    }else if (showType == TLShowTypePoint){
        pt.showPoint = point;
    }
    
    pt.allowTapDismiss = YES;
    pt.cornerRadius = 16;
    pt.popView = popView;
    pt.pType = pType;
    pt.toVc = toVc;
    [topVc presentViewController:toVc animated:YES completion:nil];
    return pt;
}

// 默认方法
- (instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController presentingViewController:(UIViewController *)presentingViewController
{
    self = [super initWithPresentedViewController:presentedViewController presentingViewController:presentingViewController];
    
    if (self) {
        presentedViewController.modalPresentationStyle = UIModalPresentationCustom;
    }
    
    return self;
}


// MARK: - lazy
- (UIView *)coverView {
    if (_coverView == nil) {
        _coverView = [[UIView alloc] initWithFrame:self.containerView.bounds];
        _coverView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        _coverView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        [_coverView addGestureRecognizer:tap];
    }
    
    return _coverView;
}

// MARK: - Actions
- (void)tap:(UITapGestureRecognizer *)tap {
    if (self.allowTapDismiss) {
        [self dismiss];
    }
}

- (void)dismiss {
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}


// MARK: - 重写
- (UIView*)presentedView
{
    return self.presentationWrappingView;
}

/** 即将布局转场子视图时调用 */
- (void)containerViewWillLayoutSubviews {
    [super containerViewWillLayoutSubviews];
    
    [self.containerView insertSubview:self.coverView atIndex:0];
    if(!_isAnimating) {
        self.presentationWrappingView.frame = self.frameOfPresentedViewInContainerView;
    }
}

- (void)presentationTransitionWillBegin
{
    
    UIView *presentedViewControllerView = [super presentedView];
    
    {
        UIView *presentationWrapperView = [[UIView alloc] initWithFrame:self.frameOfPresentedViewInContainerView];
        
        // 添加阴影
        if (_hideShadowLayer == NO) {
            presentationWrapperView.layer.shadowOpacity = 0.33f;
            presentationWrapperView.layer.shadowRadius = 13.f;
            CGSize size = self.pType == TLPopTypeActionSheet ? CGSizeMake(0, -6.f) : CGSizeMake(6, 6.f);
            presentationWrapperView.layer.shadowOffset = size;
        }
        self.presentationWrappingView = presentationWrapperView;
        
        /** 切角原理：
         * 底层一个有圆角的view，并且masksToBounds = YES，透明色
         * 顶层subView
         * 通过改变view在的中的高度来切除圆角
         *    view和subView重叠的角就会被切除【这里只要那个方向对齐或超出，就切除那个方向的圆角】
         *    当view和subView大小一样，完成重叠时就会四个角都会切出圆角
         */
        // 圆角
        CGFloat H = self.pType == TLPopTypeActionSheet ? -self.cornerRadius : 0.f;
        UIView *presentationRoundedCornerView = [[UIView alloc] initWithFrame:UIEdgeInsetsInsetRect(presentationWrapperView.bounds, UIEdgeInsetsMake(0, 0, H, 0))];
        presentationRoundedCornerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        presentationRoundedCornerView.layer.cornerRadius = self.cornerRadius;
        presentationRoundedCornerView.layer.masksToBounds = YES;
        
        
        // Add presentedViewControllerView -> presentationRoundedCornerView.
        CGRect frame = UIEdgeInsetsInsetRect(presentationRoundedCornerView.bounds, UIEdgeInsetsMake(0, 0, -H, 0));
        presentedViewControllerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        presentedViewControllerView.frame = frame;
        [presentationRoundedCornerView addSubview:presentedViewControllerView];
        
        // Add presentationRoundedCornerView -> presentationWrapperView.
        [presentationWrapperView addSubview:presentationRoundedCornerView];
        
    }
    
    
    {
        id<UIViewControllerTransitionCoordinator> transitionCoordinator = self.presentingViewController.transitionCoordinator;
        
        self.coverView.alpha = 0.f;
        [transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            self.coverView.alpha = 0.5f;
        } completion:nil];
    }
}

- (void)presentationTransitionDidEnd:(BOOL)completed
{
    if (completed == NO)
    {
        self.presentationWrappingView = nil;
        self.coverView = nil;
    }
}

- (void)dismissalTransitionWillBegin
{
    id<UIViewControllerTransitionCoordinator> transitionCoordinator = self.presentingViewController.transitionCoordinator;
    
    [transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.coverView.alpha = 0.f;
    } completion:nil];
}

- (void)dismissalTransitionDidEnd:(BOOL)completed
{
    if (completed == YES)
    {
        self.presentationWrappingView = nil;
        self.coverView = nil;
    }
}

#pragma mark -
#pragma mark Layout
/// 实时更新view的size
- (void)updateContentSize {
    [self.toVc updateContentSize];
}

- (void)preferredContentSizeDidChangeForChildContentContainer:(id<UIContentContainer>)container
{
    [super preferredContentSizeDidChangeForChildContentContainer:container];
    
    if (container == self.presentedViewController)
        [self.containerView setNeedsLayout];
}


- (CGSize)sizeForChildContentContainer:(id<UIContentContainer>)container withParentContainerSize:(CGSize)parentSize
{
    if (container == self.presentedViewController)
        return ((UIViewController*)container).preferredContentSize;
    else
        return [super sizeForChildContentContainer:container withParentContainerSize:parentSize];
}

// 最终frame
- (CGRect)frameOfPresentedViewInContainerView
{
    CGRect containerViewBounds = self.containerView.bounds;
    CGRect presentedViewControllerFrame = CGRectZero;
    CGSize presentedViewContentSize = [self sizeForChildContentContainer:self.presentedViewController withParentContainerSize:containerViewBounds.size];
    
    if(_showType == TLShowTypePoint){
        CGSize size = presentedViewContentSize;
        // 越界
        size.width = size.width > tl_ScreenW ? tl_ScreenW : size.width;
        size.height = size.height > tl_ScreenH ? tl_ScreenH : size.height;
       
        // 边缘化计算
        CGFloat x = self.showPoint.x;
        CGFloat y = self.showPoint.y;
        x = x + size.width > tl_ScreenW ? tl_ScreenW - size.width : x;
        y = y + size.width > tl_ScreenH ? tl_ScreenH - size.width : y;
        
        presentedViewControllerFrame.origin = CGPointMake(x, y);
        presentedViewControllerFrame.size = size;
        
    }else if(_showType == TLShowTypeFrame){
        
        presentedViewControllerFrame = self.finalFrame;
        
    }else { // default
        presentedViewControllerFrame.size = presentedViewContentSize;
        if(self.pType == TLPopTypeActionSheet){
            if([[self class] isIPhoneX]){
                presentedViewControllerFrame.size.height += 34;
            }
            presentedViewControllerFrame.origin.y = CGRectGetMaxY(containerViewBounds) - presentedViewControllerFrame.size.height;
        }else if(self.pType == TLPopTypeAlert){
            // 垂直居中
            presentedViewControllerFrame.origin.y = (CGRectGetMaxY(containerViewBounds) - presentedViewContentSize.height) * 0.5;
        }
        
        presentedViewControllerFrame.origin.x = (CGRectGetMaxX(containerViewBounds) - presentedViewContentSize.width) * 0.5; // 水平居中
    }
    return presentedViewControllerFrame;
}

// MARK: - 关联键盘动画
- (void)setAllowObserverForKeyBoard:(BOOL)allowObserverForKeyBoard {
    _allowObserverForKeyBoard = allowObserverForKeyBoard;
    if (_allowObserverForKeyBoard) {
        SEL sel = @selector(observerOfKeyBoard:);
        NSNotificationCenter *nCenter = [NSNotificationCenter defaultCenter];
        [nCenter addObserver:self selector:sel name:UIKeyboardWillShowNotification object:nil];
        [nCenter addObserver:self selector:sel name:UIKeyboardWillHideNotification object:nil];
    }else {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void)observerOfKeyBoard:(NSNotification *)notice {
    UIView *view = self.presentedView;
    
    NSNotificationName name = notice.name;
    NSDictionary *userInfo = notice.userInfo;
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    if ([name isEqualToString:@"UIKeyboardWillShowNotification"]) {
        CGRect rect1 = view.frame;
        CGRect rect2 = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        rect2.origin.y -= 40; // inputView
        if(CGRectIntersectsRect(rect1, rect2)) {
            _isAnimating = YES;
            CGRect frame = view.frame;
            CGFloat offsetY = CGRectGetMaxY(rect1) - CGRectGetMinY(rect2);
            frame.origin.y -= offsetY;
            [UIView animateWithDuration:duration animations:^{
                view.frame = frame;
            } completion:^(BOOL finished) {
                self->_isAnimating = NO;
            }];
        }
        
    }else {
        if (CGPointEqualToPoint(view.frame.origin, self.frameOfPresentedViewInContainerView.origin) ) {
            return;
        }
        CGRect frame = view.frame;
        frame.origin = self.frameOfPresentedViewInContainerView.origin;
        [UIView animateWithDuration:duration animations:^{
            view.frame = self.frameOfPresentedViewInContainerView;
        }];
    }
}



#pragma mark -
#pragma mark UIViewControllerAnimatedTransitioning

/** 返回动画时长
 * @param transitionContext 上下文, 里面保存了动画需要的所有参数
 * @return 动画时长
 */
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return [transitionContext isAnimated] ? 0.35 : 0;
}

// 动画效果
- (void)animateTransition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *containerView = transitionContext.containerView;
    
    // For a Presentation:
    //      fromView = The presenting view.
    //      toView   = The presented view.
    // For a Dismissal:
    //      fromView = The presented view.
    //      toView   = The presenting view.
    UIView *fromView;
    UIView *toView;
    if ([transitionContext respondsToSelector:@selector(viewForKey:)]) {
        fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
        toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    } else {
        fromView = fromViewController.view;
        toView = toViewController.view;
    }
    
    switch (self.showType) {
        case TLShowTypePoint:
            [self showTypePointAnimateTransition:transitionContext
                                fromViewController:fromViewController
                                  toViewController:toViewController
                                     containerView:containerView
                                          fromView:fromView
                                            toView:toView];
            break;
        case TLShowTypeFrame:
            [self showTypeFrameAnimateTransition:transitionContext
                                fromViewController:fromViewController
                                  toViewController:toViewController
                                     containerView:containerView
                                          fromView:fromView
                                            toView:toView];
            break;
        default:
            [self showTypeDefaultAnimateTransition:transitionContext
                                fromViewController:fromViewController
                                  toViewController:toViewController
                                     containerView:containerView
                                          fromView:fromView
                                            toView:toView];
            break;
    }
}

// showTypeDefault
- (void)showTypeDefaultAnimateTransition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext
                      fromViewController:(UIViewController *)fromViewController
                        toViewController:(UIViewController *)toViewController
                           containerView:(UIView *)containerView
                                fromView:(UIView *)fromView
                                  toView:(UIView *)toView
{
    if(self.pType == TLPopTypeAlert){
        fromView.alpha = 1.0f;
        toView.alpha = 0.0f;
        
        [containerView addSubview:toView];
        
        NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];
        [UIView animateWithDuration:transitionDuration animations:^{
            fromView.alpha = 0.0f;
            toView.alpha = 1.0;
            
        } completion:^(BOOL finished) {
            
            BOOL wasCancelled = [transitionContext transitionWasCancelled];
            [transitionContext completeTransition:!wasCancelled];
        }];
        
    }else if (self.pType == TLPopTypeActionSheet){
        BOOL isPresenting = (fromViewController == self.presentingViewController);
        
        // 我们定义了变量后，如果不使用就会出现警告.如果在变量前加__unused前缀，就可以免除警告。其原理是告诉编译器，如果变量未使用就不参与编译
        CGRect __unused fromViewInitialFrame = [transitionContext initialFrameForViewController:fromViewController];
        CGRect fromViewFinalFrame = [transitionContext finalFrameForViewController:fromViewController];
        CGRect toViewInitialFrame = [transitionContext initialFrameForViewController:toViewController];
        CGRect toViewFinalFrame = [transitionContext finalFrameForViewController:toViewController];
        
        [containerView addSubview:toView];
        
        if (isPresenting) {
            CGFloat x = (CGRectGetMaxX(containerView.bounds) - toViewFinalFrame.size.width) * 0.5;
            toViewInitialFrame.origin = CGPointMake(x, CGRectGetMaxY(containerView.bounds));
            toViewInitialFrame.size = toViewFinalFrame.size;
            toView.frame = toViewInitialFrame;
            
        } else {
            fromViewFinalFrame = CGRectOffset(fromView.frame, 0, CGRectGetHeight(fromView.frame));
        }
        
        NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];
        
        [UIView animateWithDuration:transitionDuration animations:^{
            if (isPresenting)
                toView.frame = toViewFinalFrame;
            else
                fromView.frame = fromViewFinalFrame;
            
        } completion:^(BOOL finished) {
            BOOL wasCancelled = [transitionContext transitionWasCancelled];
            [transitionContext completeTransition:!wasCancelled];
        }];
    }
}

// showTypePoint
- (void)showTypePointAnimateTransition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext
                    fromViewController:(UIViewController *)fromViewController
                      toViewController:(UIViewController *)toViewController
                         containerView:(UIView *)containerView
                              fromView:(UIView *)fromView
                                toView:(UIView *)toView
{
    [self showTypeDefaultAnimateTransition:transitionContext
                        fromViewController:fromViewController
                          toViewController:toViewController
                             containerView:containerView
                                  fromView:fromView
                                    toView:toView];
}

// showTypeFrame
- (void)showTypeFrameAnimateTransition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext
                    fromViewController:(UIViewController *)fromViewController
                      toViewController:(UIViewController *)toViewController
                         containerView:(UIView *)containerView
                              fromView:(UIView *)fromView
                                toView:(UIView *)toView
{
    
}

#pragma mark -
#pragma mark UIViewControllerTransitioningDelegate

- (UIPresentationController*)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source
{
    NSAssert(self.presentedViewController == presented, @"You didn't initialize %@ with the correct presentedViewController.  Expected %@, got %@.",
             self, presented, self.presentedViewController);
    
    return self;
}


/** 告诉系统谁来负责Modal的 present动画
 *  只要实现了一下方法, 那么系统自带的默认动画就没有了, "所有"东西都需要程序员自己来实现
 * @param presented  被展现视图
 * @param presenting 发起的视图
 * @return 谁来负责
 */
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return self;
}


/** 告诉系统谁来负责Modal的 消失动画
 * @param dismissed 被关闭的视图
 * @return 谁来负责
 */
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return self;
}

- (void)dealloc{
    tl_LogFunc
}
@end


// MARK: -
// MARK: - TLTransition (UIViewController)
@implementation TLTransition (UIViewController)



@end

