%config(generator=internal);
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import <string.h>

// PromoTrace is diagnostic-only: no presentation is blocked or dismissed.
#define BEAR_PROMO_TRACE_ENABLED 1

static BOOL BearComesFromEnhancer(const void *caller) {
#if BEAR_PROMO_TRACE_ENABLED
    Dl_info symbol = {0};
    return caller != NULL && dladdr(caller, &symbol) != 0 &&
           symbol.dli_fname != NULL && strstr(symbol.dli_fname, "BluedEnhancer") != NULL;
#else
    return NO;
#endif
}

static BOOL BearClassBelongsToEnhancer(Class cls) {
#if BEAR_PROMO_TRACE_ENABLED
    const char *image = cls != Nil ? class_getImageName(cls) : NULL;
    return image != NULL && strstr(image, "BluedEnhancer") != NULL;
#else
    return NO;
#endif
}

// The startup splash image ad is owned by Blued itself (verified in the
// 2026-10-30 launch log), not by BluedEnhancer. Match only this exact
// controller; other Blued ads and every enhancer feature are untouched.
#define BEAR_BLOCK_STARTUP_SPLASH 1
static NSString *const kBearStartupSplashClass = @"BDADX_Blued_Splash_Image_ViewController";

static BOOL BearIsStartupSplash(UIViewController *controller) {
    if (!controller) return NO;
    if ([NSStringFromClass(controller.class) isEqualToString:kBearStartupSplashClass]) return YES;
    // Only unwrap a navigation controller whose sole root is the splash.
    if ([controller isKindOfClass:[UINavigationController class]]) {
        NSArray<UIViewController *> *stack = ((UINavigationController *)controller).viewControllers;
        return stack.count == 1 &&
               [NSStringFromClass(stack.firstObject.class) isEqualToString:kBearStartupSplashClass];
    }
    return NO;
}

// This class is present in Blued's own ObjC class table. Its native
// dealForSkipCloseSplashAd calls the supplied skip handler and dismisses the ad.
@interface BDADX_Blued_Splash_Image_ViewController : UIViewController
- (void)presentBluedSplashImageViewController;
- (void)dealForSkipCloseSplashAd;
@end

// The credit belongs beside the existing BluedEnhancer Telegram/version area,
// not at the end of UITableView.tableFooterView.
static NSString *const kBearPluginLabelText = @"Bear 来过 🐻";
static const NSInteger kBearPluginLabelTag = 20261030;

static UILabel *BearFindTextLabel(UIView *root, NSString *needle) {
    if ([root isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)root;
        NSString *text = label.text ?: label.attributedText.string;
        if ([text containsString:needle]) {
            return label;
        }
    }
    for (UIView *child in root.subviews) {
        UILabel *result = BearFindTextLabel(child, needle);
        if (result != nil) {
            return result;
        }
    }
    return nil;
}

static void BearPlaceCreditNearTelegram(UIViewController *controller) {
    if (![NSStringFromClass(controller.class) isEqualToString:@"tjq"] ||
        ![controller isKindOfClass:[UITableViewController class]]) {
        return;
    }
    UITableView *table = ((UITableViewController *)controller).tableView;
    if (table == nil || !controller.isViewLoaded) {
        return;
    }

    // These are the exact strings identified in the original dylib.
    // UIKit may render them inside a cell, header, or the custom settings view.
    UILabel *telegram = BearFindTextLabel(table, @"多啦B梦");
    UILabel *version = BearFindTextLabel(table, @"2.8.9 Final");
    if (version == nil) {
        version = BearFindTextLabel(table, @"Final终版");
    }

    // Without an actual visible anchor, do not guess a fixed bottom position.
    UIView *anchor = version != nil ? version : telegram;
    if (anchor == nil || anchor.window == nil) {
        return;
    }

    CGRect anchorRect = [anchor convertRect:anchor.bounds toView:table];
    CGRect telegramRect = telegram != nil ?
        [telegram convertRect:telegram.bounds toView:table] : CGRectZero;

    // Prefer immediately under the TG text when the gap to version allows it.
    CGFloat y = CGRectGetMaxY(anchorRect) + 3.0;
    if (telegram != nil && version != nil &&
        CGRectGetMinY(anchorRect) - CGRectGetMaxY(telegramRect) >= 24.0) {
        y = CGRectGetMaxY(telegramRect) + 3.0;
    }

    CGFloat width = MAX(0.0, CGRectGetWidth(table.bounds) - 24.0);
    CGRect creditFrame = CGRectMake(12.0, y, width, 19.0);
    UILabel *credit = (UILabel *)[table viewWithTag:kBearPluginLabelTag];
    if (credit == nil) {
        credit = [[UILabel alloc] initWithFrame:creditFrame];
        credit.tag = kBearPluginLabelTag;
        credit.text = kBearPluginLabelText;
        credit.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        credit.textColor = UIColor.labelColor;
        credit.textAlignment = NSTextAlignmentCenter;
        credit.backgroundColor = UIColor.clearColor;
        credit.userInteractionEnabled = NO;
        [table addSubview:credit];
        NSLog(@"[bluedXHook] TG/version anchor found. TG=%d version=%d; added credit at y=%.1f",
              telegram != nil, version != nil, y);
    } else {
        // Table/cell layout may change; follow the existing version text.
        credit.frame = creditFrame;
    }

    // Allow scrolling to the credit even if the plugin's version is its last row.
    // This does not move or replace the Telegram action or original labels.
    UIEdgeInsets inset = table.contentInset;
    if (inset.bottom < 32.0) {
        inset.bottom = 32.0;
        table.contentInset = inset;
    }
}

// We know the settings class (tjq) because its heOpenTelegram method appears
// in BluedEnhancer, but hook the UIKit superclass so late class loading is OK.
%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig(animated);
#if BEAR_BLOCK_STARTUP_SPLASH
    // This covers any alternate code path adding the splash view directly to
    // the existing root window, bypassing the class's own present method.
    if (BearIsStartupSplash((UIViewController *)self)) {
        UIView *adView = self.view;
        NSLog(@"[bluedXHook][StartupAd] fallback: appeared by direct view insertion, superview=%@ root=%@",
              NSStringFromClass(adView.superview.class),
              NSStringFromClass(adView.window.rootViewController.class));
        adView.hidden = YES;
        adView.userInteractionEnabled = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            BDADX_Blued_Splash_Image_ViewController *splash =
                (BDADX_Blued_Splash_Image_ViewController *)self;
            [splash dealForSkipCloseSplashAd];
            [adView removeFromSuperview];
            NSLog(@"[bluedXHook][StartupAd] fallback: native skip/close completed, view detached");
        });
    }
#endif
#if BEAR_PROMO_TRACE_ENABLED
    if (BearClassBelongsToEnhancer(self.class)) {
        NSLog(@"[bluedXHook][PromoTrace] plugin controller appeared=%@ presentedBy=%@",
              NSStringFromClass(self.class), NSStringFromClass(self.presentingViewController.class));
    }
#endif
    if ([NSStringFromClass(self.class) isEqualToString:@"tjq"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            BearPlaceCreditNearTelegram((UIViewController *)self);
        });
    }
}


- (void)presentViewController:(UIViewController *)controller animated:(BOOL)animated completion:(void (^)(void))completion {
#if BEAR_BLOCK_STARTUP_SPLASH
    if (BearIsStartupSplash(controller)) {
        NSLog(@"[bluedXHook][StartupAd] blocked present host=%@ target=%@",
              NSStringFromClass(self.class), NSStringFromClass(controller.class));
        if (completion) completion();
        return;
    }
#endif
#if BEAR_PROMO_TRACE_ENABLED
    // Only observe presentations initiated by the enhancer itself, not all Blued UI.
    if (BearComesFromEnhancer(__builtin_extract_return_addr(__builtin_return_address(0))) ||
        BearClassBelongsToEnhancer(controller.class)) {
        NSString *alertTitle = @"";
        NSString *alertMessage = @"";
        if ([controller isKindOfClass:[UIAlertController class]]) {
            UIAlertController *alert = (UIAlertController *)controller;
            alertTitle = alert.title ?: @"";
            alertMessage = alert.message ?: @"";
        }
        NSLog(@"[bluedXHook][PromoTrace] present host=%@ target=%@ owner=%d title=%@ message=%@",
              NSStringFromClass(self.class), NSStringFromClass(controller.class),
              BearClassBelongsToEnhancer(controller.class), alertTitle, alertMessage);
    }
#endif
    %orig(controller, animated, completion);
}
- (void)viewDidLayoutSubviews {
    %orig;
    if ([NSStringFromClass(self.class) isEqualToString:@"tjq"]) {
        BearPlaceCreditNearTelegram((UIViewController *)self);
    }
}

%end


// Blued presents this splash by attaching its view to AppDelegate's window,
// not by using UIKit presentViewController / UINavigationController push.
// Hook the method found in the original Blued executable instead of guessing.
#if BEAR_BLOCK_STARTUP_SPLASH
%hook BDADX_Blued_Splash_Image_ViewController
- (void)presentBluedSplashImageViewController {
    NSLog(@"[bluedXHook][StartupAd] blocked native splash presentation; running native skip/close");
    [self dealForSkipCloseSplashAd];
    // Do not call %orig: that is the method that installs the ad into the window.
}
%end
#endif

#if BEAR_PROMO_TRACE_ENABLED
%hook UIWindow
- (void)makeKeyAndVisible {
    if (BearComesFromEnhancer(__builtin_extract_return_addr(__builtin_return_address(0)))) {
        NSLog(@"[bluedXHook][PromoTrace] window makeKeyAndVisible root=%@ level=%.1f",
              NSStringFromClass(self.rootViewController.class), self.windowLevel);
    }
    %orig;
}
%end
#endif

#if BEAR_PROMO_TRACE_ENABLED
%hook UINavigationController
- (void)pushViewController:(UIViewController *)controller animated:(BOOL)animated {
#if BEAR_BLOCK_STARTUP_SPLASH
    if (BearIsStartupSplash(controller)) {
        NSLog(@"[bluedXHook][StartupAd] blocked navigation push target=%@",
              NSStringFromClass(controller.class));
        return;
    }
#endif
    if (BearComesFromEnhancer(__builtin_extract_return_addr(__builtin_return_address(0))) ||
        BearClassBelongsToEnhancer(controller.class)) {
        NSLog(@"[bluedXHook][PromoTrace] navigation push target=%@ parent=%@",
              NSStringFromClass(controller.class), NSStringFromClass(self.class));
    }
    %orig(controller, animated);
}
%end

%hook UIAlertController
+ (instancetype)alertControllerWithTitle:(NSString *)title message:(NSString *)message preferredStyle:(UIAlertControllerStyle)style {
    if (BearComesFromEnhancer(__builtin_extract_return_addr(__builtin_return_address(0)))) {
        NSLog(@"[bluedXHook][PromoTrace] plugin alert created title=%@ message=%@", title ?: @"", message ?: @"");
    }
    return %orig(title, message, style);
}
%end
#endif

%ctor {
    NSLog(@"[bluedXHook] TG area credit hook initialized");
    %init;
}

